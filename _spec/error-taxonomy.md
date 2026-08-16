# Error taxonomy — five types

Referenced by `exam-quiz` after grading, by `exam-status` when aggregating, and by `exam-comp` when picking
comparison-table candidates.

**Different reasons for a wrong answer need different treatment.** Accuracy alone flattens all five into "one wrong answer."

---

## Decision order

Check top to bottom and take the **first match**. Never assign more than one type.

```
1. Do you simply not know the correct concept?           → unknown
2. Is your choice something commonly confused with it?   → confusion
3. Does applying the requirement keyword change the answer? → misread
4. Is your choice a textbook distractor pattern?         → distractor
5. Concept and direction right, only the number wrong?   → recall
```

A question answered `??` (guessed) but **correct** is classified too. Default it to `unknown`; if the user says
"I was torn between A and B," use `confusion`.

---

## 1. unknown

The correct concept is simply not known. The choice was near-random.

- **Signals**: `??` tag / the service is new to the user even after the explanation / wrong on a topic's first appearance
- **Treatment**: append to `harvest-queue.md` with `reason: unknown`, priority **high**
- If a note already exists and this still happens, the note is the problem. Re-queue with `reason: thin-note`

## 2. confusion

Both are known, but the boundary is blurry. **This is the fastest type to convert back into points.**

- **Signals**: the chosen answer is in the same family as the correct one / `?` tag with a two-way debate / repeated errors on the same pair
- **Treatment**: mark as a candidate for `notes/_compare/vs-{a}-{b}.md`. `/exam-comp` with no argument pulls this list
- **Examples**: SCP vs IAM policy / TGW vs VPC Peering / Aurora Global vs Read Replica / NLB vs ALB

## 3. misread

The knowledge was there but **the requirement was missed.** Apply the requirement and the answer changes.

- **Signals**: the chosen answer does technically work / picked highest performance when the stem said `MOST cost-effective` /
  picked a self-managed build when the stem said `LEAST operational overhead`
- **Treatment**: record the missed keyword in `wrongbook.md` and keep a running count. `exam-status` shows per-keyword totals
- On AWS SAP and SAA this **costs more points than genuine ignorance.** Always count it separately

Keywords to track:
```
MOST cost-effective        LEAST operational overhead
MOST secure                MOST resilient / highly available
LEAST amount of downtime   MOST scalable
with the LEAST effort      MINIMAL changes to the application
```

## 4. distractor

Fell for a standard wrong-answer construction.

- **Signals**: the chosen answer matches one of the patterns below
- **Treatment**: record the pattern number in `wrongbook.md`. Three or more hits on the same pattern triggers a warning in `exam-status`

Distractor patterns:
```
D1. Legacy bait       Picks a self-managed EC2 build when a managed service exists
D2. Over-engineering  Architecture more complex than the requirement calls for
D3. Boundary error    A configuration that does not work cross-region or cross-account
D4. Wrong option      Right service, wrong configuration or mode
D5. Plausible fiction A combination that sounds right but does not exist
```

## 5. recall

Direction right, number wrong.

- **Signals**: limits, quotas, defaults, SLAs, timeouts, maximum sizes
- **Treatment**: add a card to `notes/_facts.md` (`topic-id | item | value | source`)
- **Examples**: S3 max object size / Lambda timeout ceiling / subnets per VPC / SCP document size limit

---

## Partial hits on multiple response

AWS multiple-response questions (Choose TWO/THREE) have **no partial credit.** One right out of two is wrong.

That said, `1 of 2 correct` is a different signal from total ignorance, so record `partial 1/2` in the notes column
of `wrongbook.md`. Classify the type based on **the option that was wrong.**

---

## Where things get recorded

| What | File |
|---|---|
| Type + one-line description of the misconception | `state/wrongbook.md` |
| Full question, options, explanation, the user's answer | `state/log/{YYYY-MM}.md` |
| Running counts per type | hot block at the top of `state/wrongbook.md` |
| Missed requirement keywords | notes column of `state/wrongbook.md` |
