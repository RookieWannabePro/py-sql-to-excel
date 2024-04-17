SELECT A.* 
     , 'mv' ||' '|| A.ORI_INVOICE_NAME ||' ./'|| A.PRO_YN ||'/'|| A.FILE_NAME      AS "YYYYMM_mv.sh"
FROM ( SELECT DIFF.INV_DATE
            , DIFF.ACCOUNT_ID
            , DIFF.ACC_NO
            , DIFF.CARD_ID
            , DIFF.CARD_NUMBER
            , DIFF.INV_ID
            , DIFF.LAST_ID
            , DIFF.ORI_INVOICE_NAME
            , DIFF.FILE_NAME
            , DIFF.PAY_METHOD
            , CASE WHEN DIFF.FUL_PAY = '0' AND DIFF.TRX = '0' AND DIFF.PAY = '0' THEN 'N'
                   WHEN DIFF.ACC_NO = DIFF.PEN_CHARGE_ACC                        THEN 'N'
                   WHEN DIFF.CARD_ID = DIFF.PRO_ERROR_CARD_ID                    THEN 'N'
                   WHEN DIFF.CARD_ID = DIFF.PRE_ERROR_CARD_ID                    THEN 'N'
                   WHEN DIFF.CARD_ID = DIFF.MS_BO_CARD_ID                        THEN 'N'
                   WHEN DIFF.DIFF = '0' AND DIFF.ADJUST <> '0'                   THEN 'N_Y'
                   WHEN DIFF.DIFF = '0'                                          THEN 'Y'
                   WHEN DIFF.DIFF = DIFF.OWN_AMT AND DIFF.FUL_PAY = '0'          THEN 'Y'
                   WHEN DIFF.DIFF = DIFF.OWN_AMT AND DIFF.FUL_PAY <> '0'         THEN 'N'
                   WHEN DIFF.DIFF = DIFF.LAST_OWN_AMT                            THEN 'N'
                   ELSE 'N'
              END                                                                                              AS PRO_YN
            , CASE WHEN DIFF.FUL_PAY = '0' AND DIFF.TRX = '0' AND DIFF.PAY = '0' THEN 'Not Send'
                   WHEN DIFF.PEN_CHARGE_ACC = DIFF.PEN_CHARGE_ACC                THEN DIFF.PEN_CHARGE_REASON   -- #20, 11th Penalty
                   WHEN DIFF.CARD_ID = DIFF.PRO_ERROR_CARD_ID                    THEN DIFF.PRO_ERROR_REASON    -- #21 Partial Process Error
                   WHEN DIFF.CARD_ID = DIFF.PRE_ERROR_CARD_ID                    THEN DIFF.PRE_ERROR_REASON    -- #22 Representment Error
                   WHEN DIFF.CARD_ID = DIFF.MS_BO_CARD_ID                        THEN DIFF.MS_BO_REASON        -- #23 Miss BO Trx
                   WHEN DIFF.DIFF = '0' AND DIFF.ADJUST <> '0'                   THEN 'Modify Adjust List'
                   WHEN DIFF.DIFF = '0'                                          THEN 'Send'
                   WHEN DIFF.DIFF = DIFF.OWN_AMT AND DIFF.FUL_PAY = '0'          THEN 'OWN_AMT=Diff & FULL_PAY=0'
                   WHEN DIFF.DIFF = DIFF.OWN_AMT AND DIFF.FUL_PAY <> '0'         THEN 'OWN_AMT=Diff & FULL_PAY<>0'
                   WHEN DIFF.DIFF = DIFF.LAST_OWN_AMT                            THEN 'LAST_OWN_AMT=Diff'
                   ELSE 'Need Investigate'
              END                                                                                              AS REASON
            , DIFF.LAST_MIN_PAY
            , DIFF.LAST_FUL_PAY
            , DIFF.MIN_PAY
            , DIFF.FUL_PAY
            , ''                                                                                               AS MANUAL_AMNT
            , ''                                                                                               AS NEED_ADJ_AMNT
            , DIFF.DIFF
            , DIFF.SUM_ALL
            , DIFF.ADJUST
            , DIFF.TRX
            , DIFF.PRE_AMT
            , DIFF.PAY
            , DIFF.G_PAY                                                                                      
            , DIFF.PEN
            , DIFF.MAINT
            , DIFF.R_INTEREST
            , DIFF.LAST_OWN_AMT
            , DIFF.LAST_OWN_FOUNDS
            , DIFF.OWN_AMT
            , DIFF.OWN_FUNDS
            , DIFF.MIN_AMOUNT_DUE
            , DIFF.TOTAL_AMOUNT_DUE
            , DIFF.TOTAL_LIMIT
            , DIFF.INTEREST_AMOUNT
       FROM ( SELECT TO_CHAR ( CIV.INVOICE_DATE, 'YYYYMMDD' )                        AS INV_DATE
                   , CIV.ACCOUNT_ID                                                  AS ACCOUNT_ID
                   , AAV.ACCOUNT_NUMBER                                              AS ACC_NO
                   , CIV.ID                                                          AS INV_ID
                   , CIV2.ID                                                         AS LAST_ID
                   , PSF.FILE_NAME                                                   AS ORI_INVOICE_NAME
                   , CRD.CARD_ID                                                     AS CARD_ID
                   , CRD.CARD_NO                                                     AS CARD_NUMBER
                   , CRD.FILE_NAME                                                   AS FILE_NAME
                   , PT.PAYMENT_TYPE                                                 AS PAY_METHOD
                   , NVL ( ROUND ( CIV2.MIN_AMOUNT_DUE / 100, 2 ), 0 )               AS LAST_MIN_PAY
                   , NVL ( ROUND ( CIV2.TOTAL_AMOUNT_DUE / 100, 2 ), 0 )             AS LAST_FUL_PAY
                   , NVL ( ROUND ( CIV.MIN_AMOUNT_DUE / 100, 2 ), 0 )                AS MIN_PAY
                   , NVL ( ROUND ( CIV.TOTAL_AMOUNT_DUE / 100, 2 ), 0 )              AS FUL_PAY
                   , ( NVL ( ROUND ( CIV.TOTAL_AMOUNT_DUE / 100, 2 ), 0 ) ) - 
                     ( ( NVL ( ADJ.ADJ_AMNT, 0 ) ) + ( NVL ( TRX.TRX_AMNT, 0 ) ) + 
                       ( NVL ( ROUND ( CIV2.TOTAL_AMOUNT_DUE / 100, 2 ), 0 ) ) + 
                       ( NVL ( PAY.PAY_AMNT, 0 ) ) + ( NVL ( PEN.PEN_AMNT, 0 ) ) + 
                       ( NVL ( MNT.MAINTENACE_FEE_AMNT, 0 ) + 
                       ( NVL ( ROUND ( CIV.INTEREST_AMOUNT / 100, 2 ), 0 ) ) - 
                       ( NVL ( ROUND ( CIV2.OWN_FUNDS / 100, 2 ), 0 ) ) ) 
                     )                                                               AS DIFF
                   , ( ( NVL ( ADJ.ADJ_AMNT, 0 ) ) + ( NVL ( TRX.TRX_AMNT, 0 ) ) + 
                       ( NVL ( ROUND ( CIV2.TOTAL_AMOUNT_DUE / 100, 2 ), 0 ) ) + 
                       ( NVL ( PAY.PAY_AMNT, 0 ) ) + ( NVL ( PEN.PEN_AMNT, 0 ) ) + 
                       ( NVL ( MNT.MAINTENACE_FEE_AMNT, 0 ) + 
                       ( NVL ( ROUND ( CIV.INTEREST_AMOUNT / 100, 2 ), 0 ) ) - 
                       ( NVL ( ROUND ( CIV2.OWN_FUNDS / 100, 2 ), 0 ) ) )
                      )                                                               AS SUM_ALL
                   , NVL ( ADJ.ADJ_AMNT, 0 )                                          AS ADJUST
                   , NVL ( TRX.TRX_AMNT, 0 )                                          AS TRX
                   , NVL ( ROUND ( CIV2.TOTAL_AMOUNT_DUE / 100, 2 ), 0 )              AS PRE_AMT
                   , NVL ( PAY.PAY_AMNT, 0 )                                          AS PAY
                   , NVL ( G_PAY.G_PAY_AMNT, 0 )                                      AS G_PAY
                   , NVL ( PEN.PEN_AMNT, 0 )                                          AS PEN
                   , NVL ( MNT.MAINTENACE_FEE_AMNT, 0 )                               AS MAINT
                   , NVL ( ROUND ( CIV.INTEREST_AMOUNT / 100, 2 ), 0 )                AS R_INTEREST
                   , NVL ( ROUND ( CIV2.OWN_FUNDS / 100, 2 ), 0 )                     AS LAST_OWN_AMT
                   , NVL ( CIV2.OWN_FUNDS, 0 )                                        AS LAST_OWN_FOUNDS
                   , NVL ( ROUND ( CIV.OWN_FUNDS / 100, 2 ), 0 )                      AS OWN_AMT
                   , NVL ( CIV.OWN_FUNDS, 0 )                                         AS OWN_FUNDS
                   , NVL ( CIV.MIN_AMOUNT_DUE, 0 )                                    AS MIN_AMOUNT_DUE
                   , NVL ( CIV.TOTAL_AMOUNT_DUE, 0 )                                  AS TOTAL_AMOUNT_DUE
                   , NVL ( CIV.EXCEED_LIMIT, 0 )                                      AS TOTAL_LIMIT
                   , NVL ( CIV.INTEREST_AMOUNT, 0 )                                   AS INTEREST_AMOUNT
                   , PEN_CHARGE.ACC_NO                                                AS PEN_CHARGE_ACC
                   , PEN_CHARGE.REASON                                                AS PEN_CHARGE_REASON
                   , PRO_ERROR.CARD_ID                                                AS PRO_ERROR_CARD_ID
                   , PRO_ERROR.REASON                                                 AS PRO_ERROR_REASON
                   , PRE_ERROR.CARD_ID                                                AS PRE_ERROR_CARD_ID
                   , PRE_ERROR.REASON                                                 AS PRE_ERROR_REASON
                   , MS_BO.CARD_ID                                                    AS MS_BO_CARD_ID
                   , MS_BO.REASON                                                     AS MS_BO_REASON
              FROM MAIN.PRC_SESSION_FILE psf
                   LEFT JOIN MAIN.CRD_INVOICE_VW civ 
                          ON CIV.ID = PSF.OBJECT_ID
                   LEFT JOIN MAIN.ACC_ACCOUNT_VW aav 
                          ON AAV.ID = CIV.ACCOUNT_ID
                   LEFT JOIN MAIN.CRD_INVOICE_VW civ2 
                          ON CIV2.ACCOUNT_ID = AAV.ID 
                         AND TO_CHAR ( CIV2.INVOICE_DATE, 'YYYYMMDD') = '20240225'   -- Last Bill DATE
                   LEFT JOIN ( SELECT * FROM ( SELECT ICNV.CARD_NUMBER                                                                                         AS CARD_NO
                                                    , AAV2.ID                                                                                                  AS ACC_ID
                                                    , ICNV.CARD_ID                                                                                             AS CARD_ID
                                                    , COUNT ( * ) OVER ( PARTITION BY AAV2.ACCOUNT_NUMBER )                                                    AS RANK_CNT
                                                    , RANK ( ) OVER ( PARTITION BY AAV2.ACCOUNT_NUMBER 
                                                      ORDER BY ICV.CATEGORY DESC, ICV.REG_DATE DESC, ICIV.STATE, ICNV.CARD_NUMBER DESC, ICIV.SEQ_NUMBER DESC ) AS RANK_ID
                                                    , CASE WHEN ICV.CARD_TYPE_ID = 7015 THEN 'VPC#' || SUBSTR ( ICNV.CARD_NUMBER, -6 ) || '.PDF'
                                                           WHEN ICV.CARD_TYPE_ID = 7016 THEN 'VPG#' || SUBSTR ( ICNV.CARD_NUMBER, -6 ) || '.PDF'
                                                           WHEN ICV.CARD_TYPE_ID = 1009 THEN 'VBG#' || SUBSTR ( ICNV.CARD_NUMBER, -6 ) || '.PDF'
                                                           ELSE 'XXX# ' || SUBSTR ( ICNV.CARD_NUMBER, -4 )  || '.PDF' 
                                                           END                                                                                                  AS FILE_NAME
                                               FROM MAIN.ISS_CARD_VW icv
                                                    LEFT JOIN MAIN.PRD_CUSTOMER_VW pcv
                                                           ON ICV.CUSTOMER_ID = PCV.ID
                                                    LEFT JOIN MAIN.ISS_CARD_NUMBER_VW icnv
                                                           ON ICNV.CARD_ID = ICV.ID
                                                    LEFT JOIN MAIN.ACC_ACCOUNT_OBJECT_VW aaov
                                                           ON AAOV.OBJECT_ID = ICV.ID
                                                          AND AAOV.ENTITY_TYPE = 'ENTTCARD'
                                                    LEFT JOIN MAIN.ACC_ACCOUNT_VW aav2
                                                           ON AAV2.CUSTOMER_ID = PCV.ID
                                                          AND AAV2.ID = aaov.ACCOUNT_ID
                                                          AND AAV2.CONTRACT_ID = ICV.CONTRACT_ID
                                                          AND AAV2.ACCOUNT_TYPE <> 'ACTPLOYT'
                                                    LEFT JOIN MAIN.NET_CARD_TYPE_FEATURE_VW nctfv
                                                           ON nctfv.CARD_TYPE_ID = ICV.CARD_TYPE_ID
                                                    LEFT JOIN MAIN.ISS_CARD_INSTANCE_VW iciv 
                                                           ON iciv.CARD_ID = ICV.ID
                                               WHERE  1 = 1
                                                 AND NCTFV.CARD_FEATURE = 'CFCHCRDT' )
                               WHERE 1 = 1 AND RANK_ID = '1' ) CRD
                          ON CRD.ACC_ID = CIV.ACCOUNT_ID
                   LEFT JOIN ( SELECT  ACC.ID                                                                 AS ACC_ID
                                     , CASE WHEN PS.AMOUNT_ALGORITHM = 'POAA0001' THEN '0.2'
                                            WHEN PS.AMOUNT_ALGORITHM = 'POAA0002' THEN '1'
              			                  ELSE 'X' 
                                       END                                                                    AS PAYMENT_TYPE
              			           , COUNT ( * ) OVER ( PARTITION BY ACC.ACCOUNT_NUMBER )                   AS RANK_CNT
              		               , RANK ( ) OVER ( PARTITION BY ACC.ACCOUNT_NUMBER ORDER BY PS.PART_KEY ) AS RANK_ID
                               FROM MAIN.PMO_SCHEDULE ps
                                    JOIN MAIN.ACC_ACCOUNT ACC
              			            ON PS.OBJECT_ID = ACC.ID ) PT
                           ON PT.ACC_ID = CIV.ACCOUNT_ID
                   LEFT JOIN ( 
/**********************************  ADJUSTMENT  **********************************/
                               SELECT A.ACC_NO                AS ACC_NO
                                    , SUM ( A.ADJ_AMOUNT )    AS ADJ_AMNT
                               FROM ( 
                                      SELECT OPV.ACCOUNT_NUMBER                                                                         AS ACC_NO
                                           , CASE WHEN OOV.OPER_TYPE = 'OPTP0402' THEN ( OOV.OPER_AMOUNT ) / POWER ( 10, 2 )
                                                  WHEN OOV.OPER_TYPE = 'OPTP0422' THEN ( OOV.OPER_AMOUNT * ( -1 ) ) / POWER ( 10, 2 )
                                                  ELSE ( OOV.OPER_AMOUNT * ( -1 ) ) / POWER ( 10, 2 ) 
                                             END                                                                                        AS ADJ_AMOUNT
                                      FROM MAIN.OPR_OPERATION_VW oov 
                                           LEFT JOIN MAIN.OPR_PARTICIPANT_VW opv 
                                                  ON OOV.ID = OPV.OPER_ID
                                                 AND OPV.PARTICIPANT_TYPE = 'PRTYISS'
                                           LEFT JOIN MAIN.ACC_ACCOUNT_VW aav3 
                                                  ON OPV.ACCOUNT_ID = AAV3.ID
                                      WHERE 1 = 1
                                        AND TO_CHAR ( OOV.OPER_DATE, 'YYYYMMDD' ) BETWEEN '20240226' AND '20240325'
                                        AND OOV.OPER_TYPE IN ( 'OPTP0402', 'OPTP0422' )
                                        AND OOV.STATUS = 'OPST0400'
                                      ORDER BY OOV.OPER_DATE, OOV.OPER_TYPE  ) A
                               GROUP BY A.ACC_NO
                               ORDER BY A.ACC_NO 
                             ) ADJ     
                          ON ADJ.ACC_NO = AAV.ACCOUNT_NUMBER 
                   LEFT JOIN ( 
/**********************************  TRANSACTION  **********************************/
                               SELECT T.ACC_NO                        AS ACC_NO
                                    , SUM ( T.STTL_AMOUNT ) / 100     AS TRX_AMNT
                               FROM ( 
                                      SELECT AAV3.ACCOUNT_NUMBER                                                                                                                       AS ACC_NO
                                           , CASE WHEN OOV.OPER_TYPE = 'OPTP0000'                                                                THEN OPV.ACCOUNT_AMOUNT
                                                  WHEN OOV.OPER_TYPE = 'OPTP0001' AND OOV.STTL_TYPE = 'STTT0010'                                 THEN OPV.ACCOUNT_AMOUNT
                                                  WHEN OOV.OPER_TYPE = 'OPTP0001' AND OOV.STTL_TYPE = 'STTT0100' AND OPV.ACCOUNT_AMOUNT <= 20000 THEN ( OPV.ACCOUNT_AMOUNT + 500 )
                                                  WHEN OOV.OPER_TYPE = 'OPTP0001' AND OOV.STTL_TYPE = 'STTT0100' AND OPV.ACCOUNT_AMOUNT >  20000 THEN ( OPV.ACCOUNT_AMOUNT + ( OPV.ACCOUNT_AMOUNT * 0.02 ) )
                                                  WHEN OOV.OPER_TYPE = 'OPTP0012'                                                                THEN OPV.ACCOUNT_AMOUNT
                                                  WHEN OOV.OPER_TYPE = 'OPTP0020'                                                                THEN OPV.ACCOUNT_AMOUNT * ( -1 ) 
                                                  ELSE OOV.OPER_AMOUNT
                                             END                                                                                                                                       AS STTL_AMOUNT
                                      FROM MAIN.OPR_OPERATION_VW oov 
                                           LEFT JOIN MAIN.OPR_PARTICIPANT_VW opv 
                                                  ON OOV.ID = OPV.OPER_ID
                                                 AND OPV.PARTICIPANT_TYPE = 'PRTYISS'
                                           LEFT JOIN MAIN.ACC_ACCOUNT_VW aav3 
                                                  ON OPV.ACCOUNT_ID = AAV3.ID
                                      WHERE 1 = 1
                                        AND TO_CHAR ( OOV.HOST_DATE, 'YYYYMMDD' ) BETWEEN '20240226' AND '20240325'
                                        AND ( ( OOV.OPER_TYPE = 'OPTP0000' AND OOV.STTL_TYPE = 'STTT0010' AND OOV.STATUS = 'OPST0400' AND OOV.MSG_TYPE = 'MSGTBTCH' )
                                         OR   ( OOV.OPER_TYPE = 'OPTP0000' AND OOV.STTL_TYPE = 'STTT0100' AND OOV.STATUS = 'OPST0402' AND OOV.MSG_TYPE = 'MSGTAUTH' )
                                         OR   ( OOV.OPER_TYPE = 'OPTP0000' AND OOV.STTL_TYPE = 'STTT0100' AND OOV.STATUS = 'OPST0400' AND OOV.MSG_TYPE = 'MSGTPAMC' )
                                         OR   ( OOV.OPER_TYPE = 'OPTP0001' AND OOV.STTL_TYPE = 'STTT0010' AND OOV.STATUS = 'OPST0400' AND OOV.MSG_TYPE = 'MSGTAUTH' )
                                         OR   ( OOV.OPER_TYPE = 'OPTP0001' AND OOV.STTL_TYPE = 'STTT0100' AND OOV.STATUS = 'OPST0400' AND OOV.MSG_TYPE = 'MSGTPRES' )
                                         OR   ( OOV.OPER_TYPE = 'OPTP0012' AND OOV.STTL_TYPE = 'STTT0010' AND OOV.STATUS = 'OPST0400' AND OOV.MSG_TYPE = 'MSGTAUTH' )
                                         OR   ( OOV.OPER_TYPE = 'OPTP0020' AND OOV.STTL_TYPE = 'STTT0100' AND OOV.STATUS = 'OPST0400' AND OOV.MSG_TYPE = 'MSGTPRES' ) )
                                        AND LENGTH ( AAV3.ACCOUNT_NUMBER ) = '7' ) T
                               GROUP BY T.ACC_NO
                               ORDER BY T.ACC_NO
                             ) TRX
                          ON TRX.ACC_NO = AAV.ACCOUNT_NUMBER
/************************************  PAYMENT  ************************************/
                   LEFT JOIN ( SELECT P.ACC_NO                   AS ACC_NO
                                    , SUM ( P.PAY_AMOUNT )       AS PAY_AMNT
                               FROM ( 
                                      SELECT AAV.ACCOUNT_NUMBER                                  AS ACC_NO
                                           , ( OOV.OPER_AMOUNT  * ( -1 ) ) / POWER ( 10, 2 )     AS PAY_AMOUNT
                                      FROM MAIN.OPR_OPERATION_VW oov
                                           LEFT JOIN MAIN.OPR_PARTICIPANT_VW opv
                                                  ON OOV.ID = OPV.OPER_ID
                                                 AND OPV.PARTICIPANT_TYPE = 'PRTYISS'
                                           LEFT JOIN MAIN.ACC_ACCOUNT_VW aav
                                                  ON OPV.ACCOUNT_ID = AAV.ID    
                                      WHERE 1 = 1
                                        AND TO_CHAR ( OOV.OPER_DATE, 'YYYYMMDD' ) BETWEEN '20240226' AND '20240325'
                                        AND OOV.OPER_TYPE IN ( 'OPTP0028','OPTP7001' )
                                        AND ( ( OOV.OPER_TYPE IN ('OPTP0028','OPTP7001') AND OOV.MSG_TYPE = 'MSGTPRES' )                             -- OPTP0028: PAYMENT, OPTP7001: AUTO-PAYMENT
                                         OR   ( OOV.OPER_TYPE IN ('OPTP0026' ) AND OOV.MSG_TYPE = 'MSGTAUTH' AND OOV.STATUS_REASON = 'RESP0001' ) )  -- OPTP0026: P2P_CREDIT
                                        AND OOV.STATUS = 'OPST0400') P
                               GROUP BY P.ACC_NO
                               ORDER BY P.ACC_NO
                             ) PAY
                          ON PAY.ACC_NO = AAV.ACCOUNT_NUMBER
/*********************************  GRACE_PAYMENT  *********************************/
                   LEFT JOIN ( SELECT G_P.ACC_NO                   AS ACC_NO
                                    , SUM ( G_P.PAY_AMOUNT )       AS G_PAY_AMNT
                               FROM ( 
                                      SELECT AAC.ACCOUNT_NUMBER                            AS ACC_NO
                                          , ( OOV.OPER_AMOUNT * ( -1 ) ) / POWER ( 10, 2 ) AS PAY_AMOUNT
                                      FROM MAIN.OPR_OPERATION_VW oov
                                           LEFT JOIN MAIN.OPR_PARTICIPANT_VW opv
                                                  ON OOV.ID = OPV.OPER_ID
                                                 AND OPV.PARTICIPANT_TYPE = 'PRTYISS'
                                           LEFT JOIN MAIN.ACC_ACCOUNT aac
                                                  ON OPV.ACCOUNT_ID = AAC.ID    
                                      WHERE 1 = 1
                                        AND TO_CHAR ( OOV.OPER_DATE, 'YYYYMMDD' ) BETWEEN '20240226' AND '20240310'
                                        AND ( ( OOV.OPER_TYPE IN ('OPTP0028','OPTP7001') AND OOV.MSG_TYPE = 'MSGTPRES' )
                                         OR   ( OOV.OPER_TYPE IN ('OPTP0026' ) AND OOV.MSG_TYPE = 'MSGTAUTH' AND OOV.STATUS_REASON = 'RESP0001' ) )
                                        AND OOV.STATUS = 'OPST0400' ) G_P
                               GROUP BY G_P.ACC_NO
                               ORDER BY G_P.ACC_NO
                             ) G_PAY
                          ON G_PAY.ACC_NO = AAV.ACCOUNT_NUMBER
/************************************  PENALTY  ************************************/   
                   LEFT JOIN ( SELECT PN.ACC_NO                   AS ACC_NO
                                    , SUM ( PN.PEN_AMOUNT )       AS PEN_AMNT
                               FROM (
                                      SELECT OPV.ACCOUNT_NUMBER                    AS ACC_NO
                                           , ROUND ( OOV.OPER_AMOUNT / 100, 2 )    AS PEN_AMOUNT
                                      FROM MAIN.OPR_OPERATION_VW OOV
                                           LEFT JOIN MAIN.OPR_PARTICIPANT_VW OPV
                                                  ON OOV.ID = OPV.OPER_ID
                                                 AND OPV.PARTICIPANT_TYPE = 'PRTYISS'
                                      WHERE 1 = 1
                                        AND OOV.OPER_TYPE = 'OPTP0119'
                                        AND OOV.MSG_TYPE = 'MSGTPRES'
                                        AND OOV.STATUS IN ( 'OPST0500', 'OPST0400' ) -- OPST0400:PROC,  OPST0500:ERROR
                                        AND OOV.STTL_TYPE = 'STTT0001'
                                        AND OOV.OPER_REASON = 'FETP1003'
                                        AND TO_CHAR ( OOV.OPER_DATE, 'YYYYMMDD' ) BETWEEN '20240226' AND '20240325'
                                      ) PN
                               GROUP BY PN.ACC_NO
                               ORDER BY PN.ACC_NO 
                             ) PEN
                          ON PEN.ACC_NO = AAV.ACCOUNT_NUMBER
/********************************  MAINTENANCE FEE  ********************************/
                   LEFT JOIN ( SELECT OPV.ACCOUNT_NUMBER                  AS ACC_NO
                                    , ROUND ( OOV.OPER_AMOUNT / 100, 2 )  AS MAINTENACE_FEE_AMNT
                               FROM MAIN.OPR_OPERATION_VW oov
                                    LEFT JOIN MAIN.OPR_PARTICIPANT_VW opv
                                           ON OOV.ID = OPV.OPER_ID
                                          AND OPV.PARTICIPANT_TYPE = 'PRTYISS'
                               WHERE 1 = 1
                                 AND OOV.OPER_TYPE = 'OPTP0119'
                                 AND OOV.MSG_TYPE = 'MSGTPRES'
                                 AND OOV.STATUS IN ( 'OPST0400' )
                                 AND OOV.OPER_REASON = 'FETP0102'
                                 AND TO_CHAR ( OOV.OPER_DATE,'YYYYMMDD' ) BETWEEN '20240226' AND '20240325'
                                 AND LENGTH ( OPV.ACCOUNT_NUMBER ) = 7
                                 ORDER BY OOV.STATUS, OOV.OPER_AMOUNT , OPV.ACCOUNT_NUMBER
                              ) MNT
                          ON MNT.ACC_NO = AAV.ACCOUNT_NUMBER
/***************************  #20, 11th ChargeD Penalty  ***************************/
                   LEFT JOIN ( SELECT AAC.ACCOUNT_NUMBER                            AS ACC_NO
                                    , '#20, 11th Charge Penalty'                    AS REASON
                               FROM MAIN.OPR_OPERATION_VW oov
                                    LEFT JOIN MAIN.OPR_PARTICIPANT_VW opv
                                           ON OOV.ID = OPV.OPER_ID
                                          AND OPV.PARTICIPANT_TYPE = 'PRTYISS'
                                    LEFT JOIN MAIN.ACC_ACCOUNT aac
                                           ON OPV.ACCOUNT_ID = AAC.ID
                               WHERE 1 = 1
                                 AND TO_CHAR ( OOV.OPER_DATE, 'YYYYMMDD' ) = '20240311'
                                 AND ( ( OOV.OPER_TYPE IN ('OPTP0028','OPTP7001') AND OOV.MSG_TYPE = 'MSGTPRES' )                            -- OPTP0028: PAYMENT, OPTP7001: AUTO-PAYMENT
                                  OR   ( OOV.OPER_TYPE IN ('OPTP0026' ) AND OOV.MSG_TYPE = 'MSGTAUTH' AND OOV.STATUS_REASON = 'RESP0001' ) ) -- OPTP0026: P2P_CREDIT
                                 AND OOV.MSG_TYPE = 'MSGTPRES'
                                 AND OOV.STATUS = 'OPST0400'
                              ) PEN_CHARGE       
                          ON PEN_CHARGE.ACC_NO = AAV.ACCOUNT_NUMBER
/***************************  #21, Partial Process Error  **************************/
                   LEFT JOIN ( SELECT ICV.ID                           AS CARD_ID
                                    , '#21, Partial Process Error'     AS REASON
                               FROM MAIN.OPR_OPERATION_VW oov
                                    LEFT JOIN MAIN.OPR_PARTICIPANT_VW opv
                                           ON OOV.ID = OPV.OPER_ID
                                          AND OPV.PARTICIPANT_TYPE = 'PRTYISS'
                                    LEFT JOIN MAIN.ISS_CARD_VW icv
                                           ON ICV.ID = OPV.CARD_ID
                               WHERE 1 = 1
                                 AND TO_CHAR ( OOV.OPER_DATE, 'YYYYMMDD' ) BETWEEN '20240226' AND '20240325'
                                 AND OOV.OPER_TYPE = 'OPTP0000'
                                 AND OOV.STATUS    = 'OPST0600'
                                 AND OOV.MSG_TYPE  = 'MSGTPACC'
                                 AND ICV.CARD_TYPE_ID IN ( 7015, 7016, 1009 )
                             ) PRO_ERROR
                          ON PRO_ERROR.CARD_ID = CRD.CARD_ID
/***************************  #22, Representment Error  ****************************/
                   LEFT JOIN ( SELECT
                                      ICV.ID                         AS CARD_ID
                                    , '#22, Representment Error'     AS REASON
                               FROM MAIN.OPR_OPERATION_VW oov
                                    JOIN MAIN.OPR_PARTICIPANT_VW opv
                                      ON OOV.ID = OPV.OPER_ID
                                     AND OPV.PARTICIPANT_TYPE = 'PRTYISS'
                                    JOIN MAIN.ISS_CARD_VW icv
                                      ON ICV.ID = OPV.CARD_ID
                               WHERE 1 = 1
                                 AND TO_CHAR ( OOV.HOST_DATE, 'YYYYMMDD' ) BETWEEN '20240226' AND '20240325'
                                 AND OOV.OPER_TYPE = 'OPTP0000'
                                 AND OOV.STATUS    = 'OPST0600'
                                 AND OOV.MSG_TYPE  = 'MSGTREPR'
                                 AND ICV.CARD_TYPE_ID IN ( 7015, 7016, 1009 )    
                             ) PRE_ERROR
                          ON PRO_ERROR.CARD_ID = CRD.CARD_ID
/***************************  #23, Miss BO Transaction  ****************************/
                   LEFT JOIN ( SELECT
                                      ICV.ID                     AS CARD_ID
                                    , '#23, Miss BO Trx'         AS REASON
                               FROM MAIN.OPR_OPERATION_VW oov
                                    JOIN MAIN.OPR_PARTICIPANT_VW opv
                                      ON OOV.ID = OPV.OPER_ID
                                     AND OPV.PARTICIPANT_TYPE = 'PRTYISS'
                                    JOIN MAIN.ISS_CARD_VW icv
                                      ON ICV.ID = OPV.CARD_ID
                               WHERE 1 = 1
                                 AND TO_CHAR ( OOV.HOST_DATE, 'YYYYMMDD' ) BETWEEN '20240226' AND '20240325'
                                 AND OOV.OPER_TYPE = 'OPTP0000'
                                 AND OOV.STATUS IN ( 'OPST0102', 'OPST0102' )
                                 AND OOV.MSG_TYPE  = 'MSGTAUTH'
                                 AND ICV.CARD_TYPE_ID IN ( 7015, 7016, 1009 )              
                             ) MS_BO
                          ON MS_BO.CARD_ID = CRD.CARD_ID
              WHERE 1 = 1
                AND PSF.FILE_TYPE = 'FLTPROUT'
                AND FILE_ATTR_ID = '70000074'
                AND TO_CHAR ( PSF.FILE_DATE, 'YYYYMM' ) = '202403' 
                AND TO_CHAR ( CIV.INVOICE_DATE, 'YYYYMMDD' ) = '20240325'
              ORDER BY CIV.ID
            ) DIFF
    ) A