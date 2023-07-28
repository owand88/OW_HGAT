-- JIRA:            UKPLAN-454

-- Author: 			Robbie Evans
-- Date:            25/07/2023

-- Stakeholder: 	Wahaaj Shabbir
-- Description: 	As part of the eMS launch, sellers that have listed using the eBay API will need to be contacted for instructions on the new eMS listing process






select 
	lstg.SLR_ID as seller_id
	,u.user_slctd_id as seller_name
	,lstg.B2C_C2C
	,count(distinct lstg.item_id) as ll
	,avg(case when lstg.START_PRICE_LSTG_CURNCY_AMT > lstg.RSRV_PRICE_LSTG_CURNCY_AMT then lstg.START_PRICE_LSTG_CURNCY_AMT else lstg.RSRV_PRICE_LSTG_CURNCY_AMT End) as avg_price_lstg_curncy
-- 	,lstg.AUCT_TITLE
-- 	,case when lstg.START_PRICE_LSTG_CURNCY_AMT > lstg.RSRV_PRICE_LSTG_CURNCY_AMT then lstg.START_PRICE_LSTG_CURNCY_AMT else lstg.RSRV_PRICE_LSTG_CURNCY_AMT End as item_price_lstg_curncy
-- 	,lstg.DF_BRAND_TXT

FROM
	PRS_RESTRICTED_V.SLNG_LSTG_SUPER_FACT LSTG
INNER JOIN
	(
	select
		ITEM_ID
	from
		access_views.DW_PES_ELGBLT_HIST
	where
		biz_prgrm_name in ('PSA_SNEAKER_EBAY_UK')
		and ELGBL_YN_IND = 'Y'
		and evltn_end_ts = '2099-12-31 00:00:00.0'
	GROUP BY 1
	) psa
		on lstg.ITEM_ID = psa.item_id
LEFT JOIN DW_USERS u
	on lstg.SLR_ID = u.user_id
WHERE
	1=1
	AND LSTG_STATUS_ID = 0 -- Live listings only
	AND lstg.SLR_CNTRY_ID = 3
	and lstg.ITEM_SITE_ID = 3
	and upper(DEVICE_TYPE_LEVEL1) = 'API'

Group by 1,2,3

Order by ll desc