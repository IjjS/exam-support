# Harvest brief — for the subagent writing one note

Everything you need to research one topic and write its note. Read this and nothing else.
The full policy and its reasoning live in `_spec/source-policy.md`; you do not need them to follow the rules below.

---

## Sources

**Tier A — official.** Backs anything.

```
docs.aws.amazon.com · aws.amazon.com/certification · AWS Well-Architected
docs.anthropic.com · kubernetes.io · cncf.io · developer.hashicorp.com
license.korcham.net · q-net.or.kr · law.go.kr · kosis.kr
the product's own docs, official blog, official whitepapers
```

**Tier B — user-supplied files** in `_sources/`, and **published past papers with answer keys**. Backs anything.
Cite a file as `filename p.42`, a past paper as `comcbt 2024년 3회 78번`.

**Tier C — `examtopics.com`, community explanations, comments.**
**A lead, never a source.** It tells you what gets tested and how; it does not establish that anything is true.

```
C says X is the answer   →   confirm X against an A or B source
                         →   confirmed:  write the note, cite the A/B source
                         →   not confirmed:  do not write the note, report it
```

Never put a `[C]` citation in a note.

**Forbidden entirely**: any past-question site not named above, personal blogs, Medium, wiki summaries,
AI-generated summary sites, unofficial cheat sheets.

**Precedence** when sources disagree: official reference docs → official whitepapers → official FAQ →
user-supplied textbook → official blog (check the date). Tier A always wins.

---

## Citation

Every factual statement has one. Record the tier, the locator, and the date.

```markdown
## Sources
- [A] https://docs.aws.amazon.com/vpc/latest/tgw/... (2026-08-15)
- [B] 유통관리사2급_기출문제집_2024.pdf p.112 (2026-08-15)
```

Attach a source to each individual number or limit — those change most often, and a stale one is worse than none.
**A file or page you could not actually read must never be cited.** Say so and stop.

---

## Note format

Write to `notes/{section}/{topic}.md`, or `notes/{topic}.md` when the blueprint says `structure: flat`.
English kebab-case filename, matching the topic name.

**Target 800-1,500 tokens.** quiz reads five of these in one session, so the top of that range is already 7.5k —
past 1,500 and the cost lands on every session for depth most topics never use. Under 800 the note runs dry
after two or three questions and the topic starts coming back to the harvest queue.

````markdown
---
id: T-041
domain: D2
title: Transit Gateway Routing
sources: [A]
updated: 2026-08-15
---

# Transit Gateway Routing

## In one line
A regional gateway connecting many VPCs and on-premises networks hub-and-spoke, with route tables
controlling transitive routing.

## When to use
- Three or more VPCs that need to interconnect (Peering explodes to N² management)
- On-premises VPN/DX that several VPCs must share

## When not to use
- Two VPCs, simple connection → VPC Peering is cheaper with lower latency
- Cross-region → requires a separate TGW Peering setup

## Core behavior
- Association and propagation are separate, per attachment
- The default route table allows transit across all attachments → split tables to isolate

## Easily confused with
| Target | Decisive difference |
|---|---|
| VPC Peering | No transitive routing. Two parties only |

## Numbers and limits
| Item | Value | Source |
|---|---|---|
| Attachments per TGW | 5,000 | docs.aws.amazon.com/... (2026-08-15) |

## Exam angle
- `LEAST operational overhead` + many VPCs → almost always TGW

## Sources
- [A] https://docs.aws.amazon.com/vpc/latest/tgw/... (2026-08-15)
````

`sources:` in the frontmatter lists the highest tiers backing the note. quiz reads it to know how far to trust it.

### Which sections are mandatory

| Section | | Why it exists |
|---|---|---|
| frontmatter | ✅ | `id` is the join key with mastery and wrongbook |
| In one line | ✅ | `exam-desc` leads with this |
| When to use | ✅ | Raw material for scenario questions |
| **When not to use** | ✅ | **Raw material for distractors. Leave it empty and questions fall to elimination** |
| Core behavior | ✅ | Raw material for behavior-prediction questions |
| Easily confused with | recommended | Two or more entries makes it an `exam-comp` candidate |
| Numbers and limits | if any | Copy into `notes/_facts.md` as well |
| Exam angle | recommended | Requirement keyword → answer mapping |
| Sources | ✅ | |

---

## Report back, do not write it into the note

Return only `{topic id, file path, source count, one-line summary, drift observations}`.
Never return the note body — the whole point of running you separately is keeping it out of the main context.

**Drift observations** — if you notice any of these while reading, report them instead of noting them:

```
exam code change · guide version or effective date change · section or weight change
question count / duration / passing score change · a new official sample set · a deprecation notice
```

Format: `{grade: minor|major, field: "...", observed: "...", source: URL}`

---

## Never

- Cite Tier C, or state anything a Tier C source alone told you
- Put practice questions in a note — quiz generates fresh ones, stored ones get memorized by wording
- Wiki links `[[ ]]` or fold callouts — they render nowhere on a phone, the web, or GitHub
- Reference another certification's notes
- Write anything under `state/` — the main session owns those files
- State a number without a source
