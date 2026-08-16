# Design notes

Read this before modifying a skill or a state file format. Every decision here has a reason, and most of them involve tokens.

---

## 1. What problem this solves

The problem is not "review the questions you got wrong." It is **discovering the areas you never encountered.**

Accuracy-based tracking structurally cannot do this, because accuracy is computed only over the population already asked.
On top of that, 4- and 5-option questions reward elimination, so a fair share of unknown material comes out correct.
Hence three layers.

| Layer | Mechanism | Where it lives |
|---|---|---|
| 1 | Coverage map (⬜ untested tracking) | topic expansion in `blueprint.md` + coverage in `mastery.md` |
| 2 | Confidence tags (lucky guess = wrong) | answer parsing in `exam-quiz` + `mastery.lucky` |
| 3 | Error type classification | `_spec/error-taxonomy.md` |

Layer 2 is the experimental hypothesis of this system. Treating "correct but `??`" as wrong splits
surface accuracy (say 62%) from real accuracy (say 48%), and that gap is the size of the blind spot.

---

## 2. There is exactly one hot path

Of the seven skills, only `exam-quiz` runs at high frequency (1-3 times a day, on a phone). The rest are rare and are not
optimization targets. **Every optimization argument is settled by asking: does this affect per-session cost of quiz?**

### Per-session token budget — measured 2026-08-15

Measured against the two registered exams (AWS SAP-C02, 102 topics; 유통관리사 2급, 120 topics).
Korean-character rate 1.2 tok/char, ASCII 3.6 chars/tok.

| Item | Measured | Note |
|---|---|---|
| CLAUDE.md | **1.2k** | auto-loaded every session |
| exam-quiz SKILL.md + quiz-rules.md | **3.7k** | |
| format.md | **2.6k - 2.8k** | the two anchors are full-length exam scenarios |
| mastery.md (whole) | **3.4k - 3.9k** | 102-120 rows; Korean topic names cost ~4x English |
| sessions.md via `Read(limit=15)` | **0.1k** | working as designed |
| wrongbook.md (active only) | ~1.2k | projected at 50 sessions; currently 0.2-0.4k |
| 5 notes | ~3.0k | projected; currently 0 notes exist |
| `_spec/error-taxonomy.md` | +1.2k | conditional — only when something was wrong |
| **Total** | **~16k - 17k** | |

An earlier revision of this table claimed ~9-10k. That figure was an estimate, it omitted CLAUDE.md entirely,
and it undershot `format.md` by 2.8x and `mastery.md` by 2.3x. The numbers above are measured, not projected.

The **shape still holds**: none of these grow with session count. That was the design goal and it survived.
But the constant is roughly 70% higher than the design assumed.

**No change may introduce a read that grows with session count.** That is the one hard rule.

### The two heavy items, and whether they are justified

- **`format.md` at 2.8k** — the weight is the two synthetic anchors, each a full exam-length scenario with options.
  Trimming them is the obvious saving and the wrong one: prose spec alone does not fix the tone, which is the entire
  reason anchors exist. Cap anchor length at the exam's own stem-word range rather than cutting one.
- **`mastery.md` at 3.9k** — this one is genuinely open. See below.

---

## 3. Preventing unbounded growth

### wrongbook split three ways

An AWS SAP stem runs 100-150 words. Storing a wrong answer with full question text, options, and explanation costs about
450 tokens. A hundred of those is 45k — you would be reading 45k to get five questions.

```
state/wrongbook.md      Active wrong-answer index (one line ≈ 25 tokens) — quiz reads this
state/_resolved.md      Moved here after three consecutive correct answers — quiz does not read it
state/log/{YYYY-MM}.md  Full question text and explanations — quiz never reads it (audit trail)
```

Active entries leave the index when resolved, so the realistic ceiling is 30-60 entries.

### Hot block on top + `Read(limit=N)`

Mode gating needs exactly one number from `sessions.md`: how many basic-mode sessions are done.
Put the aggregates in the top four lines and cut the read at `Read(limit=15)` so the log is never loaded.

Apply this to every state file. **When designing a file, first ask whether the hot path's values sit in the first 15 lines.**

### Mock exam batching

Generating 65 questions in one context costs 13k output plus 39k input, and later questions visibly degrade.
Split into batches of 10 and carry only `{correct count, per-domain score}` across batches. Discard earlier stems.

---

## 4. Optimizations deliberately skipped

Over-optimizing only adds consistency risk. These were considered and **intentionally not done**.

| Item | Why not |
|---|---|
| ~~TOP-N cache in `mastery.md`~~ | **Reopened — the premise was wrong.** This was rejected on an estimate of 1.4k. The measured figure is **3.9k**, about a quarter of the whole session. See "Open question" below |
| Batching the per-session Edit calls | Ten of them total ~300 tokens. An append-only log would cost more in re-aggregation |
| Removing `_template/` | One `cp -r _template/exam exams/{slug}` creates six files **without reading the template**. It saves tokens |
| Session lock | Single user. Instead quiz warns if `sessions.md` was modified within 5 minutes |
| git / scheduled reminders / push | User decided against them. Add later if needed |

### Open question — a hot block for `mastery.md`

At 3.9k it is the single largest runtime read, and quiz does not actually need all of it:

- **Weakness mode** needs the top ~15 rows by score, to choose 5
- **Basic mode** needs the ⬜ list and the per-domain counts
- Everything else in the table is only touched at write time

A hot block carrying the top-20 by score plus per-domain ⬜ counts would be roughly 0.4k, saving ~3.5k —
about 22% of the session. The cost is the usual one: derived data can drift from the table it summarizes.

Unlike the version of this decision recorded above, the saving is now large enough to be worth the drift risk.
Not implemented; decide before the note corpus grows, because quiz's write path changes with it.

---

## 5. Topic IDs — the one thing that cannot be repaired

**Format `T-041`. Sequential. The domain is not encoded.**

The first draft used `T-D2-07` with a domain prefix. When domains are reorganized, the prefix and the actual
membership diverge. Fixing the prefix breaks the join key in `mastery.md` and destroys the accumulated history.
So the ID is a meaningless serial number and the domain lives in its own column.

### Migration rules when the exam is reorganized

```
Domain reorganized  → keep the ID, change only the domain column in blueprint
Topic removed       → status: deprecated (never delete the row; history is preserved, only questions are excluded)
Topic added         → issue a new ID from topic_id_next (never roll the counter back)
Weights changed     → blueprint only; mastery is unaffected
```

Rolling back `topic_id_next` in `blueprint.md` gives two different topics the same ID. Never do it.

---

## 6. format.md — compress the samples and keep them resident

Format differs between exams from the same vendor. AWS SAA is mostly single-select; SAP has a distinctly higher share of
multiple-response. Without knowing the format you keep producing questions that look plausible but don't match the real
exam, and no amount of practice on those prepares you.

Keeping the original samples resident is expensive. So **discard the content and extract only the format.**

| | Reuse value | Handling |
|---|---|---|
| Content (which service is the answer) | Low — that question won't be asked again | Read once during init, then discarded |
| Format (type mix, stem length, phrasing, distractor patterns) | High — applies to every question | Compressed into `format.md` (~1k), resident |

### Anchors are synthesized, not copied

Prose spec alone doesn't fix the tone, so two few-shot anchors are kept. But official sample text is never pasted in.

- It avoids the copyright question
- Pasting originals biases the model toward those topics

init reads the samples and **writes fresh examples in the same format on different subjects.**
Anchors are fixed to different domains and different types (one single-select, one multiple-response).

### Performance-exam switch

CKA/CKAD are hands-on, not multiple choice. `format_type: mcq | performance` marks the branch point.
Under `performance`, quiz renders "write the command / write the manifest" and grades against a reference answer.
Only the switch exists today; there is no implementation. It is there so adding K8s doesn't require restructuring the skills.

---

## 7. Format drift

Vendors revise exams (SAP-C02 → C03, curriculum updates). Harvest reads official docs, so it meets the change first.

### Detection

Read only the 8-line DRIFT-CHECK block at the top of `format.md` via `Read(limit=12)` and compare against what the web
showed. No extra web calls, about 150 tokens.

### Severity

| Grade | Condition | Action |
|---|---|---|
| minor | Wording changes, samples added, verified_at aging | Non-blocking. Append to `format-drift.md` and continue. One-line report at the end |
| major | Exam code, domain reorganization, weight change, question count or time change | Finish the current batch, then stop |

Stopping on major is not politeness — it **avoids wasted work writing notes for topics about to disappear.**

### Update path

Harvest runs subagents in parallel, so several agents editing `format.md` at once would corrupt it.

```
Subagent    Report observations only (must not modify files)
Main session  Aggregate → append to state/format-drift.md
User        Update explicitly via /exam-init --format
```

On update the previous version is preserved at `_archive/format-{version}-{date}.md`.

### Version stamp

Each row of `sessions.md` carries `fmt:4.1`. When accuracy drops after a format change, being unable to tell
skill from format makes the data uninterpretable.

---

## 8. Mode gating

Weakness mode is meaningful only once weaknesses have surfaced. One or two sessions is too small a sample.

```
basic_done = (diagnostic + mock) sessions in sessions.md

basic_done < 3   →  run basic mode even when weakness mode is requested, and say so
                    allow one override if the user asks again
basic_done >= 3  →  weakness mode by default
```

Basic mode prioritizes ⬜ untested topics, so three rounds surface the blind spots. That is the point of the gate.

### Weakness score

```
(1 - accuracy) × 3  +  lucky_rate × 2  +  shaky_rate × 1  +  domain_weight  +  staleness
```

⬜ untested ranks first in basic mode. quiz writes the score into the `mastery.md` row after grading,
so the next session only has to sort — no full recomputation.

---

## 9. Web fallback limit

Three-tier sourcing for questions:

```
1. Topic note exists  → generate only from the note, cite the note path
2. No note            → verify against vendor official docs via WebSearch/WebFetch, cite the URL
3. Web also fails     → Claude's own knowledge, tagged [UNVERIFIED]
```

**Tier 2 is capped at two questions per session.** Early on, when no notes exist, routing all five through the web
takes 1-2 minutes to start a session, and on a phone that means it stops getting used.
A fast first session matters more than note accuracy. Fill the rest with `[UNVERIFIED]` and queue them.

Every topic answered via tier 2 or 3 gets appended to `harvest-queue.md`. **The more you quiz, the more notes fill in.**

---

## 10. The non-technical bottleneck, which is the real risk

**The harvest doom loop**: harvest doesn't get run → notes stay thin → unverified questions increase →
quality and speed drop → it gets run even less.

Two mitigations are baked into the skills.

1. quiz surfaces the queue backlog at session end and nudges — `"큐 7개. /exam-harvest 3 (약 2분)"`
2. harvest has a small-batch mode — `/exam-harvest 3` handles three queue entries. **Two minutes on a phone is what makes it a habit**

**init friction**: if the exam guide can't be found, registration itself is blocked.
→ Fast-start path. Rough out the domains, start, and refine later with `/exam-init --refine`.

---

## 11. Three documents, split by load frequency

`CLAUDE.md` is **auto-loaded into every session**. It rides along on every quiz run from a phone.

| File | Audience | Loaded | Constraint |
|---|---|---|---|
| `README.md` | Human | Never | Free |
| `CLAUDE.md` | Agent | Every session, automatically | **~700 token ceiling** |
| `docs/DESIGN.md` | Agent | Only when modifying skills | Free |

Putting design rationale in CLAUDE.md would hand back every optimization recorded here.
**CLAUDE.md holds the "what"; the "why" lives in this file.**

`AGENTS.md` is a symlink to `CLAUDE.md` — tool compatibility with no duplicated content.

---

## 12. Instruction language

All instruction files are English. The measured basis:

- Claude's tokenizer has no word markers for Hangul, Han, or emoji, so **they are always tokenized character by character**,
  with UTF-8 byte fallback for characters lacking a dedicated token. Common syllables cost 1 token; others cost up to 3.
  ([Sander Land, "On the Biology of Claude's Tokenizer"](https://tokencontributions.substack.com/p/on-the-biology-of-claudes-tokenizer))
- Measured chars-per-token: English 3.60, Chinese 0.96, Japanese 1.15.
  ([Claude Code Camp tokenizer measurements](https://www.claudecodecamp.com/p/i-measured-claude-4-7-s-new-tokenizer-here-s-what-it-costs-you))
- Korean prose expands about 2.79x in characters when translated to English, measured on this repo's own `CLAUDE.md`.

Net effect on the hot path: **20-45% fewer tokens**, roughly 680-2,190 per session.
On top of that, English carries a modest but real advantage in following procedural conditional logic
and in calibrating imperative strength (`must never` vs `avoid`).

Two things stay Korean on purpose:

| Item | Why |
|---|---|
| Trigger phrases in `description` frontmatter | They are matched against what the user actually types ("문제 내줘"). Semantic matching crosses languages, but the literal phrasing helps |
| The user-facing output rule | Every skill states explicitly that the user is addressed in Korean. Instruction language does not determine output language |

---

## 13. Where this started

Taken from [bevibing/tutor-skills](https://github.com/bevibing/tutor-skills):
the setup/quiz skill split, markdown state files, proficiency badges, the zero-hint rule, progressive disclosure via references.

Changed:
dropped the Obsidian dependency (wiki links and fold callouts render nowhere on a phone or the web), dropped codebase mode,
added confidence tags, added error type classification, added the coverage map, added `format.md`,
prevented unbounded growth, and added support for multiple exams.
