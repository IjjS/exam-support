# Concept note template

Followed by collecting subagents when writing `notes/{domain}/{topic}.md`.

---

## Design intent

A note is **source material for questions, not reading material.** `exam-quiz` must be able to read this one file
and produce 2-5 questions from it.

Target size **400-700 tokens**. quiz reads five notes per session, so a bloated note weighs down the hot path.
The urge to write more is a signal to split the topic.

---

## Format

````markdown
---
id: T-041
domain: D2
title: Transit Gateway Routing
updated: 2026-08-15
---

# Transit Gateway Routing

## In one line
A regional gateway that connects many VPCs and on-premises networks hub-and-spoke, with route tables
controlling transitive routing.

## When to use
- Three or more VPCs that need to interconnect (Peering explodes to N² management)
- On-premises VPN/DX that several VPCs must share
- Segment isolation is required (separate route tables)

## When not to use
- Two VPCs, simple connection → VPC Peering is cheaper with lower latency
- Cross-region → requires a separate TGW Peering setup

## Core behavior
- Association and propagation are separate, per attachment
- The default route table allows transit across all attachments → split tables to isolate
- ...

## Easily confused with
| Target | Decisive difference |
|---|---|
| VPC Peering | No transitive routing. Two parties only |
| VPN CloudHub | For on-premises to on-premises, not a VPC hub |

## Numbers and limits
| Item | Value | Source |
|---|---|---|
| Attachments per TGW | 5,000 | docs.aws.amazon.com/... (2026-08-15) |

## Exam angle
- `LEAST operational overhead` + many VPCs → almost always TGW
- Cost is the requirement and there are only two VPCs → Peering is the answer

## Sources
- https://docs.aws.amazon.com/vpc/latest/tgw/... (2026-08-15)
````

---

## Section rules

| Section | Required | Contents |
|---|---|---|
| frontmatter | ✅ | `id` is the join key with mastery and wrongbook. Never omit it |
| In one line | ✅ | One sentence. `exam-desc` leads with this |
| When to use | ✅ | **Raw material for scenario questions.** Without it, no questions |
| When not to use | ✅ | **Raw material for distractors.** Without it, wrong options are flimsy |
| Core behavior | ✅ | Raw material for behavior-prediction questions |
| Easily confused with | Recommended | Two or more entries makes it a `_compare/` candidate |
| Numbers and limits | Conditional | If present, copy into `_facts.md` too |
| Exam angle | Recommended | Mapping from requirement keyword to the answer |
| Sources | ✅ | URL plus collection date |

**Never leave "When not to use" empty.** Without good distractors the question falls to elimination.

---

## Filename

```
notes/d2-design-new-solutions/transit-gateway-routing.md
```

English kebab-case, matching the topic name.

---

## Never

- **Insert practice questions or quizzes** — they get memorized by wording, and generating questions is quiz's job
- Wiki links `[[ ]]` or fold callouts — they render nowhere on a phone, the web, or GitHub
- Reference another certification's notes — exams stay isolated
- State a number without a source
- Quote long passages verbatim (summarize)
