---
name: exam-init
description: Register a new certification and build its study map. Use when the user says "AWS SAP 준비 시작", "새 자격증 추가", "쿠버네티스 시험 등록", "CKA 시작하자", or "exam-init". Pulls domains, weights, and topics from the official Exam Guide, analyzes official sample questions into a question-format spec (format.md), and scaffolds the whole exams/{slug}/ tree. --format refreshes only the format spec; --refine only refines the blueprint.
---

# exam-init

Runs once per certification. **It builds the skeleton only** — concept notes belong to `exam-harvest`, questions to `exam-quiz`.

**Talk to the user in their own language.**

## Subcommands

| Call | Behavior |
|---|---|
| `/exam-init {exam name}` | New registration (Phases 1-6) |
| `/exam-init --format` | Re-run Phase 4 only (refresh the format spec) |
| `/exam-init --refine` | Re-run Phase 3 only (refine topics) |

---

## Phase 0 — User-supplied sources come first

Before searching the web, check `_inbox/` and `exams/{slug}/_sources/`.
This applies to **every exam**, vendor or not — the user's own material always outranks a search result.

- Match files to this exam by filename; ask if a file is ambiguous
- Accepted: URL, PDF, MD, TXT, DOCX, XLSX, PPTX, images (PNG/JPG)
- **Before opening any local file, read `_spec/file-reading.md`.** In particular, never open a PDF with the
  Read tool first — it renders pages as images and costs 10-50x. Extract text with
  `swift _spec/pdftext.swift <file.pdf>` (macOS, no install) and read that
- **HWP cannot be read.** Ask the user to export it as PDF from 한글 — automatic conversion mangles the tables
  that carry the entire structure
- **A file you could not read must never become a citation.** If extraction fails, say so and ask how to proceed;
  do not fall back to the web while recording the file as the source
- After processing, move files to `exams/{slug}/_sources/` (never delete the originals)

### Material handed over in the conversation

If the user attaches or pastes something substantial (a criteria document, a chunk of a textbook, a photographed page),
**save it to `exams/{slug}/_sources/` before using it.** Otherwise it disappears with the session and
`--format` or `--refine` re-runs lose their basis.

- Give it a descriptive filename: `_sources/{topic-or-doctype}-{YYYY-MM-DD}.{ext}`
- Attached files: copy them in. Pasted text: write it to a `.md`
- Skip this for a few lines of throwaway text; anything worth citing gets saved
- Say in one line what was saved where

If the exam is a domestic (non-vendor) certification, expect the web alone to be insufficient and say so early:
`"출제기준 PDF가 있으면 _inbox/ 에 넣어주세요. 없으면 웹으로 진행하되 정확도가 떨어집니다."`

## Phase 1 — Identify the exam

Pin down the exact exam code from the name. **Ask** if it is ambiguous (e.g. "AWS SAP" → confirm SAP-C02).

Search vendor official pages via WebSearch and collect:

| Field | Example |
|---|---|
| Exam code | SAP-C02 |
| Questions / duration / passing score | 75 / 180 min / 750 of 1000 |
| Exam languages | English, Japanese, Korean … |
| Exam Guide URL | |
| Sample question URL | |

Ask for the exam date (optional). It drives the D-day.

## Phase 2 — Domains and weights

Pull the domains and their **official weights (%)** from the Exam Guide.

- Put **"extract only domain names, weights, and task lists"** in the WebFetch prompt. Do not pull whole pages into context
- For PDFs, convert on the command line and read only the relevant sections
- If the weights cannot be found, **do not guess** — ask the user

### Domestic exams

Korean national and quasi-national certifications publish a 출제기준 whose hierarchy maps almost directly onto the
blueprint — often more cleanly than a vendor Exam Guide's prose task statements.

```
주요항목  → domain
세부항목  → grouping
세세항목  → leaf topic
```

Weights come from **questions per subject** rather than a published percentage
(e.g. 4 subjects across 90 questions → the per-subject count is the weight).

## Phase 3 — Topic breakdown

Break each domain down to **leaf topics**. A leaf is "a unit that one question can verify."

- Too coarse (`Networking`) makes coverage meaningless; too fine (`TGW route table propagation settings`) is unmanageable
- Rule of thumb: **one topic = one concept note = 2-5 questions**
- 60-150 topics per certification is the realistic range

If the natural breakdown reaches the 150 ceiling, **do not silently truncate or merge the tail.**
Report it: `"출제기준 기준 {n}개가 나옵니다. 150 상한을 넘습니다."` and let the user decide between
raising the ceiling and coarsening the granularity. A blueprint quietly cut at the limit produces a
coverage denominator that looks complete while the tail of the exam is missing.

### Topic IDs

```
Sequential from T-001. The domain is not encoded.
Increment topic_id_next in blueprint.md after each issue.
```

**Never roll `topic_id_next` back.** Two different topics would end up with the same ID and mastery history is poisoned.
Full rules in `references/blueprint-format.md`.

With many domains, spawn one subagent per domain to break them down in parallel.
**Subagents return topic lists only** — no descriptive prose.

## Phase 4 — Question format analysis ★

Skipping this means generating plausible-looking questions that don't match the real exam.

1. Collect sample questions, in this order
   - `_sources/` — a past-paper collection or textbook the user supplied (**best option**)
   - AWS: Exam Guide appendix samples plus the free Skill Builder Official Practice Question Set
   - CNCF: curriculum plus the official exam environment notes
   - Anthropic: official exam information pages
   - Domestic exams: `comcbt.com` is permitted **for format analysis only** — see `exam-harvest/references/source-policy.md`.
     Read the question structure; never carry over its explanations, and never cite it in a note
2. Analyze and fill `format.md` — type mix, stem length, question phrasings, requirement keywords, distractor patterns, prohibitions
3. **Synthesize two anchors** — never copy originals. Same format, different subject. Different domains, one single-select and one multiple-response
4. Fill the DRIFT-CHECK block at the top (harvest compares against just those 8 lines)

If no samples can be found, draft from the typical format of that vendor and family and mark **every field `[ESTIMATED]`**.
Tell the user: `"샘플을 찾으면 /exam-init --format 으로 갱신하세요"`.

For hands-on exams (CKA/CKAD and similar), set `format_type: performance`.

## Phase 5 — Scaffold

**Bootstrap first.** `exams/` is gitignored, so a fresh clone has no `_active.md` or `_registry.md`.
Create them from the template if they are missing — never hand-write them, the column schema lives in the template.

```bash
mkdir -p exams
[ -f exams/_active.md ]   || cp _template/exams/_active.md   exams/
[ -f exams/_registry.md ] || cp _template/exams/_registry.md exams/
```

Then scaffold the exam itself:

```bash
cp -r _template/exam exams/{slug}
```

Copy **without reading** the template, then substitute the `{{PLACEHOLDER}}` values. Six files appear at once.

Then:
- `mkdir -p exams/{slug}/notes/d{n}-{domain-slug}` for each domain
- Move anything processed from `_inbox/` into `exams/{slug}/_sources/`
- `blueprint.md` — write the domain and topic tables
- `mastery.md` — one row per topic, all ⬜, coverage `0/{n}`
- `exams/_active.md` → the new slug (overwriting is correct — only one exam is active)
- `exams/_registry.md` → **append a row, preserving every existing row**

### Registry append — do not regenerate the table

Read `exams/_registry.md` first and add exactly one row with `Edit`. **Never rewrite the table body.**
Regenerating it silently drops every previously registered exam from the overview, and the data files stay
intact so nothing looks broken until `/exam-status` comes up short.

- Remove the template's empty placeholder row (`| | | | | | | | |`) only on the first registration
- Rows stay in registration order
- Same rule applies to `exam-quiz` and `exam-harvest` when they refresh their own row: edit that row, touch nothing else
- If a row for another exam has gone missing, do not silently re-add it — tell the user to run `/exam-status --rebuild`

## Phase 6 — Report, 5 lines or fewer (Korean)

```
AWS SAP-C02 등록 완료  D-42
도메인 4개 / 토픽 79개 (전부 ⬜)
형식: 5지선다 · 단일 70 / 다중 30 · 지문 평균 110단어
노트 0개 — /exam-harvest 로 시작하거나, 바로 /exam-quiz 로 진단 3회부터
```

---

## --format re-run

1. Preserve the current `format.md` at `state/_archive/format-{version}-{date}.md`
2. Re-run Phase 4, refreshing `guide_version` and `verified_at`
3. Mark the related entries in `state/format-drift.md` as `applied (v{new}, {date})`
4. If domain weights changed, continue into **blueprint migration**

### Blueprint migration

```
Domain reorganized  →  keep IDs, change only the domain column in blueprint
Topic removed       →  status: deprecated (never delete the row — mastery history survives, only questions are excluded)
Topic added         →  issue a new ID from topic_id_next
Weights changed     →  blueprint only; mastery unaffected
```

Present the change summary as a table and **get confirmation** before applying.

## Do not create friction

A missing Exam Guide must not block registration. Rough out the domains, start, and tell the user they can refine
later with `/exam-init --refine`. Not starting is worse than being imprecise.
