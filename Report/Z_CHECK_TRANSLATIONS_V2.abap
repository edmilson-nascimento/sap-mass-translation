REPORT z_check_translations_v2.

" ========================================================================
" Program     : Z_CHECK_TRANSLATIONS_V2
" Description : Check EN / FR / DE translation coverage in DDIC
"               transparent tables that contain a language key field.
" Platform    : SAP S/4HANA 2023 / ABAP Platform 2023 SP04
" Author      : (c) 2026
" ========================================================================
"
" PURPOSE
" -------
" Scans customizing and text tables (e.g. T*, TV*, MAKT, CSKT) and
" reports which entries are missing a German (DE) translation or have
" a DE text that is an untranslated copy of the English (EN) original.
" The output can be used as a work list to create or complete
" translations via SE63 / transaction maintenance.
"
" The program detects four kinds of translation states:
"   OK      – The DE translation exists and differs from EN.
"   MISSING – The DE translation does not exist (field is empty).
"   COPY    – The DE translation exists but is identical to EN,
"             indicating it was likely created by copy and never
"             actually translated.
"   NO_BASE – The EN source text is empty, so there is no reference
"             to translate from. The entry should be reviewed.
"
" ========================================================================
" OBJECTS
" ========================================================================
"
" Selection screen
"   Block B01 – Table Selection
"     S_TABNM   : Select-option for table names (pattern or exact)
"   Block B02 – Processing Limits
"     P_LIMIT   : Max. number of tables to analyze (default 300)
"     P_MAXREC  : Safety net — skip tables with more than N total rows
"                 (default 1.000.000). Prevents accidental full-scans
"                 of large transactional tables.
"   Block B03 – Status Legend
"     Informational block displayed before execution. Shows the
"     meaning of each STATUS value in the output (OK/MISSING/COPY).
"     Uses SELECTION-SCREEN COMMENT with text symbols L01–L03.
"
" Text elements to maintain (SE38 > Goto > Text Elements):
"
"   Selection Texts:
"     S_TABNM   -> Table name pattern (e.g. T*, MAKT)
"     P_LIMIT   -> Max tables to analyze
"     P_MAXREC  -> Skip tables exceeding this row count
"
"   Text Symbols:
"     B01       -> Table Selection
"     B02       -> Processing Limits
"     B03       -> Status Legend (DE Translation)
"     L01       -> OK = DE exists and differs from EN
"     L02       -> MISSING = DE translation is empty
"     L03       -> COPY = DE is identical to EN (likely untranslated)
"     L04       -> NO_BASE = EN is empty (no reference for translation)
"
" Output columns (ALV):
"   STATUS       – DE translation status: OK, MISSING, or COPY
"   TABNAME      – DDIC table name
"   FIELD_NAME   – Name of the text field being compared
"   FIELD_LENGTH – DDIC length of the text field (max chars for translation)
"   KEY_STRING   – Composite primary key (all PK fields except language)
"   TEXT_EN      – English text (sample field content for language E)
"   TEXT_FR      – French text (sample field content for language F)
"   TEXT_DE      – German text (sample field content for language D)
"
" Local class : LCL_TRANSLATION_CHECKER
"   Public methods:
"     CONSTRUCTOR        – (no-op, defaults in INITIALIZATION event)
"     RUN                – orchestrate discovery + data retrieval
"     DISPLAY            – render results via CL_SALV_TABLE
"   Private methods:
"     DISCOVER_TABLES    – query DD02L/DD03L to find candidate tables
"                          that own a language key field; skip oversized
"                          tables via IS_TABLE_OVERSIZED.
"     PROCESS_TABLE      – for a given table, call SELECT_BY_LANGUAGE
"                          three times (EN, FR, DE) and pivot the rows
"                          into a single result line per composite key.
"                          Determine STATUS per row based on DE vs EN.
"     SELECT_BY_LANGUAGE – fetch ALL rows for one language from a
"                          dynamic table (no UP TO — config tables are
"                          expected to be small).
"     IS_TABLE_OVERSIZED – SELECT COUNT(*) UP TO P_MAXREC to decide
"                          whether a table should be skipped.
"     MAKE_KEY_STRING    – build a readable composite key string from
"                          the PK fields of a dynamic row.
"     SHOW_PROGRESS      – SAPGUI_PROGRESS_INDICATOR wrapper.
"
" ========================================================================
" PROCESSING FLOW
" ========================================================================
"
" 1. INITIALIZATION
"      Pre-fill S_TABNM with default patterns (T*, TV*, MAKT, etc.)
"      so the user sees them on the selection screen.
"
" 2. START-OF-SELECTION
"      Instantiate LCL_TRANSLATION_CHECKER and call RUN → DISPLAY.
"
" 3. DISCOVER_TABLES
"      a) SELECT DISTINCT from DD02L/DD03L where TABCLASS = 'TRANSP'
"         and the table has a field whose domain or rollname is SPRAS.
"      b) For each candidate, check row count (IS_TABLE_OVERSIZED).
"         Tables exceeding P_MAXREC are logged and skipped.
"      c) Read DD03L field catalog. Determine:
"           - Language field : first match SPRAS > LANGU > domain SPRAS
"           - Key fields     : all PK fields except the language field
"           - Sample field   : the FIRST non-key field whose DDIC data
"             type is CHAR, STRG or SSTR. This is the field whose
"             content is shown in the EN/FR/DE columns.  Its name and
"             length are also exposed so the user knows the target
"             field and the maximum number of characters available
"             when creating a translation.
"
" 4. PROCESS_TABLE
"      Three independent SELECTs (one per language) guarantee that no
"      language can be silently dropped — which was the bug in the
"      original single-SELECT approach.
"      Rows are pivoted into a hashed table keyed by composite PK.
"      STATUS is determined per entry:
"        - DE is empty                    → MISSING
"        - EN is empty                    → NO_BASE
"        - DE = EN (both non-empty)       → COPY
"        - DE differs from EN             → OK
"
" 5. DISPLAY
"      CL_SALV_TABLE output. Entries with issues (MISSING, COPY) are
"      sorted first.  The list header shows the number of tables and
"      records processed with thousand separators.
"      A plain WRITE fallback exists in case SALV raises an exception.
"
" ========================================================================
" CHANGE LOG
" ========================================================================
" Date        Author   Description
" ----------  -------  --------------------------------------------------
" 2026-xx-xx  JESUSEDM Initial version: 3 SELECTs per language, safety
"                      net via COUNT(*), FIELD_NAME/FIELD_LENGTH columns,
"                      STATUS column with 4 states (OK/MISSING/COPY/
"                      NO_BASE) for DE translation analysis, selection
"                      screen legend, thousand separators in ALV header.
" ========================================================================

" ----------------------------------------------------------------------
" Types
" ----------------------------------------------------------------------
TYPES: BEGIN OF ty_tabmeta,
         tabname      TYPE dd02l-tabname,
         lang_field   TYPE dd03l-fieldname,
         key_fields   TYPE string,
         sample_field TYPE dd03l-fieldname,
         sample_leng  TYPE dd03l-leng,
       END OF ty_tabmeta.

TYPES: BEGIN OF ty_result,
         status       TYPE char10,
         tabname      TYPE dd02l-tabname,
         field_name   TYPE dd03l-fieldname,
         field_length TYPE dd03l-leng,
         key_string   TYPE string,
         text_en      TYPE string,
         text_fr      TYPE string,
         text_de      TYPE string,
       END OF ty_result.

" ----------------------------------------------------------------------
" Selection screen
" ----------------------------------------------------------------------
" --- Block 1: Table selection ---
SELECTION-SCREEN BEGIN OF BLOCK b01 WITH FRAME TITLE TEXT-b01.
  SELECT-OPTIONS s_tabnm FOR sy-repid NO INTERVALS LOWER CASE. "Table name pattern
SELECTION-SCREEN END OF BLOCK b01.

" --- Block 2: Processing limits ---
SELECTION-SCREEN BEGIN OF BLOCK b02 WITH FRAME TITLE TEXT-b02.
  PARAMETERS:
    p_limit  TYPE i DEFAULT 300,     "Max tables to analyze
    p_maxrec TYPE i DEFAULT 1000000. "Skip tables exceeding this row count
SELECTION-SCREEN END OF BLOCK b02.

" --- Block 3: Status legend (informational, no input fields) ---
" Text symbols L01–L04 hold the legend lines.
SELECTION-SCREEN BEGIN OF BLOCK b03 WITH FRAME TITLE TEXT-b03.
  SELECTION-SCREEN COMMENT /1(70) TEXT-l01.  "OK = DE exists and differs from EN
  SELECTION-SCREEN COMMENT /1(70) TEXT-l02.  "MISSING = DE translation is empty
  SELECTION-SCREEN COMMENT /1(70) TEXT-l03.  "COPY = DE is identical to EN (likely untranslated)
  SELECTION-SCREEN COMMENT /1(70) TEXT-l04.  "NO_BASE = EN is empty (no reference for translation)
SELECTION-SCREEN END OF BLOCK b03.

" ----------------------------------------------------------------------
" Class definition
" ----------------------------------------------------------------------
CLASS lcl_translation_checker DEFINITION FINAL.
  PUBLIC SECTION.
    METHODS constructor.
    METHODS run.
    METHODS display.

  PRIVATE SECTION.
    CONSTANTS c_en TYPE spras VALUE 'E'.
    CONSTANTS c_fr TYPE spras VALUE 'F'.
    CONSTANTS c_de TYPE spras VALUE 'D'.

    CONSTANTS c_status_ok      TYPE char10 VALUE 'OK'.
    CONSTANTS c_status_missing TYPE char10 VALUE 'MISSING'.
    CONSTANTS c_status_copy    TYPE char10 VALUE 'COPY'.
    CONSTANTS c_status_nobase  TYPE char10 VALUE 'NO_BASE'.

    " Structure for DD03L field catalog (avoids inline type conflicts)
    TYPES: BEGIN OF ty_fdesc,
             fieldname TYPE dd03l-fieldname,
             keyflag   TYPE dd03l-keyflag,
             position  TYPE dd03l-position,
             datatype  TYPE dd03l-datatype,
             leng      TYPE dd03l-leng,
             domname   TYPE dd03l-domname,
             rollname  TYPE dd03l-rollname,
           END OF ty_fdesc.

    DATA gt_meta    TYPE STANDARD TABLE OF ty_tabmeta WITH EMPTY KEY.
    DATA gt_result  TYPE STANDARD TABLE OF ty_result WITH EMPTY KEY.
    DATA gt_skipped TYPE STANDARD TABLE OF dd02l-tabname WITH EMPTY KEY.

    METHODS discover_tables.

    METHODS process_table
      IMPORTING
        is_meta TYPE ty_tabmeta.

    "! Fetch all rows for a single language from a dynamic table.
    "! No row limit — config/text tables are expected to be small.
    "! @parameter is_meta     | Table metadata
    "! @parameter iv_language | Language key (E, F, D)
    "! @parameter ct_target   | Target internal table — rows are APPENDed
    METHODS select_by_language
      IMPORTING
        is_meta     TYPE ty_tabmeta
        iv_language TYPE spras
      CHANGING
        ct_target   TYPE ANY TABLE.

    "! Check whether a table exceeds the safety threshold (P_MAXREC).
    "! Uses SELECT COUNT(*) UP TO — nearly instant on HANA.
    "! @parameter iv_tabname       | Table name
    "! @parameter rv_is_oversized  | ABAP_TRUE if row count >= P_MAXREC
    METHODS is_table_oversized
      IMPORTING
        iv_tabname             TYPE dd02l-tabname
      RETURNING
        VALUE(rv_is_oversized) TYPE abap_bool.

    METHODS make_key_string
      IMPORTING
        it_keys       TYPE stringtab
        is_row        TYPE any
      RETURNING
        VALUE(rv_key) TYPE string.

    METHODS show_progress
      IMPORTING
        iv_text TYPE string
        iv_cur  TYPE i
        iv_tot  TYPE i.
ENDCLASS.


" ----------------------------------------------------------------------
" Class implementation
" ----------------------------------------------------------------------
CLASS lcl_translation_checker IMPLEMENTATION.

  METHOD constructor.
    " Defaults are handled in INITIALIZATION event
  ENDMETHOD.


  METHOD run.
    DATA lv_total TYPE i.
    DATA lv_idx   TYPE i.

    discover_tables( ).

    IF gt_meta IS INITIAL.
      MESSAGE 'No candidate tables found for the given selection.' TYPE 'S'
              DISPLAY LIKE 'W'.
      RETURN.
    ENDIF.

    lv_total = lines( gt_meta ).
    lv_idx   = 0.

    LOOP AT gt_meta ASSIGNING FIELD-SYMBOL(<m>).
      lv_idx += 1.
      show_progress( iv_text = |Processing { <m>-tabname } ({ lv_idx }/{ lv_total })|
                     iv_cur  = lv_idx
                     iv_tot  = lv_total ).
      process_table( <m> ).
    ENDLOOP.

    " Sort: issues first (COPY, MISSING before OK), then by table and key
    SORT gt_result BY status     DESCENDING
                      tabname    ASCENDING
                      key_string ASCENDING.

    " Inform user about skipped tables
    IF gt_skipped IS NOT INITIAL.
      MESSAGE |{ lines( gt_skipped ) } table(s) skipped — exceeded { p_maxrec } rows.|
              TYPE 'S' DISPLAY LIKE 'W'.
    ENDIF.
  ENDMETHOD.


  METHOD discover_tables.
    DATA lt_cand       TYPE STANDARD TABLE OF dd02l-tabname WITH NON-UNIQUE KEY table_line.
    DATA lt_fdesc      TYPE STANDARD TABLE OF ty_fdesc WITH EMPTY KEY.
    DATA lt_keys       TYPE stringtab.
    DATA lv_lang_field TYPE dd03l-fieldname.
    DATA lv_sample     TYPE dd03l-fieldname.
    DATA lv_sample_len TYPE dd03l-leng.
    DATA lv_keys_csv   TYPE string.
    DATA lv_total      TYPE i.
    DATA lv_scanned    TYPE i.

    SELECT DISTINCT d2~tabname
      FROM dd02l AS d2
             INNER JOIN dd03l AS d3
               ON d3~tabname = d2~tabname
      INTO TABLE @lt_cand
      WHERE d2~tabclass  = 'TRANSP'
        AND d2~tabname  IN @s_tabnm
        AND (    d3~fieldname = 'SPRAS'
              OR d3~fieldname = 'LANGU'
              OR d3~domname   = 'SPRAS'
              OR d3~domname   = 'SYLANGU'
              OR d3~rollname  = 'SPRAS' ).

    IF sy-subrc <> 0 OR lt_cand IS INITIAL.
      RETURN.
    ENDIF.

    SORT lt_cand BY table_line.
    DELETE ADJACENT DUPLICATES FROM lt_cand.

    lv_total   = lines( lt_cand ).
    lv_scanned = 0.

    LOOP AT lt_cand ASSIGNING FIELD-SYMBOL(<tab>).
      lv_scanned += 1.

      IF lv_scanned > p_limit.
        MESSAGE |Limit reached ({ p_limit } tables). | &&
                |{ lv_total - lv_scanned + 1 } tables skipped.|
                TYPE 'S' DISPLAY LIKE 'W'.
        EXIT.
      ENDIF.

      show_progress( iv_text = |Analyzing metadata: { <tab> }|
                     iv_cur  = lv_scanned
                     iv_tot  = lv_total ).

      " --- Safety net: skip tables that are too large ---
      IF is_table_oversized( <tab> ) = abap_true.
        APPEND <tab> TO gt_skipped.
        CONTINUE.
      ENDIF.

      SELECT fieldname, keyflag, position, datatype, leng, domname, rollname
        FROM dd03l
        WHERE tabname = @<tab>
        ORDER BY position
        INTO TABLE @lt_fdesc.

      IF sy-subrc <> 0 OR lt_fdesc IS INITIAL.
        CONTINUE.
      ENDIF.

      " --- Determine language field: SPRAS > LANGU > domain/rollname ---
      CLEAR lv_lang_field.

      LOOP AT lt_fdesc ASSIGNING FIELD-SYMBOL(<fd>).
        IF <fd>-fieldname = 'SPRAS'.
          lv_lang_field = <fd>-fieldname.
          EXIT.
        ENDIF.
      ENDLOOP.

      IF lv_lang_field IS INITIAL.
        LOOP AT lt_fdesc ASSIGNING <fd>.
          IF <fd>-fieldname = 'LANGU'.
            lv_lang_field = <fd>-fieldname.
            EXIT.
          ENDIF.
        ENDLOOP.
      ENDIF.

      IF lv_lang_field IS INITIAL.
        LOOP AT lt_fdesc ASSIGNING <fd>.
          IF    <fd>-domname  = 'SPRAS'
             OR <fd>-domname  = 'SYLANGU'
             OR <fd>-rollname = 'SPRAS'.
            lv_lang_field = <fd>-fieldname.
            EXIT.
          ENDIF.
        ENDLOOP.
      ENDIF.

      IF lv_lang_field IS INITIAL.
        CONTINUE.
      ENDIF.

      " --- Key fields (PK minus the language field) ---
      CLEAR lt_keys.
      CLEAR lv_sample.
      CLEAR lv_sample_len.

      LOOP AT lt_fdesc ASSIGNING <fd>.
        IF <fd>-keyflag = abap_true AND <fd>-fieldname <> lv_lang_field.
          APPEND <fd>-fieldname TO lt_keys.
        ENDIF.
      ENDLOOP.

      " --- Sample text field: first non-key CHAR/STRG/SSTR field ---
      " This is the field whose content appears in the EN/FR/DE columns.
      " Its name and length are shown so the user knows exactly which
      " field to translate and how many characters are available.
      LOOP AT lt_fdesc ASSIGNING <fd>.
        IF <fd>-keyflag = abap_true OR <fd>-fieldname = lv_lang_field.
          CONTINUE.
        ENDIF.
        IF <fd>-datatype = 'CHAR' OR <fd>-datatype = 'STRG' OR <fd>-datatype = 'SSTR'.
          lv_sample     = <fd>-fieldname.
          lv_sample_len = <fd>-leng.
          EXIT.
        ENDIF.
      ENDLOOP.

      lv_keys_csv = REDUCE string(
        INIT acc = ``
        FOR  k IN lt_keys
        NEXT acc = COND #( WHEN acc IS INITIAL
                           THEN k
                           ELSE |{ acc },{ k }| ) ).

      APPEND VALUE ty_tabmeta( tabname      = <tab>
                               lang_field   = lv_lang_field
                               key_fields   = lv_keys_csv
                               sample_field = lv_sample
                               sample_leng  = lv_sample_len )
             TO gt_meta.

    ENDLOOP.

    SORT gt_meta BY tabname.
  ENDMETHOD.


  METHOD process_table.
    DATA lr_data   TYPE REF TO data.
    DATA lt_keys   TYPE stringtab.
    DATA lv_lang   TYPE spras.
    DATA lv_key    TYPE string.
    DATA lv_txt    TYPE string.
    DATA lv_status TYPE char10.

    " --- Build dynamic internal table based on DDIC structure ---
    TRY.
        DATA(lo_struct) = CAST cl_abap_structdescr(
          cl_abap_typedescr=>describe_by_name( is_meta-tabname ) ).
        DATA(lo_tabtyp) = cl_abap_tabledescr=>create( p_line_type = lo_struct ).
        CREATE DATA lr_data TYPE HANDLE lo_tabtyp.
        ASSIGN lr_data->* TO FIELD-SYMBOL(<lt_dyn>).
      CATCH cx_root.
        RETURN.
    ENDTRY.

    " --- Fetch each language independently (no row limit) ---
    select_by_language( EXPORTING is_meta     = is_meta
                                  iv_language = c_en
                        CHANGING  ct_target   = <lt_dyn> ).

    select_by_language( EXPORTING is_meta     = is_meta
                                  iv_language = c_fr
                        CHANGING  ct_target   = <lt_dyn> ).

    select_by_language( EXPORTING is_meta     = is_meta
                                  iv_language = c_de
                        CHANGING  ct_target   = <lt_dyn> ).

    IF <lt_dyn> IS INITIAL.
      RETURN.
    ENDIF.

    " --- Pivot rows into one result line per composite key ---
    SPLIT is_meta-key_fields AT ',' INTO TABLE lt_keys.
    DELETE lt_keys WHERE table_line IS INITIAL.

    TYPES: BEGIN OF ty_pivot,
             key     TYPE string,
             text_en TYPE string,
             text_fr TYPE string,
             text_de TYPE string,
           END OF ty_pivot.

    DATA lt_pivot TYPE HASHED TABLE OF ty_pivot WITH UNIQUE KEY key.

    LOOP AT <lt_dyn> ASSIGNING FIELD-SYMBOL(<row>).
      FIELD-SYMBOLS <lang_fld> TYPE any.
      ASSIGN COMPONENT is_meta-lang_field OF STRUCTURE <row> TO <lang_fld>.
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.

      lv_lang = <lang_fld>.
      lv_key  = make_key_string( it_keys = lt_keys
                                 is_row  = <row> ).

      " Extract sample text
      CLEAR lv_txt.
      IF is_meta-sample_field IS NOT INITIAL.
        FIELD-SYMBOLS <txt_fld> TYPE any.
        ASSIGN COMPONENT is_meta-sample_field OF STRUCTURE <row> TO <txt_fld>.
        IF sy-subrc = 0.
          lv_txt = <txt_fld>.
          CONDENSE lv_txt.
        ENDIF.
      ENDIF.

      " Read existing pivot entry or initialize a new one
      DATA(ls_piv) = VALUE ty_pivot( key = lv_key ).
      READ TABLE lt_pivot WITH TABLE KEY key = lv_key INTO ls_piv.
      IF sy-subrc <> 0.
        ls_piv = VALUE ty_pivot( key = lv_key ).
      ENDIF.

      CASE lv_lang.
        WHEN c_en. ls_piv-text_en = lv_txt.
        WHEN c_fr. ls_piv-text_fr = lv_txt.
        WHEN c_de. ls_piv-text_de = lv_txt.
      ENDCASE.

      " Upsert: insert or modify
      INSERT ls_piv INTO TABLE lt_pivot.
      IF sy-subrc <> 0.
        MODIFY TABLE lt_pivot FROM ls_piv.
      ENDIF.
    ENDLOOP.

    " --- Convert pivot into flat result with STATUS ---
    LOOP AT lt_pivot ASSIGNING FIELD-SYMBOL(<pv>).

      " Determine DE translation status:
      "   MISSING  – DE is empty (regardless of EN)
      "   NO_BASE  – EN is empty (no reference text to translate from)
      "   COPY     – DE = EN and both non-empty (likely untranslated copy)
      "   OK       – DE non-empty, EN non-empty, DE differs from EN
      IF <pv>-text_de IS INITIAL.
        lv_status = c_status_missing.
      ELSEIF <pv>-text_en IS INITIAL.
        lv_status = c_status_nobase.
      ELSEIF <pv>-text_de = <pv>-text_en.
        lv_status = c_status_copy.
      ELSE.
        lv_status = c_status_ok.
      ENDIF.

      APPEND VALUE ty_result(
        status       = lv_status
        tabname      = is_meta-tabname
        field_name   = is_meta-sample_field
        field_length = is_meta-sample_leng
        key_string   = <pv>-key
        text_en      = <pv>-text_en
        text_fr      = <pv>-text_fr
        text_de      = <pv>-text_de
      ) TO gt_result.
    ENDLOOP.
  ENDMETHOD.


  METHOD select_by_language.
    " Build WHERE clause for a single language value.
    " NOTE: iv_language comes from internal constants (c_en, c_fr, c_de),
    " not from user input — no SQL injection risk.
    DATA(lv_where) = |{ is_meta-lang_field } = '{ iv_language }'|.

    SELECT *
      FROM (is_meta-tabname)
      WHERE (lv_where)                           "#EC CI_NOWHERE
      APPENDING TABLE @ct_target.
  ENDMETHOD.


  METHOD is_table_oversized.
    DATA lv_count TYPE i.

    rv_is_oversized = abap_false.

    " SELECT COUNT(*) with UP TO is nearly instant on HANA.
    " If the count hits the ceiling, we know the table is too large.
    SELECT COUNT(*)
      FROM (iv_tabname)
      INTO @lv_count
      UP TO @p_maxrec ROWS.                      "#EC CI_NOWHERE

    IF lv_count >= p_maxrec.
      rv_is_oversized = abap_true.
    ENDIF.
  ENDMETHOD.


  METHOD make_key_string.
    rv_key = ``.

    LOOP AT it_keys ASSIGNING FIELD-SYMBOL(<kfld>).
      FIELD-SYMBOLS <comp> TYPE any.
      ASSIGN COMPONENT <kfld> OF STRUCTURE is_row TO <comp>.
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.

      DATA(lv_val) = |{ <comp> }|.
      CONDENSE lv_val.

      rv_key = COND #(
        WHEN rv_key IS INITIAL
        THEN |{ <kfld> }={ lv_val }|
        ELSE |{ rv_key }\|{ <kfld> }={ lv_val }| ).
    ENDLOOP.
  ENDMETHOD.


  METHOD display.
    DATA lo_salv TYPE REF TO cl_salv_table.
    DATA lo_col  TYPE REF TO cl_salv_column_table.

    IF gt_result IS INITIAL.
      MESSAGE 'No data found for the selected tables and languages.' TYPE 'S'
              DISPLAY LIKE 'W'.
      RETURN.
    ENDIF.

    TRY.
        cl_salv_table=>factory( IMPORTING r_salv_table = lo_salv
                                CHANGING  t_table      = gt_result ).

        lo_salv->get_functions( )->set_all( abap_true ).

        DATA(lo_cols) = lo_salv->get_columns( ).

        " Column headers
        lo_col = CAST cl_salv_column_table( lo_cols->get_column( 'STATUS' ) ).
        lo_col->set_long_text( 'DE Status' ).
        lo_col->set_output_length( 10 ).

        CAST cl_salv_column_table(
          lo_cols->get_column( 'TABNAME' ) )->set_long_text( 'Table' ).

        lo_col = CAST cl_salv_column_table( lo_cols->get_column( 'FIELD_NAME' ) ).
        lo_col->set_long_text( 'Text Field' ).
        lo_col->set_output_length( 20 ).

        lo_col = CAST cl_salv_column_table( lo_cols->get_column( 'FIELD_LENGTH' ) ).
        lo_col->set_long_text( 'Max Length' ).
        lo_col->set_output_length( 10 ).

        lo_col = CAST cl_salv_column_table( lo_cols->get_column( 'KEY_STRING' ) ).
        lo_col->set_long_text( 'Composite Key' ).
        lo_col->set_output_length( 20 ).

        lo_col = CAST cl_salv_column_table( lo_cols->get_column( 'TEXT_EN' ) ).
        lo_col->set_long_text( 'English (EN)' ).
        lo_col->set_output_length( 25 ).

        lo_col = CAST cl_salv_column_table( lo_cols->get_column( 'TEXT_FR' ) ).
        lo_col->set_long_text( 'French (FR)' ).
        lo_col->set_output_length( 25 ).

        lo_col = CAST cl_salv_column_table( lo_cols->get_column( 'TEXT_DE' ) ).
        lo_col->set_long_text( 'German (DE)' ).
        lo_col->set_output_length( 25 ).

        " List header with table count and record count
        DATA(lo_display) = lo_salv->get_display_settings( ).
        lo_display->set_list_header(
          |Translation coverage — EN / FR / DE | &&
          |({ lines( gt_meta ) NUMBER = USER } tables, | &&
          |{ lines( gt_result ) NUMBER = USER } records)| ).
        lo_display->set_striped_pattern( abap_true ).

        lo_salv->display( ).

      CATCH cx_salv_not_found
            cx_salv_msg.
        " Fallback: plain WRITE list
        WRITE: / 'Status', 12 'Table', 32 'Field', 54 'Len',
                 61 'Composite Key',
                 122 'EN', 164 'FR', 206 'DE'.
        ULINE.
        LOOP AT gt_result ASSIGNING FIELD-SYMBOL(<r>).
          WRITE: / <r>-status, 12 <r>-tabname,
                   32 <r>-field_name, 54 <r>-field_length,
                   61 <r>-key_string(60),
                   122 <r>-text_en(40), 164 <r>-text_fr(40),
                   206 <r>-text_de(40).
        ENDLOOP.
    ENDTRY.
  ENDMETHOD.


  METHOD show_progress.
    DATA(lv_pct) = COND i(
      WHEN iv_tot > 0
      THEN iv_cur * 100 / iv_tot
      ELSE 0 ).

    CALL FUNCTION 'SAPGUI_PROGRESS_INDICATOR'
      EXPORTING percentage = lv_pct
                text       = iv_text.
  ENDMETHOD.

ENDCLASS.


" ----------------------------------------------------------------------
" Events
" ----------------------------------------------------------------------
INITIALIZATION.
  " Pre-fill default table patterns (visible on selection screen)
  APPEND VALUE #( sign = 'I'  option = 'CP'  low = 'T*'     ) TO s_tabnm.
  APPEND VALUE #( sign = 'I'  option = 'CP'  low = 'TV*'    ) TO s_tabnm.
  APPEND VALUE #( sign = 'I'  option = 'EQ'  low = 'MAKT'   ) TO s_tabnm.
  APPEND VALUE #( sign = 'I'  option = 'EQ'  low = 'CSKT'   ) TO s_tabnm.
  APPEND VALUE #( sign = 'I'  option = 'EQ'  low = 'CEPC_T' ) TO s_tabnm.

START-OF-SELECTION.
  DATA(lo_checker) = NEW lcl_translation_checker( ).
  lo_checker->run( ).
  lo_checker->display( ).