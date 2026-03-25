# SAP S/4HANA Localization — XLF Translation Prompt Template

> **Purpose:** Reusable prompt for mass translation of Z* custom objects via XLF (XLIFF 1.2) files, for import into SAP via LXE_MASTER.
>
> **Version:** 2.2 — March 2026 (Updated with real import analysis - 182 length violations fixed)
>
> **Context:** SAP S/4HANA 2023 Rollout Project — EN→DE Localization

---

## How to Use

1. Start a new chat with Claude
2. Upload the `.xlf` file exported from LXE_MASTER
3. Paste the prompt below (adapt fields in `[brackets]` as needed)
4. Import the generated file back into LXE_MASTER

---

## Prompt

```
## Project Context

SAP S/4HANA 2023 Rollout project (on-premise). Localization of custom objects (Z* namespace) from English (EN) to German (DE). XLF files are exported/imported via transaction LXE_MASTER.

## Your Role

You are a Senior SAP Consultant and Localization Specialist (SAP Technical Translation). Your task is to translate the content of the attached XLF file and generate a new XLF file ready for reimport.

## Object Type to Translate

- **MESS** — Message Classes (SE91) — 73-character limit

## Translation Rules (MANDATORY)

### 1. Official SAP Terminology
Use the official SAP DE glossary. Key references:
| EN | DE |
|---|---|
| Company Code | Buchungskreis |
| Purchase Order | Bestellung |
| Plant | Werk |
| Vendor / Supplier | Kreditor / Lieferant |
| Sales Order | Kundenauftrag |
| Delivery | Lieferung |
| Material | Material |
| Batch | Charge |
| Storage Location | Lagerort |
| Cost Center | Kostenstelle |
| Profit Center | Profit Center |
| Warehouse (Number) | Lagernummer |
| Handling Unit | Handling Unit |
| Inspection Lot | Prüflos |
| Bill of Materials (BOM) | Stückliste |
| Master Data | Stammdaten |
| Authorization | Berechtigung |
| Process Order | Prozessauftrag |
| Production Order | Fertigungsauftrag |
| Goods Receipt | Wareneingang |
| Goods Issue | Warenausgang |
| Inbound Delivery | Anlieferung |
| Outbound Delivery | Auslieferung |
| Storage Bin | Lagerplatz |
| Storage Type | Lagertyp |
| Warehouse Task | Lageraufgabe |
| Serial Number | Seriennummer |
| Shelf Life | Mindesthaltbarkeit |
| Down Payment | Anzahlung |
| Credit Management | Kreditmanagement |
| Shipping | Versand |
| Picking | Kommissionierung |
| Shipment | Transport |
| Purchase Requisition | Bestellanforderung |
| Info Record | Infosatz |
| Pricing Condition | Kondition |
| MRP | Disposition |
| Reservation | Reservierung |
| Physical Inventory | Inventur |
| Goods Movement | Warenbewegung |
| Stock Transfer | Umlagerung |
| Specification | Spezifikation |
| Substance | Stoff |
| Classification | Klassifizierung |
| Characteristic | Merkmal |

### 2. Placeholder Preservation (CRITICAL — MOST IMPORTANT RULE)

**PLACEHOLDERS MUST REMAIN EXACTLY AS IN THE SOURCE.**

SAP uses `&`, `&1`, `&2`, `&3`, `&4` as dynamic placeholders that get replaced at runtime with actual values.

#### ✅ CORRECT Examples:
```xml
<source>Parameter & is missing in TVARVC table</source>
<target>Parameter & fehlt in Tabelle TVARVC</target>

<source>Input parameter &1 is mandatory.</source>
<target>Eingabeparameter &1 ist erforderlich.</target>

<source>See error messages in SLG1 with Object &1/Subobject &2/ID &3</source>
<target>Fehlermeldungen siehe SLG1 mit Objekt &1/Subobjekt &2/ID &3</target>

<source>---> &1 &2 &3 &4</source>
<target>---> &1 &2 &3 &4</target>
```

#### ❌ WRONG Examples (DO NOT DO THIS):
```xml
<!-- WRONG: Using &amp; instead of & -->
<target>Parameter &amp; fehlt in Tabelle TVARVC</target>

<!-- WRONG: Translating placeholders -->
<target>Parameter und fehlt in Tabelle TVARVC</target>

<!-- WRONG: Changing placeholder positions without grammar reason -->
<source>Field &1 in row &2 is missing</source>
<target>In Zeile &2 fehlt &1</target>  <!-- Only if German grammar requires it -->
```

**PLACEHOLDER RULES:**
- Keep ALL placeholder symbols exactly as in the original: `&`, `&1`, `&2`, `&3`, `&4`
- Do NOT translate placeholders
- Do NOT convert to XML entities (`&amp;`)
- Do NOT reposition unless absolutely required by German grammar
- The number and type of placeholders in source and target MUST match exactly
- Spaces around placeholders should match source pattern when possible

### 3. Pure German Text (CRITICAL — BASED ON REAL IMPORT ERRORS)

**ZERO TOLERANCE FOR ENGLISH WORDS IN GERMAN TEXT.**

Based on analysis of 182 length violations from real import, 100% contained mixed EN/DE text.

#### ❌ COMMON MISTAKES (from real import log):
```
❌ "It can be due Bis many reasons"  
✅ "Mehrere Gründe möglich"

❌ "Sales Beleg Und Position"  
✅ "Verkaufsbeleg und Position"

❌ "The Incoterm Bei header Stufe"  
✅ "Der Incoterm auf Header-Ebene"

❌ "Prüfen Und Änderung if Erforderlich"  
✅ "Prüfen und ggf. ändern"

❌ "Für Beliebig further clarification Bitte contact"  
✅ "Für weitere Klärung bitte kontaktieren"

❌ "already exist Und are not Aktualisiert"  
✅ "existieren bereits und sind nicht aktualisiert"

❌ "do not correspond Bis the Handling Einheit"  
✅ "entspricht nicht der Handling Unit"
```

**VALIDATION CHECKLIST:**
- [ ] NO English articles: the, a, an, this, that
- [ ] NO English verbs: is, are, was, were, can, will, should, must, do, does, have, has
- [ ] NO English prepositions: to, for, with, by, in, on, at, from, of
- [ ] NO English conjunctions: and, or, but, if, when, that, which
- [ ] NO English adjectives: all, some, any, many, more, other, same, such
- [ ] NO English adverbs: already, not, only, also, just, still, yet

### 4. Correct German Prepositions

**CRITICAL:** Wrong prepositions cause both semantic errors AND length violations.

Common incorrect mappings from real import (DO NOT USE):
| ❌ WRONG | ✅ CORRECT | Example |
|----------|-----------|---------|
| Bis (for "to") | zu, nach, um...zu | "due Bis" → "wegen", "updated Bis match" → "aktualisiert, um zu entsprechen" |
| Durch the | per, via, über | "Durch the E-Mail" → "per E-Mail" |
| Bei (for "at") | auf, in, zu | "Bei header Stufe" → "auf Header-Ebene" |
| Von (for "from") in wrong context | aus, von, seit | context-dependent |
| Mit (overused) | mit, durch, per | context-dependent |

**Standard Preposition Map:**
| EN | DE | Example |
|----|----|---------|
| to (direction) | zu, nach | "to the plant" → "zum Werk" |
| to (purpose) | um...zu | "to match" → "um zu entsprechen" |
| for | für | "for customer" → "für Kunde" |
| with | mit | "with error" → "mit Fehler" |
| by | von, durch, per | "by user" → "von Benutzer", "by email" → "per E-Mail" |
| in | in | "in table" → "in Tabelle" |
| on | auf, an | "on header" → "auf Header" |
| at | bei, auf, zu | "at level" → "auf Ebene" |
| from | von, aus | "from table" → "aus Tabelle" |
| of | von, des/der | "name of field" → "Name des Felds" |

### 5. Character Limit (STRICT) — Based on Real Import Analysis

**CRITICAL:** 182 messages exceeded 73 characters in real import. Main causes:
1. Mixed EN/DE text (adds 20-40% length)
2. Verbose translations (literal word-for-word)
3. Incorrect prepositions (longer constructions)
4. Redundant words (e.g., "Lagernummer Nummer" = "Warehouse Number Number")

#### Length Optimization Strategies (in order of preference):

**A) Eliminate ALL English Words First (saves 20-40%)**
```
❌ "Import of SDS Fehlgeschlagen. It can be due Bis many reasons. Prüfen Job Logs." (78 chars)
✅ "SDS-Import fehlgeschlagen. Mehrere Gründe möglich. Prüfen Sie Joblogs." (73 chars)

❌ "The Incoterm Bei header Stufe wurde Aktualisiert Bis match the Positionen Incoterm" (84 chars)
✅ "Incoterm auf Header-Ebene wurde aktualisiert, um Positionsincoterm anzupassen" (79 chars)
→ Still too long, apply next strategy...
✅ "Incoterm auf Header-Ebene angepasst an Positionsincoterm" (58 chars)
```

**B) Use Standard SAP German Abbreviations:**
| Full Form | Abbreviation |
|-----------|-------------|
| Position | Pos. |
| Nummer | Nr. |
| Lieferung | Lfg. |
| Berechtigung | Ber. |
| Konfiguration | Konfig. |
| zum Beispiel | z.B. |
| gegebenenfalls | ggf. |
| bezüglich | bzgl. |
| und so weiter | usw. |
| Beispiel | Bsp. |
| inklusive | inkl. |
| nicht verfügbar | fehlt |
| nicht vorhanden | fehlt |
| existiert bereits | exist. bereits |
| Prüfen Sie | Prüfen |
| Wählen Sie | Wählen |
| Bitte prüfen Sie | Bitte prüfen |

**C) Condense Verb Constructions:**
| Verbose | Condensed |
|---------|-----------|
| ist nicht erlaubt | verboten |
| ist nicht möglich | nicht möglich |
| kann nicht angelegt werden | Anlegen nicht möglich |
| muss ausgefüllt werden | muss ausgefüllt sein |
| wurde nicht eingegeben | fehlt |
| existiert nicht | fehlt |
| do not correspond | entspricht nicht |
| are not updated | nicht aktualisiert |
| will not be created | wird nicht angelegt |
| should be equal to | muss gleich sein |
| does not allow to be | erlaubt keine |

**D) Remove Redundant Words:**
```
❌ "Lagernummer Nummer do not correspond Bis the Handling Einheit Lagernummer Nummer" (82 chars)
✅ "Lagernummer entspricht nicht Handling Unit Lagernummer" (56 chars)

❌ "Material & Mit Referenz exist. bereits. Prüfen Und Änderung if Erforderlich" (77 chars)
✅ "Material & mit Referenz existiert bereits. Bitte prüfen u. ggf. ändern" (72 chars)
```

**E) Rewrite Entirely if Still Too Long:**
If after applying A-D the text still exceeds `maxwidth`, REWRITE the entire message in concise German:
```
❌ "Für Beliebig further clarification Bitte contact Durch the E-Mail address: &" (78 chars)
→ After A-D: "Für weitere Klärung bitte per E-Mail-Adresse kontaktieren: &" (62 chars)
✅ REWRITE: "Für weitere Klärung bitte E-Mail an: &" (40 chars)
```

### 6. Tone of Voice
- Formal, technical, direct
- Typical of SAP system messages (errors, warnings, information)
- Omit unnecessary articles when space is limited
- Consistent with standard SAP DE message style
- Use imperative form for instructions: "Prüfen" not "Prüfen Sie" when space is tight

### 7. Handling Existing Entries
- **Review ALL entries**, including those that already have a translation (source ≠ target)
- Fix inconsistent or low-quality translations
- Internal separator/comment messages (e.g., `--- 000-009: ...`): translate as well
- Messages that are pure placeholders only (`& & & &`, `&&&&`, `&1 &2 &3 &4`): keep identical to source

### 8. Technical Names and SAP Transactions
- Do NOT translate: transaction codes (SE91, SLG1, CG02, VF01, CM40, COR1, etc.)
- Do NOT translate: table names (TVARVC, STVARV, ZMM_GRPKEY_CONF, ZEH_TWERCSCLASS, etc.)
- Do NOT translate: program names, class names, technical field names
- Do NOT translate: acronyms/codes (RFC, BOM, MRP, EWM, GHS, LSMW, DMS, ATP, FIFO, SDS, WERCS, etc.)
- Do NOT translate: "SAP", "ABAP", "Fiori", "WERCS", "EXCEL", "PDF", "MES", "ASRS"

## Output Format

### XLF File Structure
Generate a complete, valid `.xlf` file ready for import via LXE_MASTER with these specifications:

**XML Structure (preserve exactly):**
- Same attributes on `<file>` (original, source-language, target-language, date, category)
- Same `<trans-unit>` structure (size-unit, approved, maxwidth, id, resname)
- Keep the `<alt-trans>` block unchanged if present
- Only modify:
  - The content of the `<target>` element inside `<trans-unit>`
  - The `state` attribute of `<target>` → change to `"translated"`

**Technical Specifications:**
- Encoding: UTF-8
- Line endings: CRLF (\r\n) — compatible with Windows/SAP GUI
- XML Declaration: `<?xml version="1.0" encoding="utf-8"?>`

**CRITICAL — Placeholder Handling in XML:**
- Placeholders (`&`, `&1`, `&2`, `&3`, `&4`) MUST be written as plain characters
- Do NOT use XML entities (`&amp;`, `&amp;1`, etc.)
- SAP LXE_MASTER expects unescaped ampersands in message text

**Example of correct XML output:**
```xml
<?xml version="1.0" encoding="utf-8"?>
<xliff version="1.2" xmlns="urn:oasis:names:tc:xliff:document:1.2">
  <file datatype="plaintext" original="//S4S//101//999999//MESS//ZCA 001" 
        source-language="en-US" target-language="de-DE" 
        date="2026-03-25T12:33:40Z" category="ZZ" xml:space="preserve">
    <body>
      <trans-unit size-unit="char" approved="no" maxwidth="73" 
                  id="TEXT" resname="MESS//ZCA 001//TEXT">
        <source>Parameter & is missing in TVARVC table</source>
        <target state="translated">Parameter & fehlt in Tabelle TVARVC</target>
      </trans-unit>
    </body>
  </file>
</xliff>
```

## Real Import Error Examples (Learn from These)

These are actual messages that exceeded 73 characters in production import (March 2026). Study the pattern and FIX them:

### Example 1: Mixed EN/DE
```
❌ WRONG (78 chars):
"Import of SDS Fehlgeschlagen. It can be due Bis many reasons. Prüfen Job Logs."

✅ CORRECT (73 chars):
"SDS-Import fehlgeschlagen. Mehrere Gründe möglich. Prüfen Sie Joblogs."
```

### Example 2: Wrong Prepositions + Mixed Language
```
❌ WRONG (84 chars):
"The Incoterm Bei header Stufe wurde Aktualisiert Bis match the Positionen Incoterm"

✅ CORRECT (58 chars):
"Incoterm auf Header-Ebene angepasst an Positionsincoterm"
```

### Example 3: Redundant Words
```
❌ WRONG (82 chars):
"Lagernummer Nummer do not correspond Bis the Handling Einheit Lagernummer Nummer."

✅ CORRECT (56 chars):
"Lagernummer entspricht nicht Handling Unit Lagernummer."
```

### Example 4: Verbose Construction
```
❌ WRONG (78 chars):
"Für Beliebig further clarification Bitte contact Durch the E-Mail address: &"

✅ CORRECT (40 chars):
"Für weitere Klärung bitte E-Mail an: &"
```

### Example 5: Mixed Language in Technical Context
```
❌ WRONG (77 chars):
"Material & Mit Referenz exist. bereits. Prüfen Und Änderung if Erforderlich."

✅ CORRECT (72 chars):
"Material & mit Referenz existiert bereits. Bitte prüfen u. ggf. ändern."
```

### Example 6: English Verb Constructions
```
❌ WRONG (82 chars):
"Kundenauftrag/Position &/&: Release nicht möglich Seit the Lieferung is Angelegt."

✅ CORRECT (68 chars):
"Kundenauftrag/Pos. &/&: Freigabe nicht möglich, Lieferung existiert."
```

### Example 7: Complex Technical Message
```
❌ WRONG (77 chars):
"Nein mapping Eintrag found In ZEH_TWERCSCLASS Für WERCS Code &1 Text Code &2"

✅ CORRECT (72 chars):
"Kein Mapping-Eintrag in ZEH_TWERCSCLASS für WERCS-Code &1 Textcode &2"
```

### Example 8: Passive Voice + Mixed Language
```
❌ WRONG (84 chars):
"Alle Kundenauftrag Positionen are already Korrekt. Not necessary Aktualisierung Beleg."

✅ CORRECT (73 chars):
"Alle Kundenauftragspositionen bereits korrekt. Aktualisierung nicht nötig."
```

## Attached File
[The attached XLF file was exported via LXE_MASTER from system S4D]

## Execution Instructions

1. Analyze the attached XLF file — identify all translation units
2. For EACH translation unit:
   a. Translate the `<source>` text to PURE German (zero English words)
   b. Apply official SAP terminology
   c. Use CORRECT German prepositions (NOT literal EN→DE mapping)
   d. **Preserve ALL placeholders exactly as they appear** (`&`, `&1`, `&2`, etc.) as plain characters
   e. Check length against `maxwidth`:
      - If within limit → done
      - If exceeded → Apply strategies A-E in order until within limit
   f. Place translation in `<target>` element
   g. Set `state="translated"`
3. Final validation:
   - NO English words in German text
   - Placeholders are plain characters (`&`), NOT XML entities (`&amp;`)
   - ALL translations are within their `maxwidth`
4. Generate the final XLF file with ALL entries translated
5. Verify CRLF line endings and UTF-8 encoding
6. Make the file available for download

## Post-Generation Checklist

Before providing the file, verify:
- [ ] All `<target>` elements have `state="translated"`
- [ ] ZERO English words in German text (scan for: the, is, are, can, will, should, have, etc.)
- [ ] All German prepositions are correct (no "Bis" for "to", no "Durch the", etc.)
- [ ] Placeholders match source (count and type: `&`, `&1`, `&2`, `&3`, `&4`)
- [ ] No `&amp;` entities in placeholder positions (must be plain `&`)
- [ ] No translations exceed their `maxwidth` value
- [ ] German text uses proper SAP terminology
- [ ] Special characters (ö, ü, ä, ß) are present (not escaped)
- [ ] No redundant words (e.g., "Nummer Nummer", "Beleg Beleg")
- [ ] File encoding is UTF-8
- [ ] Line endings are CRLF

## Quality Metrics to Report

After translation, provide:
- Total translation units processed
- Successfully translated count
- Any units requiring manual review (with reasons)
- Number of messages that required length optimization
- Validation: Count of English words found (should be ZERO)
- Validation: Count of `&amp;` entities found (should be ZERO)
```

---

## Usage Notes

### When the file is very large (2000+ entries)
Claude may hit context limits. In that case, split the file by message class or object group before uploading, or ask Claude to process in batches and consolidate at the end.

### Post-import verification
After importing via LXE_MASTER, verify in SE91 (for MESS) that:
- Placeholders `&1`, `&2` etc. appear correctly as dynamic substitution points
- Special characters (ö, ü, ä, ß) render correctly
- Text length does not exceed the message limit
- Messages display properly in SAP GUI
- NO mixed EN/DE text appears

### Adapting for other language pairs
Replace `de-DE` with the desired target language and adjust the SAP terminology glossary in the prompt. The XLF structure and placeholder rules are universal.

### Adapting for other object types
Adjust the "Object Type" field and character limits according to the artifact:
- **Data Elements**: 4 fields (short/medium/long/heading) with different limits
- **Domains**: fixed values with 60-char limit
- **Selection Texts**: no hard limit, but UI common sense applies
- **OTR Texts**: may have longer limits, check the XLF maxwidth

---

## Changelog

### v2.2 (March 2026) — REAL IMPORT DATA ANALYSIS
**MAJOR UPDATE based on analysis of 182 length violations from production import:**
- **NEW SECTION:** "Pure German Text" — zero tolerance for English words (caused 100% of length violations)
- **NEW SECTION:** "Correct German Prepositions" — common wrong mappings from real import log
- **EXPANDED:** "Length Optimization Strategies" with new Strategy A (eliminate English first)
- **ADDED:** 8 real import error examples with exact wrong/correct translations
- **ADDED:** Validation checklist for English word detection
- **UPDATED:** Post-Generation Checklist with English word scan and preposition check
- **UPDATED:** Quality metrics to include English word count validation
- **ENHANCED:** Execution instructions with explicit "PURE German" requirement
- **DOCUMENTED:** Real patterns from 182 warnings: mixed EN/DE (100%), wrong prepositions, redundancy

### v2.1 (March 2026)
- **CRITICAL FIX:** Added explicit instructions to use plain `&` characters, NOT `&amp;` XML entities
- Added visual examples of correct vs. incorrect placeholder handling in XML
- Added "Length Optimization Strategies" section with concrete abbreviation tables
- Added "Length Violation Examples" section with real-world fixes from production import
- Added condensed verb construction patterns for German
- Enhanced "Post-Generation Checklist" with placeholder entity verification

### v2.0 (March 2026)
- Initial template for S/4HANA 2023 project
- Support for MESS object type
- SAP DE terminology glossary
- Basic length management guidelines
