---
name: exam-comp
description: Build or show comparison tables and decision guides for concepts that get confused. Use when the user names a pair ("SCP vs IAM policy", "A랑 B 차이"), a single concept they are unsure about ("Snowball 비교해줘", "이거 뭐랑 헷갈리지"), or a theme with several options ("하이브리드 연결", "뭘 골라야 해", "언제 뭘 쓰지", "comp"). Given one concept it finds what that concept gets confused with. Called with no argument, it lists the confusion-type entries in the wrong-answer book that need a table. Tables are saved under notes/_compare/ and reused as question sources.
---

# exam-comp

`confusion` is **the error type that converts back into points fastest.** Both concepts are already known and only the
boundary is blurry, so one line of distinguishing criteria often settles it.

**Talk to the user in their own language.**

## Call forms

| Call | Behavior |
|---|---|
| `/exam-comp SCP vs IAM policy` | Pairwise table → `_compare/vs-{a}-{b}.md` |
| `/exam-comp Snowball` | **Single concept** → find what it gets confused with, then compare |
| `/exam-comp 하이브리드 연결` | Three or more options → decision guide `_compare/choose-{topic}.md` |
| `/exam-comp` | **List what needs a comparison table** |

## Phase 0 — Check what exists

Check `notes/_compare/` first. If it is already there, **show it rather than rebuilding.**
Reinforce it only if it is thin or the user asks for an update.

## Called with no argument

Read `state/wrongbook.md` and pull the `confusion` entries.

**`shaky` entries belong at the top of this list.** An answer tagged `?` means the user narrowed it to two and
guessed between them — and the Notes column often records exactly which two. That is a comparison table already
half-written, and it is the cheapest weakness in the book to close.

```
비교표가 필요한 항목

1. TGW vs VPC Peering        애매 2회 · 오답 1회  (T-041)   ← 후보가 기록돼 있음
2. SCP vs IAM policy         오답 2회             (T-052)
3. Aurora Global vs Replica  찍맞 2회             (T-018)

이미 있는 표: vs-nlb-vs-alb, vs-sqs-vs-sns

번호를 고르거나 직접 말해주세요.
```

Show the origin mix rather than a single count — `애매 2회` and `오답 2회` call for different depth.

## Phase 0-1 — One concept given: find the neighborhood

When the user names a single concept rather than a pair or a theme, **the comparison set is yours to find.**
Not knowing what it gets confused with is usually the actual problem — if they knew, they would have named a pair.

Look locally, in this order, and stop once you have 2-4 neighbors:

| Order | Source | Why |
|---|---|---|
| 1 | The topic note's `Easily confused with` table | harvest writes that section for exactly this purpose |
| 2 | `state/wrongbook.md` — what the user actually confused it with | their own error outranks textbook similarity |
| 3 | Sibling topics in the same domain, `grep "\| D4 \|" state/mastery.md` | cheap, and scoped to the exam |

Source 2 leads. If they picked Snowmobile over Snowball on a past question, that pair goes first no matter
what the note lists.

### Do not reach for the web on your own

All three sources above are local and free. Official docs and model knowledge are **not** a fourth step —
they are a separate request. If 1-3 turn up fewer than two neighbors, say so and ask:

```
Snowball 노트가 없고 오답 이력도 없습니다.
공식 문서에서 비교 대상을 찾아볼까요?
```

A one-word command should not silently turn into a web crawl.

### State the set before building

One line, so a wrong guess costs nothing to correct — and so the user can see what the build will involve:

```
Snowball 기준으로 Snowcone · Snowmobile · DataSync 와 비교합니다
(노트 1/3 — 나머지 2개는 공식 문서 확인이 필요합니다)
```

Then continue at Phase 1 with those targets. One neighbor → `vs-{a}-{b}.md`; two or more → `choose-{topic}.md`.

## Phase 1 — Sourcing

```
1. The targets appear in notes/{domain}/{topic}.md  → note-based
2. Otherwise                                        → vendor official docs (follow source-policy), cite sources
3. Web also fails                                   → [UNVERIFIED] label
```

Unlike `exam-quiz`, there is **no web fallback cap.** This is a low-frequency skill and a comparison table gets reused
for a long time, so accuracy wins.

This is about **filling in targets you already have**, and does not contradict Phase 0-1. Discovering *who* to
compare against stays local and asks first; researching *what distinguishes* an agreed set goes to the web freely.

## Phase 2 — Authoring

### Pairwise table — `_compare/vs-{a}-{b}.md`

````markdown
---
type: compare
topics: [T-041, T-052]
updated: 2026-08-15
---

# Transit Gateway vs VPC Peering

## The one line that decides it
**Transitive routing needed, or three or more VPCs → TGW. A two-party link → Peering.**

## Comparison
| | Transit Gateway | VPC Peering |
|---|---|---|
| Transitive routing | Yes | **No** |
| Scale | Hub-and-spoke, thousands | 1:1, grows as N² |
| Cost | Hourly + data processing | No attachment fee, transfer only |
| Latency | One extra hop | Direct |
| Bandwidth | Per-attachment ceiling | VPC bandwidth |

## Where the exam splits them
- `LEAST operational overhead` + many VPCs → TGW
- `MOST cost-effective` + two VPCs → Peering
- "Several VPCs share the on-premises connection" → TGW (Peering cannot do it)

## My error history
- 2026-08-10 T-041: chose Peering in a four-VPC scenario, looked only at cost and missed operational burden

## Sources
- https://docs.aws.amazon.com/... (2026-08-15)
````

### Decision guide — `_compare/choose-{topic}.md`

With three or more options, a branch tree beats a table.

````markdown
# Choosing a hybrid connectivity option

## Branches
```
Need dedicated bandwidth or consistent latency?
├─ Yes → Direct Connect
│         └─ Needs redundancy? → two DX circuits, or DX + VPN backup
└─ No  → Only encryption needed?
          ├─ Yes, fast to stand up → Site-to-Site VPN
          └─ Shared by several VPCs → TGW + VPN
```

## Answer by requirement keyword
| Keyword | Tends toward |
|---|---|
| MOST cost-effective | VPN |
| consistent/predictable latency | Direct Connect |
| LEAST time to implement | VPN |
| MOST resilient | Two DX circuits (+ VPN backup) |

## Traps
- "DX is always the answer" is false. It takes weeks to provision, so `quickly` means VPN
````

## Phase 3 — Recording

| File | Update |
|---|---|
| `notes/_compare/{file}.md` | Create or update |
| `state/wrongbook.md` | Mark the entry's notes column `comparison table written` (**do not remove the entry** — only three consecutive correct answers in a quiz resolves it) |

Do not modify `mastery.md`. Reading a comparison table does not raise proficiency.

## Output (Korean)

Do not just announce a file path — **show the deciding criterion right there.** Making the user open a file on a phone is a failure.

```
TGW vs VPC Peering  →  notes/_compare/vs-tgw-vs-vpc-peering.md

한 줄: 전이 라우팅이 필요하거나 VPC 3개 이상이면 TGW.
당신은 2026-08-10에 VPC 4개 시나리오에서 비용만 보고 Peering을 골랐습니다.

/exam-quiz 로 이 쌍을 다시 검증해 보세요.
```

## Never

- Overwrite an existing comparison table without checking
- List comparison rows without stating **what decides it** — a table alone does not enable a choice
- Remove an entry from `state/wrongbook.md`
- Insert practice questions
