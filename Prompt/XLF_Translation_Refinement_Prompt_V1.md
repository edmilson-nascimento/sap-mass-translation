# Prompt — XLF Translation Refinement from Excel Review

**Version:** V1
**Author:** Nascimento (JESUSEDM) — Inetum / TEG Project
**Purpose:** Apply human-validated translations (from an Excel review sheet) back into an SAP LXE_MASTER XLIFF/XLF file, preserving structure for safe re-import.
**Model recommendation:** Claude Sonnet (structured, rule-following task)

---

## How to use

1. Start a new chat with Claude
2. Attach **two files**:
   - The Excel review file (`.xlsx`) containing the `Data` sheet with a `New translate` column
   - The original XLF file that was exported from LXE_MASTER and translated
3. Paste the entire prompt below as your first message
4. Claude will confirm the plan and, once you approve, generate the updated XLF file for download

---

## PROMPT (copy from here)

```
Act as an SAP ABAP expert with deep knowledge of LXE_MASTER, SAP translation workflows,
Excel file manipulation (openpyxl), and XML/XLIFF 1.2 format.

## Context

I am working on the Takasago Europe GmbH (TEG) S/4HANA 2023 rollout project at Inetum.
Part of my work involves EN→DE translation of SAP repository objects using LXE_MASTER.
My workflow is:

1. Export translation objects from SAP as XLIFF/XLF files (one per object type batch)
2. Pre-translate via AI
3. Build an Excel review file with a visual `Data` sheet so a native German speaker can
   review each translation
4. The reviewer fills a `New translate` column ONLY for entries that need correction
5. I need the XLF updated with the reviewer's new translations, so I can re-import it
   into LXE_MASTER

This prompt handles step 5.

## Input files

**File 1 — Excel (.xlsx)**, two sheets:
- Sheet 1 (name varies, matches the XLF filename, e.g. `enUS_deDE_S_000052-00001`):
  mirrors the XML structure with XPath-style column headers (DataXML table)
- Sheet 2 named `Data`: review-friendly view, columns:
  - A: `Original`       — the `<file original="...">` value (unique key)
  - B: `Max. length`    — the `maxwidth` attribute
  - C: `Source language` — the `<source>` text (EN)
  - D: `Target language` — the current `<target>` text (DE, from AI)
  - E: `New translate`   — the reviewer's corrected translation (FILLED ONLY WHEN CORRECTION NEEDED)
  - F: `New translate length` — LEN formula
  - G: `Comments`        — reviewer notes (IGNORE this column for processing)

**File 2 — XLF (.xlf)**: standard SAP LXE_MASTER export, XLIFF 1.2.
Structure per unit:
  `<file original="KEY">`
    `<body>`
      `<trans-unit ...>`
        `<source>EN</source>`
        `<target state="translated">DE</target>`   ← THIS is what we replace
        `<alt-trans origin="Reference Language" xml:lang="en-US">`
          `<target>EN reference</target>`           ← DO NOT TOUCH
        `</alt-trans>`
      `</trans-unit>`
    `</body>`
  `</file>`

## Task

For every row in the `Data` sheet where column E (`New translate`) has a non-empty value,
replace the corresponding `<target>` text inside the matching `<trans-unit>` in the XLF.
All other rows (empty `New translate`) must remain BYTE-IDENTICAL in the output XLF.

## Correlation key

`Data[Original]` (column A)  ==  `<file original="...">` attribute in the XLF.
This is a 1:1 unique mapping.

## Non-negotiable rules

1. **Scope of change**: only the text between `<target state="translated">` and `</target>`
   inside the `<trans-unit>` block. Never touch `<alt-trans>`, `<source>`, attributes,
   or anything in `<file>` blocks whose `Original` has no `New translate`.

2. **Preserve everything else exactly**:
   - `state="translated"` attribute stays
   - `approved`, `maxwidth`, `resname`, `id`, `size-unit`, `datatype`, `date`, `category`,
     `xml:space`, `source-language`, `target-language` — all unchanged
   - Attribute order in every tag — unchanged
   - XML declaration `<?xml version="1.0" encoding="utf-8"?>` — unchanged
   - XLIFF namespace — unchanged
   - Single-line vs multi-line formatting of the source XLF — preserved as-is
   - BOM presence/absence — preserved as-is (detect first bytes of input, replicate in output)
   - No trailing newline added by Python — use binary write mode

3. **XML escaping**: when inserting the new translation, escape `&` → `&amp;`,
   `<` → `&lt;`, `>` → `&gt;`. Nothing else.

4. **No normalization**: do NOT trim spaces, do NOT collapse double spaces, do NOT
   change case. Use the Excel cell value EXACTLY as-is. The reviewer chose those spaces.

5. **Do NOT use an XML tree parser to write output**. ElementTree and lxml reorder
   attributes, may add `ns0:` prefixes, re-escape characters, and reformat — all of
   which can break LXE_MASTER re-import. Use targeted regex substitution on the raw
   string instead. Parsers may be used ONLY for post-write well-formedness validation.

6. **Regex anchoring** (to avoid hitting the wrong `<target>`): anchor the substitution
   pattern structurally — match `<file ... original="EXACT_KEY" ...>` then `.*?</source>`
   then `<target state="translated">CAPTURE</target>`. The non-greedy match up to
   `</source>` guarantees you land on the main `<target>`, not the one inside `<alt-trans>`
   (which always comes AFTER the main target in this format).

7. **Ignore column G (Comments)** entirely. Apply every row with a non-empty
   `New translate`, regardless of what the reviewer noted.

## Validations required before delivering the file

- Count of substitutions applied == count of non-empty `New translate` rows
- Output XLF is well-formed (parse with ElementTree after writing; do not save the
  parsed version, only validate)
- Structural counts unchanged: same number of `<file>`, `<trans-unit>`, `<alt-trans>`,
  `<source>` blocks as input
- Report any failed pattern matches

## Workflow expected from you (Claude)

1. Inspect both files and confirm the structure matches what this prompt describes.
   If the XLF has a different structure (multiple trans-units per file, missing
   `<alt-trans>`, different `state` values, namespaced tags, etc.), STOP and ask me
   before proceeding.
2. Report how many rows have `New translate` filled, and flag any whose length exceeds
   the `Max. length` (maxwidth) value — but do NOT truncate; just warn me.
3. Show me the execution plan in plain language and wait for my confirmation.
4. On confirmation, execute and produce the updated XLF named
   `{original_xlf_basename}_UPDATED.xlf` in `/mnt/user-data/outputs/`.
5. Deliver via `present_files` with a short substitution report (row | original | old → new).
6. Do NOT generate a separate diff report file unless I ask.

## Output filename convention

If input XLF is `enUS_deDE_S_000052-00001.xlf`,
output must be `enUS_deDE_S_000052-00001_UPDATED.xlf`.

## Edge cases to handle silently (no need to ask me)

- `&` in the new translation → escape to `&amp;`
- Excel reading `&amp;` from XLF as `&` (openpyxl resolves XML entities via formulas) —
  this is a cosmetic mismatch between Excel's view and the raw XLF, not an error.
  The new value must be RE-ESCAPED when written back.
- Numeric-only source/target (e.g. `9000` → `9000`): no action if `New translate` is
  empty; treat as text if the reviewer filled it.
- Rows where `Source language` == `Target language` and `New translate` is empty:
  leave untouched.
- Unicode characters in German (`ä`, `ö`, `ü`, `ß`): write as UTF-8, no HTML entities.

## Edge cases that REQUIRE you to stop and ask me

- Any `Original` key in Excel not found in the XLF (or vice versa with a filled `New translate`)
- Multiple `<trans-unit>` inside one `<file>` (this prompt assumes one-per-file)
- Missing `state="translated"` on the main `<target>`
- XLF not well-formed on input
- Excel `Data` sheet column headers do not match the expected names

---

Ready? Inspect the files, show me the plan, and wait for my confirmation before
generating the output.
```

---

## Notes on reusability across XLF types

This prompt was validated on **SRH4 (Screen Painter Headers) PROG** objects (1 trans-unit
per file). For other LXE object types exported in the same workflow, the structure
may differ:

| Object type | Pattern to verify before reuse |
|---|---|
| DTEL (data elements) | Usually 1 trans-unit per file — prompt works as-is |
| Message classes (T100) | Multiple trans-units per file — prompt will STOP and ask (safe) |
| Adobe Form labels (FORM/DOCT) | Verify `<trans-unit>` nesting |
| Screen texts (non-header) | Similar to SRH4, likely works |

If Claude flags "multiple trans-units per file" on a new run, I need to extend this
prompt with a secondary correlation key (likely `resname` or the combination of
`original` + `trans-unit/@id`).

## Future improvements (backlog)

- Add `resname` as a secondary correlation key to support multi-trans-unit XLFs
- Migrate this workflow to Claude Code for batch processing of multiple XLF files
  at once (once I'm familiar with the tool)
- Verify whether `<alt-trans>` blocks can be dropped without breaking LXE_MASTER import
  (open item from TEG project memory) — current prompt keeps them intact as the safe default
