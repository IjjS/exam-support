---
name: exam-status
description: Show certification study status on one screen and recommend what to do next. Use when the user says "지금 상태", "뭐부터 할까", "커버리지 얼마나", "D-day", "진도 어때", "약점 뭐야", or "status". Read-only — it modifies no files. --rebuild recomputes the registry cache.
---

# exam-status

**Read-only.** It modifies no files.

Naming an exam here shows that exam's status but **does not switch the active exam** — only `exam-quiz` and
`exam-harvest` do that, because those are the ones actually studying it. Checking on an exam is not switching to it.

This gets called from a phone, mid-commute. **Finish inside one screen** — if it needs scrolling, it failed.

**Talk to the user in their own language.**

## What it reads

### Overall view (no exam named)

`exams/_registry.md` **and nothing else.** Three certifications would otherwise mean nine state files, hence the cache.

### Active exam detail (default)

```
exams/_active.md
exams/{slug}/state/mastery.md         full
exams/{slug}/state/sessions.md        Read(limit=15)
exams/{slug}/state/wrongbook.md       Read(limit=10)  ← hot block: origins, types, missed keywords
exams/{slug}/state/harvest-queue.md   Read(limit=8)
exams/{slug}/exam.md                  D-day, passing score
exams/{slug}/format.md                Read(limit=14)  ← for verified_at
```

Never reads `blueprint.md`, `state/log/`, `_resolved.md`, or the wrongbook table. For the weakness top-3 detail
(`3연속 오답 · 개념혼동`), fetch just those rows: `sh _spec/wrongbook.sh {slug} rows T-041 T-052 T-018`.

## Output (Korean)

```
AWS SAP-C02   D-42   세션 12회 (진단 3 · 약점 9)

커버리지  34%  (27/79)          ⬜ 미출제 52
정답률    표면 61%  실질 47%     ← 격차 14%p = 찍어서 맞힌 몫

도메인
  D1 조직복잡성    🟩 8/11
  D2 신규솔루션    🟥 3/9    ← 최약
  D3 지속개선      🟨 5/7
  D4 마이그레이션  ⬜ 0/0    ← 완전 백지

약점 TOP3
  T-041  TGW Routing        3연속 오답 · 개념혼동
  T-052  SCP vs IAM         찍맞 2회
  T-018  Aurora Global      2연속 오답 · 암기누락

오답노트  15건 = 오답 7 · 찍맞 3 · 애매 5
오답유형  개념혼동 7 · 문제해석 5 · 지식부재 3
놓친키워드  LEAST operational overhead 4회

→ /exam-quiz D4     (백지 도메인 진단)
   /exam-harvest 3  (큐 7개)
```

## Output rules

- **Always show the gap between real and surface accuracy.** That gap is the size of the blind spot, and it is why this system exists
- Distinguish domains heavy in ⬜ as "unexplored," not "weak." They are different conditions
- Sort the weakness top 3 by the score column in `mastery.md` (do not recompute)
- **Break the wrongbook down by origin** — `오답`, `찍맞`, `애매` need different responses.
  A book that is mostly `애매` means comparison tables; mostly `오답` means notes
- The last two lines are **runnable commands**, not advice — something the user can copy and type

## Warning conditions

Add one line each, only when they apply.

| Condition | Output |
|---|---|
| `format.verified_at` past 90 days | `⚠ 형식 검증 {n}일 경과 — /exam-harvest 시 자동 대조` |
| Open `major` in `format-drift.md` | `⚠ 시험 개편 감지 — /exam-init --format 필요` |
| Queue over 10 | `⚠ 큐 {n}개 적체 — 미검증 문제가 늘고 있습니다` |
| D-day within 30 and coverage under 70% | `⚠ D-{n}에 커버리지 {n}% — 미출제 영역 우선 권장` |
| No session for 7+ days | `마지막 세션 {n}일 전` |

If more than three warnings apply, show only the two most severe.

## Next-action logic

```
An entire domain is ⬜         →  /exam-quiz {domain}   (blank areas first)
queue >= 5                    →  /exam-harvest 3
confusion errors >= 3         →  /exam-comp
D-day <= 14                   →  /exam-quiz 모의고사 30
otherwise                     →  /exam-quiz
```

## --rebuild

`exams/_registry.md` is a cache and can drift. With `--rebuild`, read every exam's state files, recompute, and rewrite
the registry. **This is the only case where the skill writes.** Tell the user it was refreshed.
