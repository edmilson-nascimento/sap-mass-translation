REPORT z_check_translations_v3.

" ========================================================================
" Program     : Z_CHECK_TRANSLATIONS_V3
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
"   Block B03 – Status Filter
"     P_OK      : Include OK records in output
"     P_MISS    : Include MISSING records in output
"     P_COPY    : Include COPY records in output
"     P_NOBASE  : Include NO_BASE records in output
"     All checkboxes default to checked ('X'). At least one
"     must be selected; validation enforced via AT SELECTION-SCREEN.
"   Block B04 – Status Legend (nested within B03)
"     Informational sub-block displayed below checkboxes. Shows the
"     meaning of each STATUS value (OK/MISSING/COPY/NO_BASE).
"     Uses SELECTION-SCREEN COMMENT with text symbols L01–L04.
"
" Text elements to maintain (SE38 > Goto > Text Elements):
"
"   Selection Texts:
"     S_TABNM   -> Table name pattern (e.g. T*, MAKT)
"     P_LIMIT   -> Max tables to analyze
"     P_MAXREC  -> Skip tables exceeding this row count
"     P_OK      -> Include OK records (DE exists and differs from EN)
"     P_MISS    -> Include MISSING records (DE translation is empty)
"     P_COPY    -> Include COPY records (DE is identical to EN)
"     P_NOBASE  -> Include NO_BASE records (EN is empty)
"
"   Text Symbols:
"     B01       -> Table Selection
"     B02       -> Processing Limits
"     B03       -> Status Filter
"     B04       -> Status Legend (DE Translation)
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
" 2. AT SELECTION-SCREEN
"      Validate that at least one status filter checkbox is selected.
"      Raises error message if all checkboxes are unchecked.
"
" 3. START-OF-SELECTION
"      Instantiate LCL_TRANSLATION_CHECKER and call RUN → DISPLAY.
"
" 4. DISCOVER_TABLES
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
" 5. PROCESS_TABLE
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
" 6. DISPLAY
"      Apply status filter based on selection screen checkboxes (B03).
"      CL_SALV_TABLE output. The list header shows the number of tables
"      and records processed with thousand separators.
"      A plain WRITE fallback exists in case SALV raises an exception.
"
" ========================================================================
" CHANGE LOG
" ========================================================================
" Date        Author   Description
" ----------  -------  --------------------------------------------------
" 2026-03-26  JESUSEDM Fixed REPORT name declaration (V2→V3). Corrected
"                      ORDER BY in DD03L discovery from fieldname to position
"                      (ensures sample_field reflects physical column order).
"                      Removed dead commented-out code in DISPLAY method.
"                      Implemented row-level color coding via LVC_T_SCOL:
"                      OK=green (col_positive), MISSING=red (col_negative),
"                      COPY=yellow (col_total), NO_BASE=grey (col_normal).
"                      Color column T_COLOR registered via set_color_column
"                      and hidden from ALV grid output.
" 2026-03-26  JESUSEDM Added nested Block B04 (Status Legend) within B03
"                      to provide reference information for status codes.
"                      Legend placed AFTER checkboxes for optimal UX
"                      (frequent users access filters first, legend below
"                      for occasional reference).
" 2026-03-26  JESUSEDM Adjusted ALV column widths for better readability
"                      (KEY_STRING: 20→35, TEXT_EN/FR/DE: 25→40,
"                      FIELD_NAME: 20→15, FIELD_LENGTH: 10→8). Moved
"                      TYPES declaration to method start in PROCESS_TABLE.
"                      TODO: Add color coding to STATUS column (MISSING=
"                      red, COPY=yellow, NO_BASE=grey, OK=green) using
"                      CL_SALV_COLORS in future enhancement.
" 2026-03-26  JESUSEDM Removed Block B03 (Status Legend) as redundant
"                      with checkbox labels. Renumbered B04 to B03.
" 2026-03-26  JESUSEDM Added status filter checkboxes (B03 block) to
"                      allow selective display of OK/MISSING/COPY/
"                      NO_BASE records. All checkboxes default to
"                      checked. Filter applied in DISPLAY method before
"                      ALV rendering.
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
         t_color      TYPE lvc_t_scol,
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

" --- Block 3: Status filter ---
SELECTION-SCREEN BEGIN OF BLOCK b03 WITH FRAME TITLE TEXT-b03.
  PARAMETERS:
    p_ok     AS CHECKBOX DEFAULT 'X',
    p_miss   AS CHECKBOX DEFAULT 'X',
    p_copy   AS CHECKBOX DEFAULT 'X',
    p_nobase AS CHECKBOX DEFAULT 'X'.

  SELECTION-SCREEN SKIP.

  " Sub-block: Status legend (reference information)
  SELECTION-SCREEN BEGIN OF BLOCK b04 WITH FRAME TITLE TEXT-b04.
    SELECTION-SCREEN COMMENT /1(70) TEXT-l01.  "OK = DE exists and differs from EN
    SELECTION-SCREEN COMMENT /1(70) TEXT-l02.  "MISSING = DE translation is empty
    SELECTION-SCREEN COMMENT /1(70) TEXT-l03.  "COPY = DE is identical to EN (likely untranslated)
    SELECTION-SCREEN COMMENT /1(70) TEXT-l04.  "NO_BASE = EN is empty (no reference for translation)
  SELECTION-SCREEN END OF BLOCK b04.
SELECTION-SCREEN END OF BLOCK b03.


" ----------------------------------------------------------------------
" Class definition
" ----------------------------------------------------------------------
CLASS lcl_translation_checker DEFINITION.
  PUBLIC SECTION.
    METHODS:
      constructor,
      run,
      display.

  PRIVATE SECTION.
    CONSTANTS:
      c_en            TYPE spras VALUE 'E',
      c_fr            TYPE spras VALUE 'F',
      c_de            TYPE spras VALUE 'D',
      c_status_ok     TYPE char10 VALUE 'OK',
      c_status_missing TYPE char10 VALUE 'MISSING',
      c_status_copy   TYPE char10 VALUE 'COPY',
      c_status_nobase TYPE char10 VALUE 'NO_BASE'.

    DATA:
      gt_meta   TYPE STANDARD TABLE OF ty_tabmeta,
      gt_result TYPE STANDARD TABLE OF ty_result.

    METHODS:
      discover_tables,
      process_table IMPORTING is_meta TYPE ty_tabmeta,
      select_by_language
        IMPORTING is_meta     TYPE ty_tabmeta
                  iv_language TYPE spras
        CHANGING  ct_target   TYPE STANDARD TABLE,
      is_table_oversized
        IMPORTING iv_tabname        TYPE dd02l-tabname
        RETURNING VALUE(rv_is_oversized) TYPE abap_bool,
      make_key_string
        IMPORTING is_row       TYPE any
                  it_keys      TYPE STANDARD TABLE
        RETURNING VALUE(rv_key) TYPE string,
      show_progress
        IMPORTING iv_cur  TYPE i
                  iv_tot  TYPE i
                  iv_text TYPE csequence.
ENDCLASS.


" ----------------------------------------------------------------------
" Class implementation
" ----------------------------------------------------------------------
CLASS lcl_translation_checker IMPLEMENTATION.

  METHOD constructor.
    " No initialization needed; defaults handled in INITIALIZATION event.
  ENDMETHOD.


  METHOD run.
    discover_tables( ).

    " Safety: early exit if no candidate tables were found
    IF gt_meta IS INITIAL.
      MESSAGE 'No translatable tables found matching the selection criteria.'
              TYPE 'S' DISPLAY LIKE 'W'.
      RETURN.
    ENDIF.

    DATA(lv_tot) = lines( gt_meta ).

    LOOP AT gt_meta ASSIGNING FIELD-SYMBOL(<meta>).
      show_progress(
        iv_cur  = sy-tabix
        iv_tot  = lv_tot
        iv_text = |Processing { <meta>-tabname }...| ).

      process_table( <meta> ).
    ENDLOOP.
  ENDMETHOD.


  METHOD discover_tables.
    DATA lt_candidates TYPE STANDARD TABLE OF dd02l-tabname.

    " --- Identify tables with a SPRAS / language key field ---
    " We look for any TRANSP table that has at least one field whose
    " domain is SPRAS or whose direct rollname is SPRAS or LANGU.
    SELECT DISTINCT d~tabname
      FROM dd02l AS d
      INNER JOIN dd03l AS f
        ON f~tabname = d~tabname
       AND f~as4local = 'A'
       AND ( f~domname = 'SPRAS' OR f~rollname IN ( 'SPRAS', 'LANGU' ) )
      WHERE d~tabclass = 'TRANSP'
        AND d~as4local = 'A'
        AND d~tabname IN @s_tabnm
      INTO TABLE @lt_candidates
      UP TO @p_limit ROWS.                           "#EC CI_NOWHERE

    IF lt_candidates IS INITIAL.
      WRITE: / 'No candidate tables found with language key fields.'.
      RETURN.
    ENDIF.

    " --- Inspect field catalog and build metadata ---
    LOOP AT lt_candidates ASSIGNING FIELD-SYMBOL(<cand>).
      " Skip oversized tables
      IF is_table_oversized( <cand> ) = abap_true.
        WRITE: / |Table { <cand> } skipped (exceeds { p_maxrec } rows)|.
        CONTINUE.
      ENDIF.

      DATA(ls_meta) = VALUE ty_tabmeta( tabname = <cand> ).

      SELECT *
        FROM dd03l
        WHERE tabname = @<cand>
          AND as4local = 'A'
          AND NOT fieldname LIKE '.%'
        ORDER BY position
        INTO TABLE @DATA(lt_fields).                 "#EC CI_NOWHERE

      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.

      " Determine language field
      LOOP AT lt_fields ASSIGNING FIELD-SYMBOL(<f>).
        IF <f>-fieldname = 'SPRAS' OR <f>-rollname = 'SPRAS'.
          ls_meta-lang_field = <f>-fieldname.
          EXIT.
        ELSEIF <f>-fieldname = 'LANGU' OR <f>-rollname = 'LANGU'.
          ls_meta-lang_field = <f>-fieldname.
          EXIT.
        ELSEIF <f>-domname = 'SPRAS'.
          ls_meta-lang_field = <f>-fieldname.
          EXIT.
        ENDIF.
      ENDLOOP.

      IF ls_meta-lang_field IS INITIAL.
        CONTINUE. " Should not happen given the SELECT logic, but defensive check
      ENDIF.

      " Collect key fields excluding the language field
      DATA lt_keyfields TYPE STANDARD TABLE OF dd03l-fieldname.
      LOOP AT lt_fields ASSIGNING <f> WHERE keyflag = abap_true
                                        AND fieldname <> ls_meta-lang_field.
        APPEND <f>-fieldname TO lt_keyfields.
      ENDLOOP.
      ls_meta-key_fields = concat_lines_of( table = lt_keyfields sep = '|' ).

      " Identify the first non-key CHAR/STRG/SSTR field as the sample field
      LOOP AT lt_fields ASSIGNING <f> WHERE keyflag = abap_false
                                        AND ( datatype = 'CHAR' OR datatype = 'STRG' OR datatype = 'SSTR' ).
        ls_meta-sample_field = <f>-fieldname.
        ls_meta-sample_leng  = <f>-leng.
        EXIT.
      ENDLOOP.

      IF ls_meta-sample_field IS INITIAL.
        CONTINUE. " No suitable text field
      ENDIF.

      APPEND ls_meta TO gt_meta.
    ENDLOOP.
  ENDMETHOD.


  METHOD process_table.
    " Local type definition for pivot table
    TYPES: BEGIN OF ty_pivot,
             key     TYPE string,
             text_en TYPE string,
             text_fr TYPE string,
             text_de TYPE string,
           END OF ty_pivot.

    DATA: lr_en TYPE REF TO data,
          lr_fr TYPE REF TO data,
          lr_de TYPE REF TO data.

    FIELD-SYMBOLS: <lt_en> TYPE STANDARD TABLE,
                   <lt_fr> TYPE STANDARD TABLE,
                   <lt_de> TYPE STANDARD TABLE.

    " Create dynamic line type for this table
    DATA lo_type_descr TYPE REF TO cl_abap_typedescr.
    DATA lo_tab_descr TYPE REF TO cl_abap_tabledescr.
    DATA lo_struct_descr TYPE REF TO cl_abap_structdescr.

    lo_type_descr = cl_abap_typedescr=>describe_by_name( is_meta-tabname ).

    " Try to cast to table descriptor first
    TRY.
        lo_tab_descr ?= lo_type_descr.
      CATCH cx_sy_move_cast_error.
        " If it's a structure, create a standard table from it
        lo_struct_descr ?= lo_type_descr.
        lo_tab_descr = cl_abap_tabledescr=>create(
          p_line_type  = lo_struct_descr
          p_table_kind = cl_abap_tabledescr=>tablekind_std ).
    ENDTRY.

    DATA(lo_line_descr) = lo_tab_descr->get_table_line_type( ).

    " Create dynamic tables using table descriptor
    CREATE DATA lr_en TYPE HANDLE lo_tab_descr.
    CREATE DATA lr_fr TYPE HANDLE lo_tab_descr.
    CREATE DATA lr_de TYPE HANDLE lo_tab_descr.
    ASSIGN lr_en->* TO <lt_en>.
    ASSIGN lr_fr->* TO <lt_fr>.
    ASSIGN lr_de->* TO <lt_de>.

    DATA lr_row TYPE REF TO data.
    CREATE DATA lr_row TYPE HANDLE lo_line_descr.

    " Fetch rows for each language
    select_by_language(
      EXPORTING is_meta     = is_meta
                iv_language = c_en
      CHANGING  ct_target   = <lt_en> ).

    select_by_language(
      EXPORTING is_meta     = is_meta
                iv_language = c_fr
      CHANGING  ct_target   = <lt_fr> ).

    select_by_language(
      EXPORTING is_meta     = is_meta
                iv_language = c_de
      CHANGING  ct_target   = <lt_de> ).

    " --- Pivot: build composite key → (EN, FR, DE) map ---
    DATA lt_pivot TYPE HASHED TABLE OF ty_pivot WITH UNIQUE KEY key.
    DATA lt_keys  TYPE STANDARD TABLE OF dd03l-fieldname.
    SPLIT is_meta-key_fields AT '|' INTO TABLE lt_keys.

    " Process EN rows
    LOOP AT <lt_en> ASSIGNING FIELD-SYMBOL(<row>).
      ASSIGN lr_row->* TO FIELD-SYMBOL(<s>).
      <s> = <row>.

      FIELD-SYMBOLS: <sample_fld> TYPE any.
      ASSIGN COMPONENT is_meta-sample_field OF STRUCTURE <s> TO <sample_fld>.
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.

      DATA(lv_key) = make_key_string( is_row = <s>  it_keys = lt_keys ).
      DATA(lv_text) = CONV string( <sample_fld> ).

      INSERT VALUE ty_pivot( key = lv_key  text_en = lv_text )
        INTO TABLE lt_pivot.
    ENDLOOP.

    " Process FR rows
    LOOP AT <lt_fr> ASSIGNING <row>.
      ASSIGN lr_row->* TO <s>.
      <s> = <row>.

      ASSIGN COMPONENT is_meta-sample_field OF STRUCTURE <s> TO <sample_fld>.
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.

      lv_key  = make_key_string( is_row = <s>  it_keys = lt_keys ).
      lv_text = CONV string( <sample_fld> ).

      READ TABLE lt_pivot ASSIGNING FIELD-SYMBOL(<pv>) WITH TABLE KEY key = lv_key.
      IF sy-subrc = 0.
        <pv>-text_fr = lv_text.
      ELSE.
        INSERT VALUE ty_pivot( key = lv_key  text_fr = lv_text )
          INTO TABLE lt_pivot.
      ENDIF.
    ENDLOOP.

    " Process DE rows
    LOOP AT <lt_de> ASSIGNING <row>.
      ASSIGN lr_row->* TO <s>.
      <s> = <row>.

      ASSIGN COMPONENT is_meta-sample_field OF STRUCTURE <s> TO <sample_fld>.
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.

      lv_key  = make_key_string( is_row = <s>  it_keys = lt_keys ).
      lv_text = CONV string( <sample_fld> ).

      READ TABLE lt_pivot ASSIGNING <pv> WITH TABLE KEY key = lv_key.
      IF sy-subrc = 0.
        <pv>-text_de = lv_text.
      ELSE.
        INSERT VALUE ty_pivot( key = lv_key  text_de = lv_text )
          INTO TABLE lt_pivot.
      ENDIF.
    ENDLOOP.

    " --- Convert pivot into flat result with STATUS ---
    DATA lv_status TYPE char10.
    DATA lt_color  TYPE lvc_t_scol.
    DATA ls_color  TYPE lvc_s_scol.

    LOOP AT lt_pivot ASSIGNING <pv>.

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

      " Build row color: empty FNAME = entire row colored
      CLEAR: lt_color, ls_color.
      ls_color-color-col = SWITCH #( lv_status
        WHEN c_status_ok      THEN col_positive   " green
        WHEN c_status_missing THEN col_negative   " red
        WHEN c_status_copy    THEN col_total      " yellow
        WHEN c_status_nobase  THEN col_normal     " grey
        ELSE 0 ).
      APPEND ls_color TO lt_color.

      APPEND VALUE ty_result(
        status       = lv_status
        tabname      = is_meta-tabname
        field_name   = is_meta-sample_field
        field_length = is_meta-sample_leng
        key_string   = <pv>-key
        text_en      = <pv>-text_en
        text_fr      = <pv>-text_fr
        text_de      = <pv>-text_de
        t_color      = lt_color
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
    DATA lt_filtered TYPE STANDARD TABLE OF ty_result.

    " Apply status filter based on selection screen checkboxes
    LOOP AT gt_result ASSIGNING FIELD-SYMBOL(<res>).
      IF ( <res>-status = c_status_ok      AND p_ok     = 'X' ) OR
         ( <res>-status = c_status_missing AND p_miss   = 'X' ) OR
         ( <res>-status = c_status_copy    AND p_copy   = 'X' ) OR
         ( <res>-status = c_status_nobase  AND p_nobase = 'X' ).
        APPEND <res> TO lt_filtered.
      ENDIF.
    ENDLOOP.

    IF lt_filtered IS INITIAL.
      MESSAGE 'No data matches the selected status filter.' TYPE 'S'
              DISPLAY LIKE 'W'.
      RETURN.
    ENDIF.

    TRY.
        cl_salv_table=>factory( IMPORTING r_salv_table = lo_salv
                                CHANGING  t_table      = lt_filtered ).

        lo_salv->get_functions( )->set_all( abap_true ).

        DATA(lo_cols) = lo_salv->get_columns( ).
        lo_cols->set_color_column( 'T_COLOR' ).

        " Column headers
        lo_col = CAST cl_salv_column_table( lo_cols->get_column( 'STATUS' ) ).
        lo_col->set_long_text( 'DE Status' ).
        lo_col->set_output_length( 10 ).

        lo_col = CAST cl_salv_column_table( lo_cols->get_column( 'TABNAME' ) ).
        lo_col->set_long_text( 'Table' ).
        lo_col->set_output_length( 7 ).

        lo_col = CAST cl_salv_column_table( lo_cols->get_column( 'FIELD_NAME' ) ).
        lo_col->set_long_text( 'Text Field' ).
        lo_col->set_output_length( 7 ).

        lo_col = CAST cl_salv_column_table( lo_cols->get_column( 'FIELD_LENGTH' ) ).
        lo_col->set_long_text( 'Max Length' ).
        lo_col->set_output_length( 7 ).

        lo_col = CAST cl_salv_column_table( lo_cols->get_column( 'KEY_STRING' ) ).
        lo_col->set_long_text( 'Composite Key' ).
        lo_col->set_output_length( 35 ).

        lo_col = CAST cl_salv_column_table( lo_cols->get_column( 'TEXT_EN' ) ).
        lo_col->set_long_text( 'English (EN)' ).
        lo_col->set_output_length( 40 ).

        lo_col = CAST cl_salv_column_table( lo_cols->get_column( 'TEXT_FR' ) ).
        lo_col->set_long_text( 'French (FR)' ).
        lo_col->set_output_length( 40 ).

        lo_col = CAST cl_salv_column_table( lo_cols->get_column( 'TEXT_DE' ) ).
        lo_col->set_long_text( 'German (DE)' ).
        lo_col->set_output_length( 40 ).

        lo_col = CAST cl_salv_column_table( lo_cols->get_column( 'T_COLOR' ) ).
        lo_col->set_visible( abap_false ).

        " List header with table count and record count
        DATA(lo_display) = lo_salv->get_display_settings( ).
        lo_display->set_list_header(
          |Translation coverage — EN / FR / DE | &&
          |({ lines( gt_meta ) NUMBER = USER } tables, | &&
          |{ lines( lt_filtered ) NUMBER = USER } records)| ).
        lo_display->set_striped_pattern( abap_true ).

        lo_salv->display( ).

      CATCH cx_salv_not_found
            cx_salv_msg.
        " Fallback: plain WRITE list
        WRITE: / 'Status', 12 'Table', 32 'Field', 54 'Len',
                 61 'Composite Key',
                 122 'EN', 164 'FR', 206 'DE'.
        ULINE.
        LOOP AT lt_filtered ASSIGNING FIELD-SYMBOL(<r>).
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
  APPEND VALUE #( sign = 'I'  option = 'EQ'  low = 'CEPCT'  ) TO s_tabnm.

AT SELECTION-SCREEN.
  " Validate that at least one status checkbox is selected
  IF p_ok IS INITIAL AND p_miss IS INITIAL AND
     p_copy IS INITIAL AND p_nobase IS INITIAL.
    MESSAGE 'At least one status must be selected.' TYPE 'E'.
  ENDIF.

START-OF-SELECTION.
  DATA(lo_checker) = NEW lcl_translation_checker( ).
  lo_checker->run( ).
  lo_checker->display( ).