# SAP S/4HANA Localization — XLF Translation Prompt Template

> **Purpose:** Reusable prompt for mass translation of Z* custom objects via XLF (XLIFF 1.2) files, for import into SAP via LXE_MASTER.
>
> **Version:** 3.0 — The Ultimate XML-Safe Edition
>
> **Context:** SAP S/4HANA 2023 Rollout Project — EN→DE Localization

---

## How to Use

1. Start a new chat with the AI (Claude/Gemini/ChatGPT).
2. Upload the `.xlf` file exported from LXE_MASTER.
3. Paste the prompt below (adapt fields in `[brackets]` as needed).
4. *Tip: You can remove the Changelog and Usage Notes below the prompt to save AI context window space.*
5. Import the generated file back into LXE_MASTER.

---

## Prompt

```text
## Project Context

SAP S/4HANA 2023 Rollout project (on-premise). Localization of custom objects (Z* namespace) from English (EN) to German (DE). XLF files are exported/imported via transaction LXE_MASTER.

## Your Role

You are a Senior SAP Consultant and Localization Specialist (SAP Technical Translation). Your task is to translate the content of the attached XLF file and generate a new valid XLF file ready for reimport.

## Object Type to Translate

- **MESS** — Message Classes (SE91) — 73-character limit (RENDERED IN SAP)

## Translation Rules (MANDATORY)

### 1. Official SAP Terminology
Use the official SAP DE glossary. Key references:
| EN | DE | Abbreviation (if needed) |
|---|---|---|
| Company Code | Buchungskreis | BuKr |
| Purchase Order | Bestellung | Best. |
| Plant | Werk | - |
| Vendor / Supplier | Kreditor / Lieferant | - |
| Sales Order | Kundenauftrag | KA |
| Delivery | Lieferung | Lief. |
| Material | Material | Mat. |
| Batch | Charge | - |
| Storage Location | Lagerort | LagOrt |
| Cost Center | Kostenstelle | KoSt |
| Warehouse (Number) | Lagernummer | LagNr |
| Handling Unit | Handling Unit | HU |
| Process Order | Prozessauftrag | PA |
| Production Order | Fertigungsauftrag | FA |
| Goods Receipt | Wareneingang | WE |
| Goods Issue | Warenausgang | WA |
| Storage Bin | Lagerplatz | - |
| Serial Number | Seriennummer | SN |
| Specification | Spezifikation | Spez. |
| Characteristic | Merkmal | - |
| Packaging | Verpackung | Verp. |
| Certificate | Zertifikat | Zert. |

### 2. Placeholder Preservation & XML Syntax (CRITICAL)

**PLACEHOLDERS MUST MATCH THE XML SYNTAX OF THE SOURCE EXACTLY.**

The SAP LXE_MASTER export encodes dynamic ampersand placeholders as XML entities (e.g., `&amp;`, `&amp;1`, `&amp;2`). You MUST preserve this exact XML encoding in the target. Generating a plain `&` character will invalidate the XML and crash the SAP import.

#### ✅ CORRECT Examples (Preserving XML Entities):
<source>Parameter &amp; is missing in TVARVC table</source>
<target state="translated">Parameter &amp; fehlt in Tabelle TVARVC</target>

<source>Input parameter &amp;1 is mandatory.</source>
<target state="translated">Eingabeparameter &amp;1 ist erforderlich.</target>

#### ❌ WRONG Examples (DO NOT DO THIS):
<target state="translated">Parameter & fehlt in Tabelle TVARVC</target> <target state="translated">Parameter und fehlt in Tabelle TVARVC</target> ### 3. Character Limit & Counting Math (STRICT 73-CHAR LIMIT)

**CRITICAL COUNTING RULE FOR PLACEHOLDERS:** The 73-character limit applies to the RENDERED text in SAP, not the raw XML string length. 
- The XML entity `&amp;` counts as exactly ONE (1) character (`&`).
- The XML entity `&amp;1` counts as exactly TWO (2) characters (`&1`).
*Example: The string "Fehler &amp;1" is exactly 9 characters long for SAP limits, even though it takes 13 characters in XML code.*

#### Length Optimization Strategies (Apply in order if over 73 rendered chars):
1. **Eliminate ALL English Words First (saves 20-40%):** Remove literal translations.
2. **Use SAP Abbreviations:** Use the abbreviations from the glossary table above, plus:
   - Position → Pos.
   - Nummer → Nr.
   - Berechtigung → Ber.
   - Mindestens → Mind.
3. **Condense Verbs:** "ist nicht möglich" → "unmöglich"; "wurde nicht eingegeben" → "fehlt".
4. **Merge Compound Nouns:** "Lager Nummer" → "Lagernummer".
5. **Use Symbols:** Use `>` instead of "mehr als", and `u.` instead of "und" (only if desperate).

### 4. Pure German Text (ZERO TOLERANCE FOR ENGLISH)
No English words are allowed in the German target text. This causes semantic errors and length violations.
- ❌ WRONG: "Import of SDS Fehlgeschlagen. It can be due Bis many reasons."
- ✅ CORRECT: "SDS-Import fehlgeschlagen. Mehrere Gründe möglich."

**Preposition Check:**
- Do NOT use "Bis" for "to" (use *zu, nach, an, um...zu*)
- Do NOT use "Durch the" for "by" (use *per, durch*)
- Do NOT use "Bei" for "at/to" level (use *auf* - e.g., "auf Header-Ebene")
- Do NOT use "Für" when "für" is meant (watch capitalization mid-sentence).

### 5. Technical Names and SAP Transactions
Do NOT translate: transaction codes (SE91, SLG1, etc.), table names (TVARVC, etc.), acronyms (RFC, BOM, MRP, EWM, GHS, etc.), or system names ("SAP", "ABAP").

## Output Format

Generate a complete, valid `.xlf` file.
- Preserve EXACTLY the XML structure of the original file (`<file>` attributes, `<trans-unit>` structure).
- Only modify the text inside `<target>` and change its attribute to `state="translated"`.
- Output as plain text inside a single code block so it can be easily copied. Do not truncate the output.

## Execution Instructions

1. For EACH translation unit in the provided file:
   a. Translate the `<source>` text to PURE German (zero English words, correct prepositions).
   b. Copy placeholders EXACTLY using XML entities (e.g., `&amp;1`).
   c. Count the rendered characters (remembering `&amp;1` = 2 chars). If > 73, compress using strategies.
   d. Set translation in `<target state="translated">`.
2. Validate final XML syntax (no loose `&` characters).
3. Output the entire valid XLF code block.
```

---

## Usage Notes

### When the file is very large (2000+ entries)
The AI may hit output token limits and truncate the code block. In that case, split the `.xlf` file by message class or object group before uploading, or ask the AI to process in batches (e.g., "Translate only from ID 001 to 050") and consolidate locally.

### Adapting for other object types
Adjust the "Object Type" field and character limits according to the artifact:
- **DTEL (Data Elements)**: 4 fields (short 10 / medium 20 / long 40 / heading 55)
- **DOMA (Domains)**: fixed value limit is 60 chars.
- **PROG/OTR**: Variable, check the `maxwidth` attribute in the XLF.

---

## Changelog

### v3.0 (March 2026) — The Ultimate XML-Safe Edition
- **CRITICAL FIX:** Reverted placeholder rule to mandate exact XML entities (e.g., `&amp;1`). Using plain `&` invalidates XLF syntax and breaks SAP LXE_MASTER import.
- **NEW LOGIC:** Added explicit character counting math. The 73-char limit applies to the SAP *rendered* string (`&1` = 2 chars), NOT the raw XML string (`&amp;1` = 6 chars).
- **CONSOLIDATED:** Merged length optimization strategies, abbreviation tables, and pure German rules into a unified, highly aggressive prompt to eradicate "Denglish" (mixed EN/DE).
- **REMOVED:** Plain `&` requirement from output format and checklists to ensure 100% valid XML generation.

### v2.3 (March 2026)
- Character limit established as ABSOLUTE PRIORITY (73 chars hard limit).
- Added explicit instruction to eliminate English words FIRST (highest impact).
- Expanded abbreviation table with "when to use" guidance.

### v2.2 (March 2026) — Real Import Data Analysis
- MAJOR UPDATE based on analysis of 182 length violations from production import.
- Added "Pure German Text" section — zero tolerance for English words (caused 100% of length violations).
- Added "Correct German Prepositions" section mapping real errors (e.g., "Bis" instead of "zu").

### v2.0 (March 2026)
- Initial template for S/4HANA 2023 project (MESS object type).
- Created standard SAP DE terminology glossary.