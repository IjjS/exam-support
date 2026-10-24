# Grading and recording

Read this when the user's answers arrive, at Phase 4. Not before.

It loads while they are still solving — the same free window the log write uses — so nothing here sits between
the user and their score.

---

## Phase 4 — Grading

### Parsing answers

```
2       confident
2?      shaky
2??     guessed    lucky (recorded as wrong even when correct)
2,4     multiple response
2,4??   multiple response, guessed
```

- Multiple response has **no partial credit.** Exact match only. Record `partial 1/2` in the notes column
- No question mark means confident. If parsing is ambiguous, assume confident and move on — do not ask again

### Verdict

Scoring and the review queue are **two separate decisions.** A question can score as correct and still
belong in the wrongbook.

| Answer | Scored | Wrongbook | origin |
|---|---|---|---|
| correct + confident | correct | — | |
| **correct + `?`** | **correct** | **✅ added** | `shaky` |
| correct + `??` | **wrong** | ✅ added | `lucky` |
| wrong | wrong | ✅ added | `miss` |

`??` scored wrong: getting it right by guessing is not knowing it. `?` scored correct but still queued: winning
a coin flip between two options is not knowing it either. Accuracy stays `(correct - lucky) / attempts` —
a shaky answer was genuinely correct, so the wrongbook entry is how it gets revisited, not a score penalty.

Record the origin on every entry. Three signals, three treatments.


### Explanations — every option, one line each

**Every question gets a verdict on every option**, including questions answered correctly.
Knowing why the other four fail is the discrimination the exam actually tests.

```
Q3   정답 4   내 답 2 ✗

  1  ✗  리전 간 전이 라우팅 불가
  2  ✗  동작은 하나 운영부담 큼 — "LEAST operational overhead" 위반
  3  ✗  DX는 구축에 수 주 — "quickly" 위반
  4  ✓  TGW + VPN. 요구조건 3개 충족
  5  ✗  실재하지 않는 조합
```

- **One line per option. No prose, no paragraph under any option.** The fixed shape is what keeps this
  readable on a phone and what stops explanations from expanding
- Name the reason, not just the verdict. `"운영부담 위반"` beats `"틀림"`; where a distractor pattern applies
  (`D1` legacy bait, `D2` over-engineering …) name it — the pattern is more memorable than the instance
- Show `내 답` only when it differs from the answer
- For multiple response, mark every correct option `✓`

If the user asks for depth on a specific question after seeing this, give it then. Do not pre-empt it.

### Classifying what goes in the wrongbook

For every `miss`, `lucky`, and `shaky` entry, **read `_spec/error-taxonomy.md`** and assign a type.
Skip that read entirely if every answer was confident and correct.

`shaky` almost always classifies as `confusion` — "I narrowed it to two" is the definition of a blurred
boundary. If the user names the other option they were weighing, record the pair; it becomes an `exam-comp` candidate.

## Phase 5 — Recording

**Print the graded output first, then write.** Every file write placed ahead of the verdicts is dead time for
someone who has been waiting since they hit send.

**Then issue the writes in the table below as parallel tool calls.** They touch different files and none reads another's
output. Settle the `W-id` for each new wrongbook entry first — the log delta and the wrongbook row both
reference it. `sh _spec/wrongbook.sh {slug} next-id` gives the first one; number the rest upward from it.

| File | Update |
|---|---|
| `state/log/{YYYY-MM}.md` | **Short delta only** — the question block is already there from Phase 3. Append one result line per question: answer, the user's pick, confidence, `W-id`, per-option verdicts |
| `state/mastery.md` | For each topic asked: attempts / correct / lucky / shaky / status / last / **recomputed score** / **the angle just used** — **rewrite the whole row**, see below. Refresh the hot block |
| `state/wrongbook.md` | **Through `_spec/wrongbook.sh` only** — see below. Add one row per `miss` / `lucky` / `shaky`, with its origin **and the question's difficulty in the trailing `Diff` column** (`E`/`M`/`H`). Increment repeats for recurrences. Retire entries that met their streak to `_resolved.md` |
| `state/sessions.md` | Refresh the hot block, append a log row (with the `fmt:` stamp) **and the session's actual difficulty mix in the trailing `Difficulty` column**, e.g. `E2/M3/H5` |
| `state/harvest-queue.md` | Queue `no-note`, `exhausted`, and `unverified-question` topics with the A/B verifier URL where one exists, plus `unknown` and `thin-note` cases |
| `exams/_registry.md` | Update this slug's coverage, accuracy, session count |
| `state/format-drift.md` | **Only when the user disputes a difficulty call this session.** One row, grade `minor`, field `difficulty` |

**Do not modify `blueprint.md`.**

### Writing a mastery row — whole line, never a span

Replace the entire line: the old string runs from `| T-041 |` through the row's final `|`, and the new string is
the complete row, one cell per header column, ending in ` |`.

```
| T-041 | {topic} | D2 | 3 | 2 | 0 | 1 | 🟨 | 2026-10-02 | 1.53 | ops |
```

Never edit a span inside a row (`| 1 | 0 |` → `| 2 | 1 |`). The same short span matches in many rows, and a span
that starts or ends one cell off leaves the old attempt count behind and drops the trailing pipe. Every column to
its right then shifts, and status and score are read from the wrong cells from the next session on.
Observed S20 and S21 (2026-10-02) — every row written in those sessions came out with an extra cell.

After the writes, check the touched rows — each must end in `|` and match the header's cell count:

```bash
awk -F'|' '/^\| ID /{n=NF} /^\| T-(041|005) /{print $2, (NF==n && /\|$/ ? "ok" : "BAD")}' exams/{slug}/state/mastery.md
```

Repair a `BAD` row before the wrap-up rather than leaving it for the next session to misread.

### Mixed questions — record on every topic

A question whose heading lists several topics (`T-041,T-005`) is recorded **on each of them, in full**:

- `mastery.md` — each topic's row gets the attempt and the same verdict (correct / lucky / shaky / wrong)
- `wrongbook.md` — one row **per topic**, each with its own `W-id`, the same origin, type, and `Diff`. Each retires
  on its own streak, so a topic that keeps failing in combination stays in the book after its partner clears
- The log result line carries every `W-id`: `W-082,W-083`

A solved question is not the same thing as topic coverage, so per-topic counts may sum past the question count.
The question-level figures — the mastery hot block's surface/real accuracy, `sessions.md`, `_registry.md` —
still count each question once.

### Recording difficulty

`sessions.Difficulty` is the **actual** mix of the questions asked, not the target from `format.md`. Writing the
target back is worthless — it makes the two agree by construction and hides exactly the drift the column exists to
catch. Count the questions as they were written and record that. When the actual mix misses the target, say so in
the wrap-up rather than silently recording the target.

`wrongbook.Diff` carries the difficulty of the question that produced the entry, so a run of wrong answers can be
read as "failing hard questions" or "failing easy ones" — two different problems.

**When the user says a level was wrong** — "이게 무슨 hard야", "이건 easy 아닌데" — they are calibrating the exam's
criteria, and they are better placed to do it than the sample set was. quiz cannot edit `format.md`, so record the
correction in `state/format-drift.md` and let `/exam-init --format` apply it:

```
| S4-Q7 hard로 냈으나 사용자는 easy 판정 | minor | difficulty | H: name 2+ viable … | 서비스명이 답을 드러냄 | 사용자 (2026-08-19) | open |
```

One row per disputed question, not per session. Do not argue the call and do not re-grade the answer — the score
stands, only the criteria are in question.

Both are **trailing columns**. Rows written before the column existed are left short, and markdown renders the
missing cell as empty. Never backfill and never reorder columns: any later column must also be appended at the end.

### Writing the wrongbook — through the script, never by hand

Editing `wrongbook.md` directly means loading it, which is the read this skill no longer does. Every change goes
through `_spec/wrongbook.sh`, one call per kind of change, each fed **complete rows** on stdin:

```bash
sh _spec/wrongbook.sh {slug} add <<'EOF'      # new entries
| W-113 | T-041 | shaky | confusion | 2026-10-11 | 0 | 0 | {core} | {notes} | M |
EOF
sh _spec/wrongbook.sh {slug} set <<'EOF'      # recurrences: the row from Phase 2 with repeats/streak/notes updated
| W-016 | T-041 | miss | confusion | 2026-08-19 | 5 | 1 | {core} | {notes} | H |
EOF
sh _spec/wrongbook.sh {slug} retire <<'EOF'   # streak met: the row in _resolved.md's columns
| W-016 | T-041 | miss | confusion | 2026-08-19 | 2026-10-11 | {sessions taken} |
EOF
echo "{new value}" | sh _spec/wrongbook.sh {slug} keywords   # only when a missed keyword was recorded
```

The script places rows inside the table, rejects a row whose cell count differs from the header, refuses a
duplicate or unknown `W-id`, and recomputes the hot block's `active` and `types` lines itself. A non-zero exit
means nothing was written for that call — fix the row and rerun it.

### Appending a row to a table

`sessions.md` ends with HTML comments **below** the table. Append inside the table, above those comments.
Appending to the end of the file puts the row outside the table and silently breaks rendering from that row down.

### The log result line — the anchor that makes the log searchable

The question block went in during Phase 3 under `### S12-Q3 — T-034 · …`. The delta closes it:

```
**결과**  정답 4 · 내 답 2 ✗ · W-001 · confusion · H
  1 ✗ 리전 간 전이 라우팅 불가
  2 ✗ 동작은 하나 운영부담 큼 — "LEAST operational overhead" 위반
  3 ✗ DX는 구축에 수 주 — "quickly" 위반
  4 ✓ TGW + VPN. 요구조건 3개 충족
  5 ✗ 실재하지 않는 조합
```

- The `W-id` on the result line is what `exam-desc` greps for. It sits **below** the question, so a lookup reads a
  window that starts above the match
- The difficulty goes last on the result line. It is already in the question heading; repeating it here means a
  grep hit on the `W-id` shows it without widening the window
- Omit the `W-id` for confident-correct answers — nothing to look up later
- A re-asked entry keeps the **same `W-id`** across months, which is what gives the entry a history

## Phase 6 — Wrap-up, 3 lines or fewer (Korean)

```
3/5  (실질 2/5 — Q4는 찍어서 맞음)
🟥 T-041 TGW 라우팅 2연속 오답 · 개념혼동 → /exam-comp 로 비교표 권장
큐 7개 쌓임. /exam-harvest 3 (약 2분)
```

- With three or more queued topics, always nudge harvest. Thin notes degrade question quality and the tool stops getting used
- Mention coverage in one line if it moved


## Never, in this phase

- Write a long explanation for a question answered correctly
- Read `blueprint.md` or `state/log/`
- Let a file write precede the printed result
