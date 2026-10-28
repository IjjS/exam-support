# Source inbox

[Korean version](README_KO.md)

Place exam material here before registration or add it later. `/exam-init` uses it to build the exam map and question bank; `/exam-harvest` uses study material to write topic notes. Include the exam name in each filename so the material can be matched to the right exam. An ambiguous filename may require clarification.

**Past questions are especially useful.** `/exam-init` stores each question and its supplied answer in the bank, maps it to topics, and uses the collection to calibrate question format and difficulty. `/exam-quiz` source mode then presents the stored questions in order. Add questions after registration with `/exam-init --bank`.

```text
_inbox/
├── AWS_SAP_past_questions_2024.pdf
├── AWS_SAP_exam_guide.pdf
└── AWS_SAP_lecture_notes.md
```

Processed files are copied to `exams/{slug}/_sources/`; the originals in `_inbox/` are retained.

## Accepted material

| Type | Handling |
|---|---|
| URL | Provide the link in the conversation |
| PDF | Preferred for structured guides and past papers |
| MD, TXT | Read directly |
| DOCX, XLSX, PPTX | Used for documents, spreadsheets, and slides |
| PNG, JPG | Photos or scans of individual pages |
| HWP | Export to PDF first; HWP cannot be read here |

You can also give a file path, URL, or attachment directly in the conversation. Substantial material supplied there is saved to the exam's `_sources/` before use.

## Where it goes

| Material | Skill | Result |
|---|---|---|
| Exam guide or criteria | `/exam-init` | Sections and permanent topic IDs in `blueprint.md` |
| Past questions | `/exam-init` or `/exam-init --bank` | Original question text and supplied key in `_sources/questions/`; topic mapping and format calibration |
| Textbooks, lecture notes, documentation | `/exam-harvest` | Sourced concept notes in `notes/` |
| Exam announcement | `/exam-init` | Exam details in `exam.md` |

If you add an exam guide after registration, run `/exam-init --refine` to update the topic map or `/exam-init --format` to refresh the question format. Harvest builds notes; it does not change the exam map or format.

User-supplied files are searched before the web, but a supplied answer key is still a claim to check when grading depends on it. See the [source policy](../_spec/source-policy.md).
