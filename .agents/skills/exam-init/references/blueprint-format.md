# Blueprint authoring rules

Referenced by `exam-init` Phase 4, `--refine`, and migrations.

---

## What blueprint is for

**It is an immutable spec.** It defines what the exam asks about. It says nothing about how much the user knows.

| | blueprint.md | state/mastery.md |
|---|---|---|
| Nature | Immutable (changes only on exam revision) | Changes every session |
| Contents | ID · domain · topic name · weight · status | attempts · correct · lucky · coverage · score |
| exam-quiz | **never reads it** | reads and writes |

Putting coverage in blueprint would force quiz to read and write this file every session.
Coverage is derived from `mastery.attempts > 0`, so there is no reason to store it.

---

## Topic IDs

```
T-001, T-002, … sequential. Domain not encoded.
```

A domain prefix like `T-D2-07` diverges from actual membership once domains are reorganized.
Fixing the prefix breaks the join key in `mastery.md` and **destroys the accumulated study history.**

Absolutely forbidden:
- Rolling back `topic_id_next`
- Reusing the ID of a deleted topic
- Changing an existing topic's ID
- Deleting a topic row from blueprint (use `status: deprecated`)

---

## Judging leaf topics

Ask: **"Can I write a question about this topic?"**

| | Example | Verdict |
|---|---|---|
| Too coarse | `Networking` | Yields 30 questions → break it down |
| Right | `Transit Gateway routing` | 2-5 questions |
| Too fine | `Steps to enable TGW route table propagation` | A 3-line note → merge upward |

Target: **one topic = one concept note = 2-5 questions.** 60-150 per certification.

Hitting exactly 150 is a warning sign, not a success. Report the natural count and let the user decide
rather than merging the tail to fit — a truncated blueprint yields a coverage denominator that reads as
complete while part of the exam is absent from it.

Topic names are written in **English** (service and technical names are English, and they become note filenames).

---

## Domain table

```markdown
| ID | Domain | Weight | Topics |
|---|---|---|---|
| D1 | Accelerate Workload Migration and Modernization | 20% | 16 |
```

- Weights come verbatim from the official Exam Guide. **Check that they sum to 100%**
- If they cannot be found, ask the user. Never guess
- Directory is `notes/d1-{kebab-slug}/`

## Topic table

```markdown
| ID | Domain | Topic | status |
|---|---|---|---|
| T-001 | D1 | VPC Peering vs Transit Gateway | active |
| T-042 | D2 | Aurora Global Database | deprecated |
```

`status`: `active` (in the question pool) | `deprecated` (dropped by revision, history retained)

---

## Initializing mastery

Right after writing the blueprint, create every topic row in `mastery.md`. **This fixes the coverage denominator.**

```markdown
| ID | Topic | D | Att | Correct | Lucky | Shaky | Status | Last | Score |
|---|---|---|---|---|---|---|---|---|---|
| T-001 | VPC Peering vs Transit Gateway | D1 | 0 | 0 | 0 | 0 | ⬜ | — | — |
```

Hot block: `Coverage: 0/79 (0%)`

Keep mastery rows for `deprecated` topics but **exclude them from the coverage denominator.**

---

## --refine

Reinforce the blueprint while preserving existing topics.

1. Read the current topic list
2. Compare against the Exam Guide to find missing areas
3. With a bank, re-map the questions (init Phase 4) — questions that fit no topic and overcrowded topics are
   the strongest evidence of a gap
4. **Only new topics get new IDs.** Renaming an existing topic is fine; the ID stays
5. Create ⬜ mastery rows for added topics and update the coverage denominator, and write the new mapping into
   `_sources/questions/index.jsonl`
6. Report the change summary: `+8 new / 2 renamed / 1 deprecated · 기출 매핑 98%`
