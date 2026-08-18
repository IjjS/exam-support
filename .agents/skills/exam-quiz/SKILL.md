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

The generation rules are at the bottom of this file, under **Question generation rules**. Follow them.

Follow `format.md` for the single/multiple-response mix, stem length, phrasing, and distractor patterns.

### Three-tier sourcing

```
1. the topic's note exists           →  generate from the note only
2. No note                           →  verify against vendor official docs via WebSearch/WebFetch
3. Web also fails                    →  Claude's own knowledge, tagged [UNVERIFIED]
```

Tier 2 may draw on **any of A, B, or C** — a question is generated fresh each time and nothing is stored, so it
holds to a lower bar than a note. Tag the source in the explanation. **Do not read `_spec/source-policy.md`;**
that is 2.3k in the hot path to learn one sentence.

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

One checklist, run over the whole message. Any failure means rewrite before sending.

```
Per question
  □ Solvable from the wording alone, without the knowledge?   → failed
  □ Answer unchanged if the requirement keyword changes?      → the requirement is decoration
  □ All distractors plausible to someone who does not know?
  □ Correct option in the same slot as the previous question?
  □ Stem inside format.md's word range?
  □ A "multiple response" question with only one correct option?

Whole message
  □ 답변 line matches the template exactly, no per-question example?
  □ Any example string with as many slots as there are questions?  → remove it
  □ Anything naming, ranking, or hinting at a correct option?
```

**Nothing preceding the user's answer may narrow the option set.**

---

# Question generation rules

Everything below governs how a question is written. It lives here rather than in a reference because Phase 3
always runs — a separate file would only have bought a round-trip.

## First principle — zero hints

**Only someone who knows should get it right.** If the answer is visible from the wording alone, the question failed.

Forbidden:
- Answer-signalling modifiers: `(recommended)`, `(best practice)`, `(the safest)`
- Length bias — the correct option noticeably longer or shorter than the rest
- Specificity bias — only the correct option is concrete while distractors are vague
- `All of the above`, `None of the above`
- Negations (`NOT`, `EXCEPT`) — real vendor exams rarely use them
- Logical containment between options (if A contains B, elimination solves it)

Required:
- **Randomize the correct position.** Never the same slot five questions in a row
- Every distractor must look plausible to someone without the knowledge
- Consistent option formatting, tense, and sentence structure

---

## Format comes from format.md

Stem length, single/multiple ratio, option count, question phrasing, and distractor patterns are **owned by `format.md`**.
Do not invent them here. Use the anchors there for tone, but **never reuse an anchor's subject matter.**

Under `format_type: performance` (CKA and similar), produce task instructions instead of options:
`"Write the kubectl command that ..."` / `"Write a manifest satisfying ..."` → grade against a reference answer.

---

## Difficulty definitions

| | Criterion |
|---|---|
| easy | A single concept. Knowing the definition and purpose solves it |
| medium | Two concepts combined, or one requirement applied |
| hard | Two or more requirements in tension (cost vs availability), or multiple response, or a whole-architecture judgment |

Per-mode distribution is in the SKILL.md table.

---

## Question types

Mix types within a session.

| Type | What it probes |
|---|---|
| Scenario selection | The configuration that satisfies the requirements (**primary — most of SAP**) |
| Comparative | Which of several similar services fits this situation |
| Behavior prediction | What happens under this configuration |
| Diagnosis | What causes this symptom |
| Limits and numbers | Constraints and quotas (validates the `recall` error type) |

---

## Requirement keywords

Include **at least one per question** from the list registered in `format.md`, spread evenly across the session.

```
MOST cost-effective        LEAST operational overhead
MOST secure                MOST resilient / highly available
LEAST amount of downtime   MOST scalable
```

The point: **changing the keyword must change the answer.** Otherwise `misread` errors never surface.
A question whose answer is the cost-optimal option must include a "faster but pricier" distractor.

### Record which angle you used

Every question lands on exactly one of the codes in `format.md`'s `angles:` list. Decide it while writing the
question, not afterwards, and hand it to Phase 5 so it reaches `mastery.Angle`.

- **One code per question.** No pairs, no compound labels — `cost`, not `scn:cost`
- Use `other` when nothing fits rather than inventing a code. A code that appears once is noise
- Attempts per topic are usually 1-3, so remembering only the most recent angle is enough resolution

---

## Re-asking rules

When bringing back an active wrong answer:

- **Never reuse the wording.** Remembering a sentence is not knowing the material
- Same knowledge, different angle: scenario selection → behavior prediction, swap the requirement, change the service mix
- Always move the correct option to a different position
- For `confusion` errors, **put the confused pair in the same option set** to force the distinction

### Retiring an entry

A streak only advances on a **confident correct** answer. Any `?` or `??` resets it to zero — the entry is in the
book precisely because certainty is what is missing.

| origin | Streak needed |
|---|---|
| `miss` · `lucky` | **3** consecutive confident correct |
| `shaky` | **2** consecutive confident correct |

Shaky clears faster on purpose. The evidence of not-knowing is weaker to begin with, and holding these to the same
bar as real misses would bloat the active list, which quiz reads every session.

---

## Sourcing and labels

| Source | Label |
|---|---|
| Note | none (default) |
| Web-verified | source URL at the end of the explanation |
| Claude's knowledge | **`[UNVERIFIED]`** |

Never omit the `[UNVERIFIED]` label. A distracting tag beats memorizing something false.

---

---

## Phase 4 onward

When the answers arrive, **read `references/grading.md`** and follow it. Do not grade from memory —
the verdict table, the origin rules, and the six writes are all specified there.

## Never

- Hint at the answer in the options (`(recommended)`, length bias, `All of the above`)
- Re-ask a previous question with its original wording
- Read `blueprint.md` or `state/log/`
- **Reveal, rank, or hint at answers before the user responds — including inside a formatting example.**
  A worked answer-syntax string is the most common way this happens; see the guard in Phase 3
