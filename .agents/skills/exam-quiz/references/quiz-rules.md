# Question generation rules

Read this immediately before writing questions, in `exam-quiz` Phase 3.

---

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

## Self-check before presenting

Run this on every question. One failure means rewrite it.

```
□ Is it solvable from the wording alone, without the knowledge?  → if yes, it failed
□ Does the answer stay the same if the requirement changes?      → if yes, the requirement is decoration
□ Are all 3-4 distractors plausible?
□ Does the correct position repeat from the previous question?
□ Is the stem within format.md's word range?
□ Is a "multiple response" question actually single-answer?
□ Does anything in the message reveal an answer — including a worked answer-syntax example?
```

The last one is the leak that actually happens in practice. An example answer string with one slot per question
gets filled with the real answers while looking like a formatting demo. Keep the 답변 line verbatim from SKILL.md.
