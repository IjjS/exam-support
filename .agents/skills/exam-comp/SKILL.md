---
name: exam-comp
description: Build or show comparison tables and decision guides for concepts that get confused. Use when the user says "A랑 B 차이", "SCP vs IAM policy", "뭘 골라야 해", "비교해줘", "언제 뭘 쓰지", or "comp". Called with no argument, it pulls the confusion-type entries out of the wrong-answer book and lists what needs a comparison table. Tables are saved under notes/_compare/ and reused as question sources.
---

# exam-comp

`confusion` is **the error type that converts back into points fastest.** Both concepts are already known and only the
boundary is blurry, so one line of distinguishing criteria often settles it.

**Talk to the user in their own language.**

## Call forms

| Call | Behavior |
|---|---|
| `/exam-comp SCP vs IAM policy` | Pairwise table → `_compare/vs-{a}-{b}.md` |
| `/exam-comp 하이브리드 연결` | Three or more options → decision guide `_compare/choose-{topic}.md` |
| `/exam-comp` | **List what needs a comparison table** |

## Phase 0 — Check what exists

Check `notes/_compare/` first. If it is already there, **show it rather than rebuilding.**
Reinforce it only if it is thin or the user asks for an update.

## Called with no argument

Read `state/wrongbook.md` and pull the `confusion` entries.

```
비교표가 필요한 항목

1. TGW vs VPC Peering        오답 3회  (T-041)
2. SCP vs IAM policy         오답 2회  (T-052)
3. Aurora Global vs Replica  찍맞 2회  (T-018)

이미 있는 표: vs-nlb-vs-alb, vs-sqs-vs-sns

번호를 고르거나 직접 말해주세요.
```

## Phase 1 — Sourcing

```
1. The targets appear in notes/{domain}/{topic}.md  → note-based
2. Otherwise                                        → vendor official docs (follow source-policy), cite sources
3. Web also fails                                   → [UNVERIFIED] label
```

Unlike `exam-quiz`, there is **no web fallback cap.** This is a low-frequency skill and a comparison table gets reused
for a long time, so accuracy wins.

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
