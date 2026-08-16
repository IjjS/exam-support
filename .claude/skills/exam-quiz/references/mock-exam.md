# Mock exam mode

Triggered by `/exam-quiz 모의고사`, `/exam-quiz 모의고사 30`, or `"실전처럼"`.

---

## Batching is the whole point

Generating 65 questions in one context costs 13k output plus 39k input, and the later questions degrade visibly.

```
Split into batches of 10.
Carry only {correct count, per-domain score, elapsed time} across batches
and drop the previous batch's stems and options from context.
```

With no count given, **recommend 30**. If the user asks for the real count (SAP has 75), state the expected time
and batch count first and get confirmation.

## Notes are not read

The purpose of a mock exam is **exam feel and the shape of your weak domains**, not precise verification.
Generate from mastery's topic names plus `format.md` alone. This differs from weakness mode, which reads five notes.

Three-tier sourcing does not apply either. Run without web lookups and tag uncertain items `[UNVERIFIED]`.

## Composition

- **Domain weights exactly as the real exam** — no weakness weighting; the point is realism
- Even difficulty distribution
- Single/multiple ratio straight from `format.md`
- ⬜ untested topics are included normally

## Flow

```
Batch 1/3 (Q1-Q10) presented
  → collect answers  (e.g. 1 3? 2,4 5?? 1 2 4? 3 1,5 2)
  → no grading, move to the next batch
Batch 2/3 …
Batch 3/3 …
  → grade everything at once
```

No mid-way grading, because that is what the real exam is like. If the user asks for interim grading, do it.

Record start and end times to report elapsed time. Skip it if the user does not supply times.

## Result report (Korean)

```
모의고사 30문항  |  22/30 (73%)  |  실질 19/30 (63%)  |  48분

도메인별
  D1 조직 복잡성      7/8   🟦
  D2 신규 솔루션      5/9   🟨   ← 취약
  D3 지속 개선        6/7   🟩
  D4 마이그레이션     4/6   🟨

유형별 오답   개념혼동 4 · 문제해석 3 · 지식부재 1
놓친 키워드   LEAST operational overhead 3회

합격선 대비: 73% (기준 75%) — 2%p 부족
다음: /exam-quiz D2
```

- Always report **real score** (lucky guesses excluded) alongside the surface score. Surface alone overstates readiness
- Compare against the passing score if `exam.md` has one

## Recording

Same state updates as a normal session, with these differences:

- Mode in `sessions.md` is `mock` → **counts toward basic_done** (helps unlock weakness mode)
- Append every question to `state/log/{YYYY-MM}.md`
- There are many mastery rows to touch — apply them **once at the end of the session**, not per batch
