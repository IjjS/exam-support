<!-- DRIFT-CHECK: harvest reads only this block via Read(limit=14) and compares -->
```
exam_code:     {{EXAM_CODE}}
format_type:   mcq
guide_version: {{GUIDE_VERSION}} ({{GUIDE_DATE}})
sample_set:    {{SAMPLE_SET}}
verified_at:   {{VERIFIED_AT}}
domains:       {{DOMAIN_WEIGHTS}}
mcq_ratio:     {{MCQ_RATIO}}
stem_words:    {{STEM_WORDS}}
difficulty_mix: {{DIFFICULTY_MIX}}
```
<!-- /DRIFT-CHECK -->

# {{EXAM_NAME}} question format

`format_type`: `mcq` (multiple choice) | `performance` (hands-on). Under `performance`, exam-quiz renders
command/manifest authoring tasks instead of options.

## Question composition
{{QUESTION_TYPES}}

## Difficulty

The skeleton below is **fixed text**. `/exam-init` fills only the bracketed nouns, and never rewrites the
sentences around them. A criterion phrased as a description ("multi-step judgment") is self-certifying — the
author reads it, agrees with themselves, and nothing can contradict them. Phrased as an instruction to name
something, a wrong level shows up as a slot that cannot be filled.

```text
E: name the one {{DIFF_UNIT_E}} that decides it
M: name the {{DIFF_UNIT_M}}, and what it rules out
H: name {{DIFF_COUNT_H}}+ viable {{DIFF_UNIT_H}}, and the {{DIFF_SEPARATOR}} that separates them
```

```
difficulty_basis: {{DIFFICULTY_BASIS}}
```

- **A slot you cannot fill means the level is wrong. Downgrade.**
- Option count and multiple-response never raise difficulty by themselves.
- If naming the service or term alone reveals the answer, downgrade.

Use `difficulty_mix` for the resolved quiz mode.

## Stem structure
{{STEM_STRUCTURE}}

## Requirement keywords
{{REQUIREMENT_KEYWORDS}}

## Angles

The axis this exam actually varies questions along. `mastery.Angle` stores one of these codes per topic,
and quiz uses it to avoid probing the same topic the same way twice.

```
angles: {{ANGLES}}
```

4-8 short codes, plus `other`. Derived in `/exam-init` Phase 4 from the sample questions —
for a scenario-heavy exam these are usually the requirement keywords; for others they are the question types.

| Exam | Typical vocabulary |
|---|---|
| AWS SAP | `cost` `ops` `secure` `resilient` `speed` `scale` |
| 유통관리사 | `계산` `개념진위` `법규적용` `사례판단` |
| CKA | `create` `debug` `configure` |

Leave `angles:` empty if the samples do not reveal a consistent axis. Quiz then applies no angle constraint.

## Question phrasings
{{QUESTION_STEMS}}

## Distractor patterns
{{DISTRACTOR_PATTERNS}}

## Prohibited
{{PROHIBITIONS}}

---

## Anchors — format reference only, ignore the subject matter

> These are **not** official sample text. They are synthesized in the same format on different subjects.
> Pasting originals creates a copyright problem and biases the model toward those topics.
> Keep them on different domains and different question types.

### A1. {{ANCHOR_1_TYPE}}
{{ANCHOR_1}}

### A2. {{ANCHOR_2_TYPE}}
{{ANCHOR_2}}
