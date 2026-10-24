# Source mode — working through the past-question bank

Triggered by `소스모드`, `소스모드 20`, `기출`, `기출 20문제`, or `기출 풀래`.

Read this instead of Phases 2-3 of the main skill. Phases 4-6 (`references/grading.md`) still apply, with the
differences listed at the end.

The bank is the real exam's own questions, so this mode does not generate anything. It presents them in order,
grades them, and records the result on the topics each one tests. **It is the closest practice to the real paper
this repo can offer**, which is why init recommends it whenever a bank exists.

---

## Before starting

- `exams/{slug}/_sources/questions/index.jsonl` must exist. If it does not:
  `"기출 뱅크가 없습니다. /exam-init --bank 로 기출을 넣으면 소스모드를 쓸 수 있습니다."` — and stop
- The cursor is `source_next:` in the `sessions.md` hot block (already read in Phase 0). If the line is missing —
  an exam registered before this mode existed — ask once where to start (`Q001` by default) and add the line
- Default count is **20**. A count the user gives wins

## Picking the batch

Take the next N entries **in bank order from the cursor**, skipping `"void":true`. Read only those lines of the index
and only those question files — never the whole bank:

```bash
grep -n '"id":"Q021"' exams/{slug}/_sources/questions/index.jsonl     # line number of the cursor
sed -n '{line},{line+40}p' exams/{slug}/_sources/questions/index.jsonl # a window wide enough to skip voids
```

None of the main skill's selection rules apply — not the section spread, not the angle, not the difficulty ratios.
The bank's order is the paper's order. An entry with no `topics` cannot be recorded; skip it and say so in the
wrap-up so the user can run `/exam-init --refine`.

## Presenting

- The stem and options **as stored** — the user's own practice material. Fix obvious extraction damage only
- Renumber the options `1, 2, 3 …` to match the answer syntax, and mark `(single)` / `(Choose TWO)` as usual
- Never show the source, the bank ID, the stored key, the level, or the topics
- The 답변 line and the leak guard from the main skill apply unchanged

Log each question as a **reference only** — the full text already lives in the bank:

```
### S31-Q1 — Q021 · T-041,T-005 · D2,D1 · M
```

## Grading — the key is a claim

Grade against the stored `answer`, but **verify it wherever the result depends on it**: when the user's answer
differs from the key, or carries `?` or `??`. Verify with the notes of the question's topics first, then official docs
or guides. A confident answer that matches the key needs no lookup.

| Verification shows | Do |
|---|---|
| The key holds | Grade normally |
| An official doc settles a different option | Grade against that option. Add `"key_fix":"B→C web: {url}"` to the index line |
| Two options defensible, or the item is broken | **Void** — no score, no record. Add `"void":true,"void_reason":"…"` to the index line |

Every option still gets its one-line verdict, on every question.

## Recording — what differs from grading.md

- **Topics come from the index**, not from selection. A question with several topics is recorded on every one,
  exactly like a mixed question
- **Difficulty** for `sessions.Difficulty` and `wrongbook.Diff` comes from the index `level`; classify only an entry
  that has none
- `sessions.md` row: Mode `source`. Then set `source_next:` to the ID after the last question presented
- **Source sessions do not count toward `basic_done`** — that counter is diagnostic and mock sessions only
- Voids and key fixes are written to the index lines touched this session, and nowhere else
- Topics whose notes could not verify a key are queued for harvest as usual

Wrap-up adds one line: `기출 Q041까지 · 남은 488문항` (count the remaining non-void entries).
