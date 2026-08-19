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

```text
E: {{DIFFICULTY_EASY}}
M: {{DIFFICULTY_MEDIUM}}
H: {{DIFFICULTY_HARD}}
gate: {{DIFFICULTY_GATE}}
```

Use `difficulty_mix` for the resolved quiz mode. Option count and multiple-response never determine difficulty by themselves.

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
