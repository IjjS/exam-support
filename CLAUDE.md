# weakness-manager

A markdown-based system for certification study that hunts down the areas you didn't know you didn't know.
Designed to be driven from a phone via remote control of this Mac. **Short output, one-line input.**

## Conversation rules

- **Talk to the user in their own language.** All conversation, explanations, warnings, and reports follow it.
  Sample outputs in the skill files are written in Korean because that is what this repo was built against —
  they illustrate shape, not language.
- The language of questions and answer options is set by the anchors in `format.md`, per exam. It follows the exam,
  not the conversation: a Korean-language exam gets Korean questions even when the conversation is English.
- Format for a phone screen. Tables at most 3 columns.
- Quiz explanations: **every option gets a one-line verdict, on every question.** No prose blocks. Depth only if asked.
- All study data lives under `exams/{slug}/`. **Never cross-reference between exams.**

## Absolute rules

1. **Topic IDs (`T-041`) are permanent** — never reissue, reuse, or delete one. If domains are reorganized, keep the ID and change only the domain column. Mark removed topics `deprecated`; never delete the row. Do not encode the domain into the ID.
2. **Hot block at the top of state files** — aggregates live in the first 15 lines. Use `Read(limit=N)` instead of loading the whole file.
3. **`state/log/` is write-only in the loop** — `exam-quiz` must never read it, at all. `exam-desc` may, only for an entry the user named, and only with grep-then-bounded-read. Log headings carry the `W-id` so that lookup is an index hit, not a scan.
4. **Sources are tiered A/B/C by artifact, not by site** — official docs, statutes, statistics (A) and user files plus **published past papers with answer keys** (B) may back a note; **Tier C (`examtopics.com`, community explanations) never can** — whitelisted for question *shape* only, never for what is true. Record source and date every time. See `exam-harvest/references/source-policy.md`.
5. **Subagents write files themselves and return only a summary** — never return note bodies into the main context.
6. **Only `/exam-init --format` may modify `format.md`** — harvest records observations in `state/format-drift.md` and nothing more.
7. **`blueprint.md` is an immutable spec** — coverage, accuracy, and every mutable value live in `state/mastery.md`. quiz neither reads nor writes blueprint.

## Skill routing

| User says | Skill |
|---|---|
| 문제 내줘 / 퀴즈 / 모의고사 / 시험 | `exam-quiz` |
| 지금 상태 / 뭐부터 / 커버리지 / D-day | `exam-status` |
| 노트 만들어 / 자료 수집 / 큐 처리 | `exam-harvest` |
| A vs B / 차이 / 뭘 골라야 / 비교 | `exam-comp` |
| ~가 뭐야 / 설명해줘 / 이 도메인 뭐야 | `exam-desc` |
| 새 자격증 / 등록 / 형식 갱신 | `exam-init` |
| 초기화 / 리셋 / 처음부터 | `exam-reset` |
| 스킬 뭐 있어 / 명령어 / 도움말 / 뭐 할 수 있어 | `exam-skills` |

`exam-desc` explains the **exam subject**; `exam-skills` explains the **tooling**. Route on which one is being asked about.

## File roles

```
_inbox/              User-supplied source files (URL·PDF·MD·TXT·DOCX·XLSX·PPTX·image; no HWP).
                     init and harvest pick them up, then move them to _sources/.
                     Material handed over in conversation is saved to _sources/ before use, or it is lost.
exams/_active.md     The exam currently being studied (every skill reads this first).
                     quiz and harvest rewrite it when the user names a different exam; status and desc never do.
exams/_registry.md   Per-exam summary cache (coverage %, accuracy, D-day)
exams/{slug}/
  exam.md            Exam metadata
  format.md          Question format spec + anchors. DRIFT-CHECK block at top
  blueprint.md       Domains, weights, topics (immutable)
  _sources/          Processed user-supplied files (originals kept)
  notes/             {domain}/{topic}.md, _compare/, _facts.md
  state/
    mastery.md       Per-topic proficiency (includes coverage)
    wrongbook.md     Active wrong-answer index (one line per entry)
    _resolved.md     Retired wrong answers
    sessions.md      Session log (aggregates on top, used for mode gating)
    harvest-queue.md Topics awaiting notes
    format-drift.md  Observed exam-format changes
    log/{YYYY-MM}.md Full question text, W-id anchored (quiz never reads; desc on request only)
    _archive/        Reset backups, superseded format versions
```

## Write permissions

| Access | Skills |
|---|---|
| Writes | `exam-init` `exam-harvest` `exam-quiz` `exam-comp` |
| Read-only | `exam-status` `exam-desc` `exam-skills` |
| Confirm first | `exam-reset` (delete only after backup) |

## Before modifying a skill

Read `docs/DESIGN.md` first. It carries the token budget, the bottleneck analysis, and the migration rules,
and the current structure is shaped by reasons recorded there. In particular, before changing any state file
format, check the "Preventing unbounded growth" section.
