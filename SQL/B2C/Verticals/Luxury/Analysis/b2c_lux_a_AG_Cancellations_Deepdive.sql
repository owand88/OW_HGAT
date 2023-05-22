-- Author: 			Robbie Evans
-- Stakeholder: 	Wahaaj Shabbir, Alice Bridson, Emma Hamilton, Keith Metcalfe
-- Purpose: 		A large portion of seller cancellations in AG have the reason listed as OOS. In order to improve this we need to test a couple of hypotheses.
--					Sellers may truly be OOS because they are selling on multiple platforms (not just eBay). To test this we need to identify:
--					1) What % of seller cancelled OOSs have QTY_SOLD = QTY_AVAIL (OOS on eBay) vs QTY_SOLD < QTY_AVAIL (OOS through combination of eBay and other platforms)
--					2) What is the average lead time to an OOS seller-cancelled sale vs the average lead time to a regular sale of AG?
-- Date Created: 	28/03/2023

--1) Are OOS SIC as a result of Fee Suprise (i.e. new to eBay sellers)/are the SIC as a result of sellers who are new to AG?

Drop table if exists p_robevans_t.b2c_lux_a_cancellations_deepdive;
Create table p_robevans_t.b2c_lux_a_cancellations_deepdive as

with prev_non_ag_sale_sellers as
(
SELECT
psa.seller_id
,case when first_non_ag_dt < first_ag_dt then 'Y'
	else 'N'
	End as prev_non_ag_seller

FROM
	(
	Select ck.SELLER_ID,min(ck.gmv_dt) as first_ag_dt
	From DW_CHECKOUT_TRANS ck
	INNER JOIN DW_CAL_DT cal
		on ck.gmv_dt = cal.CAL_DT
		and cal.AGE_FOR_RTL_WEEK_ID >= -104
		and cal.AGE_FOR_RTL_WEEK_ID <= -1
	inner JOIN 
		(select
			ITEM_ID
			from  access_views.DW_PES_ELGBLT_HIST
			where biz_prgrm_name in ('PSA_SNEAKER_EBAY_UK','PSA_HANDBAGS_UK','PSA_WATCHES_UK') -- Sneakers AG program
			and ELGBL_YN_IND = 'Y'
			and evltn_end_ts = '2099-12-31 00:00:00.0'
			GrOUP BY 1
		) PSA
			on psa.item_id = ck.ITEM_ID

	Where 1=1
	and ck.SLR_CNTRY_ID = 3

	Group by 1
	) psa
LEFT JOIN
	(
	Select ck.SELLER_ID,min(ck.gmv_dt) as first_non_ag_dt
	From DW_CHECKOUT_TRANS ck
	INNER JOIN DW_CAL_DT cal
		on ck.gmv_dt = cal.CAL_DT
		and cal.AGE_FOR_RTL_WEEK_ID >= -104
		and cal.AGE_FOR_RTL_WEEK_ID <= -1
	INNER JOIN DW_CATEGORY_GROUPINGS CAT 
		ON CAT.LEAF_CATEG_ID = ck.LEAF_CATEG_ID 
		AND CAT.SITE_ID = 3
		AND CAT.SAP_CATEGORY_ID NOT in (5,7,41,23,-999)
		and (
				(cat.CATEG_LVL2_ID = 260324) --Watches
				or (cat.CATEG_LVL3_ID = 169291) OR (cat.CATEG_LVL4_ID IN (52357,163570,169285,45258,2996,45237,169271)) --Handbags
				OR cat.CATEG_LVL4_ID IN (15709,95672,155202,57974,57929) --Sneakers
				OR (cat.META_CATEG_ID = 281 AND cat.CATEG_LVL2_ID <> 260324) --Jewellery
			)
	LEFT JOIN 
		(select
			ITEM_ID
			from  access_views.DW_PES_ELGBLT_HIST
			where biz_prgrm_name in ('PSA_SNEAKER_EBAY_UK','PSA_HANDBAGS_UK','PSA_WATCHES_UK') -- Sneakers AG program
			and ELGBL_YN_IND = 'Y'
			and evltn_end_ts = '2099-12-31 00:00:00.0'
			GrOUP BY 1
		) PSA
			on psa.item_id = ck.ITEM_ID

	Where 1=1
	and ck.SLR_CNTRY_ID = 3
	and psa.item_id is null

	Group by 1
	) non_psa
		on psa.seller_id = non_psa.seller_id
	
Group by 1,2
)


select *

From 
(
	select 
-- 	ck.item_id
-- 	,ck.SELLER_ID
	sel.prev_non_ag_seller as prev_non_AG_seller_flag
	,case when (cat.CATEG_LVL2_ID = 260324) then 'Watches'
		when (cat.CATEG_LVL3_ID = 169291) OR (cat.CATEG_LVL4_ID IN (52357,163570,169285,45258,2996,45237,169271)) then 'Handbags'
		when cat.CATEG_LVL4_ID IN (15709,95672,155202,57974,57929) then 'Sneakers'
		when (cat.META_CATEG_ID = 281 AND cat.CATEG_LVL2_ID <> 260324) then 'Jewellery'
		Else 'Other'
		End as category
-- 	,COALESCE(get_json_object(ORDER_DTL1_TXT, '$.PSA'),0) AS PSA_FLAG 
	,case when ck.item_id = psa.item_id then 'Yes' else 'No' end as AG_Flag
	,case when ck.ITEM_VRTN_ID = vrtn.ITEM_VRTN_ID then 'Y' else 'N' end as msku_flag
	,case when lstg.QTY_AVAIL > 1 then 'Y' else 'N' end as multi_quantity_lstg
-- 	,OUT_OF_STOCK_STS
	,CASE WHEN HIST.USEGM_ID = 206 THEN 'B2C' ELSE 'C2C' END SELLER_TYPE
	,bbe.cncl_yn_ind
	,case when bbe.cncl_rqst_id is not null and bbe.cncl_rqstr_type_cd = 1 then 'Seller'
		  when bbe.cncl_rqst_id is not null and bbe.cncl_rqstr_type_cd = 2 then 'Buyer'
		  else null end as cncl_requester
	,cr_lkp.rqst_rsn_desc
	-- ,cc_lkp.clsr_rsn_desc
-- 	,sum(lstg.QTY_AVAIL) as qty_avail
	,count(distinct ck.TRANSACTION_ID) as orders
	,count(distinct ck.item_id) as listings
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
-- 	LEFT JOIN DW_OMS_ORDER oms 
-- 			on (case when instr(OMS_EXTRNL_RFRNC_ID,'!') > 0 
-- 					   then substr(OMS_EXTRNL_RFRNC_ID,instr(OMS_EXTRNL_RFRNC_ID,'!')+1)
-- 					   else OMS_EXTRNL_RFRNC_ID
-- 					   END) = coalesce(ORDER_REF_ID,cast(OMS_ORDER_ID as varchar(128)))
-- -- 					   AND get_json_object(ORDER_DTL1_TXT, '$.PSA') = 1 						--Only AG transactions
	left join
		(select
		ITEM_ID
		from  access_views.DW_PES_ELGBLT_HIST
		where biz_prgrm_name in ('PSA_SNEAKER_EBAY_UK','PSA_HANDBAGS_UK','PSA_WATCHES_UK')
		and ELGBL_YN_IND = 'Y'
		and evltn_end_ts = '2099-12-31 00:00:00.0'
		GROUP BY 1) psa 
			on ck.item_id = psa.item_id

	left JOIN LSTG_ITEM_VRTN vrtn
		on ck.ITEM_VRTN_ID = vrtn.ITEM_VRTN_ID
	left join prs_restricted_v.ebay_trans_rltd_event bbe
		on ck.item_id=bbe.item_id and ck.transaction_id=bbe.trans_id
	left join po_cncl_rqst_rsn_lkp cr_lkp
		on bbe.cncl_rqst_rsn_cd=cr_lkp.rqst_rsn_cd
	LEFT JOIN DW_USEGM_HIST HIST
		ON HIST.USER_ID=ck.Seller_ID
		AND HIST.USEGM_GRP_ID = 48
		and ck.GMV_DT BETWEEN HIST.BEG_DATE AND HIST.END_DATE
	left join
		(select lstg.item_id, lstg.AUCT_END_DT, QTY_AVAIL, OUT_OF_STOCK_STS
		From PRS_RESTRICTED_V.SLNG_LSTG_SUPER_FACT lstg
		Group by 1,2,3,4) lstg on ck.item_id = lstg.item_id and lstg.auct_end_dt = ck.auct_end_dt
	LEFT JOIN prev_non_ag_sale_sellers sel
		on ck.SELLER_ID = sel.seller_id

	Where 1=1
	and ck.RPRTD_WACKO_YN = 'N'
	and (
			(cat.CATEG_LVL2_ID = 260324) --Watches
			or (cat.CATEG_LVL3_ID = 169291) OR (cat.CATEG_LVL4_ID IN (52357,163570,169285,45258,2996,45237,169271)) --Handbags
			OR cat.CATEG_LVL4_ID IN (15709,95672,155202,57974,57929) --Sneakers
			OR (cat.META_CATEG_ID = 281 AND cat.CATEG_LVL2_ID <> 260324) --Jewellery
		)
	and ck.SLR_CNTRY_ID = 3	

	Group by 1,2,3,4,5,6,7,8,9
)	
;




--2) What is the average lead time to an OOS seller-cancelled sale vs the average lead time to a regular sale of AG?

select 
lead_time_to_sale
,category
,AG_Flag
,SELLER_TYPE
,CNCL_YN_IND
,cncl_requester
,rqst_rsn_desc
,count(distinct TRANSACTION_ID) as orders
,sum(gmv) as gmv
,sum(si) as si

From
	(
	select 
	ck.item_id
	,lstg.AUCT_START_DT
	,ck.CREATED_DT
	,DATEDIFF(ck.CREATED_DT,lstg.AUCT_START_DT) AS lead_time_to_sale
	,ck.TRANSACTION_ID
	,case when (cat.CATEG_LVL2_ID = 260324) then 'Watches'
		when (cat.CATEG_LVL3_ID = 169291) OR (cat.CATEG_LVL4_ID IN (52357,163570,169285,45258,2996,45237,169271)) then 'Handbags'
		when cat.CATEG_LVL4_ID IN (15709,95672,155202,57974,57929) then 'Sneakers'
		when (cat.META_CATEG_ID = 281 AND cat.CATEG_LVL2_ID <> 260324) then 'Jewellery'
		Else 'Other'
		End as category
-- 	,COALESCE(get_json_object(ORDER_DTL1_TXT, '$.PSA'),0) AS PSA_FLAG 
	,case when ck.item_id = psa.item_id then 'Yes' else 'No' end as AG_Flag
	,OUT_OF_STOCK_STS
	,CASE WHEN HIST.USEGM_ID = 206 THEN 'B2C' ELSE 'C2C' END SELLER_TYPE
	,bbe.cncl_yn_ind
	,case when bbe.cncl_rqst_id is not null and bbe.cncl_rqstr_type_cd = 1 then 'Seller'
		  when bbe.cncl_rqst_id is not null and bbe.cncl_rqstr_type_cd = 2 then 'Buyer'
		  else null end as cncl_requester
	,cr_lkp.rqst_rsn_desc
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
-- 	INNER JOIN DW_OMS_ORDER oms 
-- 			on (case when instr(OMS_EXTRNL_RFRNC_ID,'!') > 0 
-- 					   then substr(OMS_EXTRNL_RFRNC_ID,instr(OMS_EXTRNL_RFRNC_ID,'!')+1)
-- 					   else OMS_EXTRNL_RFRNC_ID
-- 					   END) = coalesce(ORDER_REF_ID,cast(OMS_ORDER_ID as varchar(128)))
-- 					   AND get_json_object(ORDER_DTL1_TXT, '$.PSA') = 1 						--Only AG transactions
	left join
		(select
		ITEM_ID
		from  access_views.DW_PES_ELGBLT_HIST
		where biz_prgrm_name in ('PSA_SNEAKER_EBAY_UK','PSA_HANDBAGS_UK','PSA_WATCHES_UK')
		and ELGBL_YN_IND = 'Y'
		GROUP BY 1) psa 
			on ck.item_id = psa.item_id
	left join prs_restricted_v.ebay_trans_rltd_event bbe
		on ck.item_id=bbe.item_id and ck.transaction_id=bbe.trans_id
	left join po_cncl_rqst_rsn_lkp cr_lkp
		on bbe.cncl_rqst_rsn_cd=cr_lkp.rqst_rsn_cd
	LEFT JOIN DW_USEGM_HIST HIST
		ON HIST.USER_ID=ck.Seller_ID
		AND HIST.USEGM_GRP_ID = 48
		and ck.GMV_DT BETWEEN HIST.BEG_DATE AND HIST.END_DATE
	left join
		(select lstg.item_id, lstg.AUCT_START_DT, lstg.AUCT_END_DT, QTY_AVAIL, OUT_OF_STOCK_STS
		From PRS_RESTRICTED_V.SLNG_LSTG_SUPER_FACT lstg
		Group by 1,2,3,4,5) lstg
			on ck.item_id = lstg.item_id and lstg.auct_end_dt = ck.auct_end_dt

	Where 1=1
	and ck.RPRTD_WACKO_YN = 'N'
	and (
			(cat.CATEG_LVL2_ID = 260324) --Watches
			or (cat.CATEG_LVL3_ID = 169291) OR (cat.CATEG_LVL4_ID IN (52357,163570,169285,45258,2996,45237,169271)) --Handbags
			OR cat.CATEG_LVL4_ID IN (15709,95672,155202,57974,57929) --Sneakers
			OR (cat.META_CATEG_ID = 281 AND cat.CATEG_LVL2_ID <> 260324) --Jewellery
		)
	and ck.SLR_CNTRY_ID = 3	

	Group by 1,2,3,4,5,6,7,8,9,10,11,12
	)

Group by 1,2,3,4,5,6,7
;






--3) The high OOS canncellation rate is an eBay-wide issue with high-value goods

select 
case when (cat.CATEG_LVL2_ID = 260324) then 'Watches'
	when (cat.CATEG_LVL3_ID = 169291) OR (cat.CATEG_LVL4_ID IN (52357,163570,169285,45258,2996,45237,169271)) then 'Handbags'
	when cat.CATEG_LVL4_ID IN (15709,95672,155202,57974,57929) then 'Sneakers'
	when (cat.META_CATEG_ID = 281 AND cat.CATEG_LVL2_ID <> 260324) then 'Jewellery'
	Else cat.CATEG_LVL2_NAME
	End as category
,CASE WHEN HIST.USEGM_ID = 206 THEN 'B2C' ELSE 'C2C' END SELLER_TYPE
,bbe.cncl_yn_ind
,case when bbe.cncl_rqst_id is not null and bbe.cncl_rqstr_type_cd = 1 then 'Seller'
	  when bbe.cncl_rqst_id is not null and bbe.cncl_rqstr_type_cd = 2 then 'Buyer'
	  else null end as cncl_requester
,cr_lkp.rqst_rsn_desc
,count(distinct ck.TRANSACTION_ID) as orders
,count(distinct ck.item_id) as listings
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
left join prs_restricted_v.ebay_trans_rltd_event bbe
	on ck.item_id=bbe.item_id and ck.transaction_id=bbe.trans_id
left join po_cncl_rqst_rsn_lkp cr_lkp
	on bbe.cncl_rqst_rsn_cd=cr_lkp.rqst_rsn_cd
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
and ck.ITEM_PRICE >= 1000
and ck.SLR_CNTRY_ID = 3	

Group by 1,2,3,4,5