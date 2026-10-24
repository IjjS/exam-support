---
name: exam-skills
description: List every skill in this repo and what each one does. Use when the user asks what they can do here — "스킬 뭐 있어", "명령어 알려줘", "뭐 할 수 있어", "도움말", "사용법", "skills", or "help". This is about the tooling itself; questions about exam subject matter go to exam-desc instead.
---

# exam-skills

A reference card for the toolset. **Nothing else** — no state, no recommendations that require reading state,
no progress reports. Someone asked what the commands are; give them the commands.

**Talk to the user in their own language.**

## Read this much and no more

```
.agents/skills/*/SKILL.md   frontmatter only  (name + description)
exams/_active.md            one line
```

Pull the descriptions off disk rather than repeating them here — a hardcoded list goes stale the first time a
skill changes. One shell call does it:

```bash
grep -h -A1 '^name:' .agents/skills/*/SKILL.md
```

**Never read skill bodies.** Seven full SKILL.md files is roughly 20k tokens to answer "what commands are there."

## Output

Group by how often it gets used, not alphabetically. Someone asking this question wants to know
what to type next, and four of the eight are things they will rarely touch.

```
weakness-manager · 스킬 8개                    활성: aws-sap-c02

매일
  /exam-quiz       문제 풀기 · 채점 · 오답 기록
  /exam-harvest    공식 문서 → 개념 노트. 큐 소진
  /exam-status     커버리지 · 약점 · D-day 한 화면

필요할 때
  /exam-comp       A vs B 비교표 · 선택 기준
  /exam-desc       개념 · 도메인 설명
  /exam-skills     이 목록

가끔
  /exam-init       새 자격증 등록  (--format · --refine · --lang)
  /exam-reset      기록 초기화  (백업 후)

처음이면   /exam-init {자격증명}  →  /exam-quiz ×3  →  /exam-status  →  /exam-harvest
```

Keep it inside one phone screen. If the active exam is `—`, replace the last line with
`먼저 /exam-init {자격증명} 으로 자격증을 등록하세요`.

## When the user asks about one skill

Give the full description from its frontmatter, its call forms, and what it writes. Still do not read the body —
the frontmatter plus the table below covers it.

| Skill | Writes | Notable |
|---|---|---|
| `exam-quiz` | mastery · wrongbook · sessions · queue · log | 5 questions at once. `모의고사 30` for a mock |
| `exam-harvest` | notes · comparison tables · queue | `3` for a small batch. Parallel subagents |
| `exam-status` | nothing | `--rebuild` recomputes the registry cache |
| `exam-comp` | comparison tables | No argument → lists what needs one |
| `exam-desc` | nothing | Topic, domain, or free-form theme |
| `exam-init` | blueprint · format · exam · scaffold | `--format` · `--refine` |
| `exam-reset` | state, after backup | Four scopes; `stats` is the default |
| `exam-skills` | nothing | This |

## Two things worth saying unprompted

Include these only if the user seems new — asking "뭐 할 수 있어" rather than "리셋 옵션 뭐였지".

- **Answer syntax**: `1 3? 2,4?? 5 1` — question marks mean unsure, and a `??` that turns out correct is
  recorded as wrong. That is the whole point of the system
- **The loop**: quiz queues topics it had no notes for, harvest turns them into notes, the next quiz is better.
  Running only one of the two stalls it

## Never

- Read skill bodies to build this list
- Read `mastery.md`, `wrongbook.md`, or `sessions.md` — status owns progress reporting
- Report coverage, accuracy, or what to study next
- Explain exam subject matter — that is `exam-desc`
