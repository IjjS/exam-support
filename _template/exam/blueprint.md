# {{EXAM_NAME}} Blueprint

<!-- Immutable spec. Coverage, accuracy, and every mutable value live in state/mastery.md. -->
<!-- exam-quiz neither reads nor writes this file. -->

```
exam_slug:     {{SLUG}}
guide_version: {{GUIDE_VERSION}}
topic_id_next: 1
```

> Rolling back `topic_id_next` gives two different topics the same ID. **Never do it.**
> Topic IDs are permanent and do not encode the domain. On reorganization, keep the ID and change the domain column.

## Domains

| ID | Domain | Weight | Topics |
|---|---|---|---|
| | | | |

## Topics

`status`: `active` | `deprecated` (never delete a row for a removed topic — mastery history must survive)

| ID | Domain | Topic | status |
|---|---|---|---|
| | | | |
