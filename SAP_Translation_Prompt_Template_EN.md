# SAP S/4HANA Localization — XLF Translation Prompt Template

> **Purpose:** Reusable prompt for mass translation of Z* custom objects via XLF (XLIFF 1.2) files, for import into SAP via LXE_MASTER.
>
> **Version:** 2.0 — March 2026
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

[Adapt as needed — pick one:]

- **MESS** — Message Classes (SE91) — 73-character limit
- **DTEL** — Data Elements (SE11) — limits: Short=10, Medium=20, Long=40, Heading=55
- **DOMA** — Domains (SE11) — fixed value text limit: 60 characters
- **FUGR/FUNC** — Function Groups/Modules — descriptive texts
- **PROG** — Program texts / Selection texts
- **OTR** — Online Text Repository
- **TABL** — Table/Structure field labels

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

### 2. Placeholder Preservation (CRITICAL)
Keep ALL placeholder symbols exactly as in the original:
- `&`, `&1`, `&2`, `&3`, `&4`
- `&V1&`, `&V2&`
- `%1`, `%2`
- Do NOT translate, do NOT reposition (unless required by German grammar)

### 3. Character Limit
- Respect the `maxwidth` defined in each `<trans-unit>`
- German text tends to be 20-30% longer than English
- Use standard German abbreviations when necessary (Bsp., inkl., Nr., Lfg., Ber., usw., z.B., ggf., bzgl.)
- If a translation does not fit, prioritize technical clarity over literal translation

### 4. Tone of Voice
- Formal, technical, direct
- Typical of SAP system messages (errors, warnings, information)
- Omit unnecessary articles when space is limited
- Consistent with standard SAP DE message style

### 5. Handling Existing Entries
- **Review ALL entries**, including those that already have a translation (source ≠ target)
- Fix inconsistent or low-quality translations
- Internal separator/comment messages (e.g., `--- 000-009: ...`): translate as well
- Messages that are pure placeholders only (`& & & &`, `&&&&`, `&1 &2 &3 &4`): keep identical to source

### 6. Technical Names and SAP Transactions
- Do NOT translate: transaction codes (SE91, SLG1, CG02, VF01, CM40, COR1, etc.)
- Do NOT translate: table names (TVARVC, STVARV, ZMM_GRPKEY_CONF, etc.)
- Do NOT translate: program names, class names, technical field names
- Do NOT translate: acronyms/codes (RFC, BOM, MRP, EWM, GHS, LSMW, DMS, ATP, FIFO, etc.)
- Do NOT translate: "SAP", "ABAP", "Fiori", "WERCS", "EXCEL", "PDF", "MES"

## Output Format

### XLF File
- Generate a complete, valid `.xlf` file ready for import via LXE_MASTER
- Preserve EXACTLY the XML structure of the original file:
  - Same attributes on `<file>` (original, source-language, target-language, date, category)
  - Same `<trans-unit>` structure (size-unit, approved, maxwidth, id, resname)
  - Keep the `<alt-trans>` block unchanged
- Only modify:
  - The content of the `<target>` element inside `<trans-unit>`
  - The `state` attribute of `<target>` → change to `"translated"`
- Encoding: UTF-8
- Line endings: CRLF (\r\n) — compatible with Windows/SAP GUI
- XML entities: `&` as `&amp;` (maintain correct XML encoding)

## Attached File
[The attached XLF file was exported via LXE_MASTER from system S4D]

## Execution Instructions
1. Analyze the attached XLF file — identify all translation units
2. Translate each `<source>` to DE and place it in the `<target>`
3. Verify that no translation exceeds the `maxwidth`
4. Generate the final XLF file with ALL entries translated
5. Make the file available for download
```

---

## Usage Notes

### When the file is very large (2000+ entries)
Claude may hit context limits. In that case, split the file by message class or object group before uploading, or ask Claude to process in batches and consolidate at the end.

### Post-import verification
After importing via LXE_MASTER, verify in SE91 (for MESS) that:
- Placeholders `&1`, `&2` etc. appear correctly
- Special characters (ö, ü, ä, ß) render correctly
- Text length does not exceed the message limit

### Adapting for other language pairs
Replace `de-DE` with the desired target language and adjust the SAP terminology glossary in the prompt. The XLF structure and placeholder rules are universal.

### Adapting for other object types
Adjust the "Object Type" field and character limits according to the artifact:
- **Data Elements**: 4 fields (short/medium/long/heading) with different limits
- **Domains**: fixed values with 60-char limit
- **Selection Texts**: no hard limit, but UI common sense applies
- **OTR Texts**: may have longer limits, check the XLF maxwidth
