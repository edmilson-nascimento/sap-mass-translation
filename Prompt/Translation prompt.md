# SAP S/4HANA Localization — XLF Translation Prompt Template

> **Purpose:** Reusable prompt for mass translation of Z* custom objects via XLF (XLIFF 1.2) files, for import into SAP via LXE_MASTER.
>
> **Version:** 3.1 — The XML & QA Safe Edition
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
```xml
<target state="translated">Parameter & fehlt in Tabelle TVARVC</target> <target state="translated">Parameter und fehlt in Tabelle TVARVC</target> ```
<target state="translated">Parameter & fehlt in Tabelle TVARVC</target> <target state="translated">Parameter und fehlt in Tabelle TVARVC</target> ```

### 3. Character Limit & Counting Math (STRICT 73-CHAR LIMIT)

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

### 6. Anti-Copy-Paste Rule (CRITICAL)
The `<target>` text MUST NEVER be identical to the `<source>` text, EXCEPT when the string consists ONLY of placeholders, numbers, and/or formatting punctuation (e.g., `&amp;1 &amp;2 &amp;3 &amp;4`, `---`, `> 100`). If the `<source>` contains alphanumeric English words, the `<target>` MUST be grammatically completely different (translated into pure German).

## Output Format & XML Structure (STRICT)

You must output a valid XLIFF 1.2 file. Modifying the XML structure incorrectly will cause fatal import errors in SAP LXE_MASTER. Follow these exact rules for EVERY `<trans-unit>` block:

1. **The `<trans-unit>` tag:** - MUST contain `approved="yes"`. If the original says `approved="no"` or if the attribute is missing, force it to `approved="yes"`.
   - DO NOT modify any other attributes (`maxwidth`, `id`, `resname`, `size-unit`).
2. **The `<source>` tag:**
   - DO NOT modify this tag or its text content under any circumstances.
3. **The `<target>` tag (CRITICAL):**
   - MUST immediately follow the `</source>` tag.
   - If the original file DOES NOT have a `<target>` tag, you MUST CREATE IT.
   - MUST contain the attribute `state="translated"`. Remove any other state like "needs-review-translation" or "new".
   - The translated German text goes inside this tag.

**Example of the Expected Final Structure:**
```xml
<trans-unit size-unit="char" approved="yes" maxwidth="73" id="TEXT" resname="MESS//ZPP 000//TEXT">
  <source>Original English Text &amp;1</source>
  <target state="translated">Pure German Text &amp;1</target>
</trans-unit>
```
---

## Execution Instructions

1. For EACH translation unit in the provided file:
   a. Apply the structural rules defined in "Output Format" (`approved="yes"`, create `<target>` if missing, `state="translated"`).
   b. Translate the `<source>` text to PURE German (zero English words, Anti-Copy-Paste rule applied).
   c. Copy placeholders EXACTLY using XML entities (e.g., `&amp;1`).
   d. Count the rendered characters (remembering `&amp;1` = 2 chars). If > 73, compress using strategies.
   e. Place the final translation in the `<target>` element.
2. Validate final XML syntax (no loose `&` characters, all tags properly closed).
3. Output the entire valid XLF code block.

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

### v3.1 (March 2026) — The XML & QA Safe Edition
- **QA GATE:** Added Rule 6 (Anti-Copy-Paste) to prevent the LLM from marking un-translated/English strings as approved German text. 
- **XML STRUCTURAL FIX:** Explicit instructions added to handle XML units missing the `<target>` tag completely (forcing the AI to create it).
- **APPROVAL ENFORCEMENT:** Strict command added to modify `<trans-unit approved="no">` to `approved="yes"` to ensure SAP LXE_MASTER actually processes the translation out of the proposal pool.

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