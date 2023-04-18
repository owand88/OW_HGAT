-- Author: 			Robbie Evans
-- Stakeholder: 	Emma Hamilton, Keith Metcalfe, Bola Lawal
-- Purpose: 		There has been a decrease in Handbags PSNAD Acceptance rate since week 2 2023. The idea is that this may be as a result of buyers purchasing higher priced Handbags than before and as a result of more discerning on which PSNADs they choose to accept
-- Date Created: 	11/04/2023



select 
retail_year
,retail_week
,ATHNTCTN_STATUS_NAME
,IS_RETURN_FLAG_YN_IND
,case when PSNAD is not null then 'Y' else 'N' END as psnad_flag
,case when (PSNAD is not null) and (L2_ACCPT_SCAN_DATE is not null) then 'Y' else 'N' end as psnad_accepted
,CASE
		WHEN item_price < 250  THEN 'A. <250'
		WHEN item_price < 500  THEN 'B. 250-500'
		WHEN item_price < 1000 THEN 'C. 500-1000'
		WHEN item_price < 1250 THEN 'D. 1000-1250'
		WHEN item_price < 1500 THEN 'E. 1250-1500'
		WHEN item_price < 2000 THEN 'F. 1500-2000'
		WHEN item_price < 5000 THEN 'G. 2000-5000'
		WHEN item_price < 10000 THEN 'H. 5000-10,000'
		ELSE 'H.10,000' END AS
	PRICE_BUCKET
,seller_id
,buyer_id
,count(distinct item_id) as listings

From P_PSA_ANALYTICS_T.psa_hub_data

Where 1=1
and HUB_CATEGORY = 'HANDBAGS'
and HUB_REV_ROLLUP = 'UK'
and ((RETAIL_YEAR = 2022 and RETAIL_WEEK >= 40) or (RETAIL_YEAR = 2023 and AGE_FOR_RTL_WEEK_ID < 0))

Group by 1,2,3,4,5,6,7,8,9