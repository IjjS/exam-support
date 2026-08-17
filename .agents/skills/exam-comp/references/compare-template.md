# Comparison document rules

---

## Which format

| Targets | Format | Filename |
|---|---|---|
| 2 | Comparison table | `vs-{a}-{b}.md` |
| 3 or more | Decision guide (branch tree) | `choose-{topic}.md` |

Three or more in a table means too many columns to read on a phone. Switch to branches.

Filenames are English kebab-case. Sort the `vs-` pair alphabetically to avoid duplicates
(`vs-alb-vs-nlb` and `vs-nlb-vs-alb` are the same document).

---

## Required elements

### "The one line that decides it" — without it, this is not a document

A comparison exists to enable a **choice**, not to enumerate. Ten compared attributes with no criterion
is useless in the exam room.

```
✅  Transitive routing needed, or three or more VPCs → TGW. A two-party link → Peering.
❌  TGW is hub-and-spoke and Peering is a 1:1 connection.   ← just a statement of fact
```

### "Where the exam splits them"

The mapping from requirement keyword to answer. This directly reduces `misread` errors.

```
LEAST operational overhead + many VPCs  →  TGW
MOST cost-effective + two VPCs          →  Peering
```

### "My error history"

Pull this pair's entries out of `state/wrongbook.md` — the one-line core and the Notes column are exactly what
this section needs. **A comparison table with your own mistakes in it sticks better than a generic one.**

**Do not open `state/log/`.** Only `exam-desc` reads it, and only for an entry the user named. A comparison table
needs the lesson, not the original stem; if the exact question matters, the user can ask `exam-desc` for it.

Omit the section entirely if there is nothing. Never leave an empty heading.

### "Traps" (optional)

Entries that break a "X is always the answer" belief. Ties directly into distractor patterns.

---

## Choosing comparison rows

**Only the axes the exam splits on.** Five to eight rows is right; trim beyond that.

| Keep | Drop |
|---|---|
| Capability yes/no (transitive routing) | Release year |
| Cost structure | Detailed price tables |
| Operational burden | UI differences |
| Scaling limits | Marketing names |
| Latency and performance | Per-region availability (changes often) |

---

## Size

**300-600 tokens.** Like a note, it has to be something quiz can read.
Growing past that means the wrong things were grouped together — split it.

---

## Never

- List attributes without a deciding criterion
- Insert practice questions (that is quiz's job)
- Wiki links `[[ ]]`
- Reference another certification's comparison tables
- State a number or limit without a source
