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
Skip that read entirely if all five were confident and correct.

`shaky` almost always classifies as `confusion` — "I narrowed it to two" is the definition of a blurred
boundary. If the user names the other option they were weighing, record the pair; it becomes an `exam-comp` candidate.

## Phase 5 — Recording

**Print the graded output first, then write.** Every file write placed ahead of the verdicts is dead time for
someone who has been waiting since they hit send.

**Then issue all six writes as parallel tool calls.** They touch six different files and none reads another's
output. Settle the `W-id` for each new wrongbook entry first — the log delta and the wrongbook row both
reference it — but that is a decision, not a read, so it forces no order.

| File | Update |
|---|---|
| `state/log/{YYYY-MM}.md` | **Short delta only** — the question block is already there from Phase 3. Append one result line per question: answer, the user's pick, confidence, `W-id`, per-option verdicts |
| `state/mastery.md` | For each topic asked: attempts / correct / lucky / shaky / status / last / **recomputed score** / **the angle just used**. Refresh the hot block |
| `state/wrongbook.md` | Add one line per `miss` / `lucky` / `shaky`, with its origin **and the question's difficulty in the trailing `Diff` column** (`E`/`M`/`H`). Increment repeats for recurrences. Retire entries that met their streak to `_resolved.md`. Refresh the hot block |
| `state/sessions.md` | Refresh the hot block, append a log row (with the `fmt:` stamp) **and the session's actual difficulty mix in the trailing `Difficulty` column**, e.g. `E2/M3/H5` |
| `state/harvest-queue.md` | Queue `no-note`, `exhausted`, and `unverified-question` topics with the A/B verifier URL where one exists, plus `unknown` and `thin-note` cases |
| `exams/_registry.md` | Update this slug's coverage, accuracy, session count |

**Do not modify `blueprint.md`.**

### Recording difficulty

`sessions.Difficulty` is the **actual** mix of the questions asked, not the target from `format.md`. Writing the
target back is worthless — it makes the two agree by construction and hides exactly the drift the column exists to
catch. Count the questions as they were written and record that. When the actual mix misses the target, say so in
the wrap-up rather than silently recording the target.

`wrongbook.Diff` carries the difficulty of the question that produced the entry, so a run of wrong answers can be
read as "failing hard questions" or "failing easy ones" — two different problems.

Both are **trailing columns**. Rows written before the column existed are left short, and markdown renders the
missing cell as empty. Never backfill and never reorder columns: any later column must also be appended at the end.

### Appending a row to a table

`sessions.md` and `wrongbook.md` both end with HTML comments **below** the table. Append inside the table, above
those comments. Appending to the end of the file puts the row outside the table and silently breaks rendering
from that row down.

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
- When `basic_done` reaches 3, say that weakness mode takes over from the next session


## Never, in this phase

- Write a long explanation for a question answered correctly
- Read `blueprint.md` or `state/log/`
- Let a file write precede the printed result
