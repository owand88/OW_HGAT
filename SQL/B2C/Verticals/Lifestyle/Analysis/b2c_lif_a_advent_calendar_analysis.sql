-- Author: 			Robbie Evans
-- Stakeholder: 	Beth Alexander
-- Purpose: 		Looking to launch an advent calender later this year, so wanting to get some insight into the category and how it's performed in 2022
-- Date Created: 	17/07/2023


With advent_items AS
( 
Select lstg.item_id
	,lstg.AUCT_TITLE
	,lstg.DF_BRAND_TXT as brand
From PRS_RESTRICTED_V.SLNG_LSTG_SUPER_FACT lstg
INNER JOIN DW_CAL_DT cal
	on lstg.AUCT_START_DT <= cal.CAL_DT
	and lstg.AUCT_END_DT >= cal.CAL_DT
	and lstg.AUCT_START_DT < lstg.AUCT_END_DT
	and (cal.cal_dt between '2022-09-01' and '2022-12-31'
		OR cal.cal_dt between '2021-09-01' and '2021-12-31')
INNER JOIN P_INVENTORYPLANNING_T.dw_category_groupings_adj CAT
	ON lstg.LEAF_CATEG_ID = CAT.LEAF_CATEG_ID
	AND cat.site_id = 3
Where 1=1
	and cat.META_CATEG_ID = 26395 -- Health & Beauty Meta
	and lstg.ITEM_SITE_ID = 3
	and lstg.SLR_CNTRY_ID = 3
	and lower(lstg.AUCT_TITLE) like '%advent%'
	and (lower(lstg.AUCT_TITLE) like '%calender%' or lower(lstg.AUCT_TITLE) like '%calendar%')
Group by 1,2,3
)


Select 
cal.retail_year
,cal.RTL_MONTH_OF_RTL_YEAR_ID
,cal.RETAIL_WEEK
,ck.item_id
,lstg.AUCT_TITLE
,lstg.brand
,ck.DOMESTIC_CBT
,cat.CATEG_LVL2_NAME
,cat.CATEG_LVL3_NAME
,cat.CATEG_LVL4_NAME
-- ,ck.B2C_C2C
-- ,ck.SELLER_ID
-- ,u.user_slctd_id as seller_name
-- ,ck.BUYER_ID
,sum(ck.GMV20_PLAN) as gmv
,sum(ck.GMV20_LC_AMT) as gmv_lc
,sum(ck.GMV20_SOLD_QUANTITY) as sold_items
,avg(ck.ITEM_PRICE) as ABP

From PRS_RESTRICTED_V.SLNG_TRANS_SUPER_FACT ck
INNER JOIN DW_CAL_DT cal
	on ck.gmv_dt = cal.CAL_DT
	and (cal.cal_dt between '2022-09-01' and '2022-12-31'
		OR cal.cal_dt between '2021-09-01' and '2021-12-31')
INNER JOIN advent_items lstg
	on ck.item_id = lstg.item_id
-- INNER JOIN DW_USERS u
-- 	on ck.SELLER_ID = u.user_id
INNER JOIN P_INVENTORYPLANNING_T.dw_category_groupings_adj CAT
	ON ck.LEAF_CATEG_ID = CAT.LEAF_CATEG_ID
	AND cat.site_id = 3

Where 1=1
and ck.site_id = 3

group by 1,2,3,4,5,6,7,8,9,10