# exam-support

[Korean version](README_KO.md)

A Markdown-based certification study system for finding two kinds of gaps: **topics you have never been tested on** and **topics you have tested poorly on**. It maps the exam scope, tracks both coverage and performance by topic, and directs practice toward the gaps.

It uses eight agent skills and local Markdown files. There is no database or server. Sessions are designed for short output and one-line answers on a phone.

## How it finds gaps

| Signal | What it reveals | Where to focus |
|---|---|---|
| Untested topics | Parts of the exam scope you have not encountered | Diagnostic quiz |
| Wrong, guessed, or shaky answers | Knowledge that needs another check, even when a guess was correct | Weakness quiz and wrong-answer book |
| Error types | Whether the problem was missing knowledge, confusion, misreading, a distractor, or recall | Notes, comparisons, and targeted practice |

Coverage and accuracy answer different questions. A topic with no attempts is **unexplored**, not proven weak. The status view shows both surface accuracy and real accuracy; a correct answer marked as a guess is excluded from real accuracy.

## Start studying

1. Put any exam guide, study material, or past questions in [`_inbox/`](_inbox/README.md). You can also provide a path, URL, or attachment when registering the exam.
2. Register the exam with `/exam-init {exam name}`. This creates the topic map and question format. Past questions, when available, become a bank and help calibrate both.
3. Run `/exam-quiz` to test unexplored topics. Run `/exam-status` to see coverage, weak topics, and the next suggested action.
4. Run `/exam-harvest 3` to turn queued topics into sourced notes. Ask for weakness mode when you want to revisit known gaps.

The default quiz is diagnostic at every stage. **Weakness mode runs only when requested**, after at least three diagnostic or mock sessions; this keeps the default focused on finding untested areas. Source mode works through the past-question bank in order when one exists.

```text
/exam-quiz                 # Find untested topics
/exam-quiz weakness mode   # Revisit recorded weak topics
/exam-quiz source mode 20  # Work through 20 bank questions
```

## Answer on one line

```text
1 3? 2,4?? 5
```

Each entry answers the next question. Commas select multiple options. Add `?` for an uncertain choice or `??` for a guess.

| Answer | Score if correct | Review |
|---|---|---|
| `2` | Correct | No entry |
| `2?` | Correct | Added as shaky; clears after 2 confident correct answers |
| `2??` | Wrong | Added as lucky; clears after 3 confident correct answers |
| Any wrong answer | Wrong | Added as miss; clears after 3 confident correct answers |

An uncertain or guessed answer resets the confident-answer streak. After grading, every option receives a one-line verdict.

## Skills

| Skill | Use |
|---|---|
| `/exam-init` | Register an exam; add past questions with `--bank`, refine topics with `--refine`, or refresh the question format with `--format` |
| `/exam-quiz` | Diagnostic questions by default; request weakness, source, section, or mock mode as needed |
| `/exam-status` | See coverage, accuracy, weak topics, and a suggested next action |
| `/exam-harvest` | Build or extend notes for queued topics from source material |
| `/exam-comp` | Compare concepts you confuse |
| `/exam-desc` | Explain an exam concept or retrieve a named past question |
| `/exam-reset` | Reset study state after a backup and confirmation |
| `/exam-skills` | List the skills and their commands |

Generated questions follow the exam-specific `format.md`. They favor untested topics in diagnostic mode and recorded weak topics in weakness mode. Source mode presents stored past questions in bank order. A disputed source answer is checked against notes and official material; an ambiguous or broken item is voided.

## Sources and records

Search starts with the exam's `_sources/`, then the web. Claims and answer distinctions are checked against official documentation or guides. A readable user-supplied file may stand on its own when no official source covers it. Questions that cannot be verified are marked `[UNVERIFIED]`; their topics can be queued for note collection. Notes record their sources and dates.

Accepted input includes URLs, PDF, Markdown, TXT, DOCX, XLSX, PPTX, PNG, and JPG. Export HWP files to PDF first. Files from `_inbox/` are copied into the exam's `_sources/`; the originals are retained.

```text
exams/{slug}/
├── exam.md              Exam metadata and date
├── blueprint.md         Sections, weights, and permanent topic IDs
├── format.md            Exam-specific question format
├── _sources/            Supplied material and the optional question bank
├── notes/               Topic notes, comparisons, and fact cards
└── state/
    ├── mastery.md       Topic attempts, coverage, accuracy, and weakness scores
    ├── wrongbook.md     Active misses, lucky guesses, and shaky answers
    ├── sessions.md      Session summaries and source-mode progress
    ├── harvest-queue.md Topics awaiting notes
    └── log/             Archived question text and results
```

Each exam has separate study data. `blueprint.md` defines the scope; changing proficiency and coverage live in `state/mastery.md`. Topic IDs are permanent, including when an exam is reorganized. The quiz does not reread the growing question log during ordinary sessions.

## Project files

- [Agent instructions](CLAUDE.md) — operating rules shared through `AGENTS.md` and `GEMINI.md` links.
- [Design notes](docs/DESIGN.md) — rationale and data rules.
- [Source policy](_spec/source-policy.md) — verification and citation rules.
- [Inbox guide](_inbox/README.md) — supported input and handling details.

The skills live in `.agents/skills/`; `.claude/skills/` links to the same directory.

## License

[MIT](LICENSE). The initial structure drew on [bevibing/tutor-skills](https://github.com/bevibing/tutor-skills); see [design notes](docs/DESIGN.md) for the changes.
