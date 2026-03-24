# SAP S/4HANA Localization — XLF Translation Prompt Template

> **Objetivo:** Prompt reutilizável para tradução massiva de objetos Z* custom via ficheiros XLF (XLIFF 1.2), para importação em SAP via LXE_MASTER.
>
> **Versão:** 2.0 — Março 2026
>
> **Contexto:** Projeto de Rollout SAP S/4HANA 2023 — Localização EN→DE

---

## Como Usar

1. Iniciar um novo chat com Claude
2. Fazer upload do ficheiro `.xlf` exportado da LXE_MASTER
3. Colar o prompt abaixo (adaptar os campos entre `[colchetes]` conforme necessário)
4. Importar o ficheiro gerado de volta na LXE_MASTER

---

## Prompt

```
## Contexto do Projeto

Projeto de Rollout SAP S/4HANA 2023 (on-premise). Localização de objetos custom (namespace Z*) do Inglês (EN) para o Alemão (DE). Os ficheiros XLF são exportados/importados via transação LXE_MASTER.

## Seu Papel

Você é um Consultor SAP Sênior e Especialista em Localização (Tradução Técnica SAP). Sua tarefa é traduzir o conteúdo do ficheiro XLF anexado, gerando um novo ficheiro XLF pronto para reimportação.

## Tipo de Objeto a Traduzir

[Adaptar conforme o caso — escolher um:]

- **MESS** — Message Classes (SE91) — limite de 73 caracteres
- **DTEL** — Data Elements (SE11) — limites: Short=10, Medium=20, Long=40, Heading=55
- **DOMA** — Domains (SE11) — limite do fixed value text: 60 caracteres
- **FUGR/FUNC** — Function Groups/Modules — textos descritivos
- **PROG** — Program texts / Selection texts
- **OTR** — Online Text Repository
- **TABL** — Table/Structure field labels

## Regras de Tradução (OBRIGATÓRIO)

### 1. Terminologia SAP Oficial
Usar o glossário oficial SAP DE. Referências-chave:
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
| Warehouse | Lagernummer |
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

### 2. Preservação de Variáveis (CRÍTICO)
Manter TODOS os placeholders exatamente como no original:
- `&`, `&1`, `&2`, `&3`, `&4`
- `&V1&`, `&V2&`
- `%1`, `%2`
- Não traduzir, não reposicionar (exceto se necessário pela gramática alemã)

### 3. Limite de Caracteres
- Respeitar o `maxwidth` definido em cada `<trans-unit>`
- O Alemão tende a ser 20-30% mais longo que o Inglês
- Usar abreviações alemãs padrão quando necessário (Bsp., inkl., Nr., Lfg., Ber., usw.)
- Se uma tradução não cabe, priorizar clareza técnica sobre tradução literal

### 4. Tom de Voz
- Formal, técnico, direto
- Típico de mensagens de sistema SAP (erros, avisos, informações)
- Sem artigos desnecessários quando o espaço é limitado
- Consistente com o estilo das mensagens standard SAP em DE

### 5. Tratamento de Entradas Existentes
- **Revisar TODAS as entradas**, incluindo as que já têm tradução (source ≠ target)
- Corrigir traduções inconsistentes ou de baixa qualidade
- Mensagens que são separadores/comentários internos (ex: `--- 000-009: ...`): traduzir também
- Mensagens que são apenas placeholders puros (`& & & &`, `&&&&`, `&1 &2 &3 &4`): manter iguais ao source

### 6. Nomes Técnicos e Transações SAP
- NÃO traduzir: nomes de transações (SE91, SLG1, CG02, VF01, etc.)
- NÃO traduzir: nomes de tabelas (TVARVC, ZMM_GRPKEY_CONF, etc.)
- NÃO traduzir: nomes de programas, classes, campos técnicos
- NÃO traduzir: códigos (RFC, BOM, MRP, EWM, GHS, LSMW, etc.)
- NÃO traduzir: "SAP", "ABAP", "Fiori", "WERCS", "EXCEL"

## Formato do Output

### Ficheiro XLF
- Gerar um ficheiro `.xlf` completo e válido, pronto para importação via LXE_MASTER
- Preservar EXATAMENTE a estrutura XML do ficheiro original:
  - Mesmos atributos em `<file>` (original, source-language, target-language, date, category)
  - Mesma estrutura de `<trans-unit>` (size-unit, approved, maxwidth, id, resname)
  - Manter o bloco `<alt-trans>` inalterado
- Alterar apenas:
  - O conteúdo do elemento `<target>` dentro de `<trans-unit>`
  - O atributo `state` do `<target>` → mudar para `"translated"`
- Encoding: UTF-8
- Line endings: CRLF (\r\n) — compatível com Windows/SAP GUI
- XML entities: `&` como `&amp;` (manter encoding XML correto)

## Ficheiro Anexado
[O ficheiro XLF em anexo foi exportado via LXE_MASTER do sistema S4D]

## Instruções de Execução
1. Analisar o ficheiro XLF anexado — identificar todas as translation units
2. Traduzir cada `<source>` para DE e colocar no `<target>`
3. Verificar que nenhuma tradução excede o `maxwidth`
4. Gerar o ficheiro XLF final com TODAS as entradas traduzidas
5. Disponibilizar o ficheiro para download
```

---

## Notas de Uso

### Quando o ficheiro é muito grande (2000+ entradas)
O Claude pode atingir limites de contexto. Nesse caso, dividir o ficheiro por message class ou grupo de objetos antes do upload, ou pedir ao Claude para processar em blocos e consolidar no final.

### Verificação pós-importação
Após importar via LXE_MASTER, verificar na SE91 (para MESS) se:
- Os placeholders `&1`, `&2` etc. aparecem corretamente
- Os caracteres especiais (ö, ü, ä, ß) estão corretos
- O comprimento não excede o limite da mensagem

### Adaptação para outros pares de idiomas
Substituir `de-DE` pelo target language desejado e ajustar a terminologia SAP e o glossário no prompt. A estrutura XLF e as regras de placeholders são universais.

### Adaptação para outros tipos de objeto
Ajustar o campo "Tipo de Objeto" e os limites de caracteres conforme o artefato:
- **Data Elements**: 4 campos (short/medium/long/heading) com limites diferentes
- **Domains**: fixed values com limite de 60 chars
- **Selection Texts**: geralmente sem limite fixo, mas bom senso de UI
