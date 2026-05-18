*&---------------------------------------------------------------------*
*& Report ZTR_MOVE_OBJECTS_MASS
*&---------------------------------------------------------------------*
*& Mass move of objects between transport requests (ALV based)
*& Similar to SE10 "Move Object" but allows multi-selection
*&---------------------------------------------------------------------*
*& Author : JESUSEDM
*& Date   : 20260518
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
        cl_salv_table=>factory(
          IMPORTING r_salv_table = mo_alv
          CHANGING  t_table      = mt_out ).

      CATCH cx_salv_msg INTO DATA(lx_msg).
        MESSAGE lx_msg TYPE 'E'.
        RETURN.
    ENDTRY.

    " Selection mode: multi-row, with checkboxes — needed for mass move later
    mo_alv->get_selections( )->set_selection_mode( if_salv_c_selection_mode=>row_column ).

    " Standard ALV functions on
    mo_alv->get_functions( )->set_all( ).

    configure_columns( ).
    configure_functions( ).

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
    " Placeholder for custom toolbar buttons (e.g. MOVE_OBJ)
    " To be added in v2. For now, only standard ALV functions are active.
    RETURN.
  ENDMETHOD.

  METHOD on_link_click.
    " Hotspot on Request column -> open SE10 for that request
    READ TABLE mt_out ASSIGNING FIELD-SYMBOL(<ls>) INDEX row.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    CASE column.
      WHEN 'TRKORR'.
        " Open Transport Organizer focused on this request
        SET PARAMETER ID 'KOR' FIELD <ls>-trkorr.
        CALL TRANSACTION 'SE10' AND SKIP FIRST SCREEN.

      WHEN OTHERS.
        RETURN.
    ENDCASE.
  ENDMETHOD.

  METHOD on_user_command.
    " Placeholder for future custom functions (MOVE_OBJ etc.)
    CASE e_salv_function.

      WHEN OTHERS.
        " Refresh data and ALV
        collect_data( ).
        mo_alv->refresh( ).
    ENDCASE.
  ENDMETHOD.

ENDCLASS.

*----------------------------------------------------------------------*
* Main
*----------------------------------------------------------------------*
START-OF-SELECTION.
  lcl_app=>run( ).
