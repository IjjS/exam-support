# Source policy

The policy of record for what may back a claim. Referenced by `exam-init` (Phases 2 and 5), `exam-comp`, and `exam-desc`.

**Collecting subagents do not read this file** — they get the operational subset in
`exam-harvest/references/harvest-policy.md`. `exam-quiz` never reads it either; its inline rule is enough.
This file carries the reasoning, which is what you need when *changing* the policy rather than following it.

---

## The rule — search, then verify

```
1. Search   the exam's _sources/ first (PDFs, past papers, textbooks, lecture notes), then the web
2. Verify   every claim against official docs or guides
```

There are no tiers and no site lists. Past-question sites, blogs, community answers, and model knowledge are all
fine for finding and organizing the material — they show what gets tested. None of them is the reason a claim is
believed; verification is. It works the same way on every exam, so nothing here is maintained per exam.

`_sources/` comes first because it is what the user is actually studying from. The web fills what it does not cover.

## Verification

| Found in | Verified when | No official doc or guide covers it |
|---|---|---|
| `_sources/` | An official doc confirms it | **The file stands on its own** |
| The web | An official doc or guide confirms it | Leave it out — queue the topic as `unknown` |

When an official doc **contradicts** either one, the official doc wins. Say so in the note.

The asymmetry is deliberate. A textbook or past paper the user chose is often the only material a domestic exam
has; refusing it would leave nothing. A web page nobody vetted earns trust only through an official confirmation.

An answer key is a claim like any other — whether it came with a past paper in `_sources/` or from a website.

**Official** means the vendor's or administering body's own documentation, guides, whitepapers, FAQs, and official
blog — for any exam, without a per-exam list. Two subjects have an authority of their own: statutes and regulations
(the government statute database, `law.go.kr` in Korea) and published statistics (the official statistics office,
`kosis.kr` in Korea). A domestic administering body often publishes only the 출제기준, a table of contents rather
than content; statutes and statistics still cover a real share of such exams.

**Caution on institutional sites**: pages are often JS-rendered or session-dependent, and a fetch can return content
for a *different exam* without erroring. Sanity-check subject names, question count, and passing rule against the
search results. If they disagree, trust neither — ask the user.

## Recording — where it came from, nothing more

```markdown
## Sources
- source: 유통관리사2급_기출문제집_2024.pdf p.112 (2026-08-15)
- web: docs.aws.amazon.com/vpc/latest/tgw/what-is-transit-gateway.html (2026-08-15)
- web: examtopics.com/discussions/amazon/view/12345 (2026-08-15)
```

- `source:` a file in `_sources/`, with the page. `web:` a URL — the address itself says which site
- List every page you used, including the one that verified the claim and the one that first pointed you there
- Record **the date** on each line — vendor docs change quietly
- Attach a source to each individual number and limit — those change most often
- Material handed over in the conversation is saved to `exams/{slug}/_sources/` before it is cited, or the citation
  points at nothing. **HWP cannot be read** — ask for a PDF export
- A file or page you could not actually read is never listed
- Never copy question text, answer explanations, or long passages into a note. Summarize in your own words —
  copied text invites a copyright problem and gets memorized by wording

## Which official page to prefer

```
1. Reference docs (docs.*, 출제기준)        — highest accuracy
2. Whitepapers / Well-Architected / guides  — judgment criteria and trade-offs
3. FAQ                                      — limits and quotas
4. Official blog                            — new features. Always check the date
```

Exams test **judgment criteria.** Reference docs tell you what something is; guides and whitepapers tell you when
to use it. Without the latter, scenario questions cannot be written, so collect both.

---

## Drift observations

If you see any of the following while reading, **do not put it in the note — return it as an observation.**

```
Exam code change (SAP-C02 → C03)
Exam Guide or 출제기준 version / effective date change
Domain composition or weight change
Question count, duration, or passing score change
A new official sample question set published
Deprecation notice for a service or feature
```

Return format:
```
{grade: minor|major, field: "domain weights", observed: "D1 26%→22%", source: URL}
```

Subagents must not modify `format.md` or `format-drift.md` **directly.** The main session aggregates.
