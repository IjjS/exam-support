---
name: exam-desc
description: Explain a concept, a topic, or a whole exam domain. Use when the user asks what something is or how it works — "Transit Gateway가 뭐야", "SCP 설명해줘", "상권분석이 뭐야", "이 도메인 뭐 배우는거야", "이거 무슨 개념이야", or "desc". Answers from the study notes where they exist, otherwise from official documentation. Read-only.
---

# exam-desc

**This skill explains things.** The user asked a question about the subject matter; answer that question.

Study history is a footnote, not the content. See the footer rule below — it is deliberately restrictive.

**Read-only.** The one exception: queueing a topic for harvest, with the user's consent.

## Phase 1 — What is being asked about

| Scope | Signal | Where to look |
|---|---|---|
| **Topic** | A specific service, term, model, or law — `Transit Gateway`, `레일리 법칙`, `SCP` | Grep `notes/`, then `notes/_compare/` |
| **Domain** | A domain name or number — `상권분석`, `D2`, `이 도메인` | Grep mastery for that domain's rows: `grep "| D2 |" state/mastery.md` |
| **Free-form theme** | Spans topics — `상권분석에서 계산 문제`, `SCP랑 IAM 관계` | Grep across `notes/`, gather what matches |

Do not load whole files to find something. Grep, then read the hit.
For a domain, grep only that domain's rows out of `mastery.md` — never read the whole 3-4k table for a lookup.

On several plausible matches, list them and let the user choose. Do not silently pick one.

## Phase 2 — Explain

This is the deliverable. Depth should match the question: a short question gets a short answer.

### Topic

Lead with the concept. Structure follows the note, compressed:

```
Transit Gateway Routing

여러 VPC·온프레미스를 허브-스포크로 연결하고, 라우트 테이블로 전이 라우팅을 제어하는
리전 단위 게이트웨이.

언제 쓰나
  · VPC 3개 이상 상호 연결 (Peering은 N² 관리 폭증)
  · 온프레미스 VPN/DX를 여러 VPC가 공유

안 쓰는 경우
  · VPC 2개 단순 연결 → Peering이 싸고 지연 낮음

혼동 주의   VPC Peering (전이 불가) · VPN CloudHub (VPC 허브 아님)
```

- Do not dump the note verbatim. Compress to what answers the question
- Include numbers and limits only when asked, or when the question is clearly about them
- If a `_compare/` document covers this pair, mention it in one line rather than reproducing it

### Domain

Orientation, not a topic dump:

```
D2 상권분석   출제비중 22% (90문항 중 20문항)

상권의 범위를 정하고, 그 안의 매출을 추정하고, 입지를 고르고, 개점을 결정하기까지의
과정을 다룹니다. 4개 도메인 중 계산 문제가 가장 많이 나오는 영역입니다.

주요 갈래
  · 상권조사    상권의 개념·유형, 상권 설정 기법
  · 매출추정    레일리 법칙, 허프 모델, 티센 다각형
  · 입지분석    입지 유형과 평가 지표
  · 개점전략    점포 개설·업종전환·폐점 의사결정

토픽 23개 · 계산형 문제가 집중되는 구간
```

- Explain what the domain is *about* first; the topic list is supporting detail
- Never print all 23-37 topic names. Group them into 3-5 강줄기
- Exam weight is worth one line — it tells the user how much to invest

### Free-form theme

Answer the question directly, pulling from whatever notes are relevant. No fixed structure.

## Phase 3 — Footer, at most one line, usually none

The explanation ends. Then, **only if it is actionable**, add a single line.

| Situation | Footer |
|---|---|
| 🟥 or 🟨, or repeated wrong answers on this topic | `⚠ 이 토픽 3연속 오답 (개념혼동) → /exam-comp TGW vs VPC Peering` |
| Lucky guess recorded (`??` but correct) | `⚠ 지난번 찍어서 맞힌 토픽입니다` |
| No note exists | `노트 없음 — /exam-harvest 로 정리할까요?` |
| 🟩, 🟦, ⬜ untested, or no history at all | **nothing** |

Rules:
- **One line maximum. Always last.** Never before or inside the explanation
- Never open with a proficiency badge or a stats block
- Never list past wrong answers with dates unless the user asks
- Never mention coverage, session counts, or overall accuracy — that is `exam-status`

The user asked what something is. Turning that into a progress report is the failure mode this section exists to prevent.

## Phase 4 — When there is no note

**Explain anyway.** Do not stop to do bookkeeping.

1. Check official documentation and explain from it, citing the source
2. If the web has nothing usable, explain from your own knowledge tagged `[미검증]`
3. Then, as the footer, offer to queue it: `노트 없음 — /exam-harvest 로 정리할까요?`

Queue it only if the user says yes. That write is the only one this skill may perform.

If the concept is not in the blueprint either, say it may be outside the exam scope and mention
`/exam-init --refine` if it looks like a real gap.

## Never

- Lead with, or dwell on, study history
- Print a stats block, coverage, or session counts
- Dump a note file verbatim, or list every topic in a domain
- Blend web or model knowledge in as if it came from the notes — label the source
- Modify note files (harvest's job) or generate questions (quiz's job)
