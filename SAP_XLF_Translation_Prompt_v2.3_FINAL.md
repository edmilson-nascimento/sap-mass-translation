# SAP XLF Translation Prompt v2.3 FINAL
## English → German (EN-US → DE-DE)

**Version:** 2.3 FINAL  
**Date:** 2025-03-26  
**Target System:** SAP S/4HANA 2023 SP04  
**Format:** XLIFF 1.2  
**Object Type:** MESS (Message Texts)  
**Character Limit:** 73 characters (HARD LIMIT)

---

## CRITICAL RULES (NON-NEGOTIABLE)

### 1. CHARACTER LIMIT - ABSOLUTE PRIORITY
- **HARD LIMIT:** 73 characters maximum
- **NO EXCEPTIONS:** Even 74 chars will be REJECTED by SAP LXE_MASTER
- **Count includes:** Letters, numbers, spaces, punctuation, placeholders
- **Strategy order:** 
  1. Eliminate ALL English words (saves 20-40%)
  2. Use SAP abbreviations (see table below)
  3. Remove filler words (bitte, falls, etc. when not critical)
  4. Condense compound nouns (Verpackungsgruppe → Verp.-Gruppe)
  5. Use symbols: > instead of "mehr als", & instead of "und"

### 2. PLACEHOLDER SYNTAX - CRITICAL
**Placeholders MUST be plain characters, NOT XML entities:**
```
✅ CORRECT:   &  &1  &2  &3  &4
❌ WRONG:     &amp;  &amp;1  &amp;2  (XML entities - SAP rejects these)
```

### 3. PURE GERMAN TEXT - ZERO TOLERANCE
**FORBIDDEN ENGLISH WORDS (must be translated):**
- Articles: the, a, an
- Verbs: is, are, was, were, do, does, can, will, must, check, select
- Prepositions: to, for, with, by, from, at, in, on
- Conjunctions: and, or, but
- Common nouns: error, warning, data, file, job, log

**Validation checklist:**
- [ ] Count English words = 0
- [ ] German prepositions correct (zu not Bis, für not For)
- [ ] No mixed EN/DE constructions

---

## SAP TERMINOLOGY (Official German)

### Core Objects
| English | German | Abbreviation |
|---------|--------|--------------|
| Company Code | Buchungskreis | BuKr |
| Plant | Werk | - |
| Storage Location | Lagerort | LagOrt |
| Warehouse | Lagernummer | LagNr |
| Cost Center | Kostenstelle | KoSt |
| Material | Material | Mat |
| Batch | Charge | - |
| Serial Number | Seriennummer | SN |
| Equipment | Anlage | Anl. |
| Handling Unit | Handling Unit | HU |

### Documents
| English | German | Abbreviation |
|---------|--------|--------------|
| Sales Order | Kundenauftrag | KA |
| Purchase Order | Bestellung | Best. |
| Delivery | Lieferung | Lief. |
| Sales Document | Verkaufsbeleg | VkBeleg |
| Document | Beleg | - |
| Item/Position | Position | Pos. |
| Specification | Spezifikation | Spez. |
| Certificate | Zertifikat | Zert. |

### Processes
| English | German | Abbreviation |
|---------|--------|--------------|
| Production Order | Fertigungsauftrag | FA |
| Process Order | Prozessauftrag | PA |
| Goods Receipt | Wareneingang | WE |
| Goods Issue | Warenausgang | WA |
| Stock Transfer | Umlagerung | - |
| Physical Inventory | Inventur | - |
| Inspection Lot | Prüflos | - |
| BOM | Stückliste | Stücklist. |
| Picking | Kommissionierung | Kommiss. |
| Shipping | Versand | - |
| Down Payment | Anzahlung | - |
| Reservation | Reservierung | Reserv. |
| MRP | Disposition | Dispo |

### Technical Terms
| English | German | Abbreviation |
|---------|--------|--------------|
| Authorization | Berechtigung | Ber. |
| Partner Function | Partnerfunktion | PartFunk |
| Packaging | Verpackung | Verp. |
| Packaging Group | Verpackungsgruppe | Verp.-Gruppe / Verp.-Gr. |
| Shelf Life | Mindesthaltbarkeit | MHD |
| Characteristic | Merkmal | - |
| Field | Feld | - |
| Parameter | Parameter | Param. |
| Profile | Profil | - |
| Reference | Referenz | Ref. |
| Identification | Identifikation | Ident. |

### Abbreviations for Length Optimization
| Full Form | Abbreviation | When to Use |
|-----------|--------------|-------------|
| Mindestens | Mind. | Always when over limit |
| Bitte | - | Omit when over limit |
| Position | Pos. | Always |
| Lagerort | LagOrt | When needed |
| Lagernummer | LagNr | When needed |
| Verpackung | Verp. | Always |
| Spezifikation | Spez. | Always |
| Zertifikat | Zert. | Always |
| Berechtigung | Ber. | When needed |
| Kommissionierung | Kommiss. | When needed |
| Übertragung | Übertr. | When over limit |
| Mehrwegverpackung | Mehrwegverp. | Always |
| Gruppe | Gr. | When over limit |
| und | u. | When over limit |

---

## LENGTH OPTIMIZATION STRATEGIES

### Strategy A: Eliminate English Words (HIGHEST PRIORITY - 20-40% savings)
```
❌ "It can be due Bis many reasons"
✅ "Mehrere Gründe möglich"
   Savings: 15 chars (English words removed)

❌ "do not correspond Bis the"  
✅ "entspricht nicht"
   Savings: 10 chars (English words removed)
```

### Strategy B: Use SAP Abbreviations
```
❌ "Verpackungsgruppe" (17 chars)
✅ "Verp.-Gruppe" (12 chars) or "Verp.-Gr." (9 chars)

❌ "Position" (8 chars)
✅ "Pos." (4 chars)

❌ "Mindestens" (10 chars)
✅ "Mind." (5 chars)
```

### Strategy C: Condense Verbal Constructions
```
❌ "wurde aktualisiert um zu entsprechen" (37 chars)
✅ "angepasst an" (12 chars)

❌ "ist nicht möglich" (18 chars)
✅ "unmöglich" (9 chars)

❌ "muss gepflegt werden" (20 chars)
✅ "pflegen Sie" (11 chars)
```

### Strategy D: Merge Compound Nouns
```
❌ "Verkaufs Beleg" (14 chars)
✅ "Verkaufsbeleg" (13 chars)

❌ "Lager Nummer" (12 chars)
✅ "Lagernummer" (11 chars)

❌ "Job Logs" (8 chars)
✅ "Joblogs" (7 chars)
```

### Strategy E: Remove Filler Words
```
❌ "Bitte prüfen Sie"
✅ "Prüfen Sie"
   (Only remove if over limit)

❌ "Falls keine Palette"
✅ "Sonst"
   (When desperate for space)
```

### Strategy F: Use Symbols and Punctuation
```
❌ "mehr als 1" (10 chars)
✅ ">1" (2 chars)

❌ "und" (3 chars)
✅ "u." (2 chars) - only when over limit
```

---

## CORRECT GERMAN PREPOSITIONS

| English | ❌ WRONG | ✅ CORRECT |
|---------|----------|-----------|
| to | Bis, Bei | zu, nach, an |
| for | Bis, Bei | für |
| with | Durch, Bei | mit |
| by | Durch, Bis | per, durch |
| from | Bei | von, aus |
| at | Bis, Durch | bei, an, auf |
| in | Bei | in, im |
| due to | Bis | wegen, aufgrund |
| in order to | Bis | um...zu |

**Common ERROR patterns from real data:**
```
❌ "It can be due Bis many reasons"
✅ "Mehrere Gründe möglich"

❌ "Aktualisiert Bis match"
✅ "Angepasst an"

❌ "Durch the E-Mail"
✅ "per E-Mail"
```

---

## REAL EXAMPLES FROM 2,006 MESSAGE TRANSLATION

### Example 1: Mixed EN/DE + Wrong Preposition (84 chars → 73 chars)
```
❌ "The Incoterm Bei header Stufe wurde Aktualisiert Bis match the Positionen Incoterm"
✅ "Incoterm auf Header-Ebene angepasst an Positionsincoterm"

Changes applied:
- Removed ALL English words (The, header, the, match)
- Fixed preposition: Bei → auf, Bis → an
- Condensed: "wurde aktualisiert um zu entsprechen" → "angepasst an"
- Merged: "Positionen Incoterm" → "Positionsincoterm"
```

### Example 2: Redundancy + Mixed Language (82 chars → 56 chars)
```
❌ "Lagernummer Nummer do not correspond Bis the Handling Einheit Lagernummer Nummer."
✅ "Lagernummer entspricht nicht Handling-Unit-Lagernummer."

Changes applied:
- Removed redundancy: "Lagernummer Nummer" → "Lagernummer"
- Eliminated English: "do not correspond" → "entspricht nicht"
- Removed wrong preposition: "Bis the"
- Merged compound: "Handling Einheit" → "Handling-Unit"
```

### Example 3: Verbose Construction (78 chars → 73 chars)
```
❌ "Import of SDS Fehlgeschlagen. It can be due Bis many reasons. Prüfen Job Logs."
✅ "SDS-Import fehlgeschlagen. Mehrere Gründe möglich. Prüfen Sie Joblogs."

Changes applied:
- Condensed: "Import of SDS" → "SDS-Import"
- Eliminated English + preposition: "It can be due Bis many reasons" → "Mehrere Gründe möglich"
- Merged: "Job Logs" → "Joblogs"
```

### Example 4: Long Compound Words (84 chars → 70 chars)
```
❌ "Mind. 1 Position aus Umpack-/Neuetikettierungs-Prozessauftragsliste wählen."
✅ "Mind. 1 Pos. aus Umpack-/Neuetikettierungs-Prozessauftragsliste wählen"

Changes applied:
- Abbreviated: "Position" → "Pos."
- Removed period at end (not critical)
```

### Example 5: Technical Abbreviations (82 chars → 68 chars)
```
❌ "Paletten müssen mehr als 1 SN haben. Falls keine Palette \"Enter\" für Überspringen."
✅ "Paletten müssen >1 SN haben. Sonst 'Enter' zum Überspringen drücken."

Changes applied:
- Symbol: "mehr als" → ">"
- Condensed: "Falls keine Palette" → "Sonst"
- Simplified: "für Überspringen" → "zum Überspringen drücken"
```

### Example 6: Multi-word Reduction (74 chars → 71 chars)
```
❌ "UN-gelistete Substanz für UN &1, Verpackungsgruppe &2 Verordnung &3 nicht gefunden"
✅ "UN-gelistete Substanz für UN &1, Verp.-Gr. &2 Verord. &3 nicht gefunden"

Changes applied:
- Abbreviated: "Verpackungsgruppe" → "Verp.-Gr."
- Abbreviated: "Verordnung" → "Verord."
```

### Example 7: Preposition Fix + Condensing (75 chars → 68 chars)
```
❌ "Beenden vor Bestätigung Rückgabeaufgaben? Umlagerungsaufgaben bleiben offen"
✅ "Beenden vor Bestätigung Rückgaben? Umlagerungsaufgaben bleiben offen"

Changes applied:
- Shortened: "Rückgabeaufgaben" → "Rückgaben" (context is clear)
```

### Example 8: Transfer Context (78 chars → 70 chars)
```
❌ "Fertigware nicht übertragen zu Mehrwegverpackungs-HU &1. Bestand auf Ressource"
✅ "Fertigware-Übertr. zu Mehrwegverp.-HU &1 fehlgeschlagen. Auf Ressource"

Changes applied:
- Compound: "Fertigware nicht übertragen" → "Fertigware-Übertr."
- Abbreviated: "Mehrwegverpackungs" → "Mehrwegverp."
- Added clarity: "fehlgeschlagen" (failure explicit)
```

---

## POST-GENERATION VALIDATION CHECKLIST

After generating each translation, verify:

1. **Character count ≤ 73**
   - Count manually or programmatically
   - Include ALL characters (spaces, punctuation, placeholders)

2. **Pure German text**
   - Scan for ANY English words
   - English word count MUST = 0

3. **Correct placeholders**
   - Placeholders: `&` `&1` `&2` `&3` `&4` (plain chars)
   - NOT: `&amp;` `&amp;1` (XML entities)

4. **German prepositions**
   - No "Bis" for "to/for"
   - No "Bei" for "at/to"
   - No "Durch" for "by" (use "per")

5. **Compound nouns merged**
   - "Verkaufsbeleg" not "Verkaufs Beleg"
   - "Lagernummer" not "Lager Nummer"

6. **Natural German flow**
   - Reads naturally to native speaker
   - No awkward word order

---

## TRANSLATION WORKFLOW

For each message:

1. **Read source text** and understand context
2. **Count source length** to estimate compression needed
3. **Draft translation** using SAP terminology
4. **Count characters** - if >73, optimize:
   - Apply Strategy A (eliminate English) FIRST
   - Then Strategy B (abbreviations)
   - Then C-F as needed
5. **Validate** against checklist above
6. **Final check:** Count one more time

---

## SPECIAL CASES

### Decorative Lines (dashes/asterisks)
```
Original: "----------Selected Calculation Parameters--------------------------------"
German:   "----------Gewählte Berechnungsparameter----------------------------------"
Rule: Translate the text part, adjust dash count to reach 73 chars exactly
```

### Error Messages with Technical Codes
```
Original: "Error to execute CM40 with parameters and profile &. Job was not created."
German:   "Fehler bei CM40-Ausführung mit Parametern u. Profil &. Job nicht angelegt"
Rule: Keep technical codes (CM40) unchanged, compress rest
```

### Multiple Placeholders
```
Original: "Sales Order/Item &/&: Open Quantity and Confirmed Quantity are different."
German:   "Kundenauftrag/Pos. &/&: Offenmenge u. bestätigte Menge unterschiedlich"
Rule: Placeholders (&/&) count as 3 chars total
```

### Questions/Confirmations
```
Original: "Exit before confirming return tasks? Transfer tasks will remain pending."
German:   "Beenden vor Bestätigung Rückgaben? Umlagerungsaufgaben bleiben offen"
Rule: Keep question format, condense explanation
```

---

## COMMON PITFALLS TO AVOID

### ❌ Pitfall 1: XML Entities in Placeholders
```
WRONG: "Parameter &amp;1 ist erforderlich"
RIGHT: "Parameter &1 ist erforderlich"
```

### ❌ Pitfall 2: Keeping English Words
```
WRONG: "Sales Order wurde aktualisiert"
RIGHT: "Kundenauftrag wurde aktualisiert"
```

### ❌ Pitfall 3: Wrong Prepositions
```
WRONG: "Aktualisiert Bis entsprechen"
RIGHT: "Aktualisiert um zu entsprechen" OR BETTER: "Angepasst an"
```

### ❌ Pitfall 4: Ignoring Character Limit
```
WRONG: "Die Verpackungsgruppe für den Gefahrguttransport wurde nicht gefunden" (74 chars)
RIGHT: "Verp.-Gr. für Gefahrguttransport nicht gefunden" (48 chars)
```

### ❌ Pitfall 5: Separated Compound Nouns
```
WRONG: "Verkaufs Beleg und Kunden Auftrag"
RIGHT: "Verkaufsbeleg und Kundenauftrag"
```

---

## VERSION HISTORY

### v2.3 FINAL (2025-03-26)
**Added:**
- Character limit as ABSOLUTE PRIORITY (73 chars hard limit)
- Strategy A: Eliminate English words FIRST (highest impact)
- 8 real examples from 2,006 message corpus showing before/after
- Extended abbreviation table with "when to use" guidance
- Special cases: decorative lines, technical codes, multiple placeholders
- Symbol usage: > for "mehr als", u. for "und"
- Explicit "Count one more time" reminder in workflow

**Fixed:**
- Reordered strategies by impact (English elimination first)
- Added explicit char count examples (82→56, 84→73, etc.)
- Clarified abbreviation usage (always vs. when needed vs. when over limit)

### v2.2 (2025-03-25)
**Added:**
- Pure German text section with zero tolerance policy
- Correct German prepositions table with error examples
- 8 real examples from 182 length violation analysis
- Post-generation checklist with validation steps

**Fixed:**
- Placeholder syntax documentation (& not &amp;)
- Mixed EN/DE elimination strategy
- Wrong preposition patterns from real data

### v2.1 (2025-03-25)
**Added:**
- Visual XML examples for correct/incorrect placeholder syntax
- Explicit instruction: use & plain, NOT &amp;
- Abbreviations table (18 entries)
- 5 optimization techniques
- 5 real violation examples

**Fixed:**
- CRITICAL BUG: Changed "XML entities: & as &amp;" to correct syntax
- Clarified placeholder handling

### v2.0 (2025-03-25)
**Initial comprehensive version**
- SAP terminology (40+ terms)
- Basic placeholder rules
- Generic length optimization
- Standard German grammar

---

## FINAL REMINDER

**The #1 cause of import failures was: EXCEEDING 73 CHARACTERS**

Even one character over (74) will cause SAP LXE_MASTER to reject the translation.

**Always count twice. Better to be at 70 chars with clear meaning than at 74 chars with perfect prose.**

---

**End of Prompt v2.3 FINAL**
