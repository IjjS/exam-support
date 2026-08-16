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
```
<!-- /DRIFT-CHECK -->

# {{EXAM_NAME}} question format

`format_type`: `mcq` (multiple choice) | `performance` (hands-on). Under `performance`, exam-quiz renders
command/manifest authoring tasks instead of options.

## Question composition
{{QUESTION_TYPES}}

## Stem structure
{{STEM_STRUCTURE}}

## Requirement keywords
{{REQUIREMENT_KEYWORDS}}

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
