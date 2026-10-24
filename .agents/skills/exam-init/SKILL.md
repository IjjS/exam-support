---
name: exam-init
description: Register a new certification and build its study map. Use when the user says "AWS SAP 준비 시작", "새 자격증 추가", "쿠버네티스 시험 등록", "CKA 시작하자", "기출 추가", or "exam-init". Asks for past questions first, turns them into a question bank, pulls sections, weights, and topics from the official guide, validates the topics against the past questions, calibrates the question format and difficulty (format.md) on them, and scaffolds the whole exams/{slug}/ tree. --bank adds past questions later; --format refreshes only the format spec; --refine only refines the topics.
---

# exam-init

Registers a certification. **It builds the skeleton only** — concept notes belong to `exam-harvest`, questions to `exam-quiz`.

**Past questions are the best input this skill can get.** They decide the topics, the difficulty, and the question
format, and they become the bank that `exam-quiz` source mode works through. Everything below works without them,
but every step is more accurate with them.

**Talk to the user in their own language.**

## Subcommands

| Call | Behavior |
|---|---|
| `/exam-init {exam name}` | New registration (Phases 0-7) |
| `/exam-init --bank` | Add past questions to an existing exam: Phase 2, then mapping (Phase 4) and levels (Phase 5) for the new ones only |
| `/exam-init --format` | Re-run Phase 5 only (refresh the format spec) |
| `/exam-init --refine` | Re-run Phase 4 only (refine topics, re-map the bank) |

---

## Phase 0 — Sources first, and ask once if there are none

Check `_inbox/` (and `exams/{slug}/_sources/` on a re-run). Match files to this exam by filename; ask if one is
ambiguous. Accepted: URL, PDF, MD, TXT, DOCX, XLSX, PPTX, images (PNG/JPG).

**If nothing is there, ask before going further** — one message, numbered, answerable in one word:

```
_inbox/에 자료가 없습니다. 기출문제가 있으면 토픽·난이도·형식이 실제 시험에 맞춰지고, 소스모드로 기출을 순서대로 풀 수 있습니다.

① _inbox/에 넣고 다시 부를게요    ② 웹에서 기출을 찾아 수집해 주세요    ③ 공식 가이드만으로 진행
```

For a domestic exam, name the 출제기준 PDF in the same message — the web alone rarely carries it.

- `①` stop here; the user re-runs `/exam-init` after adding files
- `②` continue, and build the bank from the web in Phase 2
- `③` continue without a bank. Never ask again in this run — the question exists to inform, not to block

**Reading files**: read `_spec/file-reading.md` before opening any local file. Never open a PDF with the Read tool
first — it renders pages as images and costs 10-50x; extract text with `swift _spec/pdftext.swift <file.pdf>`.
**HWP cannot be read** — ask for a PDF export from 한글. **A file you could not read is never cited**; say so and ask
how to proceed.

**Material handed over in the conversation** — a criteria document, a chunk of a textbook, a photographed page — is
saved to `exams/{slug}/_sources/{topic-or-doctype}-{YYYY-MM-DD}.{ext}` before it is used. Otherwise `--format` and
`--refine` re-runs lose their basis. Say in one line what was saved where.

## Phase 1 — Identify the exam and create the tree

Pin down the exact exam code from the name. **Ask** if it is ambiguous (e.g. "AWS SAP" → confirm SAP-C02).
Search official pages and collect:

| Field | Example |
|---|---|
| Exam code | SAP-C02 |
| Questions / duration / passing score | 75 / 180 min / 750 of 1000 |
| Exam languages | English, Japanese, Korean … |
| Exam Guide URL · sample question URL | |

Ask for the exam date (optional). It drives the D-day.

Then create the tree, so the bank and sources have somewhere to go. `exams/` is gitignored, so bootstrap the shared
files from the template if they are missing — never hand-write them:

```bash
mkdir -p exams
[ -f exams/_active.md ]   || cp _template/exams/_active.md   exams/
[ -f exams/_registry.md ] || cp _template/exams/_registry.md exams/
cp -r _template/exam exams/{slug}
```

Copy **without reading** the template, then substitute the `{{PLACEHOLDER}}` values. Move processed files from
`_inbox/` into `exams/{slug}/_sources/` (never delete originals). `_active.md` and `_registry.md` are not touched until
Phase 6, so an interrupted run leaves no half-registered exam.

## Phase 2 — The past-question bank

Skip when there are no past questions and the user chose `③`.

Normalize every past question into one file, numbered in source order:

```
exams/{slug}/_sources/questions/Q001.md      (Q0001 once there are more than 999)
```

```markdown
<!-- source: past-papers-2024.pdf p.12 | web: examtopics.com/discussions/... -->
<!-- retrieved: 2026-10-24 -->

# Q001

## Scenario
{stem, verbatim}

## Options
A. …
B. …

## Answer
B          ← as given by the source; a claim until verified
```

- Keep the stem and options **verbatim** — this is the user's own practice material, and the exact wording is what
  source mode presents. Clean obvious extraction damage (merged words, broken lines) without changing meaning
- Options that exist only as images are **transcribed**, never skipped. An unreadable item is still filed, and Phase 5
  marks it void
- Store no explanations, discussion, or vote counts — only the question and the key
- **From the web (`②`)**: search past-question collections for the exam code, fetch page by page, and file each
  question with its URL and retrieval date. Collect what is available rather than a sample. Tell the user the count

Then start the index, one line per question:

```
exams/{slug}/_sources/questions/index.jsonl
{"id":"Q001","answer":"B"}
```

Phase 4 adds `topics`, Phase 5 adds `level`, `recall`, and `void`. `exam-quiz` source mode reads it in place of the
question files' metadata and may later add `void` or `key_fix`. Report one line: `기출 529문항 정리 (이미지 12건 전사)`.

## Phase 3 — Discover the exam's own structure

**Do not assume the exam has domains.** Find out how it is actually organized and record that — every later skill reads
it rather than guessing.

- Put **"extract only the section names, weights, and task lists"** in the WebFetch prompt. Do not pull whole pages
- For PDFs, convert on the command line and read only the relevant sections
- If the weights cannot be found, **do not guess** — ask the user

| `structure` | Looks like | Weight comes from |
|---|---|---|
| `weighted` | Named domains with published percentages — AWS, most vendor exams | The published % |
| `counted` | 과목 with a fixed number of questions each — Korean national certifications | Questions per section ÷ total |
| `flat` | A single curriculum with no grouping at all | None. Every topic is equal |

Record it in `blueprint.md` as `structure:`, with the exam's own word for the grouping (`domain`, `과목`, `area`) in
`section_label:`. `flat` is a legitimate outcome — forcing a structure invents weights that distort every allocation
downstream.

Korean 출제기준 often runs three deep. Flatten the middle: 주요항목 → section, 세부항목 → grouping only (not stored),
세세항목 → leaf topic.

## Phase 4 — Topics, validated against the bank

Break each section down to **leaf topics** — a unit one question can verify.

- Too coarse (`Networking`) makes coverage meaningless; too fine (`TGW route table propagation settings`) is unmanageable
- Rule of thumb: **one topic = one concept note = 2-5 questions**. 60-150 topics is the realistic range
- At the 150 ceiling, **do not silently truncate or merge the tail.** Report `"{n}개가 나옵니다. 150 상한을 넘습니다."`
  and let the user choose between raising the ceiling and coarsening — a quietly cut blueprint has a coverage
  denominator that looks complete while the tail is missing
- IDs run `T-001` upward with no section encoded; increment `topic_id_next` after each. **Never roll it back.**
  Full rules in `references/blueprint-format.md`
- With many sections, one subagent per section may draft topics in parallel; they return topic lists only

### Map the bank and let it correct the topics

With a bank, map every question to the topics whose knowledge is **load-bearing** — some option dies, or the chain
advances, on that topic's facts. A service merely named in the stem does not count. Write the result into the index
(`"topics":["T-041","T-005"]`). For a large bank, split by question range across subagents; each writes its own
`index.part-N.jsonl` and the main session merges them.

Then use the mapping to fix the topic list before anything depends on it:

| Finding | Action |
|---|---|
| Questions that fit no topic | A missing topic — add it, or widen the closest one |
| Questions crowding one topic far past the rest | Too coarse — split it |
| A topic with no question | Keep it (the guide covers it) and list it as unexamined |

Report one line: `토픽 130개 · 기출 매핑 98% · 미출제 토픽 7개`. `--refine` re-runs this whole phase, mapping included.

## Phase 5 — Question format analysis ★

Skipping this means generating plausible-looking questions that don't match the real exam.

1. Collect questions, in this order: **the bank** (best by far) → the vendor's official samples and practice sets →
   past-question collections on the web (shape only; answers unverified, wording never copied — see
   `_spec/source-policy.md`)
2. Analyze and fill `format.md` — type mix, stem length, question phrasings, requirement keywords, prohibitions
   - **Distractor patterns from the real questions**, not a generic list: what the wrong options in this exam actually
     do. IDs are `P1`, `P2`, … — never `D`, which collides with section IDs. This is the only pattern vocabulary:
     grading names patterns by these IDs and the wrongbook records them
   - **`angles:`** — 4-8 short codes naming the axis this exam varies along: requirement keywords for a scenario-heavy
     exam, question types otherwise. Fixed explicitly, since free-form labels drift (`cost` / `cost-effective` / `비용`).
     Leave it empty if the questions show no consistent axis
   - **Difficulty — from real questions, not the official sample set**, which is a showcase balanced by design.
     Calibrate on the bank, else on tens of web past questions, and use official samples only to confirm a shape.
     Work the sources until something separates the hard questions from the easy ones; do not stop at the first
     failed fetch, and do not ask the user to supply the criteria.

     **Sort the real questions from easiest to hardest and read off what actually changes** — it is rarely the
     number of requirements. Judge reasoning depth as if every subject fact were supplied; track unfamiliarity as
     recall load, never as a higher level; count only inferences the solver must derive. **Everything level-specific
     goes in `format.md`, never in a skill** — the lines, the tests that confirm each level, the conditions that void an
     item — because quiz runs exactly what `format.md` lists, and a rule in quiz would apply to every exam.

     Each line must be an instruction to name something countable, never a description of the finished question.
     A description ("multi-step judgment") is self-certifying — the author reads it and agrees — while a naming
     instruction fails visibly: a wrong level shows up as a slot that cannot be filled. Record the calibration source
     in `difficulty_basis` (`_sources/questions n=529 (date)` / `web n=40` / `[ESTIMATED]`). Write per-mode ratios
     (`diagnostic`, `weakness`, `section`, `mock`), each totaling 100; mark them `[ESTIMATED]` under five usable samples.
   - **Topic mixing**, measured on the same questions with the same load-bearing rule as the mapping:

     ```
     topic_mix: 45% (2 topics 40% · 3+ 5%)
     topic_mix_basis: _sources/questions n=505 (2026-09-27)
     ```

     Write `topic_mix: 0%` when it genuinely is — quiz treats a missing section as single-topic. Two topics side by
     side are breadth; only one topic's result feeding the other's inference raises the level.
3. **Write each bank question's level into the index** while calibrating — `"level":"M","recall":"twin"` — and mark
   items that cannot be answered as written `"void":true,"void_reason":"…"`: two defensible answers, a key the official
   docs contradict, options lost in extraction, a service change that makes the key impossible
4. **Synthesize two anchors** — never copy originals. Same format, different subject; different sections, one
   single-select and one multiple-response. Draft the higher-level anchor's trace first and confirm every slot of its
   line fills and every listed test passes. Reject an anchor whose correct option paraphrases the whole trace, or whose
   correct positions form a visible family
5. Fill the compact DRIFT-CHECK block at the top (harvest reads it with a bounded read)

No samples anywhere → draft from the vendor's typical format, mark **every field `[ESTIMATED]`**, and tell the user:
`"기출을 구하면 /exam-init --bank 로 넣고 --format 으로 갱신하세요"`.

For hands-on exams (CKA/CKAD and similar), set `format_type: performance`.

## Phase 6 — Register

- `mkdir -p exams/{slug}/notes/{section-slug}` for each section — **skip under `structure: flat`**, where notes go in
  `notes/{topic}.md`
- `blueprint.md` — the section and topic tables
- `mastery.md` — one row per topic, all ⬜, coverage `0/{n}`
- `exams/_active.md` → the new slug (overwriting is correct — only one exam is active)
- `exams/_registry.md` → **append one row with `Edit`, preserving every existing row**

**Never regenerate the registry table.** That silently drops every other exam from the overview while their data
files stay intact, so nothing looks broken until `/exam-status` comes up short. Remove the template's empty placeholder
row only on the first registration. Rows stay in registration order. If another exam's row has gone missing, do not
re-add it — tell the user to run `/exam-status --rebuild`.

## Phase 7 — Report and the next step

Five lines or fewer, and the last line is the path forward — what to type next, chosen by what this run produced:

```
AWS SAP-C02 등록 완료  D-42
도메인 4개 · 토픽 130개 · 기출 529문항 (매핑 98%, 미출제 토픽 7개)
형식: 4지선다·복수응답 · 단일 79 / 다중 21 · 난도 E65/M25/H10
다음: /exam-quiz 소스모드 20 — 기출을 순서대로. 사이사이 /exam-quiz 로 미출제 토픽 진단
```

| What exists | Next step to print |
|---|---|
| A bank | `/exam-quiz 소스모드 20`, with `/exam-quiz` in between for the topics the bank never reaches |
| No bank | `/exam-quiz`, then `/exam-harvest 3` for the topics it queues |

---

## --bank — adding past questions later

Run Phase 2 on the new files, numbering after the bank's last ID. Map the new questions (Phase 4 mapping only —
new topics still need `--refine`) and give them levels (Phase 5 step 3). Report the count and whether the new questions
exposed topics the blueprint lacks.

## --format re-run

1. Copy the current `format.md` to `state/_archive/format-{YYYY-MM-DD}.md` (add `-2` on a second run that day)
2. Re-run Phase 5 and replace `format.md`, refreshing `guide_version` and `verified_at`
3. Mark the related entries in `state/format-drift.md` as `applied (v{new}, {date})`
4. If section weights changed, continue into **blueprint migration**

### Blueprint migration

```
Section reorganized  →  keep IDs, change only the section column in blueprint
Topic removed        →  status: deprecated (never delete the row — mastery history survives, only questions are excluded)
Topic added          →  issue a new ID from topic_id_next
Weights changed      →  blueprint only; mastery unaffected
```

Present the change summary as a table and **get confirmation** before applying.

## Do not create friction

Ask about sources once (Phase 0) and never again. A missing exam guide must not block registration either — rough
out the sections, start, and tell the user they can refine later with `/exam-init --refine`. Not starting is worse
than being imprecise.
