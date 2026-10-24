# Design notes

Read this before modifying a skill or a state file format. Each section states the decision and the reason for it.
History — how a decision was reached — lives in `docs/HISTORY.md` and git, not here.

---

## 1. What problem this solves

Not "review what you got wrong," but **finding the areas you never encountered.** Accuracy cannot do that: it is
computed only over what was asked, and multiple choice rewards elimination, so unknown material often scores as
correct. Three layers address it.

| Layer | Mechanism | Lives in |
|---|---|---|
| 1 | Coverage map — ⬜ untested topics | topics in `blueprint.md`, coverage in `mastery.md` |
| 2 | Confidence tags — `?` shaky, `??` guessed | answer parsing in `exam-quiz`, `mastery.lucky`, `wrongbook.origin` |
| 3 | Error types | `_spec/error-taxonomy.md` |

Confidence tags do two separate jobs:

- **Scoring** — `??` counts as wrong. Surface accuracy minus real accuracy is the size of the blind spot
- **Queueing** — `?` and `??` both enter the wrongbook even when correct. The queue asks "would I get this again
  without hesitating?", a lower bar than "did I get it right." A shaky answer scores as correct and is still revisited

---

## 2. Who reads and writes what

Most bugs here come from a skill writing a file it does not own.

```
               READ                                         WRITE
exam-init      _inbox/ · _sources/ · web · _template/       blueprint · format · exam · mastery (init)
                                                            _sources/questions/ (bank + index.jsonl)
                                                            _active · _registry (append) · state/_archive/ (--format)
exam-harvest   _inbox/ · _sources/ · web · queue            notes/ · notes/_compare/ · _facts.md
               format.md (limit=14)                         harvest-queue · format-drift · _registry (own row)
  └ subagent   harvest-policy.md · _sources/ · web          its one note file — never anything under state/
exam-quiz      _active · sessions (limit=15) · format       mastery · sessions · log/ · harvest-queue
               mastery · wrongbook (hot block, via script)  wrongbook (via script) · _registry (own row)
               selected notes · _sources/ · web             _active (on switch) · format-drift (disputed level only)
               grading.md (after answers) · taxonomy (miss) questions/index.jsonl (source mode: void, key_fix)
               source mode: bank index window + its Q files
exam-status    _registry — or, for the active exam:         nothing  (--rebuild rewrites _registry)
               mastery · sessions · wrongbook hot block
exam-comp      wrongbook (via script) · notes/ · web        notes/_compare/ · wrongbook notes column (via script)
                                                            harvest-queue (only after asking)
exam-desc      notes/ · mastery rows (grep) · web           nothing  (harvest-queue only after asking)
               log/ (named entry, bounded window)
exam-reset     reset-scope.md                               state/* after copying to state/_archive/
                                                            --rm: moves exams/{slug}/ to exams/_archive/
```

| File | Sole writer | Why |
|---|---|---|
| `blueprint.md` | `exam-init` | Immutable spec. If quiz could write it, definition and coverage would drift apart |
| `format.md` | `exam-init --format` | Harvest sees drift first, but parallel subagents writing one file would corrupt it |
| `state/log/` | `exam-quiz`, append only | Anything that reads it every session makes session cost grow with history |
| `mastery.md` | `exam-quiz` | Proficiency changes only by being tested. Reading a note does not make you better |
| `_sources/questions/` | `exam-init` | quiz adds only `void` and `key_fix` to index lines it played; the questions themselves never change |
| topic notes | `exam-harvest` | Quiz consumes notes and never produces them, so questions stay freshly generated |

**Subagents** (harvest, one per topic) write their note file themselves and return only
`{topic id, file path, source count, one-line summary, drift observations}`. Two reasons: a returned note body would
put the prose back into the main context and defeat the fan-out, and several subagents editing `harvest-queue.md`
at once would corrupt it — only the main session aggregates.

---

## 3. Where the tokens go

Two skills run often. `exam-quiz` is the most frequent and is used from a phone, so it is the hot path.
`exam-harvest` runs nearly as often and fans out into subagents. The rest are occasional.
**Any change is judged by what it costs per quiz session, every session, from then on.**

### Before the questions appear — measured 2026-10-24 on SAP-C02

| Read | Tokens |
|---|---|
| CLAUDE.md | 1.5k |
| exam-quiz SKILL.md | 5.9k |
| format.md | 5.8k |
| mastery.md | 5.0k |
| sessions.md, `Read(limit=15)` | 0.1k |
| wrongbook hot block + topic index (`wrongbook.sh index`) | 0.9k |
| wrongbook rows for the selected topics (`wrongbook.sh rows`) | 0.5-3k |
| 5 selected notes (median 2.5k, mean 3.6k each) | ~18k |
| **Total** | **~38-40k** |

After the answers arrive: `references/grading.md` 3.1k, and `_spec/error-taxonomy.md` 1.2k only on a miss.

### Files are not the largest cost

Transcripts (Aug-Oct) show a quiz session takes about 21 API calls and ~67k output tokens, and every call
re-reads the harness baseline — system prompt plus tool definitions, ~50k. A harvest subagent makes about 33 calls
on the same baseline. So the levers, in order:

1. **Fewer calls** — batch reads into one shell call, issue independent writes in parallel
2. **No read that grows** — see §4. This is the one hard rule
3. Shorter files — worth doing, but a paragraph saved is small next to a call saved

Running a quiz inside a long conversation multiplies everything, because the whole conversation is re-read per call.

---

## 4. Preventing unbounded growth

**No change may introduce a read that grows with session count.** Every state file is shaped around this.

### The wrong-answer lifecycle

| origin | How it enters | Scored as | Retires after |
|---|---|---|---|
| `miss` | answered wrong | wrong | 3 confident correct in a row |
| `lucky` | correct, tagged `??` | wrong | 3 confident correct in a row |
| `shaky` | correct, tagged `?` | correct | 2 confident correct in a row |

Any `?` or `??` resets the streak. A retired entry moves to `_resolved.md`, which quiz never reads; if the topic
fails again, it returns to the wrongbook with its history. `shaky` retires faster because its evidence of
not-knowing is weaker. A question that spans several topics gets one entry per topic, each on its own streak, so a
topic that only fails in combination stays in the book after its partner clears.

### The wrongbook is never read whole

Entries accumulate faster than they retire — 341 active at session 56, about 37k tokens as a full read. So no skill
loads the table. `_spec/wrongbook.sh` answers the narrow questions instead:

| Need | Command | Size |
|---|---|---|
| Which topics have active entries | `index` | one line per topic — bounded by the topic count |
| The entries behind the selected topics | `rows T-041 …` | only those topics |
| A new W-id, a write, a retirement | `next-id` · `add` · `set` · `retire` · `keywords` | output is one line |

Writes go through the script as whole rows: it rejects a row whose cell count differs from the header, refuses a
duplicate or unknown W-id, and recomputes the hot block itself. The table stays the single source of truth — there
is no derived cache to drift from it.

### The log is archival, not sealed

Full question text goes to `state/log/{YYYY-MM}.md`. The question block is written while the user is solving
(heading `S12-Q3 — T-034 · …`); the result line with the `W-id` is appended after grading. quiz never reads the log.
`exam-desc` may, for one entry the user named: grep the W-id, then read a bounded window starting about 30 lines
above the match, since the W-id sits below its question. **Reading a log file without an offset and a limit is
forbidden.** The path exists for `misread` errors, where the wording of the stem is the lesson.

### Hot blocks

Aggregates sit in the first 15 lines of each state file and are read with `Read(limit=N)`. Mode gating needs one
number from `sessions.md`; it never loads the session log below it. When designing a file, first ask whether the
values a hot path needs sit in those lines.

### Notes accumulate

A note has a floor of 800 tokens — below it, a topic runs dry after two or three questions and keeps returning to the
queue — and **no ceiling**. A note is accumulated knowledge, and depth a topic has earned stays in it. What keeps the
cost bounded is the read rule: quiz reads only the selected topics' notes, never a section's worth.

A note supports a finite number of distinct questions. When `mastery.Att >= 4` and the note has not been updated
since, quiz uses the source pipeline for that question and queues the topic as `exhausted` — harvest extends the
note rather than rewriting it. A single threshold fires early for a deep note, and early is the safe direction.

### Mock exams

Generated in batches of 10, carrying only `{correct count, per-domain score, elapsed time}` between batches. Earlier stems are
discarded; one 65-question context is expensive and visibly degrades the later questions.

### Considered and skipped

| Item | Why not |
|---|---|
| Removing `_template/` | `cp -r` creates the whole exam tree without reading the template — it saves tokens |
| Session lock | Single user. quiz warns if `sessions.md` changed within 5 minutes |
| git, reminders, push | The user decided against them |

**Open**: `mastery.md` is read whole (5.0k) though quiz needs only the top scores and the ⬜ list. A hot block for
those would save most of it, at the cost of derived data that can drift from the table.

---

## 5. Topic IDs — the one thing that cannot be repaired

**`T-041`, sequential, with no section encoded.** A section prefix diverges from real membership the first time the
exam is reorganized, and fixing the prefix breaks the join key in `mastery.md` and the wrongbook — destroying history.

```
Section reorganized  → keep the ID, change only the section column in blueprint
Topic removed        → status: deprecated (never delete the row; history stays, the topic leaves the question pool)
Topic added          → issue a new ID from topic_id_next (never roll the counter back)
Weights changed      → blueprint only; mastery is unaffected
```

---

## 6. Not every exam has domains

`blueprint.md` records the exam's real shape, found in init Phase 3 rather than assumed.

| `structure` | Shape | Weight from |
|---|---|---|
| `weighted` | Named domains with published percentages — most vendor exams | the published % |
| `counted` | Subjects with a fixed question count — Korean national certifications | count ÷ total |
| `flat` | One curriculum, no grouping | nothing; every topic is equal |

`flat` is a finding, not a failed search: inventing weights would distort question spread, harvest priority, and
coverage. Under `flat`, notes go to `notes/{topic}.md`, the section column stays empty, and question spread uses
topic-ID distance. `section_label` keeps the exam's own word (`domain`, `과목`). A three-level 출제기준 maps
주요항목 → section and 세세항목 → topic; the middle level is dropped once topics exist.

---

## 7. Past questions — the best input, and a bank

Past questions are the only material that shows the real exam rather than describing it. init asks for them before
anything else — once, as a numbered choice (add files / collect from the web / go on without), never blocking — and
turns them into a bank:

```
_sources/questions/Q001.md …   stem and options verbatim, the key as given — no explanations stored
_sources/questions/index.jsonl one line per question: answer · topics · level · recall · void · key_fix
```

The bank feeds three things:

- **Topics** — every question is mapped to its load-bearing topics, and the mapping corrects the topic list before
  anything depends on it: questions that fit nowhere are a missing topic, a crowded topic is too coarse, a topic with
  no question is kept (the guide covers it) and reported as unexamined. Topics drawn from a guide's prose alone drift
  from what is actually asked
- **format.md** — difficulty, topic mixing, and distractor patterns are calibrated on the bank, and each question's
  level is written into its index line
- **Source mode** — quiz presents the bank in order, as written, from a cursor in the `sessions.md` hot block

Source mode generates nothing, so it needs no notes up front: it reads a window of the index and the batch's question
files, never the whole bank. Each question is recorded on the topics the index lists. The key is a claim — it is
verified only where the grade depends on it (the user disagreed with it, or tagged `?`/`??`). A key an official doc
overturns is corrected in the index (`key_fix`); an item with two defensible answers is voided (`void`) and never
asked again. Source sessions do not count toward `basic_done`, which measures generated sessions.

The index is the bank's only metadata, kept as JSONL so one question is one line — a read of the next twenty is a
bounded window, and an edit touches one line.

---

## 8. format.md — the exam's spec, resident

Format differs even between exams from one vendor, and questions in the wrong format do not prepare anyone for the
real one. Keeping samples resident would be expensive, so init **reads them once and keeps only the format**: what a
question looks like, not which answer a past question had.

format.md is generated by init and changed only by `/exam-init --format`, which archives the previous version to
`state/_archive/` first. It carries everything exam-specific that quiz executes:

- type mix, stem length, question phrasings, requirement keywords, prohibitions
- `angles:` — the axis this exam varies along, with its real distribution
- `topic_mix:` — the share of questions whose answer turns on two or more topics
- the difficulty rubric, the tests that confirm each level, the conditions that void an item, and per-mode ratios
- distractor patterns
- two synthesized anchors

**Difficulty belongs to the exam.** quiz owns no level definition — a rule written into quiz would silently become
every exam's rule. Levels are calibrated on real past questions, not the official sample set, which is a showcase
balanced by design. The SAP-C02 rubric measures the length of the dependent chain of inferences the solver must derive
with every product fact supplied; unfamiliar facts are tracked as a separate recall-load axis, not as depth. quiz owns
only exam-neutral procedure: draft the level's trace before choosing a topic, classify after the options exist, keep
the honest lower label, and lift a weak topic by chaining it into a secondary rather than swapping it out — at most
twice per topic.

**Topic mixing** is measured on the same real questions. A mixed question is recorded on every topic it lists, since
a solved question is not topic coverage; question-level aggregates still count it once. Secondaries come from the
session's already-open notes, so mixing adds at most one note read.

**Distractor patterns are per exam**, derived from the real questions, with IDs `P1`, `P2`, … — `D` would collide
with section IDs. There is no shared list; grading and the wrongbook name patterns by these IDs. (SAP-C02's
format.md predates this and uses `D1-D10`.)

**Anchors are synthesized, never copied** — on different subjects, one single-select and one multiple-response, in
different sections. Pasting originals invites a copyright problem and biases generation toward those topics.

**Performance exams** (CKA/CKAD) set `format_type: performance`; quiz then asks for commands or manifests and grades
against a reference answer. Only the switch exists today.

---

## 9. Format drift

Vendors revise exams. Harvest reads official docs, so it meets the change first.

- **Detection** — harvest reads only the DRIFT-CHECK block at the top of format.md (`Read(limit=14)`) and compares it
  with what the docs show. No extra web calls
- **minor** (wording, new samples, `verified_at` aging) — append to `format-drift.md`, keep going, one line at the end
- **major** (exam code, section reorganization, weights, question count or duration) — finish the batch, then stop,
  so no notes are written for topics about to disappear
- **Applying** — only `/exam-init --format`, run by the user, which marks the entries `applied`. Observation and
  application are different actors because harvest runs subagents in parallel

quiz also appends a row when the user disputes a difficulty call: the user is calibrating the exam's criteria, and
quiz cannot edit format.md. Each `sessions.md` row carries the format version it ran under, so a drop in accuracy can
be told apart from a format change.

---

## 10. Mode and topic selection

```
basic_done = (diagnostic + mock) sessions

no weakness request                      → basic mode
weakness requested, basic_done >= 3      → weakness mode
weakness requested, basic_done < 3       → basic mode, said once; one override allowed
```

- **Basic is the default at every session count.** It prioritizes ⬜ untested topics, and coverage is the long pole;
  switching automatically would freeze coverage at whatever came up first and drill that set forever
- **The `< 3` gate** is about sample size: weakness mode sorts by a score built from attempts
- **Source mode** (§7) is outside this scheme: it follows the bank's order, and none of the spread, angle, or
  difficulty-ratio rules below apply to it
- **Spread is a share, not a count.** Basic follows the blueprint weights by largest remainder; weakness caps one
  section at 60% of the session. While coverage is 80% or below, re-asking active entries is capped at 40%
- **Weakness score** — `(1 - accuracy) × 3 + lucky_rate × 2 + shaky_rate × 1 + domain_weight + staleness`, written
  onto the mastery row after grading so the next session only sorts
- **Angle** — `mastery.Angle` keeps the last-used code from format.md's `angles:`. A recurring topic prefers a
  different angle, but only to break ties inside the exam's real distribution; one facet is not the topic

**Difficulty is recorded as asked, never as targeted** — `sessions.Difficulty` holds the actual mix and
`wrongbook.Diff` the level behind each entry. Recording the target would make the two agree by construction. Both
are trailing columns: older rows stay short and render empty, so no row is ever backfilled or reordered.

---

## 11. Latency after the answer is submitted

The user is waiting for verdicts; nothing should stand in front of them.

- **The question block goes to the log when the questions are presented**, during solving time. Only a short result
  line is written after grading
- **Verdicts are printed before any file is written**
- **The writes go out as parallel calls** — they touch different files and none reads another's output

Speed must not come from narrow edits. A mastery row is rewritten whole and checked with one `awk` for cell count
and the trailing pipe: a span edit that starts one cell off shifts every column to its right, and nothing errors when
it happens. Wrongbook writes get the same guarantee from `wrongbook.sh`.

---

## 12. Sources — search, then verify

```
usable note        → generate from the note
no/exhausted note  → search: _sources/ first, then the web → fresh draft → verify
nothing found      → model draft → verify
verification fails → [UNVERIFIED]
```

One rule for notes and questions alike, and no tiers or site lists to maintain per exam. Anything the search turns
up — past papers, past-question sites, blogs — may shape a scenario or point at a fact. Only verification makes it
true: material from `_sources/` against official docs (a file with no official coverage stands on its own, since a
domestic exam's textbook is often all there is), material from the web against official docs or guides. Batch
searches across topics; there is no per-session verification cap.

Sources are recorded as where they came from, nothing more: `source: file p.N` or `web: URL`, each dated, the
verifying page included. Verified questions carry no visible label; the cold log keeps the search and the verifier
in an invisible comment. `harvest-queue.md` carries the verifying URL in its `Source` column, so harvest starts there
instead of searching again.

---

## 13. The non-technical risk

**The harvest doom loop**: harvest is not run → notes stay thin → more unverified questions → quality and speed
drop → it is run even less. Two mitigations: quiz nudges at session end when three or more topics are queued, and
`/exam-harvest 3` is a two-minute batch — short enough to become a habit.

**Init friction**: init asks about sources once and never again, and a missing exam guide must not block
registration either. Rough out the sections, start, and refine later with `/exam-init --refine`; past questions found
later go in with `--bank`.

---

## 14. Three documents, split by load frequency

| File | Audience | Loaded |
|---|---|---|
| `README.md` | Human | Never |
| `CLAUDE.md` | Agent | Every session, automatically — **1.5k ceiling** (measured 1,491) |
| `docs/DESIGN.md` | Agent | Only when modifying skills |

CLAUDE.md holds the *what*; this file holds the *why*. Every part of CLAUDE.md is load-bearing — the absolute rules,
the routing table, the file-role map, write permissions — so a push past 1.5k is a signal to move something into a
skill, not a budget to spend. `AGENTS.md` is a symlink to it, for other agents.

---

## 15. Instruction language

Instruction files are English. Hangul is tokenized character by character, and this repo's Korean prose expanded
about 2.79× in characters when translated, so English saves roughly 20-45% on the hot path; it also carries
conditional procedure and imperative strength (`must never` vs `avoid`) more reliably.

- **Trigger phrases** in skill descriptions stay Korean — they are matched against what the user actually types
- **The user is addressed in their own language**, whatever the instruction language
- **Question language follows the exam**, set by the anchors in format.md

---

## 16. Origin

Started from [bevibing/tutor-skills](https://github.com/bevibing/tutor-skills): the setup/quiz split, markdown state
files, proficiency badges, the zero-hint rule, progressive disclosure through references. Dropped the Obsidian
dependency (wiki links and fold callouts render nowhere on a phone) and codebase mode. Added confidence tags, error
types, the coverage map, format.md, the growth limits above, and multiple exams.
