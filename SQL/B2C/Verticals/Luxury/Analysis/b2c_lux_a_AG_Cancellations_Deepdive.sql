-- Author: 			Robbie Evans
-- Stakeholder: 	Wahaaj Shabbir, Alice Bridson, Emma Hamilton, Keith Metcalfe
-- Purpose: 		Majority of luxury AG cancellations are coming from sellers, but unsure what the reasoning is behind this and how it differs by Lux category. Is it B2C or C2C-driven?
-- Date Created: 	22/03/2023


select 
ck.SELLER_ID
,case when (cat.CATEG_LVL2_ID = 260324) then 'Watches'
	when (cat.CATEG_LVL3_ID = 169291) OR (cat.CATEG_LVL4_ID IN (52357,163570,169285,45258,2996,45237,169271)) then 'Handbags'
	when cat.CATEG_LVL4_ID IN (15709,95672,155202,57974,57929) then 'Sneakers'
	when (cat.META_CATEG_ID = 281 AND cat.CATEG_LVL2_ID <> 260324) then 'Jewellery'
	Else 'Other'
	End as category
,COALESCE(get_json_object(ORDER_DTL1_TXT, '$.PSA'),0) AS PSA_FLAG 
,OUT_OF_STOCK_STS
,CASE WHEN HIST.USEGM_ID = 206 THEN 'B2C' ELSE 'C2C' END SELLER_TYPE
,bbe.cncl_yn_ind
,case when bbe.cncl_rqst_id is not null and bbe.cncl_rqstr_type_cd = 1 then 'Seller'
	  when bbe.cncl_rqst_id is not null and bbe.cncl_rqstr_type_cd = 2 then 'Buyer'
	  else null end as cncl_requester
,cr_lkp.rqst_rsn_desc
-- ,cc_lkp.clsr_rsn_desc
,count(distinct ck.TRANSACTION_ID) as orders
,count(distinct case when bbe.cncl_yn_ind = 'Y' then ck.TRANSACTION_ID End) as cancelled_orders
,sum(ck.gmv_plan_usd) as GMV
,sum(ck.QUANTITY) as SI

FROM DW_CHECKOUT_TRANS ck 
INNER JOIN DW_CAL_DT cal
	on ck.gmv_dt = cal.CAL_DT
	and cal.AGE_FOR_RTL_WEEK_ID >= -52
	and cal.AGE_FOR_RTL_WEEK_ID <= -1
INNER JOIN DW_CATEGORY_GROUPINGS CAT 
	ON CAT.LEAF_CATEG_ID = ck.LEAF_CATEG_ID 
	AND CAT.SITE_ID = 3
	AND CAT.SAP_CATEGORY_ID NOT in (5,7,41,23,-999) 
INNER JOIN DW_OMS_ORDER oms 
		on (case when instr(OMS_EXTRNL_RFRNC_ID,'!') > 0 
				   then substr(OMS_EXTRNL_RFRNC_ID,instr(OMS_EXTRNL_RFRNC_ID,'!')+1)
				   else OMS_EXTRNL_RFRNC_ID
				   END) = coalesce(ORDER_REF_ID,cast(OMS_ORDER_ID as varchar(128)))
				   AND get_json_object(ORDER_DTL1_TXT, '$.PSA') = 1 						--Only AG transactions
left join prs_restricted_v.ebay_trans_rltd_event bbe
	on ck.item_id=bbe.item_id and ck.transaction_id=bbe.trans_id
left join po_cncl_rqst_rsn_lkp cr_lkp
	on bbe.cncl_rqst_rsn_cd=cr_lkp.rqst_rsn_cd
left join po_cncl_clsr_rsn_lkp cc_lkp
	on bbe.cncl_clsr_rsn_cd=cc_lkp.clsr_rsn_cd
LEFT JOIN DW_USEGM_HIST HIST
	ON HIST.USER_ID=ck.Seller_ID
	AND HIST.USEGM_GRP_ID = 48
	and ck.GMV_DT BETWEEN HIST.BEG_DATE AND HIST.END_DATE
left join
	(select lstg.item_id, lstg.AUCT_END_DT, QTY_AVAIL, OUT_OF_STOCK_STS
	From PRS_RESTRICTED_V.SLNG_LSTG_SUPER_FACT lstg
	Group by 1,2,3,4) lstg on ck.item_id = lstg.item_id and lstg.auct_end_dt = ck.auct_end_dt

Where 1=1
and ck.RPRTD_WACKO_YN = 'N'
and (
		(cat.CATEG_LVL2_ID = 260324) --Watches
		or (cat.CATEG_LVL3_ID = 169291) OR (cat.CATEG_LVL4_ID IN (52357,163570,169285,45258,2996,45237,169271)) --Handbags
		OR cat.CATEG_LVL4_ID IN (15709,95672,155202,57974,57929) --Sneakers
		OR (cat.META_CATEG_ID = 281 AND cat.CATEG_LVL2_ID <> 260324) --Jewellery
	)
and ck.SLR_CNTRY_ID = 3	
	
Group by 1,2,3,4,5,6,7,8
	
	
;