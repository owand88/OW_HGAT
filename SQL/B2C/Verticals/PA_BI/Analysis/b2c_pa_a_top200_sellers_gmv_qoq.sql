-- JIRA:            UKPLAN-481

-- Author: 			Robbie Evans
-- Date:            01/08/2023

-- Stakeholder: 	Manish Goenka
-- Description: 	Provides a QoQ view of the top 200 P&A sellers (based on YTD 2023 GMV up to 1 Aug) for 2022 and 2023




With top_sellers as 
( 
SELECT ck.SELLER_ID
	,sum(ck.GMV20_PLAN) as gmv_ytd
FROM
	PRS_RESTRICTED_V.SLNG_TRANS_SUPER_FACT ck
INNER JOIN
	P_INVENTORYPLANNING_T.dw_category_groupings_adj CAT
		ON ck.LEAF_CATEG_ID = CAT.LEAF_CATEG_ID
		AND cat.site_id = 3
INNER JOIN
	DW_CAL_DT cal
		on ck.gmv_dt = cal.CAL_DT
		and cal.RETAIL_YEAR = 2023
WHERE
	1=1
	AND lower(cat.NEW_VERTICAL) = 'parts & accessories'
	and ck.SLR_CNTRY_ID = 3
	and ck.SITE_ID = 3
GROUP BY
	1
ORDER BY
	gmv_ytd DESC
LIMIT
	200
)



select 
	cal.RETAIL_YEAR
	,cal.RTL_QTR_OF_RTL_YEAR_ID
	,ck.DOMESTIC_CBT
	,ck.SELLER_ID
	,u.user_slctd_id as seller_name
	,u.comp as company_name
	,sum(ck.GMV20_PLAN) as GMV
	,sum(ck.GMV20_SOLD_QUANTITY) as sold_items
FROM
	PRS_RESTRICTED_V.SLNG_TRANS_SUPER_FACT ck
INNER JOIN
	P_INVENTORYPLANNING_T.dw_category_groupings_adj CAT
		ON ck.LEAF_CATEG_ID = CAT.LEAF_CATEG_ID
		AND cat.site_id = 3
INNER JOIN
	DW_CAL_DT cal
		on ck.gmv_dt = cal.CAL_DT
		and cal.RETAIL_YEAR in (2022,2023)
INNER JOIN
	DW_USERS u 
		on ck.SELLER_ID = u.user_id
INNER JOIN
	top_sellers
		on ck.SELLER_ID = top_sellers.seller_id
WHERE
	1=1
	AND lower(cat.NEW_VERTICAL) = 'parts & accessories'
	and ck.SITE_ID = 3
GROUP BY 
	1,2,3,4,5,6