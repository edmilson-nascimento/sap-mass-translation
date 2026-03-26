# Z_CHECK_TRANSLATIONS_V2 - Text Elements Configuration

Execute **SE38** > Program `Z_CHECK_TRANSLATIONS_V2` > **Goto** > **Text Elements**

---

## Selection Texts

| Field Name | Description (max 30 chars) |
|------------|----------------------------|
| `S_TABNM`  | Table name pattern |
| `P_LIMIT`  | Max tables to analyze |
| `P_MAXREC` | Skip tables > this count |
| `P_OK`     | Include OK records |
| `P_MISS`   | Include MISSING records |
| `P_COPY`   | Include COPY records |
| `P_NOBASE` | Include NO_BASE records |

---

## Text Symbols

| Symbol | Text |
|--------|------|
| `B01`  | Table Selection |
| `B02`  | Processing Limits |
| `B03`  | Status Filter |
| `B04`  | Status Legend (DE Translation) |
| `L01`  | OK = DE exists and differs from EN |
| `L02`  | MISSING = DE translation is empty |
| `L03`  | COPY = DE is identical to EN (likely untranslated) |
| `L04`  | NO_BASE = EN is empty (no reference for translation) |

---

## Quick Setup Steps

1. Open **SE38** > Enter program `Z_CHECK_TRANSLATIONS_V2`
2. Click **Goto** → **Text Elements** → **Selection Texts**
3. Fill in the descriptions from the **Selection Texts** table above
4. Click **Text Symbols** tab
5. Fill in the texts from the **Text Symbols** table above
6. **Save** and **Activate**

---

## Structure Overview

```
┌─ Status Filter (B03) ──────────────────────┐
│ ☑ Include OK records                       │
│ ☑ Include MISSING records                  │
│ ☑ Include COPY records                     │
│ ☑ Include NO_BASE records                  │
│                                             │
│ ┌─ Status Legend (B04) ──────────────────┐ │
│ │ OK = DE exists and differs from EN     │ │
│ │ MISSING = DE translation is empty      │ │
│ │ COPY = DE is identical to EN (copied)  │ │
│ │ NO_BASE = EN is empty (no reference)   │ │
│ └────────────────────────────────────────┘ │
└─────────────────────────────────────────────┘
```

**Design Rationale:** Checkboxes are positioned first for frequent users who go directly to filters. Legend is nested below for occasional reference.
