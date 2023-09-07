-- JIRA Ticket:     UKPLAN-506

-- Author: 			Robbie Evans
-- Stakeholder: 	Ines Morais
-- Purpose: 		Ahead of the Jewellery AG launch, the Product team need a list of specific B2C sellers to switch the feature on for.
-- Date Created: 	16/08/2023




Select
	ck.SELLER_ID
	,u.user_slctd_id as seller_name
	,sc.cntry_desc as seller_country
	,case when ck.SITE_ID = 3 then 'UK' else 'Other' end as site
	,case when u.USER_DSGNTN_ID = 2 then 'B2C'
		else 'C2C'
		end as seller_type
	,case when ck.SLR_CNTRY_ID = ck.BYR_CNTRY_ID then 'Domestic'
		else 'CBT'
		end as trade_type
	,sum(ck.gmv_plan_usd) as gmv
	
FROM DW_CHECKOUT_TRANS ck
INNER JOIN DW_CAL_DT cal
	on ck.gmv_dt = cal.CAL_DT
	and cal.RETAIL_YEAR = 2023
	and cal.AGE_FOR_RTL_WEEK_ID <= -1
INNER JOIN P_INVENTORYPLANNING_T.dw_category_groupings_adj CAT
	ON ck.LEAF_CATEG_ID = CAT.LEAF_CATEG_ID
	AND cat.site_id = 3
INNER JOIN DW_USERS u
	on ck.SELLER_ID = u.user_id
LEFT JOIN DW_COUNTRIES sc 
	on ck.SLR_CNTRY_ID = sc.cntry_id

	
Where 1=1
	and u.USER_DSGNTN_ID = 2	--B2C sellers only
	and ck.SLR_CNTRY_ID = 3		--UK sellers only
	and ck.ITEM_PRICE >= 500	--listings over £500
	and cat.META_CATEG_ID = 281	--Jewellery only
	AND cat.CATEG_LVL2_ID <> 260324

Group By
	1,2,3,4,5,6

Order by gmv DESC

Limit 100

