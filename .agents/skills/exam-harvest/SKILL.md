---
name: exam-harvest
description: Collect knowledge from vendor official documentation and turn it into concept notes. Use when the user says "노트 만들어", "자료 수집", "큐 처리해줘", "D2 정리해줘", "공부 자료 만들어", or "harvest". Drains the harvest queue first, collects in parallel via subagents, and detects exam-format drift while reading official docs. A number argument processes only that many entries.
---

# exam-harvest

Turns the queue the quiz built into notes. **A small batch that finishes in two minutes on a phone is the default** —
anything heavier stops getting run, and once it stops the question quality decays.

**Talk to the user in their own language.**

## Call forms

| Call | Target |
|---|---|
| `/exam-harvest` | Top 5 of the queue |
| `/exam-harvest 3` | Top 3 (**recommended on a phone**) |
| `/exam-harvest D2` | Topics in section D2 that have no note (skip under `structure: flat`) |
| `/exam-harvest Transit Gateway` | One specific topic |

## Phase 0 — Drift comparison

1. `exams/_active.md` → slug. A slug named by the user wins, and when it differs,
   **update `exams/_active.md` to it before continuing** and say so in one line.
   Notes are being written for that exam, so it is the one being studied
2. `exams/{slug}/format.md` via **`Read(limit=14)`** (DRIFT-CHECK block only)
3. While reading official docs during collection, compare against those 8 lines

| Grade | Condition | Action |
|---|---|---|
| minor | Wording changes, samples added, `verified_at` past 90 days | **Non-blocking.** Append to `state/format-drift.md` and continue |
| major | Exam code change, domain reorganization, weight change, question count or duration change | Finish the current batch, then **stop** |

Stopping on major exists to **avoid writing notes for topics about to disappear.**
On stop: `"⚠ SAP-C03 개편 감지 (도메인 4→5). /exam-init --format 실행 후 재개하세요."`

**Never modify `format.md` here.** Only `/exam-init --format` may.

## Phase 1 — Target selection

Check `_inbox/` first. New files there for this exam get processed ahead of the queue, then moved to
`exams/{slug}/_sources/`. Tell the user in one line: `"_inbox에 새 자료 2개 — 먼저 반영합니다"`.

Accepted: URL, PDF, MD, TXT, DOCX, XLSX, PPTX, images. HWP must be exported to PDF from 한글 first.

**Read `_spec/file-reading.md` before opening any local file.** PDFs go through
`swift _spec/pdftext.swift <file.pdf>` (macOS, no install), never the Read tool — page rendering costs 10-50x.
A file that could not be read must never be cited as a source.

**Material handed over in the conversation** — if the user attaches or pastes something substantial, save it to
`exams/{slug}/_sources/` before turning it into notes. Otherwise the note's citation points at something that
no longer exists. Name it `{topic-or-doctype}-{YYYY-MM-DD}.{ext}` and cite it as `[B] filename p.42`.

If what arrives is an exam guide or 출제기준 rather than study material, **do not try to use it here.**
Notes are harvest's only output. Point the user at `/exam-init --refine` (topics) or `/exam-init --format`
(question format), after saving the file to `_sources/`.

Priority:

```
1. harvest-queue.md, priority high  (unknown · thin-note)
2. harvest-queue.md, the rest
3. mastery 🟥 topics with no note
4. ⬜ untested topics, heaviest section first — or simply in topic-ID order under `structure: flat`
```

**Use the queue's `Source` column.** When a row carries a URL, whoever queued it already found and verified that
page — start from it and skip the search. Only widen out if it turns out to be thin.

Announce the selection in one line and begin: `"큐 3개 처리: T-041, T-052, T-018 (예상 2분)"`

## Phase 2 — Parallel collection

With two or more topics, **process them in parallel with subagents.**

```
One subagent = one topic
Instruction: research official docs → write the note file directly → return a summary only
              path: notes/{section}/{topic}.md, or notes/{topic}.md under structure: flat
Return: {topic id, file path, source count, one-line summary, drift observations}
```

**A subagent that returns note bodies destroys the isolation benefit.** Have it write the file and return only the summary.
Subagents must not modify anything under `state/` — that is how parallel-write corruption is avoided.
The main session aggregates queue and drift updates.

Instruct each subagent to read **`references/harvest-policy.md`, and nothing else.** It carries the source
rules, the citation format, the note skeleton, and the return format in one place.

The full policy in `_spec/source-policy.md` is for the main session and for changing the policy — sending it to
five subagents costs 2.3k each to answer questions they were never going to ask.

## Phase 3 — Aggregation

The main session handles these, in order:

| File | Update |
|---|---|
| `state/harvest-queue.md` | Remove processed entries, refresh the pending count |
| `state/format-drift.md` | Append the observations subagents reported |
| `notes/_facts.md` | Add limit and quota cards discovered during collection |
| `notes/_compare/` | Create a comparison table when a confusable pair surfaces (follow the `exam-comp` rules) |
| `exams/_registry.md` | Refresh the fmt-checked date |

Do not modify `blueprint.md` (if new topics surface, point the user at `/exam-init --refine`).
Do not modify `mastery.md` either — having a note does not raise proficiency.

## Phase 4 — Report, 3 lines (Korean)

```
노트 3개 생성: T-041 TGW Routing · T-052 SCP · T-018 Aurora Global
비교표 1개: vs-scp-vs-iam-policy
큐 4개 남음. /exam-quiz 로 방금 만든 노트를 검증해 보세요
```

---

## Never

- **Put practice questions in a note.** Questions are quiz's job, and stored questions get memorized by wording
- Collect from dump or question-bank sites
- Omit the source URL or collection date
- Process more than 10 topics at once (feels like a timeout on a phone)
- Modify `format.md` directly
