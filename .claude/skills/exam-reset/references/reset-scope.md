# Reset scope detail

Per-file handling. Read before running `exam-reset`.

Legend: **DELETE** = back up, then reset from template · KEEP = untouched · *PARTIAL* = only some values

| File | stats | wrong | state | all |
|---|---|---|---|---|
| `state/mastery.md` | **PARTIAL** | KEEP | **DELETE** | **DELETE** |
| `state/sessions.md` | **DELETE** | KEEP | **DELETE** | **DELETE** |
| `state/wrongbook.md` | KEEP | **DELETE** | **DELETE** | **DELETE** |
| `state/_resolved.md` | KEEP | **DELETE** | **DELETE** | **DELETE** |
| `state/harvest-queue.md` | KEEP | KEEP | **DELETE** | **DELETE** |
| `state/format-drift.md` | KEEP | KEEP | KEEP | KEEP |
| `state/log/` | KEEP | KEEP | KEEP | KEEP |
| `state/_archive/` | KEEP | KEEP | KEEP | KEEP |
| `notes/**` | KEEP | KEEP | KEEP | **DELETE** |
| `notes/_compare/**` | KEEP | KEEP | KEEP | **DELETE** |
| `notes/_facts.md` | KEEP | KEEP | KEEP | **DELETE** |
| `blueprint.md` | KEEP | KEEP | KEEP | KEEP |
| `format.md` | KEEP | KEEP | KEEP | KEEP |
| `exam.md` | KEEP | KEEP | KEEP | KEEP |

---

## mastery **PARTIAL** reset (stats)

```
Never delete rows.
Leave the ID, Topic, and Domain columns as they are.
attempts / correct / lucky / shaky → 0
status → ⬜
last → —
score → —
hot block coverage → 0/{total}
```

Deleting rows desynchronizes mastery from the blueprint topic list and breaks the coverage denominator;
recovering would mean re-running `/exam-init --refine`.

---

## Why the split works this way

| Decision | Reason |
|---|---|
| `state/log/` is never deleted | Audit record of question text. quiz never reads it so it costs nothing, and it is the only way back from a mistaken reset |
| `format-drift.md` is never deleted | Observations about exam revisions have nothing to do with the user's scores |
| `stats` keeps the wrong-answer book | The most common request is "reset my scores but remember my weak spots" |
| `wrong` keeps the statistics | This scope is for a cluttered wrong-answer book. There is no reason to throw away coverage |
| Even `all` keeps blueprint and format | They define the exam, not the user's data. Deleting them would force a full `/exam-init` |
| harvest-queue goes at `state` and above | The queue is a derivative of quiz. Dropping it on a stats-only reset loses the collection plan |

---

## Recovery

Backups sit untouched at `state/_archive/{YYYY-MM-DD}-{scope}/`.

```bash
cp exams/{slug}/state/_archive/2026-08-15-stats/*.md exams/{slug}/state/
```

If the user asks to undo, show this path, confirm which backup, then copy.
