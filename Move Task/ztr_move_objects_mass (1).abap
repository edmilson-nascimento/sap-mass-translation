*&---------------------------------------------------------------------*
*& Report ZTR_MOVE_OBJECTS_MASS
*&---------------------------------------------------------------------*
*& Mass move of objects between transport requests (ALV based)
*&
*& Purpose
*& -------
*& Provides a SE10-like view of objects across multiple modifiable
*& transport requests and offers a "Move" action that lets the user
*& reassign one or many selected objects to another request/task in
*& bulk. Typical use case: cleaning a request before release by moving
*& objects that should NOT be transported (yet) to a temporary
*& "parking" request, so they can be transported later if needed.
*&
*& Design
*& ------
*& - Pure local OO: one local class LCL_APP, singleton pattern.
*& - All code in a single include (no FUGR, no global class, no dynpro).
*& - ABAP 7.40+ syntax throughout (inline DATA(), VALUE #( ),
*&   CORRESPONDING #( ), table expressions, FOR ALL ENTRIES with @host
*&   variables, etc.).
*& - ALV via cl_salv_table=>factory (fullscreen).
*& - Custom PF status (STANDARD_FULLSCREEN, local copy in this program)
*&   holding the MOVE_OBJ button — ADD_FUNCTION at runtime does NOT work
*&   in fullscreen SALV, so the button is defined statically in a copy
*&   of SAPLSLVC_FULLSCREEN's STANDARD_FULLSCREEN status (see "PF status
*&   setup" below).
*&
*& v1 — ALV base (collect_data, enrich_user_names, enrich_obj_text,
*&      display_alv, configure_columns, on_link_click)
*& ------------------------------------------------------------------
*& - SELECT-OPTIONS on E070-TRKORR (no intervals).
*& - Only modifiable requests/tasks are loaded (TRSTATUS in 'D','L').
*& - Output table: one row per E071 entry, enriched with:
*&     - request status / owner / owner full name (from USER_ADDR-NAME_TEXTC)
*&     - task    status / owner / owner full name
*&     - object type description (from OBJT-DDTEXT, key OBJECTNAME+LANGUAGE)
*&     - function group for LIMU FUNC entries (from TFDIR-PNAME,
*&       stripped of 'SAPL' prefix)
*& - Hotspot on Request and Task columns → CALL FUNCTION
*&   'TR_PRESENT_REQUEST' (standard SAP popup, same one SE10 opens on
*&   double-click; keeps the ALV alive in background).
*&
*& v2 — Mass move (configure_functions, on_user_command,
*&      handle_move_objects, get_selected_rows)
*& ------------------------------------------------------------------
*& - Custom button MOVE_OBJ added via PF status Z_SALV_MOVE_OBJ.
*& - Validation: at least one row selected; ALL selected rows must
*&   share the SAME source request AND task. The "single common origin"
*&   rule keeps the operation safe and predictable; cross-source moves
*&   are intentionally NOT supported in v2 (can be relaxed later by
*&   grouping by source and calling the move FM per group).
*& - Target picker via FM TRINT_ORDER_CHOICE. Same popup SE10 uses for
*&   "Move Object" — lists modifiable requests with their tasks expanded
*&   and offers "Create" for both request and task. Returns we_order
*&   (request) and we_task (task) separately; we use the task when set,
*&   otherwise the root request (covers the "objects directly on the
*&   request" case).
*& - Same-source/same-target short-circuit: aborts cleanly when target
*&   matches source (nothing to move).
*& - Confirmation popup via POPUP_TO_CONFIRM showing object count,
*&   source and target TRKORRs.
*& - Move execution: calls FM TR_MOVE_OBJECTS (function group SAPLSTRI),
*&   passing it_e071 with the selected (pgmid, object, obj_name) triples,
*&   plus cs_request_from-h-trkorr (source task/request) and
*&   cs_request_to_header-trkorr (target). iv_suppress_dialog='X' because
*&   we already drove the picker via TR_REQUEST_CHOICE. The FM handles
*&   ENQUEUE/DEQUEUE on both sides; we COMMIT WORK on success and surface
*&   the FM's own message on any of its 13 failure exceptions.
*&
*& PF status setup (one-time, manual)
*& ----------------------------------
*& 1. SE41 → enter program SAPLSLVC_FULLSCREEN, status STANDARD_FULLSCREEN
*& 2. Copy → target program = this report, status STANDARD_FULLSCREEN
*&    (same name; the local copy shadows the original)
*& 3. Open STANDARD_FULLSCREEN in change mode and add a function:
*&    - FCode  : MOVE_OBJ
*&    - Text   : Move
*&    - Icon   : ICON_TRANSPORT (@D0@)
*&    - Tooltip: Move selected objects to another request/task
*&    Place it in the Application Toolbar.
*&    Optional second button (REFRESH is also already available via the
*&    standard SALV refresh icon &REFRESH; add a custom one only if a
*&    more prominent placement is desired):
*&    - FCode  : REFRESH
*&    - Text   : Refresh
*&    - Icon   : ICON_REFRESH (@2L@)
*& 4. Activate. display_alv() then calls
*&    set_screen_status( pfstatus = 'STANDARD_FULLSCREEN' report = sy-repid
*&                       set_functions = c_functions_all ) and picks up
*&    the local copy automatically.
*&
*& Why not add_function at runtime?
*& - cl_salv_functions_list->add_function is supported ONLY by the SALV
*&   grid-in-container adapter (cl_salv_grid_adapter). Fullscreen mode
*&   uses cl_salv_fullscreen_adapter, which raises
*&   CX_SALV_METHOD_NOT_SUPPORTED. The "use container" workaround
*&   requires a real dynpro with PBO/PAI — too heavy for this report.
*&
*& Tables touched
*& - Read-only (for display): E070, E071, USER_ADDR, OBJT, TFDIR
*& - Written indirectly via TR_MOVE_OBJECTS / TRINT_MOVE_OBJECTS:
*&   E070 (status), E071, E071K, TLOCK (lock entries are reassigned to
*&   the target request). No direct UPDATE/INSERT/DELETE on these
*&   tables from this report — all goes through the standard FM.
*&
*&---------------------------------------------------------------------*
*& MODLOG
*&---------------------------------------------------------------------*
*& JESUSEDM 20260518 INS v1 — initial ALV report (selection, enrichment,
*&                            display, hotspot to SE10 via
*&                            TR_PRESENT_REQUEST).
*& JESUSEDM 20260518 INS v2 — MOVE_OBJ button + handle_move_objects:
*&                            multi-select validation, TRINT_ORDER_CHOICE
*&                            picker (returns request + task separately),
*&                            POPUP_TO_CONFIRM, TR_MOVE_OBJECTS call wired,
*&                            COMMIT WORK on success.
*&---------------------------------------------------------------------*
REPORT ztr_move_objects_mass.

*----------------------------------------------------------------------*
* Selection screen
*----------------------------------------------------------------------*
DATA gv_trkorr TYPE e070-trkorr.

SELECTION-SCREEN BEGIN OF BLOCK b01 WITH FRAME TITLE TEXT-b01.
SELECT-OPTIONS s_trkorr FOR gv_trkorr NO INTERVALS.
SELECTION-SCREEN END OF BLOCK b01.

*----------------------------------------------------------------------*
* Local class
*----------------------------------------------------------------------*
CLASS lcl_app DEFINITION FINAL CREATE PRIVATE.

  PUBLIC SECTION.
    CLASS-METHODS:
      get_instance RETURNING VALUE(ro_app) TYPE REF TO lcl_app,
      run.

    TYPES:
      BEGIN OF ty_out,
        trkorr      TYPE e070-trkorr,             " Request
        trstatus_r  TYPE e070-trstatus,           " Status Request
        as4user_r   TYPE e070-as4user,            " Owner Request
        username_r  TYPE user_addr-name_textc,    " Owner full name (Req)
        trkorr_t    TYPE e070-trkorr,             " Task
        trstatus_t  TYPE e070-trstatus,           " Status Task
        as4user_t   TYPE e070-as4user,            " Owner Task
        username_t  TYPE user_addr-name_textc,    " Owner full name (Task)
        pgmid       TYPE e071-pgmid,              " Pgmid
        object      TYPE e071-object,             " Object Type
        obj_name    TYPE e071-obj_name,           " Object Name
        obj_text    TYPE objt-ddtext,            " Object Type Description
        fgroup      TYPE rs38l_area,              " Function Group (LIMU)
        lockflag    TYPE e071-lockflag,           " Lock Status
        lang        TYPE e071-lang,               " Language
      END OF ty_out,
      tt_out TYPE STANDARD TABLE OF ty_out WITH EMPTY KEY.

  PRIVATE SECTION.
    CLASS-DATA go_app TYPE REF TO lcl_app.

    DATA:
      mt_out   TYPE tt_out,
      mo_alv   TYPE REF TO cl_salv_table.

    METHODS:
      collect_data,
      enrich_user_names CHANGING ct_out TYPE tt_out,
      enrich_obj_text   CHANGING ct_out TYPE tt_out,
      display_alv,
      configure_columns,
      configure_functions,
      handle_move_objects,
      get_selected_rows
        RETURNING VALUE(rt_rows) TYPE salv_t_row,

      on_link_click
        FOR EVENT link_click OF cl_salv_events_table
          IMPORTING row column,

      on_user_command
        FOR EVENT added_function OF cl_salv_events
          IMPORTING e_salv_function.

ENDCLASS.

CLASS lcl_app IMPLEMENTATION.

  METHOD get_instance.
    IF go_app IS INITIAL.
      go_app = NEW lcl_app( ).
    ENDIF.
    ro_app = go_app.
  ENDMETHOD.

  METHOD run.
    DATA(lo_app) = get_instance( ).
    lo_app->collect_data( ).

    IF lo_app->mt_out IS INITIAL.
      MESSAGE 'No modifiable requests/objects found for selection' TYPE 'S'.
      RETURN.
    ENDIF.

    lo_app->display_alv( ).
  ENDMETHOD.

  METHOD collect_data.
    CLEAR mt_out.

    " Modifiable status only: D = Modifiable, L = Modifiable, protected
    CONSTANTS:
      lc_status_d TYPE e070-trstatus VALUE 'D',
      lc_status_l TYPE e070-trstatus VALUE 'L'.

    " 1) Get matching requests (parents) — only modifiable
    SELECT trkorr, trstatus, as4user
      FROM e070
      WHERE trkorr     IN @s_trkorr
        AND strkorr    =  @space          " parent requests only
        AND trstatus  IN ( @lc_status_d, @lc_status_l )
      INTO TABLE @DATA(lt_requests).

    IF lt_requests IS INITIAL.
      RETURN.
    ENDIF.

    " 2) Get tasks of those requests — also only modifiable
    SELECT trkorr, strkorr, trstatus, as4user
      FROM e070
      FOR ALL ENTRIES IN @lt_requests
      WHERE strkorr   =  @lt_requests-trkorr
        AND trstatus IN ( @lc_status_d, @lc_status_l )
      INTO TABLE @DATA(lt_tasks).

    " Build a combined "scope" table: every task + its parent info
    " (we only show object rows that live under a task, which matches SE10)
    IF lt_tasks IS INITIAL.
      RETURN.
    ENDIF.

    " 3) Get all E071 entries of those tasks
    SELECT trkorr, pgmid, object, obj_name, lockflag, lang
      FROM e071
      FOR ALL ENTRIES IN @lt_tasks
      WHERE trkorr = @lt_tasks-trkorr
      INTO TABLE @DATA(lt_e071).

    IF lt_e071 IS INITIAL.
      RETURN.
    ENDIF.

    " 4) Index parent requests for fast lookup
    DATA lt_req_idx TYPE HASHED TABLE OF e070
                    WITH UNIQUE KEY trkorr.
    lt_req_idx = CORRESPONDING #( lt_requests ).

    " 5) Index tasks for fast lookup
    DATA lt_task_idx TYPE HASHED TABLE OF e070
                     WITH UNIQUE KEY trkorr.
    lt_task_idx = CORRESPONDING #( lt_tasks ).

    " 6) Build output rows
    LOOP AT lt_e071 ASSIGNING FIELD-SYMBOL(<ls_e071>).

      ASSIGN lt_task_idx[ trkorr = <ls_e071>-trkorr ] TO FIELD-SYMBOL(<ls_task>).
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.

      ASSIGN lt_req_idx[ trkorr = <ls_task>-strkorr ] TO FIELD-SYMBOL(<ls_req>).
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.

      APPEND VALUE ty_out(
        trkorr     = <ls_req>-trkorr
        trstatus_r = <ls_req>-trstatus
        as4user_r  = <ls_req>-as4user
        trkorr_t   = <ls_task>-trkorr
        trstatus_t = <ls_task>-trstatus
        as4user_t  = <ls_task>-as4user
        pgmid      = <ls_e071>-pgmid
        object     = <ls_e071>-object
        obj_name   = <ls_e071>-obj_name
        lockflag   = <ls_e071>-lockflag
        lang       = <ls_e071>-lang
      ) TO mt_out.

    ENDLOOP.

    enrich_user_names( CHANGING ct_out = mt_out ).
    enrich_obj_text(   CHANGING ct_out = mt_out ).

    SORT mt_out BY trkorr trkorr_t pgmid object obj_name.
  ENDMETHOD.

  METHOD enrich_user_names.
    " Collect distinct users
    DATA lt_users TYPE STANDARD TABLE OF user_addr-bname.

    LOOP AT ct_out ASSIGNING FIELD-SYMBOL(<ls>).
      APPEND <ls>-as4user_r TO lt_users.
      APPEND <ls>-as4user_t TO lt_users.
    ENDLOOP.

    SORT lt_users.
    DELETE ADJACENT DUPLICATES FROM lt_users.
    DELETE lt_users WHERE table_line IS INITIAL.

    IF lt_users IS INITIAL.
      RETURN.
    ENDIF.

    SELECT bname, name_textc
      FROM user_addr
      FOR ALL ENTRIES IN @lt_users
      WHERE bname = @lt_users-table_line
      INTO TABLE @DATA(lt_addr).

    DATA lt_addr_idx TYPE HASHED TABLE OF user_addr
                     WITH UNIQUE KEY bname.
    lt_addr_idx = CORRESPONDING #( lt_addr ).

    LOOP AT ct_out ASSIGNING <ls>.
      ASSIGN lt_addr_idx[ bname = <ls>-as4user_r ] TO FIELD-SYMBOL(<ls_addr>).
      IF sy-subrc = 0.
        <ls>-username_r = <ls_addr>-name_textc.
      ENDIF.

      ASSIGN lt_addr_idx[ bname = <ls>-as4user_t ] TO <ls_addr>.
      IF sy-subrc = 0.
        <ls>-username_t = <ls_addr>-name_textc.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD enrich_obj_text.
    " OBJT is the text table of OBJH and contains descriptions for ALL
    " object types referenced in transports (both R3TR logical objects
    " and LIMU subobjects). Key: OBJECTNAME + LANGUAGE.

    " Collect distinct object types into a list typed with OBJT-OBJECTNAME
    " so that FOR ALL ENTRIES is type-compatible.
    DATA lt_objt_keys TYPE STANDARD TABLE OF objt-objectname.

    LOOP AT ct_out ASSIGNING FIELD-SYMBOL(<ls>).
      APPEND CONV objt-objectname( <ls>-object ) TO lt_objt_keys.
    ENDLOOP.

    SORT lt_objt_keys.
    DELETE ADJACENT DUPLICATES FROM lt_objt_keys.
    DELETE lt_objt_keys WHERE table_line IS INITIAL.

    IF lt_objt_keys IS NOT INITIAL.
      SELECT objectname, ddtext
        FROM objt
        FOR ALL ENTRIES IN @lt_objt_keys
        WHERE objectname = @lt_objt_keys-table_line
          AND language   = @sy-langu
        INTO TABLE @DATA(lt_objt).

      DATA lt_objt_idx TYPE HASHED TABLE OF objt
                       WITH UNIQUE KEY objectname.
      lt_objt_idx = CORRESPONDING #( lt_objt ).

      LOOP AT ct_out ASSIGNING <ls>.
        ASSIGN lt_objt_idx[ objectname = <ls>-object ] TO FIELD-SYMBOL(<ls_objt>).
        IF sy-subrc = 0.
          <ls>-obj_text = <ls_objt>-ddtext.
        ENDIF.
      ENDLOOP.
    ENDIF.

    " --- Function group for LIMU FUNC -------------------------------
    " TFDIR-PNAME holds the program name in the form 'SAPL<fgroup>'
    " (e.g. SAPLZMM_UTILS -> fgroup ZMM_UTILS).
    LOOP AT ct_out ASSIGNING <ls> WHERE pgmid = 'LIMU' AND object = 'FUNC'.
      SELECT SINGLE pname
        FROM tfdir
        WHERE funcname = @<ls>-obj_name
        INTO @DATA(lv_pname).
      IF sy-subrc = 0 AND lv_pname(4) = 'SAPL'.
        <ls>-fgroup = lv_pname+4(*).
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD display_alv.
    TRY.
        " Fullscreen factory (no container). Custom button MOVE_OBJ comes from
        " the PF status Z_SALV_MOVE_OBJ (copied from SAPLSLVC_FULLSCREEN's
        " SALV_TABLE_STANDARD and extended).
        cl_salv_table=>factory(
          IMPORTING r_salv_table = mo_alv
          CHANGING  t_table      = mt_out ).

      CATCH cx_salv_msg INTO DATA(lx_msg).
        MESSAGE lx_msg TYPE 'E'.
        RETURN.
    ENDTRY.

    " Apply custom PF status (copied from SAPLSLVC_FULLSCREEN's
    " STANDARD_FULLSCREEN with the MOVE_OBJ button added).
    DATA lv_repid TYPE syrepid.
    lv_repid = sy-repid.
    mo_alv->set_screen_status(
      report        = lv_repid
      pfstatus      = 'STANDARD_FULLSCREEN'
      set_functions = mo_alv->c_functions_all ).

    " Selection mode: multi-row — needed for mass move
    mo_alv->get_selections( )->set_selection_mode( if_salv_c_selection_mode=>row_column ).

    configure_columns( ).

    " Events
    DATA(lo_events) = mo_alv->get_event( ).
    SET HANDLER on_link_click   FOR lo_events.
    SET HANDLER on_user_command FOR lo_events.

    " Optimize column widths + display
    mo_alv->get_columns( )->set_optimize( abap_true ).
    mo_alv->get_display_settings( )->set_striped_pattern( abap_true ).
    mo_alv->get_display_settings( )->set_list_header( 'Mass Move Objects - Transport Requests' ).

    mo_alv->display( ).
  ENDMETHOD.

  METHOD configure_columns.
    DATA(lo_cols) = mo_alv->get_columns( ).
    lo_cols->set_optimize( abap_true ).

    TRY.
        " Request -> hotspot to SE10
        DATA(lo_col) = CAST cl_salv_column_table( lo_cols->get_column( 'TRKORR' ) ).
        lo_col->set_short_text( 'Request' ).
        lo_col->set_medium_text( 'Request' ).
        lo_col->set_long_text( 'Transport Request' ).
        lo_col->set_cell_type( if_salv_c_cell_type=>hotspot ).

        " Other columns - friendly headers
        CAST cl_salv_column_table( lo_cols->get_column( 'TRSTATUS_R' )
          )->set_short_text( 'St.Req' ).
        CAST cl_salv_column_table( lo_cols->get_column( 'TRSTATUS_R' )
          )->set_long_text( 'Request Status' ).

        CAST cl_salv_column_table( lo_cols->get_column( 'AS4USER_R' )
          )->set_short_text( 'Req.Own.' ).
        CAST cl_salv_column_table( lo_cols->get_column( 'AS4USER_R' )
          )->set_long_text( 'Request Owner' ).

        CAST cl_salv_column_table( lo_cols->get_column( 'USERNAME_R' )
          )->set_short_text( 'Req.User' ).
        CAST cl_salv_column_table( lo_cols->get_column( 'USERNAME_R' )
          )->set_long_text( 'Request Owner Name' ).

        CAST cl_salv_column_table( lo_cols->get_column( 'TRKORR_T' )
          )->set_short_text( 'Task' ).
        CAST cl_salv_column_table( lo_cols->get_column( 'TRKORR_T' )
          )->set_long_text( 'Task' ).
        CAST cl_salv_column_table( lo_cols->get_column( 'TRKORR_T' )
          )->set_cell_type( if_salv_c_cell_type=>hotspot ).

        CAST cl_salv_column_table( lo_cols->get_column( 'TRSTATUS_T' )
          )->set_short_text( 'St.Task' ).
        CAST cl_salv_column_table( lo_cols->get_column( 'TRSTATUS_T' )
          )->set_long_text( 'Task Status' ).

        CAST cl_salv_column_table( lo_cols->get_column( 'AS4USER_T' )
          )->set_short_text( 'Task.Own' ).
        CAST cl_salv_column_table( lo_cols->get_column( 'AS4USER_T' )
          )->set_long_text( 'Task Owner' ).

        CAST cl_salv_column_table( lo_cols->get_column( 'USERNAME_T' )
          )->set_short_text( 'Task.User' ).
        CAST cl_salv_column_table( lo_cols->get_column( 'USERNAME_T' )
          )->set_long_text( 'Task Owner Name' ).

        CAST cl_salv_column_table( lo_cols->get_column( 'PGMID' )
          )->set_short_text( 'Pgmid' ).

        CAST cl_salv_column_table( lo_cols->get_column( 'OBJECT' )
          )->set_short_text( 'Type' ).
        CAST cl_salv_column_table( lo_cols->get_column( 'OBJECT' )
          )->set_long_text( 'Object Type' ).

        CAST cl_salv_column_table( lo_cols->get_column( 'OBJ_NAME' )
          )->set_short_text( 'Obj.Name' ).
        CAST cl_salv_column_table( lo_cols->get_column( 'OBJ_NAME' )
          )->set_long_text( 'Object Name' ).

        CAST cl_salv_column_table( lo_cols->get_column( 'OBJ_TEXT' )
          )->set_short_text( 'Obj.Desc' ).
        CAST cl_salv_column_table( lo_cols->get_column( 'OBJ_TEXT' )
          )->set_long_text( 'Object Description' ).

        CAST cl_salv_column_table( lo_cols->get_column( 'FGROUP' )
          )->set_short_text( 'FuncGrp' ).
        CAST cl_salv_column_table( lo_cols->get_column( 'FGROUP' )
          )->set_long_text( 'Function Group' ).

        CAST cl_salv_column_table( lo_cols->get_column( 'LOCKFLAG' )
          )->set_short_text( 'Lock' ).
        CAST cl_salv_column_table( lo_cols->get_column( 'LOCKFLAG' )
          )->set_long_text( 'Lock Status' ).

        CAST cl_salv_column_table( lo_cols->get_column( 'LANG' )
          )->set_short_text( 'Lang' ).
        CAST cl_salv_column_table( lo_cols->get_column( 'LANG' )
          )->set_long_text( 'Language' ).

      CATCH cx_salv_not_found.
        " ignore
    ENDTRY.
  ENDMETHOD.

  METHOD configure_functions.
    " NO-OP. Custom toolbar buttons are defined statically in PF status
    " STANDARD_FULLSCREEN (local copy in this program — see header notes
    " "PF status setup"). add_function( ) is not supported by fullscreen
    " SALV, so runtime registration is not an option here. Method kept as
    " a stub to preserve the structure and mark the design intent.
    RETURN.
  ENDMETHOD.

  METHOD on_link_click.
    READ TABLE mt_out ASSIGNING FIELD-SYMBOL(<ls>) INDEX row.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    DATA lv_trkorr TYPE trkorr.

    CASE column.
      WHEN 'TRKORR'.   lv_trkorr = <ls>-trkorr.
      WHEN 'TRKORR_T'. lv_trkorr = <ls>-trkorr_t.
      WHEN OTHERS.
        RETURN.
    ENDCASE.

    IF lv_trkorr IS INITIAL.
      RETURN.
    ENDIF.

    " Standard SAP popup showing the request/task — same dialog SE10 opens on
    " double-click. iv_highlight focuses the row, iv_showonly opens read-only.
    " Keeps the ALV alive in background.
    CALL FUNCTION 'TR_PRESENT_REQUEST'
      EXPORTING
        iv_trkorr    = lv_trkorr
        iv_highlight = 'X'
        iv_showonly  = 'X'.
  ENDMETHOD.

  METHOD on_user_command.
    CASE e_salv_function.

      WHEN 'MOVE_OBJ'.
        handle_move_objects( ).

      WHEN 'REFRESH'  "  custom refresh button (if added in PF status)
        OR '&REFRESH'."  standard SALV refresh button
        collect_data( ).
        mo_alv->refresh( ).

      WHEN OTHERS.
        " Any other custom function added in the future
        RETURN.
    ENDCASE.
  ENDMETHOD.

  METHOD get_selected_rows.
    rt_rows = mo_alv->get_selections( )->get_selected_rows( ).
  ENDMETHOD.

  METHOD handle_move_objects.
    " ----------------------------------------------------------------
    " 1) Validate selection: at least one row, single common origin
    " ----------------------------------------------------------------
    DATA(lt_rows) = get_selected_rows( ).

    IF lt_rows IS INITIAL.
      MESSAGE 'Please select at least one object to move' TYPE 'S' DISPLAY LIKE 'W'.
      RETURN.
    ENDIF.

    " Build the list of selected output rows + check single origin
    DATA: lv_src_trkorr   TYPE trkorr,
          lv_src_trkorr_t TYPE trkorr.

    DATA lt_selected TYPE tt_out.

    LOOP AT lt_rows ASSIGNING FIELD-SYMBOL(<lv_row>).
      READ TABLE mt_out ASSIGNING FIELD-SYMBOL(<ls>) INDEX <lv_row>.
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.

      IF sy-tabix = 1.
        lv_src_trkorr   = <ls>-trkorr.
        lv_src_trkorr_t = <ls>-trkorr_t.
      ELSE.
        IF    <ls>-trkorr   <> lv_src_trkorr
           OR <ls>-trkorr_t <> lv_src_trkorr_t.
          MESSAGE 'All selected objects must belong to the same source request/task'
                  TYPE 'S' DISPLAY LIKE 'E'.
          RETURN.
        ENDIF.
      ENDIF.

      APPEND <ls> TO lt_selected.
    ENDLOOP.

    IF lt_selected IS INITIAL.
      RETURN.
    ENDIF.

    " ----------------------------------------------------------------
    " 2) Ask target request/task via standard SAP popup
    " ----------------------------------------------------------------
    " TRINT_ORDER_CHOICE shows the same popup SE10 uses for "Move Object":
    " a list of modifiable requests with their tasks expanded, plus a
    " "Create" button for both request and task. Returns:
    "   - we_order : the request TRKORR
    "   - we_task  : the task TRKORR (if the user picked a task; empty
    "                if the user picked the root request only)
    " Empty wi_order_type / wi_task_type / wi_category let the user pick
    " any modifiable target, regardless of type. TR_MOVE_OBJECTS will
    " then check type compatibility (raises request_types_not_consistent
    " if e.g. workbench source goes to customizing target).
    DATA: lv_target_trkorr TYPE trkorr,
          lv_target_order  TYPE trkorr,
          lv_target_task   TYPE trkorr,
          lt_e071_pick     TYPE STANDARD TABLE OF e071,
          lt_e071k_pick    TYPE STANDARD TABLE OF e071k.

    CALL FUNCTION 'TRINT_ORDER_CHOICE'
      IMPORTING
        we_order               = lv_target_order
        we_task                = lv_target_task
      TABLES
        wt_e071                = lt_e071_pick
        wt_e071k               = lt_e071k_pick
      EXCEPTIONS
        no_correction_selected = 1
        display_mode           = 2
        object_append_error    = 3
        recursive_call         = 4
        wrong_order_type       = 5
        OTHERS                 = 6.

    IF sy-subrc <> 0.
      IF sy-subrc = 1.
        " user cancelled (no_correction_selected) — silent
        RETURN.
      ENDIF.
      MESSAGE ID sy-msgid TYPE 'S' NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4 DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

    " Prefer the task as target; fall back to the root request if the
    " user picked only a request (objects sit directly on the request).
    IF lv_target_task IS NOT INITIAL.
      lv_target_trkorr = lv_target_task.
    ELSE.
      lv_target_trkorr = lv_target_order.
    ENDIF.

    " ----------------------------------------------------------------
    " 3) Sanity: target must differ from source
    " ----------------------------------------------------------------
    IF lv_target_trkorr = lv_src_trkorr_t.
      MESSAGE 'Target is the same as source — nothing to do' TYPE 'S' DISPLAY LIKE 'W'.
      RETURN.
    ENDIF.

    " ----------------------------------------------------------------
    " 4) Confirmation popup
    " ----------------------------------------------------------------
    DATA: lv_question TYPE string,
          lv_answer   TYPE c LENGTH 1.

    lv_question = |Move { lines( lt_selected ) } object(s)| &&
                  | from { lv_src_trkorr_t }| &&
                  | to { lv_target_trkorr }?|.

    CALL FUNCTION 'POPUP_TO_CONFIRM'
      EXPORTING
        titlebar              = 'Confirm Move'
        text_question         = lv_question
        text_button_1         = 'Move'
        text_button_2         = 'Cancel'
        default_button        = '2'
        display_cancel_button = abap_false
      IMPORTING
        answer                = lv_answer
      EXCEPTIONS
        text_not_found        = 1
        OTHERS                = 2.

    IF sy-subrc <> 0 OR lv_answer <> '1'.
      RETURN.
    ENDIF.

    " ----------------------------------------------------------------
    " 5) Execute the move via TR_MOVE_OBJECTS (function group SAPLSTRI)
    " ----------------------------------------------------------------
    " Notes on the FM contract:
    " - it_e071: table of objects (pgmid/object/obj_name) to be moved.
    " - cs_request_from: source request/task. Only -h-trkorr is mandatory
    "   here; the FM calls TRINT_READ_REQUEST internally to fill the rest.
    " - cs_request_to_header: target header. -trkorr is mandatory.
    " - iv_suppress_dialog = 'X' so the FM does not open its own CALL
    "   SCREEN 0300 picker — we already asked the user via TR_REQUEST_CHOICE.
    " - The FM handles ENQUEUE/DEQUEUE on both requests internally; we
    "   only need to COMMIT WORK on success to persist the row movements.
    DATA: ls_request_from      TYPE trwbo_request,
          ls_request_to_header TYPE trwbo_request_header,
          lt_e071              TYPE tr_objects.

    ls_request_from-h-trkorr      = lv_src_trkorr_t.
    ls_request_to_header-trkorr   = lv_target_trkorr.

    " Build it_e071 with the (pgmid, object, obj_name) keys of selected rows
    lt_e071 = VALUE #( FOR <ls_sel> IN lt_selected
                       ( pgmid    = <ls_sel>-pgmid
                         object   = <ls_sel>-object
                         obj_name = <ls_sel>-obj_name ) ).

    CALL FUNCTION 'TR_MOVE_OBJECTS'
      EXPORTING
        it_e071                      = lt_e071
        iv_suppress_dialog           = 'X'
        iv_testmode                  = ' '
      CHANGING
        cs_request_from              = ls_request_from
        cs_request_to_header         = ls_request_to_header
      EXCEPTIONS
        database_access_error        = 1
        no_authorization             = 2
        request_from_other_system    = 3
        request_already_released     = 4
        wrong_source_client          = 5
        user_not_owner               = 6
        no_move_of_corr_entry        = 7
        object_entry_doesnt_exist    = 8
        duplicate_entry              = 9
        empty_lockkey                = 10
        foreign_lock                 = 11
        request_types_not_consistent = 12
        canceled_by_user             = 13
        OTHERS                       = 14.

    IF sy-subrc <> 0.
      " Surface the FM's own message verbatim — it carries the precise
      " reason (e.g. foreign lock with owner name, incompatible request
      " types K vs W, etc.) which is far more useful than a generic text.
      MESSAGE ID sy-msgid TYPE 'S' NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4 DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

    " Persist the row movements in E070/E071/E071K/TLOCK
    COMMIT WORK.

    MESSAGE |{ lines( lt_selected ) } object(s) moved from { lv_src_trkorr_t } to { lv_target_trkorr }|
            TYPE 'S'.

    " ----------------------------------------------------------------
    " 6) Refresh ALV
    " ----------------------------------------------------------------
    collect_data( ).
    mo_alv->refresh( ).
  ENDMETHOD.

ENDCLASS.

*----------------------------------------------------------------------*
* Main
*----------------------------------------------------------------------*
START-OF-SELECTION.
  lcl_app=>run( ).
