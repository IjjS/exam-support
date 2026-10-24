---
name: exam-reset
description: Reset a certification's study state — accuracy, wrong-answer book, session history, coverage. Use when the user says "리셋", "초기화", "처음부터 다시", "기록 지워줘", "오답노트 비워", or "reset". --rm {exam} unregisters an exam entirely so init can start clean. Always backs up before deleting, preserves notes and blueprint depending on scope, and requires explicit user confirmation before removing anything.
---

# exam-reset

**This is destructive.** Nothing is deleted without a backup, and nothing runs without confirmation.

Read `references/reset-scope.md` before executing.

**Talk to the user in their own language.**

## Phase 1 — Determine scope

Map the user's phrasing to a scope. **Ask** if it is ambiguous.

| Scope | Deletes | Keeps | User phrasing |
|---|---|---|---|
| `stats` **(default)** | mastery statistics, session log, coverage | wrong-answer book, notes, comparison tables, blueprint, format | "성적 초기화", "처음부터 다시 풀래" |
| `wrong` | wrong-answer book, `_resolved` | statistics, notes, blueprint | "오답노트 비워" |
| `state` | all six state files | notes, comparison tables, blueprint, format | "학습기록 다 지워" |
| `all` | state + notes + comparison tables | blueprint, exam.md, format | "완전히 처음부터" |
| **`--rm`** | **the entire exam directory** | **nothing** | "시험 자체를 지워", "등록 취소", "처음부터 다시 등록" |

**No study scope deletes `blueprint.md`, `exam.md`, or `format.md`.**
Those define the exam; they are not the user's study data. To remove a certification entirely, use `--rm`.

### `--rm` — unregister the exam

`/exam-reset --rm {exam}` clears everything and returns the slug to a state where `/exam-init` starts clean.
For when the blueprint itself is wrong, the schema changed, or it was a test registration.

```
exams/{slug}/       → moved to exams/_archive/{slug}-{YYYY-MM-DD}/
exams/_registry.md  → the slug's row removed
exams/_active.md    → cleared to — if it pointed here
```

**Move, never delete.** The directory goes to `exams/_archive/` intact. A mistaken `--rm` over months of mastery
data is unrecoverable any other way, and the archive costs nothing since `exams/` is gitignored.

Three confirmations — this is the only command that can destroy a study history in one step:

1. Show what goes: topics, sessions, notes, wrongbook entries, coverage
2. Require the user to **type the slug**
3. Report the archive path, so undo is one `mv`

## Phase 2 — Confirmation

Show what will be deleted **as numbers.** Never ask abstractly.

```
AWS SAP-C02  범위: stats

지워짐
  세션 기록 12회
  숙련도 통계 (27토픽 시도 → 전부 ⬜)
  커버리지 34% → 0%

보존
  오답노트 18건
  노트 23개 · 비교표 4개
  blueprint · format

백업: exams/aws-sap/state/_archive/2026-08-15-stats/

진행할까요?
```

- For `state` and `all`, require the user to **type the exam slug** as a second confirmation
- For `all`, state explicitly that notes disappear and harvest must be re-run

## Phase 3 — Backup

```bash
mkdir -p exams/{slug}/state/_archive/{YYYY-MM-DD}-{scope}
```

Copy **every file to be deleted first**, then reset. Never reverse this order.
A second run on the same day with the same scope gets a `-2` suffix (never overwrite).

`state/log/` is **never deleted under any scope.** It is the audit record of question text, it costs nothing in the hot
path, and it is the only basis for recovery later.

## Phase 4 — Reset

Copy the matching file from `_template/exam/state/`, overwrite, and substitute the `{{PLACEHOLDER}}` values.
That is safer and faster than editing in place.

Under `stats`, mastery **rows are not deleted.** Keep the topic list, zero the counts, return status to ⬜.
Deleting rows desynchronizes it from blueprint and breaks the coverage denominator.

Update the matching row in `exams/_registry.md` as well.

## Phase 5 — Report (Korean)

```
초기화 완료  AWS SAP-C02 (stats)
백업: state/_archive/2026-08-15-stats/
오답노트 18건과 노트 23개는 보존됨
```

## Never

- Delete before backing up
- Run without confirmation (show the inventory even if the user says "그냥 지워")
- Delete `blueprint.md`, `exam.md`, or `format.md` **under any scope except `--rm`**
- Run `--rm` without moving the directory to `exams/_archive/` first
- Run `--rm` on a slug the user did not type out
- Delete `state/log/`
- Delete mastery rows (zero the values instead)
- Overwrite an existing backup
- Reset several certifications at once (one at a time)
