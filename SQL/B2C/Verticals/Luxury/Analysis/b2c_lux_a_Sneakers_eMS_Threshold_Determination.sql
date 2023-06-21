-- JIRA:            UKPLAN-373

-- Author: 			Robbie Evans
-- Date:            22/05/2023

-- Stakeholder: 	Wahaaj Shabbir
-- Description: 	AG Sneaker GMV and Listings by price tranche for the past 2 years to assist in devising a price threshold for eBay Managed Shipping (eMS)





-----------------------------------GMV-------------------------------------------


select
		CASE
		WHEN CK.ITEM_PRICE < 100 THEN 'A. <100'
		WHEN CK.ITEM_PRICE < 500 THEN 'B. 100-500'
		WHEN CK.ITEM_PRICE < 1000 THEN 'C. 500-1000'
		WHEN CK.ITEM_PRICE < 5000 THEN 'D. 1000-5000'
		WHEN CK.ITEM_PRICE < 10000 THEN 'E. 5000-10000'
		WHEN CK.ITEM_PRICE < 20000 THEN 'F. 10000-20000'
		WHEN CK.ITEM_PRICE < 30000 THEN 'G. 20000-30000'
		WHEN CK.ITEM_PRICE < 40000 THEN 'H. 30000-40000'
		WHEN CK.ITEM_PRICE < 50000 THEN 'I. 40000-50000'
		WHEN CK.ITEM_PRICE < 60000 THEN 'J. 50000-60000'
		WHEN CK.ITEM_PRICE < 70000 THEN 'K. 60000-70000'
		WHEN CK.ITEM_PRICE < 80000 THEN 'L. 70000-80000'
		ELSE 'M.80000+' END AS
	PRICE_BUCKET_GBP,
	SUM(CK.gmv_plan_usd) AS GMV, 
	SUM(QUANTITY) AS BI

FROM DW_CHECKOUT_TRANS AS CK
INNER JOIN 
	(select
	  ITEM_ID
	from  access_views.DW_PES_ELGBLT_HIST
	where biz_prgrm_name in ('PSA_SNEAKER_EBAY_UK')
	  and ELGBL_YN_IND = 'Y'
	  and evltn_end_ts = '2099-12-31 00:00:00.0'
	GROUP BY 1
	) psa 
		on ck.ITEM_ID = psa.item_id

INNER JOIN ACCESS_VIEWS.DW_CAL_DT CAL 
	ON CAL.CAL_DT = CK.gmv_dt 
	and AGE_FOR_RTL_WEEK_ID >= -104 and AGE_FOR_RTL_WEEK_ID <= -1

WHERE 1=1                
AND CK.SLR_CNTRY_ID = 3
and ck.BYR_CNTRY_ID = 3

GROUP BY 1






-----------------------------------Listings-------------------------------------------


select
		CASE
		WHEN lstg.START_PRICE_LSTG_CURNCY < 100 THEN 'A. <100'
		WHEN lstg.START_PRICE_LSTG_CURNCY  < 500 THEN 'B. 100-500'
		WHEN lstg.START_PRICE_LSTG_CURNCY  < 1000 THEN 'C. 500-1000'
		WHEN lstg.START_PRICE_LSTG_CURNCY  < 5000 THEN 'D. 1000-5000'
		WHEN lstg.START_PRICE_LSTG_CURNCY  < 10000 THEN 'E. 5000-10000'
		WHEN lstg.START_PRICE_LSTG_CURNCY  < 20000 THEN 'F. 10000-20000'
		WHEN lstg.START_PRICE_LSTG_CURNCY  < 30000 THEN 'G. 20000-30000'
		WHEN lstg.START_PRICE_LSTG_CURNCY  < 40000 THEN 'H. 30000-40000'
		WHEN lstg.START_PRICE_LSTG_CURNCY  < 50000 THEN 'I. 40000-50000'
		WHEN lstg.START_PRICE_LSTG_CURNCY  < 60000 THEN 'J. 50000-60000'
		WHEN lstg.START_PRICE_LSTG_CURNCY  < 70000 THEN 'K. 60000-70000'
		WHEN lstg.START_PRICE_LSTG_CURNCY  < 80000 THEN 'L. 70000-80000'
		ELSE 'M.80000+' END AS
	PRICE_BUCKET_GBP,
	count(distinct lstg.ITEM_ID) as ll,
	count(distinct lstg.SLR_ID) as sellers

FROM DW_LSTG_ITEM AS lstg
INNER JOIN 
	(select
	  ITEM_ID
	from  access_views.DW_PES_ELGBLT_HIST
	where biz_prgrm_name in ('PSA_SNEAKER_EBAY_UK')
	  and ELGBL_YN_IND = 'Y'
	  and evltn_end_ts = '2099-12-31 00:00:00.0'
	  and item_id = 404007534856
	GROUP BY 1
	) psa 
		on lstg.ITEM_ID = psa.item_id

INNER JOIN ACCESS_VIEWS.DW_CAL_DT CAL 
	ON lstg.auct_start_dt <= cal.CAL_DT
	and lstg.AUCT_END_DT >= cal.CAL_DT
	and AGE_FOR_RTL_WEEK_ID >= -104 and AGE_FOR_RTL_WEEK_ID <= -1

WHERE 1=1                
AND lstg.SLR_CNTRY_ID = 3
and lstg.ITEM_SITE_ID = 3

GROUP BY 1