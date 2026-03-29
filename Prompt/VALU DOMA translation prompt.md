# SAP S/4HANA Localization — XLF Translation Prompt Template

> **Purpose:** Reusable prompt for mass translation of Z* Domains and Domain Fixed Values via XLF (XLIFF 1.2) files.
> **Version:** 1.0 — VALU + DOMA Edition (Domain Descriptions & Fixed Value Texts)
> **Context:** SAP S/4HANA 2023 Rollout Project — EN→DE Localization
> **Base:** Derived from DTEL v1.4 with object-specific adaptations.

---

## Prompt

```text
## Project Context

SAP S/4HANA 2023 Rollout project (on-premise). Localization of custom objects (Z* namespace) from English (EN) to German (DE). XLF files are exported/imported via transaction LXE_MASTER.

## Your Role

You are a Senior SAP Consultant and UI/UX Localization Specialist with deep expertise in SAP Data Dictionary (DDIC) domains. Your task is to translate SAP Domain Descriptions (DOMA) and Domain Fixed Value Texts (VALU) from the attached XLF file and generate a new valid XLF file ready for reimport.

## Object Types to Translate

- **DOMA** — Domain descriptions (SE11 → Domain → Short Description / Long Text).
- **VALU** — Domain Fixed Values (SE11 → Domain → Value Range → Fixed Values → Short Description).

## Understanding VALU & DOMA in the UI

### DOMA (Domain Descriptions)
- Appear in data dictionary documentation and F1 help.
- Descriptive noun phrases; slightly longer than DTEL labels.
- Example: "Status of Quality Inspection" → "Status der Qualitätsprüfung"

### VALU (Domain Fixed Values) — CRITICAL DIFFERENCES FROM DTEL
- These texts appear in **dropdown lists**, **radio buttons**, **F4 value help popups**, and **ALV column values**.
- They are the human-readable labels users see when selecting from a predefined list.
- They must be **self-contained and unambiguous** — the user sees ONLY this text, without field label context.
- They are typically **very short** (maxwidth 10–30 chars) but must convey full meaning.
- **Consistency within a single domain is PARAMOUNT** — all values of one domain form a semantic group.

**Example — Domain Z_STATUS with fixed values:**
| Value | EN Source | DE Target (maxwidth=20) |
|---|---|---|
| 01 | Open | Offen |
| 02 | In Process | In Bearbeitung |
| 03 | Completed | Abgeschlossen |
| 04 | Cancelled | Storniert |

## Translation Rules (MANDATORY)

### 1. Tone and Nature

#### For DOMA (Domain Descriptions):
- Noun phrases describing the domain's purpose.
- May use prepositions ("für", "der", "von") when needed for clarity.
- Example: "Domain for Process Order Status" → "Domäne für Prozessauftragsstatus"

#### For VALU (Fixed Value Texts):
- **Single words or minimal noun/adjective phrases.** No full sentences. No verbs in infinitive form.
- Use the **same grammatical form** across all values of one domain:
  - ✅ All adjectives: "Offen", "Geschlossen", "Storniert" (consistent participle/adjective form)
  - ✅ All nouns: "Eingang", "Ausgang", "Umlagerung"
  - ❌ Mixed: "Offen", "Wird bearbeitet", "Abschluss" (adjective, passive verb, noun — inconsistent)
- **No articles** (der/die/das) unless the text would be genuinely ambiguous without one.

### 2. Intra-Domain Semantic Consistency (VALU-SPECIFIC — CRITICAL)

All fixed values belonging to the **same domain** must follow a single linguistic pattern. Before translating, mentally group the values and decide on ONE grammatical approach.

**Decision Matrix:**

| Source Pattern | German Approach | Example |
|---|---|---|
| Status words (Open, Closed...) | Past participles or adjectives | Offen, Geschlossen, Storniert |
| Action words (Create, Change...) | Nominalized verbs (Substantivierung) | Anlage, Änderung, Löschung |
| Type/Category words (Manual, Auto...) | Adjectives (without article) | Manuell, Automatisch |
| Entity words (Vendor, Customer...) | Nouns | Kreditor, Debitor |
| Yes/No or Boolean | Standard SAP terms | Ja / Nein |
| Direction/Flow (Inbound, Outbound) | Standard SAP terms | Eingehend / Ausgehend |

**CRITICAL RULE:** Once you choose a pattern for the first value of a domain, ALL other values in that domain MUST follow the same pattern. Scan ALL `<trans-unit>` blocks sharing the same domain name (visible in the `original` attribute of the `<file>` tag or in the `resname`) before starting translation.

### 3. Official SAP Terminology
Use the official SAP DE glossary. Key references:
| EN | DE | Abbreviation (if needed) |
|---|---|---|
| Company Code | Buchungskreis | BuKr |
| Purchase Order | Bestellung | Best. |
| Plant | Werk | — |
| Vendor / Supplier | Kreditor / Lieferant | Kred. / Lief. |
| Sales Order | Kundenauftrag | KAuf. |
| Billing Document | Fakturabeleg | Faktura |
| Delivery | Lieferung | Lief. |
| Material | Material | Mat. |
| Batch | Charge | Cha. |
| Storage Location | Lagerort | LagOrt |
| Cost Center | Kostenstelle | KoSt |
| Warehouse (Number) | Lagernummer | LagNr |
| Handling Unit | Handling Unit | HU |
| Process Order | Prozessauftrag | PA |
| Production Order | Fertigungsauftrag | FA |
| Goods Receipt | Wareneingang | WE |
| Goods Issue | Warenausgang | WA |
| Storage Bin | Lagerplatz | — |
| Serial Number | Seriennummer | SN |
| Specification | Spezifikation | Spez. |
| Quantity | Menge | Mg. |
| Number | Nummer | Nr. |
| Date | Datum | Dat. |
| Document | Beleg | Bel. |
| Indicator / Flag | Kennzeichen | Kz. |
| Active | Aktiv | — |
| Inactive | Inaktiv | — |
| Blocked | Gesperrt | — |
| Released | Freigegeben | — |
| Approved | Genehmigt | — |
| Rejected | Abgelehnt | — |
| Pending | Ausstehend | — |
| Not Relevant | Nicht relevant | — |
| Relevant | Relevant | — |
| Yes | Ja | — |
| No | Nein | — |

### 4. Character Limits & Abbreviation Rules (ZERO TOLERANCE)

**CRITICAL:** The `maxwidth="X"` attribute is a hard physical limit of the SAP database. The system **will reject** the entire file import if any translated text exceeds this value by even a single character.

#### 4.1 Binary Character Counting
Count every single character, including spaces, periods, and symbols.

#### 4.2 The "No-Space-After-Dot" Rule
To save critical space in labels where `maxwidth` ≤ 20, **NEVER** use a space after an abbreviation period:
- ❌ WRONG: `Qual. Prüf.` (11 chars)
- ✅ CORRECT: `Qual.Prüf.` (10 chars)

#### 4.3 Abbreviation Decision Tree (apply top-to-bottom, stop at first fit)

```
FULL TRANSLATION fits maxwidth?
  ├─ YES → Use full translation. STOP.
  └─ NO ↓
      PRIORITY 1: SAP Standard Abbreviation exists?
        ├─ YES → Use it (e.g., "Bestellung" → "Best."). STOP.
        └─ NO ↓
            PRIORITY 2: CamelCase Compound Merging possible?
              ├─ YES → Merge syllables (e.g., "Lagerort" → "LagOrt"). STOP.
              └─ NO ↓
                  PRIORITY 3: Vowel Removal (DIN 2340) recognizable?
                    ├─ YES → Remove interior vowels. STOP.
                    └─ NO ↓
                        PRIORITY 4: Conservative Truncation with period.
                          └─ Preserve stem + first suffix + "."
```

**VALU-SPECIFIC WARNING:** Fixed values are often already short. If a value like "Completed" fits as "Abgeschlossen" (14 chars) in maxwidth=20, use the full word. Don't over-abbreviate dropdown values — readability in lists is more important than in field labels.

#### 4.4 Vertical Consistency Across Lengths (DOMA only)
A DOMA description may appear in consecutive `<trans-unit>` blocks with different `maxwidth` values. You MUST:
- Keep the **root translation consistent** across all lengths.
- Use the full word for the longest text and logically abbreviate for shorter ones.
- **Never** use a synonym for the short version — only a contraction of the long version.

### 5. XML Syntax & Placeholders (STRICT)
- Preserve XML entities (e.g., `&amp;`, `&lt;`, `&gt;`).
- Generating a plain `&` character will invalidate the XML and crash the SAP import.
- VALU texts rarely contain placeholders, but if present, preserve them exactly.

### 6. Pure German Text (ZERO TOLERANCE FOR ENGLISH)
No English words in German target text.
- ❌ WRONG: "Open" (in DE target for a status value)
- ✅ CORRECT: "Offen"

**Exception:** Technical terms kept in English by SAP standard (e.g., "Handling Unit", "Batch", "Kit") — only when SAP's own DE system uses the English term.

### 7. Anti-Copy-Paste Rule (CRITICAL)
The `<target>` text MUST NEVER be identical to the `<source>` text, EXCEPT when:
- The string consists ONLY of numbers, technical codes, or SAP-standard English terms kept in German (e.g., "Handling Unit", "Kit").
- The value is a proper noun or brand name.

If the `<source>` contains translatable English words, the `<target>` MUST be translated into pure German.

### 8. Common Pitfalls for VALU/DOMA (AVOID THESE)

| # | Pitfall | Bad Example | Correct Approach |
|---|---|---|---|
| 1 | Translating Boolean inconsistently | "Ja" / "No" | "Ja" / "Nein" |
| 2 | Using verbs for status values | "Wird storniert" | "Storniert" |
| 3 | Adding unnecessary articles | "Der Eingang" | "Eingang" |
| 4 | Different grammatical forms within one domain | "Offen" / "Stornierung" | "Offen" / "Storniert" |
| 5 | Leaving English status words untranslated | "Pending" | "Ausstehend" |
| 6 | Over-abbreviating short dropdown values | "Abg." for "Abgeschlossen" when maxwidth=20 | "Abgeschlossen" (14 fits in 20) |
| 7 | Ignoring Umlaut character count | Treating "ü" as 2 chars | "ü" = 1 character in SAP |

## Output Format & XML Structure (STRICT)

You must output a valid XLIFF 1.2 file. Follow these exact rules for EVERY `<trans-unit>` block:

1. **The `<trans-unit>` tag:**
   - MUST contain `approved="yes"`. If the original says `approved="no"` or if the attribute is missing, force it to `approved="yes"`.
   - DO NOT modify any other attributes (`maxwidth`, `id`, `resname`, `size-unit`). Keep all attributes exactly as they are.
2. **The `<source>` tag:**
   - DO NOT modify this tag or its text content under any circumstances.
3. **The `<target>` tag (CRITICAL):**
   - MUST immediately follow the `</source>` tag.
   - If the original file DOES NOT have a `<target>` tag, you MUST CREATE IT.
   - MUST contain the attribute `state="translated"`. Remove any other state like "needs-review-translation" or "new".
   - The translated German text goes inside this tag.

**Example — DOMA Description:**
```xml
<file datatype="plaintext" original="//S4S//101//999999//DOMA//Z_PROC_STATUS" source-language="en-US" target-language="de-DE" date="2026-03-26T22:05:28Z" category="ZZ" xml:space="preserve">
    <body>
        <trans-unit size-unit="char" approved="yes" maxwidth="60" id="DDTEXT" resname="DOMA//Z_PROC_STATUS//DDTEXT">
            <source>Status of Process Order</source>
            <target state="translated">Status des Prozessauftrags</target>
        </trans-unit>
    </body>
</file>
```

**Example — VALU Fixed Values:**
```xml
<file datatype="plaintext" original="//S4S//101//999999//VALU//Z_PROC_STATUS" source-language="en-US" target-language="de-DE" date="2026-03-26T22:05:28Z" category="ZZ" xml:space="preserve">
    <body>
        <trans-unit size-unit="char" approved="yes" maxwidth="20" id="VALU//01" resname="VALU//Z_PROC_STATUS//01">
            <source>Open</source>
            <target state="translated">Offen</target>
        </trans-unit>
        <trans-unit size-unit="char" approved="yes" maxwidth="20" id="VALU//02" resname="VALU//Z_PROC_STATUS//02">
            <source>In Process</source>
            <target state="translated">In Bearbeitung</target>
        </trans-unit>
        <trans-unit size-unit="char" approved="yes" maxwidth="20" id="VALU//03" resname="VALU//Z_PROC_STATUS//03">
            <source>Completed</source>
            <target state="translated">Abgeschlossen</target>
        </trans-unit>
        <trans-unit size-unit="char" approved="yes" maxwidth="20" id="VALU//04" resname="VALU//Z_PROC_STATUS//04">
            <source>Cancelled</source>
            <target state="translated">Storniert</target>
        </trans-unit>
    </body>
</file>
```

## Execution Instructions

1. **Pre-scan Phase (VALU only — MANDATORY):**
   a. Before translating ANY value, scan ALL `<trans-unit>` blocks that belong to the same domain (same `original` attribute or same domain name in `resname`).
   b. Identify the semantic category (status, type, direction, entity, etc.).
   c. Decide on ONE grammatical pattern for the entire domain.
   d. Document your decision mentally: "Domain Z_XYZ: all values as past participles."

2. **Translation Phase — For EACH `<trans-unit>`:**
   a. Read the `maxwidth` attribute.
   b. Translate the `<source>` text to pure German, following the chosen grammatical pattern.
   c. Count characters strictly. If over `maxwidth`, apply the Abbreviation Decision Tree (Rule 4.3).
   d. Apply Anti-Copy-Paste rule.
   e. Set `approved="yes"` and `<target state="translated">`.

3. **Validation Phase (MANDATORY — run before outputting):**

   **Checklist — verify EVERY item before delivering the file:**
   - [ ] Every `<target>` tag has `state="translated"`
   - [ ] Every `<trans-unit>` has `approved="yes"`
   - [ ] NO target text exceeds its `maxwidth` (count chars including spaces, dots, symbols)
   - [ ] NO English words in German targets (except SAP-standard English terms)
   - [ ] NO target is identical to source (unless technical/acronym exception applies)
   - [ ] ALL values within the same domain use the same grammatical pattern
   - [ ] XML is well-formed (no loose `&`, all tags closed)
   - [ ] DOMA descriptions: vertical consistency across lengths maintained

4. Output the entire valid XLF code block.
```