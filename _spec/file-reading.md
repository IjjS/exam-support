# Reading source files

Read this before opening anything in `_inbox/` or `exams/{slug}/_sources/`.
Used by `exam-init` (Phase 0, Phase 4) and `exam-harvest` (Phase 1).

---

## PDF — never open it with the Read tool first

The Read tool renders PDF pages **as images**. A 64-page exam criteria document becomes 64 page images,
costing roughly **10-50x** the tokens of a text extraction. Extract text first, read the text.

### Order to try

**1. macOS PDFKit — no installation needed, use this first**

```bash
swift _spec/pdftext.swift <file.pdf> > /tmp/out.txt          # whole document
swift _spec/pdftext.swift <file.pdf> 14 20 > /tmp/out.txt    # pages 14-20
```

Roughly 4 seconds for 64 pages, including Swift's compile step. Output is marked `===== p.N =====` per page,
so a citation can carry a real page number.

**2. `pdftotext`, if it happens to be installed**

```bash
pdftotext -layout <file.pdf> /tmp/out.txt
```

`-layout` preserves column and table structure, which matters for exam criteria documents.

**3. Read tool page rendering — last resort, specific pages only**

Only when the two above produce empty output, meaning the PDF is a **scan with no text layer**,
or when the table structure came out unusable and the layout itself has to be seen.
Never render the whole document. Locate the pages you need first, then render those.

### After extraction

Do not read the entire dump into context. Grep for the section you need and read that range.
For a 4,000-line criteria document, the target section is usually 300 lines.

---

## Other formats

| Format | How |
|---|---|
| MD · TXT | Read directly |
| Images (PNG/JPG) | Read directly — this is a genuine vision task |
| DOCX · XLSX · PPTX | Read directly; if that fails, convert via the Bash tool |
| HWP | **Not readable.** Ask the user to export as PDF from 한글. Automatic conversion destroys the tables that carry the structure |
| URL | WebFetch, with a prompt narrowing it to the fields you need |

---

## A file you could not read must never become a citation

If extraction fails, **say so and stop.** Do not proceed on web or model knowledge while recording the file as
the basis.

```
✅  "출제기준 PDF에서 텍스트를 추출하지 못했습니다 (스캔본으로 보임).
     페이지 렌더링으로 진행할까요, 아니면 웹 기준으로 진행할까요?"
❌  Move the file to _sources/, write `guide_version: 2024`, and build the blueprint from the web
```

A citation pointing at a file nobody read is worse than no citation: the note looks backed by the user's
material when it is really unsourced model knowledge.

Record what was actually read:

```markdown
## Sources
- source: 유통관리사-출제기준-2024.pdf p.13-18 (2026-08-15, PDFKit 추출)
```
