# {{EXAM_NAME}} Blueprint

<!-- Immutable spec. Coverage, accuracy, and every mutable value live in state/mastery.md. -->
<!-- exam-quiz neither reads nor writes this file. -->

```
exam_slug:      {{SLUG}}
guide_version:  {{GUIDE_VERSION}}
structure:      {{STRUCTURE}}
section_label:  {{SECTION_LABEL}}
topic_id_next:  1
```

`structure`: `weighted` (published %) · `counted` (questions per section) · `flat` (no grouping)
`section_label`: the exam's own word — `domain`, `과목`, `area`. Empty when `flat`.

> Rolling back `topic_id_next` gives two different topics the same ID. **Never do it.**
> Topic IDs are permanent and do not encode the domain. On reorganization, keep the ID and change the domain column.

## Sections

Omit this table entirely under `structure: flat`.
Under `counted`, put the question count in Weight and the derived percentage in parentheses.

| ID | Section | Weight | Topics |
|---|---|---|---|
| | | | |

## Topics

`status`: `active` | `deprecated` (never delete a row for a removed topic — mastery history must survive)

Leave the Section column empty under `structure: flat`.

| ID | Section | Topic | status |
|---|---|---|---|
| | | | |
