# Harvest brief — for the subagent writing one note

Everything you need to research one topic and write its note. Read this and nothing else.
The full policy and its reasoning live in `_spec/source-policy.md`; you do not need them to follow the rules below.

---

## Sources — search, then verify

```
1. Search   the exam's _sources/ first — PDFs, past papers, textbooks covering this topic — then the web
            (past-question sites, blogs, community answers are all fine for finding and organizing)
2. Verify   every claim against official docs or guides
```

| Found in | Verified when | No official doc or guide covers it |
|---|---|---|
| `_sources/` | An official doc confirms it | The file stands on its own |
| The web | An official doc or guide confirms it | Leave the claim out and report it |

**Official** means the vendor's or administering body's own docs, guides, whitepapers, FAQs, and official blog; for
statutes the government statute database (`law.go.kr`), for statistics the official statistics office (`kosis.kr`).
An official doc that **contradicts** what you found wins — say so in the note. An answer key is a claim too: verify it.
Prefer reference docs → guides and whitepapers → FAQ → official blog (check the date).

---

## Recording sources — where it came from, nothing more

```markdown
## Sources
- source: 유통관리사2급_기출문제집_2024.pdf p.112 (2026-08-15)
- web: docs.aws.amazon.com/vpc/latest/tgw/what-is-transit-gateway.html (2026-08-15)
- web: examtopics.com/discussions/amazon/view/12345 (2026-08-15)
```

`source:` a file in `_sources/` with its page; `web:` a URL — the address says which site. List every page you used,
the verifying one included, each with its date. Attach a source to each individual number or limit — those change
most often, and a stale one is worse than none. **A file or page you could not actually read is never listed.**
Say so and stop. Never copy question text or explanations into the note; summarize.

---

## Note format

Write to `notes/{section}/{topic}.md`, or `notes/{topic}.md` when the blueprint says `structure: flat`.
English kebab-case filename, matching the topic name.

**At least 800 tokens, no upper limit.** Under 800 the note runs dry after two or three questions and the topic
starts coming back to the harvest queue. Above that, let it grow: a note is accumulated knowledge, and depth a
topic has earned stays in it.

````markdown
---
id: T-041
domain: D2
title: Transit Gateway Routing
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
- web: docs.aws.amazon.com/vpc/latest/tgw/what-is-transit-gateway.html (2026-08-15)
````


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

- State a claim that only an unofficial web page supports — it needs an official doc or guide, or it stays out
- Put practice questions in a note — quiz generates fresh ones, stored ones get memorized by wording
- Wiki links `[[ ]]` or fold callouts — they render nowhere on a phone, the web, or GitHub
- Reference another certification's notes
- Write anything under `state/` — the main session owns those files
- State a number without a source
