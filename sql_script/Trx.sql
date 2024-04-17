/*
 * #11_1 (FE) Manual Bill trx source data
 * */
SELECT -- (FE) BALANCE INQ
   SUBSTR(A.hpan,1,6) || 'XX..XX' || SUBSTR(A.hpan,11,6) AS CARD_NO_MSK
 , A.hpan                                                AS CARD_NO
 , TO_CHAR(A.udate)                                      AS TRNX_DATE
 , TO_CHAR(A.udate)                                      AS POST_DATE
 , b.trans_name || ' ' || A.address_city                 AS TRNX_DEC
 , 0.5                                                  AS ORG_AMNT
 , 840                                                   AS CR_CODE
 , 0.5                                                  AS TRNX_AMNT
 , ' '                                                   AS SETT_ACC
 , '08'                                                  AS TRNX_TYPE
 , ' ' AS ACC_NO
 , a.acct1                                AS ACC
FROM svista.curr_trans A
     JOIN svista.TRANSACTION b
                   ON A.trans_type = b.trans_type
      LEFT OUTER JOIN svista.iso_currency_codes C
                   ON A.currency = C.code_n3
      LEFT OUTER JOIN svista.t_resp_code D
                   ON A.resp = D.resp_code
      LEFT OUTER JOIN svista.device_resp atm_tr
                   ON A.utrnno = atm_tr.utrnno
      LEFT OUTER JOIN svista.t_resp_code F
                   ON atm_tr.response = F.resp_code
      LEFT OUTER JOIN svista.emv_trans emv_tr
                   ON A.utrnno = emv_tr.utrnno
      LEFT OUTER JOIN svista.instit_tab j
                   ON A.iss_inst = j.inst_id
      LEFT OUTER JOIN svista.netname_tab K
                   ON j.nw_ind = K.nwindicator
      LEFT OUTER JOIN svista.instit_tab jj
                   ON A.acq_inst = jj.inst_id
      LEFT OUTER JOIN svista.netname_tab kk
                   ON jj.nw_ind = kk.nwindicator
WHERE 1 = 1
															 
--      AND a.udate BETWEEN '20230926' AND '20231025'
      AND a.udate BETWEEN ':startMonth26' AND ':endMonth25'
      AND j.descx = 'PPCB'
      AND jj.descx = 'VISA'
      AND b.trans_name IN ('BALANCE INQUIRY') -- 4) BAL INQ
      AND substr(A.hpan,1,6) IN ('405007','405012', '401683')
      AND A.resp = -1
UNION ALL

SELECT -- ATM CASH WITHDRAWAL
	SUBSTR(A.hpan,1,6) || 'XX..XX' || SUBSTR(A.hpan,11,6) AS CARD_NO_MSK
	, A.hpan                                                AS CARD_NO
	, TO_CHAR(A.udate)                                      AS TRNX_DATE
	, TO_CHAR(A.udate)                                      AS POST_DATE
	, A.address_name                                        AS TRNX_DEC
	, (CASE WHEN A.reqamt = 0 THEN 0
		WHEN C.EXP    = 0 THEN A.reqamt
		ELSE A.reqamt / POWER(10, C.EXP) END )    AS ORG_AMNT
	, A.currency                                            AS CR_CODE
	, (A.conamt / POWER(10, 2)) - A.debpfeeamt / POWER(10, 2) AS TRNX_AMNT
	, ' '                                                   AS SETT_ACC
	, '07' AS TRNX_TYPE
	, ' ' AS ACC_NO
	, a.acct1                                AS ACC
FROM svista.curr_trans A
		JOIN svista.TRANSACTION b
					ON A.trans_type = b.trans_type
		LEFT OUTER JOIN svista.iso_currency_codes C
					ON A.currency = C.code_n3
		LEFT OUTER JOIN svista.t_resp_code D
					ON A.resp = D.resp_code
		LEFT OUTER JOIN svista.device_resp atm_tr
					ON A.utrnno = atm_tr.utrnno
		LEFT OUTER JOIN svista.t_resp_code F
					ON atm_tr.response = F.resp_code
		LEFT OUTER JOIN svista.emv_trans emv_tr
					ON A.utrnno = emv_tr.utrnno
		LEFT OUTER JOIN svista.instit_tab j
					ON A.iss_inst = j.inst_id
		LEFT OUTER JOIN svista.netname_tab K
					ON j.nw_ind = K.nwindicator
		LEFT OUTER JOIN svista.instit_tab jj
					ON A.acq_inst = jj.inst_id
		LEFT OUTER JOIN svista.netname_tab kk
					ON jj.nw_ind = kk.nwindicator
WHERE 1 = 1
--		  AND a.udate BETWEEN '20230926' AND '20231025'													  
		AND a.udate BETWEEN ':startMonth26' AND ':endMonth25'
		AND j.descx = 'PPCB'
		AND jj.descx = 'PPCB'
		AND b.trans_name IN ('CASH WITHDRAWAL','EPOS CASH') -- 2) ATM(add row Cash Ad Charge)
		AND substr(A.hpan,1,6) IN ('405007','405012', '401683')
		AND A.resp = -1
		AND A.utrnno NOT in (SELECT DISTINCT A.utrnno
			FROM svista.curr_trans A
					JOIN svista.TRANSACTION b
						ON A.trans_type = b.trans_type
					LEFT OUTER JOIN svista.instit_tab j
						ON A.iss_inst = j.inst_id
					LEFT OUTER JOIN svista.instit_tab jj
						ON A.acq_inst = jj.inst_id
			WHERE 1 = 1
--				 AND a.udate BETWEEN '20230926' AND '20231025'											
				AND a.udate BETWEEN ':startMonth26' AND ':endMonth25'
				AND j.descx = 'PPCB'
				AND jj.descx = 'PPCB'
				AND substr(A.hpan,1,6) IN ('405007','405012', '401683')
				AND A.resp = -1
				AND A.reversal  = 1) -- remove reversal
UNION ALL
	SELECT -- On us ATM Cash Advance Charge
	   SUBSTR(A.hpan,1,6) || 'XX..XX' || SUBSTR(A.hpan,11,6) AS CARD_NO_MSK
	 , A.hpan                                                AS CARD_NO
	 , TO_CHAR(A.udate)                                      AS TRNX_DATE
	 , TO_CHAR(A.udate)                                      AS POST_DATE
	 , 'CASH ADVANCE CHARGE'                                 AS TRNX_DEC
	 , A.debpfeeamt / POWER(10, 2)    AS ORG_AMNT
	 , 840                                                   AS CR_CODE
     , A.debpfeeamt / POWER(10, 2) AS TRNX_AMNT
	 , ' '                                                   AS SETT_ACC
	 , '08' AS TRNX_TYPE
	 , ' ' AS ACC_NO
     , a.acct1                                AS ACC
	FROM svista.curr_trans A
	     JOIN svista.TRANSACTION b
	                   ON A.trans_type = b.trans_type
	      LEFT OUTER JOIN svista.iso_currency_codes C
	                   ON A.currency = C.code_n3
	      LEFT OUTER JOIN svista.t_resp_code D
	                   ON A.resp = D.resp_code
	      LEFT OUTER JOIN svista.device_resp atm_tr
	                   ON A.utrnno = atm_tr.utrnno
	      LEFT OUTER JOIN svista.t_resp_code F
	                   ON atm_tr.response = F.resp_code
	      LEFT OUTER JOIN svista.emv_trans emv_tr
	                   ON A.utrnno = emv_tr.utrnno
	      LEFT OUTER JOIN svista.instit_tab j
	                   ON A.iss_inst = j.inst_id
	      LEFT OUTER JOIN svista.netname_tab K
	                   ON j.nw_ind = K.nwindicator
	      LEFT OUTER JOIN svista.instit_tab jj
	                   ON A.acq_inst = jj.inst_id
	      LEFT OUTER JOIN svista.netname_tab kk
	                   ON jj.nw_ind = kk.nwindicator
	WHERE 1 = 1
--          AND a.udate BETWEEN '20230926' AND '20231025'												  
	      AND a.udate BETWEEN ':startMonth26' AND ':endMonth25'
	      AND j.descx = 'PPCB'
	      AND jj.descx = 'PPCB'
	      AND b.trans_name IN ('CASH WITHDRAWAL', 'EPOS CASH') -- 2) ATM(add row Cash Ad Charge)
	      AND substr(A.hpan,1,6) IN ('405007','405012', '401683')
	      AND A.resp = -1
	      AND A.utrnno NOT in (SELECT DISTINCT A.utrnno
				FROM svista.curr_trans A
				     JOIN svista.TRANSACTION b
				           ON A.trans_type = b.trans_type
				      LEFT OUTER JOIN svista.instit_tab j
				           ON A.iss_inst = j.inst_id
				      LEFT OUTER JOIN svista.instit_tab jj
				           ON A.acq_inst = jj.inst_id
				WHERE 1 = 1
--                 AND a.udate BETWEEN '20230926' AND '20231025'										
				 AND a.udate BETWEEN ':startMonth26' AND ':endMonth25'
				 AND j.descx = 'PPCB'
				 AND jj.descx = 'PPCB'
				 AND substr(A.hpan,1,6) IN ('405007','405012', '401683')
				 AND A.resp = -1
				 AND  A.reversal  = 1) -- remove reversal
UNION ALL

SELECT -- (FE) On Us POS
   SUBSTR(A.hpan,1,6) || 'XX..XX' || SUBSTR(A.hpan,11,6) AS CARD_NO_MSK
 , A.hpan                                                AS CARD_NO
 , TO_CHAR(A.udate)                                      AS TRNX_DATE
 , TO_CHAR(A.udate)                                      AS POST_DATE
 , A.address_name                                        AS TRNX_DEC
 , CASE WHEN A.reqamt = 0 THEN 0
        WHEN C.EXP    = 0 THEN A.reqamt
        ELSE A.reqamt / POWER(10, C.EXP) END             AS ORG_AMNT
 , A.currency                                            AS CR_CODE
 , CASE WHEN A.reqamt = 0 THEN 0
        WHEN C.EXP    = 0 THEN A.reqamt
        ELSE A.reqamt / POWER(10, C.EXP) END             AS TRNX_AMNT
 , ' '                                                   AS SETT_ACC
 , CASE WHEN  b.trans_name = 'POS PURCHASE'  THEN '05'
        WHEN  b.trans_name = 'CASH WITHDRAWAL' THEN '07'
        WHEN  b.trans_name =  'EPOS CASH' THEN '05' END  AS TRNX_TYPE
 , ' ' AS ACC_NO
 , a.acct1                                AS ACC
FROM svista.curr_trans A
     JOIN svista.TRANSACTION b
                   ON A.trans_type = b.trans_type
      LEFT OUTER JOIN svista.iso_currency_codes C
                   ON A.currency = C.code_n3
      LEFT OUTER JOIN svista.t_resp_code D
                   ON A.resp = D.resp_code
      LEFT OUTER JOIN svista.device_resp atm_tr
                   ON A.utrnno = atm_tr.utrnno
      LEFT OUTER JOIN svista.t_resp_code F
                   ON atm_tr.response = F.resp_code
      LEFT OUTER JOIN svista.emv_trans emv_tr
                   ON A.utrnno = emv_tr.utrnno
      LEFT OUTER JOIN svista.instit_tab j
                   ON A.iss_inst = j.inst_id
      LEFT OUTER JOIN svista.netname_tab K
                   ON j.nw_ind = K.nwindicator
      LEFT OUTER JOIN svista.instit_tab jj
                   ON A.acq_inst = jj.inst_id
      LEFT OUTER JOIN svista.netname_tab kk
                   ON jj.nw_ind = kk.nwindicator
WHERE 1 = 1
--      AND a.udate BETWEEN '20230926' AND '20231025'													 
      AND a.udate BETWEEN ':startMonth26' AND ':endMonth25'
      AND j.descx = 'PPCB'
      AND jj.descx = 'PPCB'
		AND b.trans_name IN ('POS PURCHASE') -- On Us pos  262
      AND substr(A.hpan,1,6) IN ('405007','405012', '401683')
      AND A.resp = -1
      AND A.utrnno NOT in (SELECT DISTINCT A.utrnno
                     			FROM svista.curr_trans A
                     			     JOIN svista.TRANSACTION b
                     			           ON A.trans_type = b.trans_type
                     			      LEFT OUTER JOIN svista.instit_tab j
                     			           ON A.iss_inst = j.inst_id
                     			      LEFT OUTER JOIN svista.instit_tab jj
                     			           ON A.acq_inst = jj.inst_id
                     			WHERE 1 = 1
--                                 AND a.udate BETWEEN '20230926' AND '20231025'
                     			 AND a.udate BETWEEN ':startMonth26' AND ':endMonth25'
                     			 AND j.descx = 'PPCB'
                     			 AND jj.descx = 'PPCB'
                     			 AND substr(A.hpan,1,6) IN ('405007','405012', '401683')
                     			 AND A.resp = -1
                     			 AND  A.reversal  = 1) -- remove reversal
UNION ALL

SELECT -- (FE) On Us POS REFUND
   SUBSTR(A.hpan,1,6) || 'XX..XX' || SUBSTR(A.hpan,11,6) AS CARD_NO_MSK
 , A.hpan                                                AS CARD_NO
 , TO_CHAR(A.udate)                                      AS TRNX_DATE
 , TO_CHAR(A.udate)                                      AS POST_DATE
 , A.address_name                                        AS TRNX_DEC
 , CASE WHEN A.reqamt = 0 THEN 0
        WHEN C.EXP    = 0 THEN A.reqamt
        ELSE A.reqamt / POWER(10, C.EXP) END             AS ORG_AMNT
 , A.currency                                            AS CR_CODE
 , CASE WHEN A.reqamt = 0 THEN 0
        WHEN C.EXP    = 0 THEN A.reqamt
        ELSE A.reqamt / POWER(10, C.EXP) END             AS TRNX_AMNT
 , ' '                                                   AS SETT_ACC
 , CASE WHEN  b.trans_name = 'POS PURCHASE'  THEN '05'
        WHEN  b.trans_name = 'CASH WITHDRAWAL' THEN '07'
        WHEN  b.trans_name =  'EPOS CASH' THEN '05' END  AS TRNX_TYPE
 , ' ' AS ACC_NO   
 , a.acct1                                AS ACC
FROM svista.curr_trans A
     JOIN svista.TRANSACTION b
                   ON A.trans_type = b.trans_type
      LEFT OUTER JOIN svista.iso_currency_codes C
                   ON A.currency = C.code_n3
      LEFT OUTER JOIN svista.t_resp_code D
                   ON A.resp = D.resp_code
      LEFT OUTER JOIN svista.device_resp atm_tr
                   ON A.utrnno = atm_tr.utrnno
      LEFT OUTER JOIN svista.t_resp_code F
                   ON atm_tr.response = F.resp_code
      LEFT OUTER JOIN svista.emv_trans emv_tr
                   ON A.utrnno = emv_tr.utrnno
      LEFT OUTER JOIN svista.instit_tab j
                   ON A.iss_inst = j.inst_id
      LEFT OUTER JOIN svista.netname_tab K
                   ON j.nw_ind = K.nwindicator
      LEFT OUTER JOIN svista.instit_tab jj
                   ON A.acq_inst = jj.inst_id
      LEFT OUTER JOIN svista.netname_tab kk
                   ON jj.nw_ind = kk.nwindicator
WHERE 1 = 1
--      AND a.udate BETWEEN '20230926' AND '20231025'													 
      AND a.udate BETWEEN ':startMonth26' AND ':endMonth25'
      AND j.descx = 'PPCB'
      AND jj.descx = 'PPCB'
	  AND b.trans_name IN ('POS REFUND') -- On Us pos  262
      AND substr(A.hpan,1,6) IN ('405007','405012', '401683')
      AND A.resp = -1
      AND A.utrnno NOT in (SELECT DISTINCT A.utrnno
                     			FROM svista.curr_trans A
                     			     JOIN svista.TRANSACTION b
                     			           ON A.trans_type = b.trans_type
                     			      LEFT OUTER JOIN svista.instit_tab j
                     			           ON A.iss_inst = j.inst_id
                     			      LEFT OUTER JOIN svista.instit_tab jj
                     			           ON A.acq_inst = jj.inst_id
                     			WHERE 1 = 1
--								 AND a.udate BETWEEN '20230926' AND '20231025'												
                     			 AND a.udate BETWEEN ':startMonth26' AND ':endMonth25'
                     			 AND j.descx = 'PPCB'
                     			 AND jj.descx = 'PPCB'
                     			 AND substr(A.hpan,1,6) IN ('405007','405012', '401683')
                     			 AND A.resp = -1
                     			 AND  A.reversal  = 1) -- remove reversal
ORDER BY TRNX_DATE,CARD_NO