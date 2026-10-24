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

## Pairwise table — `_compare/vs-{a}-{b}.md`

````markdown
---
type: compare
topics: [T-041, T-052]
updated: 2026-08-15
---

# Transit Gateway vs VPC Peering

## The one line that decides it
**Transitive routing needed, or three or more VPCs → TGW. A two-party link → Peering.**

## Comparison
| | Transit Gateway | VPC Peering |
|---|---|---|
| Transitive routing | Yes | **No** |
| Scale | Hub-and-spoke, thousands | 1:1, grows as N² |
| Cost | Hourly + data processing | No attachment fee, transfer only |
| Latency | One extra hop | Direct |
| Bandwidth | Per-attachment ceiling | VPC bandwidth |

## Where the exam splits them
- `LEAST operational overhead` + many VPCs → TGW
- `MOST cost-effective` + two VPCs → Peering
- "Several VPCs share the on-premises connection" → TGW (Peering cannot do it)

## My error history
- 2026-08-10 T-041: chose Peering in a four-VPC scenario, looked only at cost and missed operational burden

## Sources
- web: docs.aws.amazon.com/... (2026-08-15)
````

## Decision guide — `_compare/choose-{topic}.md`

With three or more options, a branch tree beats a table.

````markdown
# Choosing a hybrid connectivity option

## Branches
```
Need dedicated bandwidth or consistent latency?
├─ Yes → Direct Connect
│         └─ Needs redundancy? → two DX circuits, or DX + VPN backup
└─ No  → Only encryption needed?
          ├─ Yes, fast to stand up → Site-to-Site VPN
          └─ Shared by several VPCs → TGW + VPN
```

## Answer by requirement keyword
| Keyword | Tends toward |
|---|---|
| MOST cost-effective | VPN |
| consistent/predictable latency | Direct Connect |
| LEAST time to implement | VPN |
| MOST resilient | Two DX circuits (+ VPN backup) |

## Traps
- "DX is always the answer" is false. It takes weeks to provision, so `quickly` means VPN
````

---

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

Pull this pair's entries with `sh _spec/wrongbook.sh {slug} rows T-xxx T-yyy` — the one-line core and the Notes column are exactly what
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

**One phone screen — roughly 300-600 tokens.** The user reads it on a phone, usually right before a quiz.
Growing past that means the wrong things were grouped together — split it.

---

## Never

- List attributes without a deciding criterion
- Insert practice questions (that is quiz's job)
- Wiki links `[[ ]]`
- Reference another certification's comparison tables
- State a number or limit without a source
