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

**Basic (diagnostic) mode is always the default, at every `basic_done`.**
Weakness mode never turns on by itself — it runs only when the user asks for it.

```
basic_done = (diagnostic + mock) from the sessions hot block

no weakness request                        →  basic (diagnostic) mode
user asked for weakness, basic_done >= 3   →  weakness mode
user asked for weakness, basic_done < 3    →  basic mode, and say so:
                                              "약점 파악이 아직 부족합니다 ({n}/3회). 이번엔 기본모드로 갑니다."
                                              allow one override if they ask again
```

Weakness requests are phrased as `약점모드` · `약점만` · `틀린 것 위주` · `오답 다시`.
Anything else — a bare `/exam-quiz`, a count, a domain — is basic mode.

An explicit user instruction wins: domain (`D2`), question count (`10문제`), mock exam.

| Mode | Topic selection |
|---|---|
| Basic (diagnostic) | **⬜ untested first**, allocated by blueprint weight |
| Weakness | Top scores + lucky-guess topics + active wrong answers |
| Section | Same rules inside the named section |
| Mock exam | → `references/mock-exam.md` |

Default is **5 questions**. Announce the resolved mode in one line before starting.

Take both the difficulty rubric and the resolved mode's ratio from `format.md`. Scale the ratio by largest remainder.
If either is missing, stop with `/exam-init --format`; never invent a cross-exam fallback.

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

### Source pipeline

```
usable note       → generate from the note
no/exhausted note → Tier C lead → fresh draft → verify against A/B
no Tier C hit     → model draft → verify against A/B
verification fails → [UNVERIFIED]
```

**Read exactly the notes for the topics you selected — five files, in full, and nothing else.**
Never read a whole section's worth of notes. At a measured 1.2k per note, five is already 6k; a domain of
thirty would be 36k for five questions.

### When the note runs out

A note holds 3-7 questions' worth of material, depending on where in the 800-1,500 range it landed. Ask past
that and you are rewording a question already asked, which is exactly the failure the whole system exists to prevent.

```
mastery.Att >= 4  and the note has not been updated since
        ├─ this question:  use the source pipeline
        └─ the queue:      add with reason `exhausted`
```

Both halves matter. The source pipeline rescues this question; the queue entry means harvest deepens the note so the topic
stops needing rescuing. `exhausted` is not `thin-note` — the note was adequate and got used up, so harvest
should extend it rather than start over.

Four is a single threshold against a range, so it fires early for a note at the top of the range and on time
for one at the bottom. **Early is the safe direction**: queueing too soon costs one row, queueing too late
costs a repeated question on the topic the user is worst at.

This bites hardest in weakness mode, where a stubborn topic returns every second or third session. That topic
is also the one most in need of varied probing, so leaving it on a spent note is the worst place to economize.

**Manual override.** `"웹도 써서"`, `"새로운 각도로"`, `"더 어렵게"` forces this pipeline even when a note is usable.

Tier C is a **lead only**: extract the tested service combination, scenario shape, and distractor traps. Never copy its
wording or trust its answer. Verify the correct answer and every capability, limit, or trade-off that distinguishes an
option against vendor official docs (A) or a user source (B). Batch searches across selected topics when possible.

Do not read `_spec/source-policy.md`; the operational rule above is complete. There is no per-session verification cap.
When A/B verification succeeds, show **no source label**. When it fails, keep `[UNVERIFIED]`.

Queue no-note topics as `no-note`, exhausted notes as `exhausted`, and failed verification as `unverified-question`.
Put the A/B verifier URL in `Source`; leave it empty only when verification failed.

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

Omit any source label for note-backed or A/B-verified questions; never emit `[WEB]`. After the options, record an
invisible log-only comment. Use one exact form:

```html
<!-- source: note path (updated date) -->
<!-- source: lead [C] URL · verified [A|B] locator (date) -->
<!-- source: model · no C lead: "<query>" · verified [A|B] locator (date) -->
<!-- source: model|lead URL · unverified (date) -->
```

The third form is the fallback, and it must carry the search that came up empty. **A missing `no C lead:` field
means the Tier C step was skipped, not that it found nothing** — the two are indistinguishable otherwise, and
skipping it is what turns exam-shaped questions into documentation-shaped ones.

Use `[UNVERIFIED]` visibly only with the fourth form. Verdicts and the `W-id` come later as a short delta.

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
  □ For every rejected option, declare which: the stem KILLS it (name the sentence) or the requirement
    keyword OUTRANKS it (say what it costs more of). Neither → the question is void
  □ Final sentence matches one of format.md's registered question phrasings
  □ Solvable from the wording alone, without the knowledge?   → failed
  □ Answer unchanged if the requirement keyword changes?      → the requirement is decoration
  □ All distractors plausible to someone who does not know?
  □ Meets format.md's assigned difficulty after writing? Multiple-response alone does not count.
    Every rejection was a kill → M, whatever the constraint count. H needs 2+ options that break nothing
  □ Correct option in the same slot as the previous question?
  □ Stem inside format.md's word range?
  □ A "multiple response" question with only one correct option?

Whole message
  □ 답변 line matches the template exactly, no per-question example?
  □ Any example string with as many slots as there are questions?  → remove it
  □ Anything naming, ranking, or hinting at a correct option?
```

**Nothing preceding the user's answer may narrow the option set.**

The first check runs first because it voids questions rather than weakening them, and because the level falls
out of its answer. Two quiet failures it catches:

- The constraint that eliminates an option stays in your head instead of the stem. Every option still looks
  wrong to you and defensible to the candidate.
- Every rejected option is *killed* by a stated rule. That reads as rigorous and is in fact the easy shape —
  careful reading eliminates everything, the requirement keyword has nothing left to rank, and `misread`
  errors can never surface. Writing an `H` means deliberately leaving two options standing that break nothing
  and differ only in cost, operational overhead, or recovery speed.

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

## Source labels

Note-backed and A/B-verified questions have no visible source label. Never use `[WEB]`.
Use `[UNVERIFIED]` only when the verification step failed; never omit it in that case.

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
