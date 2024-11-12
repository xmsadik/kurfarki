CLASS lhc_ZFI003_DD_Behaviour DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR ZFI003_DD_Behaviourd RESULT result.

    METHODS read FOR READ
      IMPORTING keys FOR READ ZFI003_DD_Behaviourd RESULT result.

    METHODS lock FOR LOCK
      IMPORTING keys FOR LOCK ZFI003_DD_Behaviourd.

    METHODS kur_farki FOR MODIFY
      IMPORTING keys FOR ACTION ZFI003_DD_Behaviourd~kur_farki.

ENDCLASS.

CLASS lhc_ZFI003_DD_Behaviour IMPLEMENTATION.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD read.
  ENDMETHOD.

  METHOD lock.
  ENDMETHOD.

  METHOD kur_farki.
    DATA lv_index_item TYPE int4.

    IF keys IS INITIAL.
      APPEND VALUE #( dummy = 1 ) TO failed-behaviour.

      DATA(lv_msg) = new_message_with_text( text = 'Veri olmadan işlem yapılamaz.' severity = cl_abap_behv=>ms-error ).

      APPEND VALUE #( %msg  = lv_msg
                      dummy = 1 ) TO reported-behaviour.
      EXIT.
    ENDIF.

    DATA(ls_data) = VALUE #( keys[ dummy = 1 ] OPTIONAL ).

    DATA: lt_je_deep TYPE TABLE FOR ACTION IMPORT i_journalentrytp~Post,
          lv_cid     TYPE abp_behv_cid.
    TRY.
        lv_cid = to_upper( cl_uuid_factory=>create_system_uuid( )->create_uuid_x16( ) ).
      CATCH cx_uuid_error.
        ASSERT 1 = 0.
    ENDTRY.

*    SELECT tax~* FROM zfi003_t_taxcode AS tax
*    INNER JOIN @ls_data-%param-_itemtable AS itable ON tax~tax_code = itable~tax_code
*    INTO TABLE @DATA(lt_taxcode).
*    IF sy-subrc NE 0.
*      APPEND VALUE #( dummy = 1 ) TO failed-behaviour.
*
*      lv_msg = new_message_with_text( text = 'Vergi bakım tablosunu doldurunuz.' severity = cl_abap_behv=>ms-error ).
*
*      APPEND VALUE #( %msg  = lv_msg
*                      dummy = 1 ) TO reported-behaviour.
*      EXIT.
*    ENDIF.

    IF ls_data-%param-customer IS NOT INITIAL AND ls_data-%param-supplier IS NOT INITIAL.
      APPEND VALUE #( dummy = 1 ) TO failed-behaviour.

      lv_msg = new_message_with_text( text = 'Müşteri ve Satıcı aynı anda doldurulamaz.' severity = cl_abap_behv=>ms-error ).

      APPEND VALUE #( %msg  = lv_msg
                      dummy = 1 ) TO reported-behaviour.
      EXIT.
    ENDIF.

*    SORT lt_taxcode BY tax_code.
*    DELETE ADJACENT DUPLICATES FROM lt_taxcode COMPARING tax_code.

*    LOOP AT ls_data-%param-_itemtable INTO DATA(ls_control).
*      READ TABLE lt_taxcode TRANSPORTING NO FIELDS WITH KEY tax_code = ls_control-tax_code.
*      IF sy-subrc NE 0.
*        APPEND VALUE #( dummy = 1 ) TO failed-behaviour.
*
*        lv_msg = new_message_with_text( text = |{ ls_control-tax_code } vergisi bakım tablosunda bulunmamaktadır.| severity = cl_abap_behv=>ms-error ).
*
*        APPEND VALUE #( %msg  = lv_msg
*                        dummy = 1 ) TO reported-behaviour.
*        EXIT.
*      ENDIF.
*
*    ENDLOOP.

    IF ls_data-%param-_itemtable IS NOT INITIAL.

      DATA(lv_line) = lines( ls_data-%param-_itemtable ).

    ENDIF.

    IF reported-behaviour IS INITIAL.
      APPEND INITIAL LINE TO lt_je_deep ASSIGNING FIELD-SYMBOL(<je_deep>).
      <je_deep>-%cid = lv_cid.
      <je_deep>-%param = VALUE #(
      BusinessTransactionType = 'RFBU'
      accountingdocumenttype = ls_data-%param-acc_type
      companycode = ls_data-%param-com_code
      createdbyuser = sy-uname
      documentdate = ls_data-%param-doc_date
      postingdate = ls_data-%param-post_date
      AccountingDocumentHeaderText = ls_data-%param-doc_header_text
      documentreferenceid = ls_data-%param-doc_reference
      TaxDeterminationDate = ls_data-%param-post_date

      _aritems = COND #( WHEN ls_data-%param-customer IS NOT INITIAL
                         THEN VALUE #( ( GLAccountLineItem = '000001'
                                         customer          = ls_data-%param-customer
                                         _currencyamount   = VALUE #( ( currencyrole           = '00'
                                                                        journalentryitemamount = 0
                                                                        currency               = ls_data-%param-doc_currency )
                                                                      ( currencyrole           = '10'
                                                                        journalentryitemamount = COND #( WHEN ls_data-%param-debit_credit_code = 'A'
                                                                                                         THEN ls_data-%param-amount * -1
                                                                                                         WHEN ls_data-%param-debit_credit_code = 'B'
                                                                                                         THEN ls_data-%param-amount
                                                                                                       )
                                                                        currency               = 'TRY' )
*                                                                    currency = ls_data-%param-currency )
                                                                      ( currencyrole           = '30'
                                                                        journalentryitemamount = 0
                                                                        currency               = 'EUR' )
                                                                      ( currencyrole           = 'Z0'
                                                                        journalentryitemamount = 0
                                                                        currency               = 'USD' )
)
                                       DocumentItemText = ls_data-%param-doc_item_text
                                          ) ) )
        _apitems = COND #( WHEN ls_data-%param-supplier IS NOT INITIAL
                           THEN VALUE #( ( GLAccountLineItem = '000001'
                                           supplier          = ls_data-%param-supplier
                                           _currencyamount   = VALUE #( ( currencyrole           = '00'
                                                                          journalentryitemamount = 0
                                                                          currency               = ls_data-%param-doc_currency )
                                                                        ( currencyrole           = '10'
                                                                          journalentryitemamount = COND #( WHEN ls_data-%param-debit_credit_code = 'A'
                                                                                                           THEN ls_data-%param-amount * -1
                                                                                                           WHEN ls_data-%param-debit_credit_code = 'B'
                                                                                                           THEN ls_data-%param-amount
                                                                                                           )
                                                                          currency               = 'TRY' )
*                                                                    currency = ls_data-%param-currency )
                                                                        ( currencyrole           = '30'
                                                                          journalentryitemamount = 0
                                                                          currency               = 'EUR' )
                                                                        ( currencyrole           = 'Z0'
                                                                          journalentryitemamount = 0
                                                                          currency               = 'USD' )
                                                                          )
                                       DocumentItemText = ls_data-%param-doc_item_text
                                          ) ) )
         _glitems = VALUE #( FOR ls_item IN ls_data-%param-_itemtable INDEX INTO lv_index
*                             FOR ls_taxcode IN lt_taxcode WHERE ( tax_code = ls_item-tax_code )
                           ( GLAccountLineItem = lv_index + 1
                             GLAccount         = ls_item-gl_account
                             _currencyamount   = VALUE #( ( currencyrole           = '00'
                                                            journalentryitemamount = 0
                                                            currency               = ls_data-%param-doc_currency )
                                                          ( currencyrole           = '10'
                                                            journalentryitemamount = COND #( WHEN ls_item-debit_credit_code = 'A'
*                                                                                             THEN ( ( 100 - ls_taxcode-percent ) / 100 ) * ls_item-amount * -1
                                                                                             THEN ls_item-amount * -1
                                                                                             WHEN ls_item-debit_credit_code = 'B'
*                                                                                             THEN ( ( 100 - ls_taxcode-percent ) / 100 ) * ls_item-amount
                                                                                             THEN ls_item-amount
                                                                                             )
*                                                            TaxBaseAmount = ( ( 100 - ls_taxcode-percent ) / 100 ) * ls_item-amount
                                                            currency               = 'TRY' )

*                                                         currency = ls_data-%param-currency )
                                                          ( currencyrole           = '30'
                                                            journalentryitemamount = 0
                                                            currency               = 'EUR' )
                                                          ( currencyrole           = 'Z0'
                                                            journalentryitemamount = 0
                                                            currency               = 'USD' )
                                                            )
                            DocumentItemText    = ls_item-doc_item_text
                            AssignmentReference = ls_item-assign_ref
                            TaxCode             = ls_item-tax_code
                            ProfitCenter        = ls_item-profit_center
                            CostCenter          = ls_item-cost_center ) )
*         _TaxItems = VALUE #( FOR ls_item IN ls_data-%param-_itemtable INDEX INTO lv_index
*                              FOR ls_taxcode IN lt_taxcode WHERE ( tax_code = ls_item-tax_code )
*                             ( GLAccountLineItem = lv_line + lv_index + 1
*                               taxcode           = ls_item-tax_code
*                               _currencyamount   = VALUE #( ( currencyrole           = '00'
*                                                              journalentryitemamount = 0
*                                                              currency               = 'EUR' )""Burası fiori ekranına eklendikten sonra güncellenecek
*                                                            ( currencyrole           = '10'
*                                                              journalentryitemamount = COND #( WHEN ls_item-debit_credit_code = 'A'
*                                                                                             THEN ( ls_taxcode-percent / 100 ) * ls_item-amount * -1
*                                                                                             WHEN ls_item-debit_credit_code = 'B'
*                                                                                             THEN ( ls_taxcode-percent / 100 ) * ls_item-amount )
**                                                              journalentryitemamount = ( ls_taxcode-percent / 100 ) * ls_item-amount
**                                                              journalentryitemamount = '0.00'
*                                                              TaxBaseAmount          = COND #( WHEN ls_item-debit_credit_code = 'A'
*                                                                                             THEN ( ( 100 - ls_taxcode-percent ) / 100 ) * ls_item-amount * -1
*                                                                                             WHEN ls_item-debit_credit_code = 'B'
*                                                                                             THEN ( ( 100 - ls_taxcode-percent ) / 100 ) * ls_item-amount )
*                                                              currency               = 'TRY' )
**                                                         currency = ls_data-%param-currency )
*                                                            ( currencyrole           = '30'
*                                                              journalentryitemamount = 0
*                                                              currency               = 'EUR' )
*                                                            ( currencyrole           = 'Z0'
*                                                              journalentryitemamount = 0
*                                                              currency               = 'USD' )
*                                                              )
*                            ConditionType         = ls_taxcode-move_type
*                            TaxItemClassification = ls_taxcode-tax_type ) )

                            ).

*      IF ls_data-%param-simulation IS NOT INITIAL.
*        result = VALUE #( ( %key-dummy = 1
*                            %param = CORRESPONDING #( ls_data-%param ) ) ).
*      ELSE.
      CLEAR zfi003_cl_dd_behaviourd=>gt_table.
      zfi003_cl_dd_behaviourd=>gt_table = lt_je_deep.
*      ENDIF.
    ENDIF.


  ENDMETHOD.

ENDCLASS.

CLASS lsc_ZFI003_DD_BEHAVIOUR DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.

    METHODS finalize REDEFINITION.

    METHODS check_before_save REDEFINITION.

    METHODS save REDEFINITION.

    METHODS cleanup REDEFINITION.

    METHODS cleanup_finalize REDEFINITION.

    METHODS adjust_numbers REDEFINITION.

ENDCLASS.

CLASS lsc_ZFI003_DD_BEHAVIOUR IMPLEMENTATION.

  METHOD finalize.
    CLEAR zfi003_cl_dd_behaviourd=>gv_pid.

    IF zfi003_cl_dd_behaviourd=>gt_table IS NOT INITIAL.
      MODIFY ENTITIES OF i_journalentrytp
      ENTITY journalentry
      EXECUTE post FROM zfi003_cl_dd_behaviourd=>gt_table
      FAILED DATA(ls_failed_deep)
      REPORTED DATA(ls_reported_deep)
      MAPPED DATA(ls_mapped_deep).
      IF ls_failed_deep IS NOT INITIAL.
        LOOP AT ls_reported_deep-journalentry ASSIGNING FIELD-SYMBOL(<ls_reported_deep>).
          DATA(lv_result) = <ls_reported_deep>-%msg->if_message~get_text( ).

          APPEND VALUE #( %msg  = <ls_reported_deep>-%msg
                          dummy = 1 ) TO reported-behaviour.
        ENDLOOP.
      ELSE.

        DATA(ls_map) = VALUE #( ls_mapped_deep-journalentry[ 1 ] OPTIONAL ).

        zfi003_cl_dd_behaviourd=>gv_pid = ls_map-%pid.

      ENDIF.
    ENDIF.

  ENDMETHOD.

  METHOD check_before_save.

  ENDMETHOD.

  METHOD save.

    IF zfi003_cl_dd_behaviourd=>gv_pid IS NOT INITIAL.
      CONVERT KEY OF i_journalentrytp FROM zfi003_cl_dd_behaviourd=>gv_pid TO DATA(ls_convert).

      DATA(lv_msg) = new_message_with_text( text = |Fatura: { ls_convert-AccountingDocument }| severity = cl_abap_behv=>ms-success ).

      APPEND VALUE #( %msg  = lv_msg
                      dummy = 1
                      ) TO reported-behaviour.

    ENDIF.

  ENDMETHOD.

  METHOD cleanup.
  ENDMETHOD.

  METHOD cleanup_finalize.
  ENDMETHOD.

  METHOD adjust_numbers.

  ENDMETHOD.

ENDCLASS.