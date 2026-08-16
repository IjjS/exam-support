# Source policy

Required reading for every collecting subagent, and for `exam-init` Phase 4.

Sources are graded A/B/C. **The grade decides what the source may be used for**, not just whether it is allowed.

---

## Tier A — Official. Usable for everything

Concept notes, facts, numbers, blueprint, format analysis.

| Vendor / body | Domains |
|---|---|
| AWS | `docs.aws.amazon.com` · `aws.amazon.com/certification` · `aws.amazon.com/blogs/architecture` · Well-Architected |
| Anthropic | `docs.anthropic.com` · `anthropic.com` |
| Kubernetes / CNCF | `kubernetes.io` · `cncf.io` · `github.com/cncf/curriculum` |
| HashiCorp | `developer.hashicorp.com` · `hashicorp.com/certification` |
| 대한상공회의소 | `license.korcham.net` |
| 한국산업인력공단 | `q-net.or.kr` |
| 법령 | `law.go.kr` (국가법령정보센터) — the authority for any statute or regulation question |
| 통계 | `kostat.go.kr` · `kosis.kr` — the authority for any published-statistic question |
| Domestic exams, general | The administering body's or ministry's official site |
| General | The product's official docs, official blog, official whitepapers |

Note for domestic exams: the administering body often publishes **only the 출제기준, which is a table of contents,
not content.** That does not mean Tier A is empty — statutes, regulations, and official statistics have their own
authoritative sources, and for a subject like 유통관리사 those cover a real share of the exam.

**Caution on Korean institutional sites**: pages are often JS-rendered or session-parameter dependent, and a fetch can
return content for a *different exam* without erroring. Always sanity-check the fetched subject names, question count,
and passing rule against the search results. If they disagree, trust neither — ask the user.

## Tier B — User-supplied material. Usable for everything, cite precisely

Anything the user provided: files in `_inbox/` or `exams/{slug}/_sources/`, a path or URL they named, or something
attached or pasted into the conversation. Official criteria PDFs, textbooks, lecture notes, past-paper collections,
photographed book pages.

Accepted formats: URL, PDF, MD, TXT, DOCX, XLSX, PPTX, images (PNG/JPG). **HWP cannot be read** — ask for a PDF export.

**Conversation-supplied material must be written to `exams/{slug}/_sources/` before it is cited.**
A citation pointing at something that only existed in one session is worthless.

- Usable for notes, facts, blueprint, and format analysis
- Cite as `filename p.42` instead of a URL
- A commercial textbook is often the **best available knowledge source for a domestic exam.** Do not refuse it
- If it contradicts Tier A, Tier A wins — and say so in the note

## Tier B (cont.) — Past questions and answer keys from whitelisted sites

| Site | Tier B part |
|---|---|
| `comcbt.com` | **Question text, options, and the answer key** |

These are transcriptions of real exams, and a citation like `comcbt 2024년 3회 78번` is **specific and checkable** —
that is what separates Tier B from model knowledge. For a domestic exam where the administering body publishes no
content, this is often the only evidence of what is actually tested and which position is correct.

Citation must name the sitting and the question number:

```markdown
- [B] comcbt 유통관리사2급 2024년 3회 78번 (2026-08-15)
```

Handle with two cautions:

- Answer keys are **community-reconstructed**, not official — CBT sittings do not publish 확정답안. Page titles on the
  site openly carry revision notes (`78번 내용 변경 및 해설 수정`), so errors do get found and fixed
- **Corroborate before treating one as settled.** The same conclusion appearing across two or more sittings is strong;
  a single question is a lead. If a statute or a statistic is involved, verify against Tier A (`law.go.kr`, `kosis.kr`)
  and let Tier A win

## Tier C — Format reference only. **Never a fact**

| Source | Allowed use |
|---|---|
| `comcbt.com` 해설, comments, user commentary | ✅ Format analysis, distractor patterns, topic frequency |
| **`examtopics.com`** — questions, community answers, discussion | ✅ Format analysis, distractor patterns, topic frequency |
| | ❌ **Never the factual basis for a note** |
| | ❌ **Never copied into an explanation** |
| | ❌ **Never treated as a verified answer key** |

Read these for **shape**: stem length, option count, single vs multiple response, how requirement keywords are phrased,
what a plausible distractor looks like. Then close the tab. Nothing read here may end up as a claim in a note.

### Why examtopics is C and not B

`comcbt` earned Tier B for its questions and answer keys because they transcribe published Korean past papers and the
citation (`2024년 3회 78번`) points at a real, identifiable exam sitting.

`examtopics` is different on both counts: the questions are unauthorized reproductions rather than published past
papers, and the "answer" is a community vote that is frequently contested in the discussion thread right below it.
A voted answer is not an answer key. **Use it to see what a question looks like, never to learn what is true.**

### The general rule

The split is by **artifact, not by site.** A single page can be Tier B for one part and Tier C for another —
`comcbt` is B for its question text and C for its explanation.

When only a Tier C source supports a claim, do not write the note. Queue the topic as `unknown` and report it.

One legitimate Tier C use: **topic frequency.** A topic recurring across past papers is a real weighting signal.
Record it as an observation, not as a fact.

## Forbidden entirely

```
Any past-question site not named in Tier B or Tier C above
Personal blogs · Medium · wiki summaries
AI-generated summary sites
Unofficial cheat sheets
```

No information beats wrong information.

Note that the Tier C entries are **whitelisted for format only.** Being on the list is not permission to treat their
content as true — it is permission to look at the shape of their questions. The tier is the constraint, not the listing.

---

## Source recording — no exceptions

Every factual statement in a note has a source, tagged with its tier.

```markdown
## Sources
- [A] https://docs.aws.amazon.com/vpc/latest/tgw/... (2026-08-15)
- [B] 유통관리사2급_기출문제집_2024.pdf p.112 (2026-08-15)
- [B] comcbt 유통관리사2급 2024년 3회 78번 · 2025년 1회 34번 (2026-08-15)
```

- Record the URL or filename **and the date**. Vendor docs change quietly
- Attach a source to each individual number and limit — those change most often
- Past-question citations name the sitting and question number, and list more than one when they corroborate
- **Never put a `[C]` citation in a note.** If that is the only source, the note should not exist yet

---

## Precedence

When the same content appears in several places:

```
1. Official reference docs (docs.*, 출제기준)      — highest accuracy
2. Official whitepapers / Well-Architected        — judgment criteria and trade-offs
3. Official FAQ                                   — limits and quotas
4. User-supplied textbook                         — often the only option for domestic exams
5. Official blog                                  — new features. Always check the date
```

Exams test **judgment criteria.** Reference docs tell you what something is; whitepapers tell you when to use it.
Without the latter, scenario questions cannot be written, so collect both.

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
