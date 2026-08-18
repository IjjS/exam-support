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
| Basic (diagnostic) | **⬜ untested first**, allocated by blueprint weight | easy 40 / med 40 / hard 20 |
| Weakness | Top scores + lucky-guess topics + active wrong answers | med 30 / hard 70 |
| Section | Same rules inside the named section | med 40 / hard 60 |
| Mock exam | → `references/mock-exam.md` | Real weights |

Default is **5 questions**. Announce the resolved mode in one line before starting.

## Phase 2 — Topic selection

The weakness score is already stored on each mastery row. **Sort, do not recompute.**

```
score = (1-accuracy)×3 + lucky_rate×2 + shaky_rate×1 + domain_weight + staleness
```

### Spread — by share, not by count

The blueprint's structure drives the spread. Express every limit as a **percentage of the session**, never as a
fixed number of questions: three-of-five and three-of-fifty are not the same request.

| Mode | Allocation |
|---|---|
| Basic · Mock | **Match the blueprint weights.** Allocate by largest remainder, so 5 questions over 26/29/25/20 gives 1/2/1/1 |
| Weakness | Weight is only one term in the score. Cap any single section at **60% of the session** so at least two get touched |
| Section | The named section takes 100%; spread within it instead |

With 5 questions, the 60% cap works out to 3 — the same as the old fixed rule. With 30 it becomes 18,
which the old rule would have wrongly held to 3.

**If the exam has no sections** (`structure: flat` in blueprint), none of this applies. Spread across the topic
list instead: no two questions from adjacent topic IDs, since neighbouring IDs came from the same part of the
source material.

### Angle — probe a recurring topic from a different side

`mastery.Angle` holds the single code last used for that topic, drawn from the `angles:` list in `format.md`.
When a topic comes up again, **prefer an angle different from the recorded one.**

Getting a topic right three times from one angle is not mastery of the topic — it is mastery of one facet.
🟦 earned entirely through `cost` says nothing about whether the same service is understood under `resilient`.

**The exam's distribution wins.** `format.md` says how often each angle really appears; if an exam is 60% `cost`,
forcing variety would train against the real paper. Pick within the distribution first, and use angle difference
only to break ties. Never distort the mix to chase a fresh angle.

If `format.md` has no `angles:` list, skip this entirely — there is no axis to vary along.

- Re-asking active wrong answers is capped at **40% of the questions**; the rest are new topics
- When re-asking, **never reuse the same question** — probe the same knowledge from a different angle
- Skip `deprecated` topics

## Phase 3 — Question generation

**Read `references/quiz-rules.md` before writing any question.**

Follow `format.md` for the single/multiple-response mix, stem length, phrasing, and distractor patterns.

### Three-tier sourcing

```
1. the topic's note exists           →  generate from the note only
2. No note                           →  verify against vendor official docs via WebSearch/WebFetch
3. Web also fails                    →  Claude's own knowledge, tagged [UNVERIFIED]
```

**Tier 2 is capped at two questions per session.** Anything beyond that falls to tier 3.
A slow start on a phone means the tool stops getting used — speed beats accuracy here.

Every topic sourced via tier 2 or 3 goes into `harvest-queue.md` (reason: `unverified-question`).

**Tier 2 queues the URL it just used**, in the queue's `Source` column. You paid to find and verify that page;
harvest would otherwise search for it again from scratch. Tier 3 leaves `Source` empty — there was nothing to record.

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

### Log the questions now, before the user answers

Immediately after emitting the questions, append the question block to `state/log/{YYYY-MM}.md`.

**Do this here, not after grading.** The user is about to spend minutes reading and solving; a write issued now
costs them nothing. The same write issued after they submit is roughly 2,000 tokens sitting directly in front of
the answer they are waiting for.

Heading carries a session-question ref, since no wrongbook ID exists yet:

```
### S12-Q3 — T-034 · D2 · Database replication · hard · single · [UNVERIFIED]
```

Write the stem, the options, and nothing else. Verdicts and the `W-id` come later as a short delta.

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

Scoring and the review queue are **two separate decisions.** A question can score as correct and still
belong in the wrongbook.

| Answer | Scored | Wrongbook | origin |
|---|---|---|---|
| correct + confident | correct | — | |
| **correct + `?`** | **correct** | **✅ added** | `shaky` |
| correct + `??` | **wrong** | ✅ added | `lucky` |
| wrong | wrong | ✅ added | `miss` |

- **`??` is scored as wrong.** Getting it right by guessing is not knowing it. Do not soften this
- **`?` is scored as correct but still queued.** The user narrowed it to two and happened to pick right;
  that is a coin flip they won. It goes in the review queue without being punished in the score
- Accuracy stays `(correct - lucky) / attempts`. Shaky answers were genuinely correct, so they count —
  the wrongbook entry is how they get revisited, not a score penalty

Record the origin on every wrongbook entry. Three different signals need three different treatments.

### Older wrongbooks without the origin column

A book created before origin tracking has no `origin` or `Streak` column. Do not rewrite its history.

- Add the two columns, leaving them blank on existing rows
- A blank origin is treated as `miss` (the strictest bar: 3 confident correct)
- New rows get a real origin
- Refresh the hot block to the `active: n (miss / lucky / shaky)` form, counting blanks as `miss`

Say in one line that the format was extended. Never guess an origin for a past entry — the information was
not recorded, and inventing it would corrupt the one dataset that cannot be regenerated.

### Explanations — every option, one line each

**Every question gets a verdict on every option**, including questions answered correctly.
Knowing why the other four fail is the discrimination the exam actually tests.

```
Q3   정답 4   내 답 2 ✗

  1  ✗  리전 간 전이 라우팅 불가
  2  ✗  동작은 하나 운영부담 큼 — "LEAST operational overhead" 위반
  3  ✗  DX는 구축에 수 주 — "quickly" 위반
  4  ✓  TGW + VPN. 요구조건 3개 충족
  5  ✗  실재하지 않는 조합
```

- **One line per option. No prose, no paragraph under any option.** The fixed shape is what keeps this
  readable on a phone and what stops explanations from expanding
- Name the reason, not just the verdict. `"운영부담 위반"` beats `"틀림"`; where a distractor pattern applies
  (`D1` legacy bait, `D2` over-engineering …) name it — the pattern is more memorable than the instance
- Show `내 답` only when it differs from the answer
- For multiple response, mark every correct option `✓`

If the user asks for depth on a specific question after seeing this, give it then. Do not pre-empt it.

### Classifying what goes in the wrongbook

For every `miss`, `lucky`, and `shaky` entry, **read `_spec/error-taxonomy.md`** and assign a type.
Skip that read entirely if all five were confident and correct.

`shaky` almost always classifies as `confusion` — "I narrowed it to two" is the definition of a blurred
boundary. If the user names the other option they were weighing, record the pair; it becomes an `exam-comp` candidate.

## Phase 5 — Recording

### Show the results before writing anything

**Emit the graded output as text first.** Only then touch files.

The user has been waiting since they hit send; the verdicts are what they are waiting for, and every file write
placed ahead of them is dead time. Once the results are on screen they start reading, and the writes happen
underneath that.

### Then issue the writes together, not in sequence

These six touch six different files and **none of them reads another's output**. Issue them as parallel tool
calls in a single step. Sequencing them multiplies the wait for no benefit.

The one thing to settle *before* writing is the `W-id` for each new wrongbook entry — the log delta and the
wrongbook row both reference it. That is a decision, not a file read, so it does not force an order.

| File | Update |
|---|---|
| `state/log/{YYYY-MM}.md` | **Short delta only** — the question block is already there from Phase 3. Append one result line per question: answer, the user's pick, confidence, `W-id`, per-option verdicts |
| `state/mastery.md` | For each topic asked: attempts / correct / lucky / shaky / status / last / **recomputed score** / **the angle just used**. Refresh the hot block |
| `state/wrongbook.md` | Add one line per `miss` / `lucky` / `shaky`, with its origin. Increment repeats for recurrences. Retire entries that met their streak to `_resolved.md`. Refresh the hot block |
| `state/sessions.md` | Refresh the hot block, append a log row (with the `fmt:` stamp) |
| `state/harvest-queue.md` | Queue tier 2/3 topics with the `Source` URL where one exists, plus `unknown` and `thin-note` cases |
| `exams/_registry.md` | Update this slug's coverage, accuracy, session count |

**Do not modify `blueprint.md`.**

### The log result line — the anchor that makes the log searchable

The question block went in during Phase 3 under `### S12-Q3 — T-034 · …`. The delta closes it:

```
**결과**  정답 4 · 내 답 2 ✗ · W-001 · confusion
  1 ✗ 리전 간 전이 라우팅 불가
  2 ✗ 동작은 하나 운영부담 큼 — "LEAST operational overhead" 위반
  3 ✗ DX는 구축에 수 주 — "quickly" 위반
  4 ✓ TGW + VPN. 요구조건 3개 충족
  5 ✗ 실재하지 않는 조합
```

- The `W-id` on the result line is what `exam-desc` greps for. It sits **below** the question, so a lookup reads a
  window that starts above the match
- Omit the `W-id` for confident-correct answers — nothing to look up later
- A re-asked entry keeps the **same `W-id`** across months, which is what gives the entry a history

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
