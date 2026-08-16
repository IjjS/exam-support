---
name: exam-quiz
description: Generate and grade certification exam questions, then record the weaknesses they expose. Use when the user says "문제 내줘", "퀴즈", "시험 보자", "5문제", "모의고사", "D2만 풀래", "문제 풀기", or "quiz". Picks diagnostic vs weakness mode automatically from session count, treats confidence-tagged guesses as wrong even when the answer is correct, classifies error types, and updates the state files.
---

# exam-quiz

Ask questions, grade them, and **find what the user doesn't know.** This is the only high-frequency skill in the repo,
so it is deliberately sensitive to token cost and response latency.

**Talk to the user in their own language.** The language of the questions themselves is set by the anchors
in `format.md` — it follows the exam, not the conversation.

## Phase 0 — Resolve the target, read as little as possible

1. `exams/_active.md` → active slug. A slug named by the user wins
   - **If the user named a different exam, update `exams/_active.md` to it before continuing.**
     Rewrite the `active:` line and its one-line description. Say so in one line: `"활성 자격증을 aws-sap-c02로 전환했습니다"`.
     Without this the user has to retype the slug every session, and the next bare `/exam-quiz` silently
     goes back to the old exam
   - No confirmation needed — naming an exam to study is the intent, and switching back costs one word
2. No exam registered → tell the user `"등록된 자격증이 없습니다. /exam-init {자격증명}"` and **stop**
3. `exams/{slug}/state/sessions.md` via **`Read(limit=15)`** (hot block only)
4. `exams/{slug}/format.md` in full
5. `exams/{slug}/state/mastery.md` in full
6. `exams/{slug}/state/wrongbook.md` in full

**Never read**: `blueprint.md`, `state/log/`, `_resolved.md`, `state/format-drift.md`.
mastery already carries topic names and domains, so blueprint is unnecessary.

If `sessions.md` was modified within the last 5 minutes, another session may be running — warn in one line and continue.

## Phase 1 — Mode gating

```
basic_done = (diagnostic + mock) from the sessions hot block

basic_done < 3   →  basic (diagnostic) mode, unconditionally
                    if the user asked for weakness mode:
                    "약점 파악이 아직 부족합니다 ({n}/3회). 이번엔 기본모드로 갑니다."
                    allow one override if they ask again
basic_done >= 3  →  weakness mode (default)
```

An explicit user instruction wins: domain (`D2`), question count (`10문제`), mock exam.

| Mode | Topic selection | Difficulty |
|---|---|---|
| Basic (diagnostic) | **⬜ untested first** + spread across domains by weight | easy 40 / med 40 / hard 20 |
| Weakness | Top scores + lucky-guess topics + active wrong answers | med 30 / hard 70 |
| Section | Same rules inside the named domain | med 40 / hard 60 |
| Mock exam | → `references/mock-exam.md` | Real weights |

Default is **5 questions**. Announce the resolved mode in one line before starting.

## Phase 2 — Topic selection

The weakness score is already stored on each mastery row. **Sort, do not recompute.**

```
score = (1-accuracy)×3 + lucky_rate×2 + shaky_rate×1 + domain_weight + staleness
```

- No more than 3 questions from one domain
- Re-asking active wrong answers is capped at **40% of the questions**; the rest are new topics
- When re-asking, **never reuse the same question** — probe the same knowledge from a different angle
- Skip `deprecated` topics

## Phase 3 — Question generation

**Read `references/quiz-rules.md` before writing any question.**

Follow `format.md` for the single/multiple-response mix, stem length, phrasing, and distractor patterns.

### Three-tier sourcing

```
1. notes/{domain}/{topic}.md exists  →  generate from the note only
2. No note                           →  verify against vendor official docs via WebSearch/WebFetch
3. Web also fails                    →  Claude's own knowledge, tagged [UNVERIFIED]
```

**Tier 2 is capped at two questions per session.** Anything beyond that falls to tier 3.
A slow start on a phone means the tool stops getting used — speed beats accuracy here.

Every topic sourced via tier 2 or 3 goes into `harvest-queue.md` (reason: `unverified-question`).

### Presentation

Present all five questions **at once**. Questions and options in English, the surrounding guidance in Korean.
Options are numbered, matching the numeric answer syntax.

```
Q1. (single) [stem]
  1. …  2. …  3. …  4. …

Q2. (Choose TWO) [stem]
  1. …  2. …  3. …  4. …  5. …
...

답변: 문항 순서대로 한 줄로. `?`=애매, `??`=찍음, 복수선택은 `2,4`
```

### ⛔ The answer-syntax line must not carry answers

**Print the 답변 line exactly as written above. Never build a worked example of the full answer string.**

The failure mode is mechanical: an example like `1 3? 2,4?? 5 1` has **the same number of slots as the question set**,
so those slots get filled with the real answers while appearing to demonstrate formatting. It reads as instruction and
functions as a leak.

- Never produce an example whose length matches the question count. If one token of illustration is needed, use `3?` — arity 1
- Never number the syntax explanation per question (`Q1은 이렇게, Q2는…`)
- Never say which questions are single vs multiple **beyond the `(single)` / `(Choose TWO)` marker already on each stem**
- Never comment on difficulty, on which option is tempting, or on how many people miss it
- Do not restate the answer syntax after the questions; the one line above is enough

### Before sending, verify

```
□ Does the 답변 line match the template exactly, with no per-question example?
□ Does any example string have as many slots as there are questions?  → if yes, remove it
□ Does any text before the user's reply name, rank, or hint at a correct option?
```

If any check fails, rewrite before sending. **Nothing preceding the user's answer may narrow the option set.**

## Phase 4 — Grading

### Parsing answers

```
2       confident
2?      shaky
2??     guessed    lucky (recorded as wrong even when correct)
2,4     multiple response
2,4??   multiple response, guessed
```

- Multiple response has **no partial credit.** Exact match only. Record `partial 1/2` in the notes column
- No question mark means confident. If parsing is ambiguous, assume confident and move on — do not ask again

### Verdict

```
correct + confident/shaky  →  correct
correct + guessed (??)     →  ★ recorded as wrong (lucky +1)
wrong                      →  wrong
```

Counting lucky guesses as wrong is the core of this system. Do not soften it.

### Handling wrong answers

For each wrong answer (lucky guesses included), **read `_spec/error-taxonomy.md`** and assign a type.
Skip that read entirely if nothing was wrong.

Explain **only the wrong ones, in 3-5 lines** (Korean): why the answer is right, and why their pick is not.
Say nothing about the ones they got right.

## Phase 5 — Recording

Update the following, **in order**.

| File | Update |
|---|---|
| `state/log/{YYYY-MM}.md` | Append full question, options, user answer, correct answer, explanation (**write-only**) |
| `state/mastery.md` | For each topic asked: attempts / correct / lucky / shaky / status / last / **recomputed score**. Refresh the hot block |
| `state/wrongbook.md` | Add one line per new wrong answer, increment repeats for recurrences, move three-in-a-row correct entries to `_resolved.md`. Refresh the hot block |
| `state/sessions.md` | Refresh the hot block, append a log row (with the `fmt:` stamp) |
| `state/harvest-queue.md` | Queue tier 2/3 topics, plus `unknown` and `thin-note` cases |
| `exams/_registry.md` | Update this slug's coverage, accuracy, session count |

**Do not modify `blueprint.md`.**

## Phase 6 — Wrap-up, 3 lines or fewer (Korean)

```
3/5  (실질 2/5 — Q4는 찍어서 맞음)
🟥 T-041 TGW 라우팅 2연속 오답 · 개념혼동 → /exam-comp 로 비교표 권장
큐 7개 쌓임. /exam-harvest 3 (약 2분)
```

- With three or more queued topics, always nudge harvest. Thin notes degrade question quality and the tool stops getting used
- Mention coverage in one line if it moved
- When `basic_done` reaches 3, say that weakness mode takes over from the next session

## Never

- Hint at the answer in the options (`(recommended)`, length bias, `All of the above`)
- Re-ask a previous question with its original wording
- Write a long explanation for a question answered correctly
- Read `blueprint.md` or `state/log/`
- **Reveal, rank, or hint at answers before the user responds — including inside a formatting example.**
  A worked answer-syntax string is the most common way this happens; see the guard in Phase 3
