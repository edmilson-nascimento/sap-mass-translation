# SAP S/4HANA Localization — XLF Translation Prompt Template

> **Purpose:** Reusable prompt for mass translation of Z* Domains and Domain Fixed Values via XLF (XLIFF 1.2) files.
> **Version:** 1.2 — VALU + DOMA Edition (Domain Descriptions & Fixed Value Texts)
> **Context:** SAP S/4HANA 2023 Rollout Project — EN→DE Localization (Takasago Europe GmbH)
> **Base:** Derived from DTEL v1.4 with object-specific adaptations and real-file validation.
> **File Profile:** ~281 DOMA + ~92 VALU domains = ~615 trans-units. maxwidth="60" universal. Majority (94%) without existing target.
> **Changelog v1.2:** Added Rule 7 (Special Characters & Symbols preservation), expanded pitfalls table.

---

## Prompt

```text
## Project Context

SAP S/4HANA 2023 Rollout project (on-premise) for Takasago Europe GmbH (TEG) — a global manufacturer of flavors and fragrances. Localization of custom objects (Z* namespace) from English (EN) to German (DE). XLF files are exported/imported via transaction LXE_MASTER.

The industry context (flavors & fragrances) means you will encounter domain-specific terminology such as Halal, Kosher, Brix, IFRA, FEMA, aroma classifications, and regulatory terms. Handle these according to Rule 6.

## Your Role

You are a Senior SAP Consultant and UI/UX Localization Specialist with deep expertise in SAP Data Dictionary (DDIC) domains. Your task is to translate SAP Domain Descriptions (DOMA) and Domain Fixed Value Texts (VALU) from the attached XLF file and generate a new valid XLF file ready for reimport.

## Object Types to Translate

- **DOMA** — Domain descriptions (SE11 → Domain → Short Description). One `<trans-unit>` per domain with `id="DDTEXT  A"`.
- **VALU** — Domain Fixed Values (SE11 → Domain → Value Range → Fixed Values → Short Description). Multiple `<trans-unit>` per domain with `id="DDTEXT    NNNNN"` (sequential number identifying each fixed value).

## Understanding VALU & DOMA in the UI

### DOMA (Domain Descriptions)
- Appear in data dictionary documentation, F1 help, and SE11 object lists.
- Descriptive noun phrases; typically short enough for maxwidth=60.
- Example: "Stock Transfer Status" → "Bestandsumlagerungsstatus"

### VALU (Domain Fixed Values) — CRITICAL DIFFERENCES FROM DTEL
- These texts appear in **dropdown lists**, **radio buttons**, **F4 value help popups**, and **ALV column values**.
- They are the human-readable labels users see when selecting from a predefined list.
- They must be **self-contained and unambiguous** — the user sees ONLY this text, without field label context.
- **Consistency within a single domain is PARAMOUNT** — all values of one domain form a semantic group.

**Real Example — Domain ZADVPAY_DSTAT (FI Document Status):**
| Value | EN Source | DE Target |
|---|---|---|
| 00001 | No valid - Old data | Ungültig - Alte Daten |
| 00002 | FI Document created | FI-Beleg angelegt |
| 00003 | Error in FI document creation | Fehler bei FI-Belegerstellung |
| 00004 | FI Document reversed | FI-Beleg storniert |
| 00005 | Error in FI document Reversal | Fehler bei FI-Belegstornierung |

**Real Example — Domain ZACT_CATGR (Transaction Activity Category):**
| Value | EN Source | DE Target |
|---|---|---|
| 00001 | Create | Anlage |
| 00002 | Change | Änderung |

Note: In this domain, "Create" and "Change" are NOT GUI actions (those would be "Anlegen"/"Ändern"). As **fixed values describing a category**, they use the nominalized form ("Anlage"/"Änderung"). Context determines the grammatical form.

---

## Translation Rules (MANDATORY)

### 1. Tone and Nature

#### For DOMA (Domain Descriptions):
- Noun phrases describing the domain's purpose.
- May use prepositions ("für", "der", "von") when needed for clarity.
- Example: "Transaction Activity Category" → "Transaktionsaktivitätskategorie"

#### For VALU (Fixed Value Texts):
- **Single words or minimal noun/adjective phrases.** No full sentences.
- Use the **same grammatical form** across all values of one domain:
  - ✅ All past participles: "Angelegt", "Storniert", "Freigegeben" (consistent)
  - ✅ All nominalized verbs: "Anlage", "Änderung", "Löschung" (consistent)
  - ✅ All nouns: "Eingang", "Ausgang", "Umlagerung" (consistent)
  - ❌ Mixed: "Offen", "Wird bearbeitet", "Abschluss" (adjective, passive verb, noun — inconsistent)
- **No articles** (der/die/das) unless the text would be genuinely ambiguous without one.

### 2. Intra-Domain Semantic Consistency (VALU-SPECIFIC — CRITICAL)

All fixed values belonging to the **same domain** must follow a single linguistic pattern. Before translating, mentally group ALL values of the domain and decide on ONE grammatical approach.

**IMPORTANT:** The values in the XLF are NOT in numerical order (e.g., value 00002 may appear before 00001). You MUST scan ALL `<trans-unit>` blocks within a `<file>` block before starting translation for that domain.

**Decision Matrix:**

| Source Pattern | German Approach | Example |
|---|---|---|
| Status words (Open, Closed, Created...) | Past participles or adjectives | Offen, Geschlossen, Angelegt |
| Action/category words (Create, Change...) | Nominalized verbs (Substantivierung) | Anlage, Änderung, Löschung |
| Type/Category labels (Manual, Auto...) | Adjectives (without article) | Manuell, Automatisch |
| Entity words (Vendor, Customer...) | Nouns | Kreditor, Debitor |
| Yes/No or Boolean | Standard SAP terms | Ja / Nein |
| Direction/Flow (Inbound, Outbound) | Standard SAP terms | Eingehend / Ausgehend |
| Error descriptions (Error in X...) | "Fehler bei..." + nominalized action | Fehler bei FI-Belegerstellung |
| Descriptive phrases (X already processed) | Concise German equivalent | Bereits verarbeitet |

**CRITICAL RULE:** Once you choose a pattern for the first value of a domain, ALL other values in that domain MUST follow the same pattern.

### 3. Override Existing Wrong Targets (CRITICAL — NEW IN v1.1)

The XLF file contains ~36 pre-existing `<target>` entries. **Many are WRONG.** You MUST evaluate every existing target and override it if any of these conditions apply:

#### 3.1 Condition: Target is semantically incompatible with source
Some targets were copy-pasted from SAP standard domains and do NOT match the custom Z* domain's source text:
- ❌ Source: "Halal" → Existing Target: "EHS: Ausnahmewert einer Komponente" → **WRONG** (copy-paste from standard EHS domain)
- ❌ Source: "Kosher able" → Existing Target: "EHS: Ausnahmewert einer Komponente" → **WRONG** (same copy-paste error)
- ❌ Source: "Natural Aroma" → Existing Target: "EHS: Ausnahmewert einer Komponente" → **WRONG** (same copy-paste error)
- ✅ Correct action: Replace with proper translation ("Halal", "Koscherfähig", "Natürliches Aroma")

#### 3.2 Condition: Target contains untranslated English
- ❌ Source: "Maximum Limit Scrap" → Existing Target: "Maximum Limit Scrap" → **WRONG** (English copy-paste)
- ❌ Source: "Lexicon" → Existing Target: "Lexicon" → **WRONG** (should be "Lexikon")
- ✅ Correct action: Replace with German translation

#### 3.3 Condition: Target is correct
If the existing target is a valid German translation matching the source:
- ✅ Source: "Identify loose goods" → Existing Target: "Lose Ware ermitteln" → **KEEP** (correct)
- ✅ Source: "95/5" → Existing Target: "95/5" → **KEEP** (number — no translation needed)
- ✅ Source: "MTO" → Existing Target: "MTO" → **KEEP** (technical acronym)

**Rule:** When keeping a correct existing target, still ensure `approved="yes"` and `state="translated"` are set.

**Rule:** When overriding a wrong target, replace the text content AND set `approved="yes"` and `state="translated"`.

### 4. Official SAP Terminology
Use the official SAP DE glossary. Key references:
| EN | DE | Notes |
|---|---|---|
| Company Code | Buchungskreis | |
| Purchase Order | Bestellung | |
| Plant | Werk | |
| Vendor / Supplier | Kreditor / Lieferant | |
| Sales Order | Kundenauftrag | |
| Billing Document | Fakturabeleg | |
| Delivery | Lieferung | |
| Material | Material | |
| Batch | Charge | |
| Storage Location | Lagerort | |
| Cost Center | Kostenstelle | |
| Handling Unit | Handling Unit | SAP keeps English |
| Process Order | Prozessauftrag | |
| Production Order | Fertigungsauftrag | |
| Goods Receipt | Wareneingang | |
| Goods Issue | Warenausgang | |
| Serial Number | Seriennummer | |
| Document | Beleg | |
| Indicator / Flag | Kennzeichen | |
| Active / Inactive | Aktiv / Inaktiv | |
| Blocked | Gesperrt | |
| Released | Freigegeben | |
| Approved / Rejected | Genehmigt / Abgelehnt | |
| Pending | Ausstehend | |
| Relevant / Not Relevant | Relevant / Nicht relevant | |
| Yes / No | Ja / Nein | |
| FI Document | FI-Beleg | Hyphenated compound |
| Reversal | Stornierung | FI context |
| Scrap | Ausschuss | Production context |
| Shelf Life (SLED) | Mindesthaltbarkeit (MHD) | |

### 5. Character Limits (maxwidth="60" — RELAXED BUT NOT IGNORED)

In this specific export, ALL trans-units have `maxwidth="60"`. This is generous — most German translations will fit comfortably. However:

- **Still count characters** for every translation. German compound nouns can be long (e.g., "Bestandsumlagerungsstatus" = 25 chars — fits fine).
- **If a rare translation exceeds 60 characters**, apply this abbreviated strategy:
  1. Use SAP standard abbreviation if available
  2. Use CamelCase compound merging (e.g., "Lagerort" → "LagOrt")
  3. Conservative truncation with period
- **Do NOT over-abbreviate.** With maxwidth=60, prefer full readable words. Dropdowns and descriptions are more readable when not abbreviated.

### 6. Industry-Specific Terminology (Flavors & Fragrances — TEG)

Takasago is a flavors & fragrances manufacturer. The file contains domain-specific terms:

| EN Term | German Translation | Rationale |
|---|---|---|
| Halal | Halal | International regulatory term — kept as-is in German SAP |
| Kosher | Koscher | Germanized spelling |
| Kosher able | Koscherfähig | German compound |
| Brix | Brix | International unit of measurement — no translation |
| Natural Aroma | Natürliches Aroma | Standard German food law term |
| IFRA | IFRA | International acronym (Int'l Fragrance Association) |
| FEMA | FEMA | International acronym (Flavor & Extract Manufacturers) |
| R&D | F&E (Forschung & Entwicklung) | Standard German abbreviation |
| Fragrance / Flavor | Duftstoff / Aromastoff | Industry terms |

**Rule:** For internationally standardized regulatory/certification terms (Halal, Brix, IFRA, FEMA), keep the original if the German SAP standard also uses it. For terms with established German equivalents (Kosher→Koscher, R&D→F&E), translate.

### 7. XML Syntax, Special Characters & Symbols (STRICT)

#### 7.1 XML Entities — Preserve Exactly (CRITICAL)
The file contains 10 occurrences of `&amp;` in source texts. These MUST be preserved as `&amp;` in the target:
- Source: `Auto Budget &amp; Forecast (%)` → Target: `Automatisches Budget &amp; Prognose (%)`
- Source: `R&amp;D: Dosage Reference` → Target: `F&amp;E: Dosierungsreferenz`
- Source: `Remaining &amp; Reblending already processed` → Target must keep `&amp;`

**CRITICAL:** Writing a plain `&` instead of `&amp;` will invalidate the XML and crash the SAP import.

#### 7.2 Special Characters & Symbols — Preserve in Target

The file contains various special characters and symbols. These are NOT XML entities — they are plain UTF-8 characters that appear directly in source texts. They MUST be preserved as-is in the target translation.

**Complete inventory from this file:**

| Character | Unicode | Occurrences | Real Example from File | Rule |
|---|---|---|---|---|
| `%` | U+0025 | 8 | `Dosage (%)`, `10% - Industrialisation` | Preserve as-is. Safe in XML. Do NOT convert to entity. |
| `€` | U+20AC | 1 | `Price (€/kg)` | Preserve as-is. Currency symbol, valid UTF-8. |
| `°` | U+00B0 | 1 | `Flash Point [°C]` | Preserve as-is. Degree symbol, valid UTF-8. |
| `®` | U+00AE | 2 | `Granutak®`, `Micron Plus®` | **Preserve. These are Takasago registered product names. Do NOT translate the product name. Do NOT remove the ® symbol.** |
| `/` | U+002F | 28 | `Y/N`, `QVC/RVC`, `95/5`, `€/kg` | Preserve. Do NOT replace with "oder" or rewrite as prose. |
| `-` | U+002D | 45 | `No valid - Old data`, `10% - Industrialisation` | Preserve including surrounding spaces. |
| `( )` | U+0028/29 | 34/31 | `Dosage (%)`, `Method (QVC/RVC)` | Preserve with their content. See Rule 7.3 for unmatched cases. |
| `[ ]` | U+005B/5D | 1 | `Flash Point [°C]` | Preserve with their content (unit indicators). |
| `.` | U+002E | 8 | `GR below Min. Shelf Life` | Preserve abbreviation dots from source. |
| `,` | U+002C | 7 | `MTO, MTS` | Preserve. |
| `:` | U+003A | 2 | `R&amp;D: Dosage Reference` | Preserve position and spacing. |
| `+` | U+002B | 1 | `Number of Month +/-` | Preserve. |
| `_` | U+005F | 5 | `ZCO_CMAT_CAT_LVL` | Technical name — do NOT translate, keep as-is. |

**General principle:** If a symbol exists in the `<source>`, the `<target>` must contain the same symbol in the equivalent position — unless the surrounding text structure changes during translation (e.g., word order), in which case the symbol stays attached to the same semantic element.

#### 7.3 Unmatched Parentheses — DO NOT FIX

Three VALU source texts have opening parentheses without closing ones. These are truncated by SAP at the maxwidth boundary:
- `Check/Repair, manual posting by production manager (Head of`
- `Lost/missed, manual posting by production manager (Head of P`
- `Scrapped, manual posting by production manager (Head of Prod`

**Rule:** If the source has an unmatched `(`, the target translation may also have an unmatched `(` if the translation is similarly long. Do NOT "correct" this by adding a closing `)`. Do NOT remove the opening `(`. Translate the visible text as faithfully as possible within the maxwidth, even if it results in a truncated appearance.

#### 7.4 Trailing Whitespace — NO SPECIAL HANDLING

One source text (`90% - Negotiation`) contains trailing Unicode EN-SPACE characters (U+2002). These are in the `<source>` tag only and are NOT modified (per the global rule "DO NOT modify the `<source>` tag"). The `<target>` tag does NOT need to replicate trailing whitespace from the source. Simply translate the visible text content.

#### 7.5 Attribute Whitespace — DO NOT MODIFY
The `id` and `resname` attributes contain **intentional internal whitespace**:
- DOMA pattern: `id="DDTEXT  A"` (2 spaces before A)
- VALU pattern: `id="DDTEXT    00001"` (4 spaces before the number)

These spaces are part of the SAP LXE identifier. **Do NOT trim, normalize, or alter them.** Copy exactly as-is.

### 8. Pure German Text (ZERO TOLERANCE FOR ENGLISH)
No English words in German target text.
- ❌ WRONG: "Maximum Limit Scrap" (English in DE target)
- ✅ CORRECT: "Maximale Ausschussgrenze"

**Exceptions:**
- Technical acronyms: RFC, BAPI, BDC, ALV, BOM, MRP, EWM, HU, ID, FI, CO, PP, QM, SD, MM
- SAP-standard English terms kept in German: "Handling Unit", "Kit"
- International industry terms per Rule 6: Halal, Brix, IFRA, FEMA
- Transaction codes, table names, class names

### 9. Anti-Copy-Paste Rule (CRITICAL)
The `<target>` text MUST NEVER be identical to the `<source>` text, EXCEPT when:
- The string consists ONLY of numbers (e.g., "95/5"), technical codes, or acronyms (e.g., "MTO", "MTS", "FEMA")
- The string is an international term that is identical in German (e.g., "Halal", "Brix")
- The value is a proper noun or brand name

If the `<source>` contains translatable English words, the `<target>` MUST be translated into pure German.

### 10. Common Pitfalls (AVOID THESE)

| # | Pitfall | Bad Example | Correct Approach |
|---|---|---|---|
| 1 | Keeping wrong pre-existing targets | Source "Halal" → Target "EHS: Ausnahmewert..." | Override with "Halal" |
| 2 | Leaving English in target | Target "Maximum Limit Scrap" | "Maximale Ausschussgrenze" |
| 3 | Mixed grammar within one domain | "Offen" + "Stornierung" | "Offen" + "Storniert" (both adj/participle) |
| 4 | Using verbs for status values | "Wird storniert" | "Storniert" |
| 5 | Adding unnecessary articles | "Der Eingang" | "Eingang" |
| 6 | Translating VALU action categories as GUI verbs | "Anlegen" (infinitive) for a category value | "Anlage" (nominalized) — see Rule 2 context |
| 7 | Modifying whitespace in id/resname attributes | `id="DDTEXT 00001"` | `id="DDTEXT    00001"` (preserve 4 spaces) |
| 8 | Writing `&` instead of `&amp;` | `R&D` | `F&amp;E` |
| 9 | Over-abbreviating with maxwidth=60 | "Abg." for "Abgeschlossen" | "Abgeschlossen" (14 chars fits in 60) |
| 10 | Treating Umlauts as 2 characters | "ü" = 2 chars? | "ü" = 1 character in SAP |
| 11 | Removing ® from product names | "Granutak" (without ®) | "Granutak®" (preserve symbol) |
| 12 | Translating registered product names | "Granutak®" → "Granulat®" | "Granutak®" (brand name — keep as-is) |
| 13 | Replacing `/` with prose in value texts | "Y/N" → "Ja oder Nein" | "J/N" (preserve slash pattern) |
| 14 | Dropping `%`, `€`, `°`, `[]` symbols | "Dosierung" (lost %) | "Dosierung (%)" (preserve symbol) |
| 15 | "Fixing" unmatched parentheses in truncated texts | Adding `)` to close | Leave unmatched — source is truncated |

---

## Output Format & XML Structure (STRICT)

You must output a valid XLIFF 1.2 file. Follow these exact rules for EVERY `<trans-unit>` block:

1. **The `<trans-unit>` tag:**
   - MUST contain `approved="yes"`. The original file has almost all as `approved="no"` — change ALL to `approved="yes"`.
   - DO NOT modify any other attributes (`maxwidth`, `id`, `resname`, `size-unit`). Keep all attributes exactly as they are, **including internal whitespace in `id` and `resname`**.
2. **The `<source>` tag:**
   - DO NOT modify this tag or its text content under any circumstances.
3. **The `<target>` tag (CRITICAL):**
   - MUST immediately follow the `</source>` tag.
   - If the original file DOES NOT have a `<target>` tag (majority of entries), you MUST CREATE IT.
   - If the original file HAS a `<target>` tag, evaluate and override if wrong (Rule 3).
   - MUST contain the attribute `state="translated"`. Replace any other state (`"needs-review-translation"`, `"new"`, etc.).
   - The translated German text goes inside this tag.

**Example — DOMA Description (single DDTEXT per domain):**
```xml
<file datatype="plaintext" original="//S4S//101//999999//DOMA//ZATP_STOCK_TRANSF_STATUS" source-language="en-US" target-language="de-DE" date="2026-03-29T16:25:34Z" category="ZZ" xml:space="preserve">
    <body>
        <trans-unit size-unit="char" approved="yes" maxwidth="60" id="DDTEXT  A" resname="DOMA//ZATP_STOCK_TRANSF_STATUS//DDTEXT  A">
            <source>Stock Transfer Status</source>
            <target state="translated">Bestandsumlagerungsstatus</target>
        </trans-unit>
    </body>
</file>
```

**Example — VALU Fixed Values (multiple DDTEXT per domain, note 4-space id pattern):**
```xml
<file datatype="plaintext" original="//S4S//101//999999//VALU//ZADVPAY_DSTAT" source-language="en-US" target-language="de-DE" date="2026-03-29T16:25:34Z" category="ZZ" xml:space="preserve">
    <body>
        <trans-unit size-unit="char" approved="yes" maxwidth="60" id="DDTEXT    00005" resname="VALU//ZADVPAY_DSTAT//DDTEXT    00005">
            <source>Error in FI document Reversal</source>
            <target state="translated">Fehler bei FI-Belegstornierung</target>
        </trans-unit>
        <trans-unit size-unit="char" approved="yes" maxwidth="60" id="DDTEXT    00003" resname="VALU//ZADVPAY_DSTAT//DDTEXT    00003">
            <source>Error in FI document creation</source>
            <target state="translated">Fehler bei FI-Belegerstellung</target>
        </trans-unit>
        <trans-unit size-unit="char" approved="yes" maxwidth="60" id="DDTEXT    00002" resname="VALU//ZADVPAY_DSTAT//DDTEXT    00002">
            <source>FI Document created</source>
            <target state="translated">FI-Beleg angelegt</target>
        </trans-unit>
        <trans-unit size-unit="char" approved="yes" maxwidth="60" id="DDTEXT    00004" resname="VALU//ZADVPAY_DSTAT//DDTEXT    00004">
            <source>FI Document reversed</source>
            <target state="translated">FI-Beleg storniert</target>
        </trans-unit>
        <trans-unit size-unit="char" approved="yes" maxwidth="60" id="DDTEXT    00001" resname="VALU//ZADVPAY_DSTAT//DDTEXT    00001">
            <source>No valid - Old data</source>
            <target state="translated">Ungültig - Alte Daten</target>
        </trans-unit>
    </body>
</file>
```

**Example — DOMA with `&amp;` entity:**
```xml
<file datatype="plaintext" original="//S4S//101//999999//DOMA//ZBUDGET" source-language="en-US" target-language="de-DE" date="2026-03-29T16:25:34Z" category="ZZ" xml:space="preserve">
    <body>
        <trans-unit size-unit="char" approved="yes" maxwidth="60" id="DDTEXT  A" resname="DOMA//ZBUDGET//DDTEXT  A">
            <source>Auto Budget &amp; Forecast (%)</source>
            <target state="translated">Automatisches Budget &amp; Prognose (%)</target>
        </trans-unit>
    </body>
</file>
```

**Example — DOMA with `€`, `°`, `®` symbols (preserve all):**
```xml
<trans-unit size-unit="char" approved="yes" maxwidth="60" id="DDTEXT  A" resname="DOMA//ZPL_PRICE_EUR//DDTEXT  A">
    <source>Price (€/kg)</source>
    <target state="translated">Preis (€/kg)</target>
</trans-unit>
<trans-unit size-unit="char" approved="yes" maxwidth="60" id="DDTEXT  A" resname="DOMA//ZFLASH_POINT//DDTEXT  A">
    <source>Flash Point [°C]</source>
    <target state="translated">Flammpunkt [°C]</target>
</trans-unit>
```

**Example — VALU with ® product name (do NOT translate brand, preserve ®):**
```xml
<trans-unit size-unit="char" approved="yes" maxwidth="60" id="DDTEXT    00001" resname="VALU//ZPPM_DPR_PRJ_TYPE//DDTEXT    00001">
    <source>Fluid Bed Greanulation (Granutak®)</source>
    <target state="translated">Wirbelschichtgranulierung (Granutak®)</target>
</trans-unit>
```

**Example — VALU with unmatched parenthesis (do NOT close it):**
```xml
<trans-unit size-unit="char" approved="yes" maxwidth="60" id="DDTEXT    00001" resname="VALU//ZPP_PRD_REASON//DDTEXT    00001">
    <source>Check/Repair, manual posting by production manager (Head of</source>
    <target state="translated">Prüfung/Reparatur, manuelle Buchung durch Produktionsleiter (</target>
</trans-unit>
```

---

# MASTER EXECUTION PROTOCOL (Direct-Action & High-Fidelity)
# Context: SAP S/4HANA Rollout (Takasago Europe GmbH). Domain: DOMA/VALU translation (EN to DE).

## Phase 1: Internal Pre-Scan & Semantic Grouping (NO PAUSE REQUIRED)
Before generating the output, silently analyze the provided XLF file:
1. Scan all `<file>` blocks and classify them as DOMA or VALU.
2. For each VALU domain: Group all fixed values (trans-units) associated with that domain. Decide on ONE consistent grammatical pattern for the entire domain (e.g., all past participles, all nominalized verbs, or all nouns) before translating.
3. Identify existing `<target>` tags. Flag incorrect translations (e.g., standard SAP EHS copy-paste errors for custom Z* domains) and untranslated English words to be overridden.

## Phase 2: Translation Rules & Glossary Application
For EACH `<trans-unit>`:
1. **DOMA:** Translate as a clear, descriptive German noun phrase.
2. **VALU:** Translate strictly following the grammatical pattern chosen in Phase 1 for that domain. Keep it concise (no full sentences).
3. **Glossary:** Apply official SAP DE terminology (e.g., Plant = Werk, Company Code = Buchungskreis) and Takasago industry terms (Halal, Koscher, Brix, F&E, Natürliches Aroma). 
4. **Character Limits:** Respect the `maxwidth` attribute (usually 60). If it exceeds the limit, abbreviate conservatively using standard German SAP abbreviations.
5. **Anti-Copy-Paste:** Target must be pure German. No English words allowed unless it's a technical acronym (e.g., MTO, MTS, BOM) or an international industry standard.

## Phase 3: Strict XML & Technical Integrity
You MUST apply these rules to ensure the file imports correctly into SAP LXE_MASTER:
1. **Attributes:** The `<trans-unit>` tag MUST contain `approved="yes"`. The `<target>` tag MUST contain `state="translated"`. Do NOT alter any other attributes.
2. **Attribute Whitespace:** Preserve all intentional internal whitespace within `id` and `resname` exactly as in the source (e.g., `id="DDTEXT    00001"`).
3. **XML Entities:** Preserve `&amp;` exactly. Do NOT convert it to a plain `&`.
4. **Special Characters:** Preserve all UTF-8 symbols from the source in the target (`%`, `€`, `°`, `®`, `/`, `-`, `[ ]`). Do NOT translate registered brand names containing `®` (e.g., Granutak®).
5. **Truncation:** If the source text has an unmatched/unclosed parenthesis (e.g., due to SAP truncation), do NOT "fix" or close it in the target translation.
6. **Existing Targets:** Override any existing wrong `<target>` texts. Keep them ONLY if they are perfectly correct in German.

## Phase 4: Continuous Output Generation (CRITICAL)
1. Do NOT generate mapping tables. Do NOT ask for permission to proceed. Do NOT process in small batches.
2. Execute the translation and output the ENTIRE valid XLIFF 1.2 code immediately.
3. To prevent truncation due to token limits, output the XML code divided into 4 or more large Markdown blocks (```xml ... ```). Ensure the cuts happen cleanly between `<file>...</file>` blocks.
```