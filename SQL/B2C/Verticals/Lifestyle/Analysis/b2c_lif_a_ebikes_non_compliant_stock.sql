-- JIRA Ticket:     UKPLAN-424

-- Author: 			Robbie Evans
-- Stakeholder: 	Lizzie Read
-- Purpose: 		UK legislation states all eBikes sold in the UK must adhere to certain restrictions, including not exceeding 25km/h or 15.5mph and not exert more than 250W of power. currently eBay does not manage these requirements on listings and so there is a risk to GMV and supply should we begin implementing restrictions on this. Need to understand the potential risk to current supply as well as GMV.
-- Date Created: 	12/07/2023





---------------------------------Currently Live Listings----------------------------

select
case when lstg.SLR_CNTRY_ID = 3 then 'UK'
	else 'International' end as seller_cntry
,aspct.POWER
,aspct.SPEED
,count(distinct lstg.item_id) as ll

from PRS_RESTRICTED_V.SLNG_LSTG_SUPER_FACT_EXT lstg
INNER JOIN DW_CAL_DT cal
	on lstg.AUCT_START_DT <= CURRENT_DATE --- live listings only
	and lstg.AUCT_END_DT >= CURRENT_DATE --- live listings only
INNER JOIN P_INVENTORYPLANNING_T.dw_category_groupings_adj CAT
	ON lstg.LEAF_CATEG_ID = CAT.LEAF_CATEG_ID
	AND cat.site_id = 3
LEFT JOIN 
	(
	SELECT
		ITEM_ID
		,coalesce(case when tag_name = 'Maximum Speed' then tag_value_txt End,"") as SPEED
		,coalesce(case when tag_name = 'Motor Power' then tag_value_txt End,"") as POWER
	FROM DW_ATTR_LSTG_TAG_DTL ASPCT
	GROUP BY 1,2,3
	) aspct
		on lstg.item_id = aspct.item_id

Where 1=1
and cat.LEAF_CATEG_ID = 74469 --- eBikes
and lstg.ITEM_SITE_ID = 3

Group By 1,2,3;




-----------------------GMV------------------------------

select
case when ck.SLR_CNTRY_ID = 3 then 'UK'
	else 'International' end as seller_cntry
,case when cal.retail_week <= 27 then 'YTD' else 'Rest of Year' End as ytd_flag
,sum(case when cal.retail_year = 2022 then ck.GMV20_PLAN end) as gmv_2022
,sum(case when cal.retail_year = 2023 then ck.GMV20_PLAN end) as gmv_2023


from PRS_RESTRICTED_V.SLNG_TRANS_SUPER_FACT ck
INNER JOIN DW_CAL_DT cal
	on ck.GMV_DT = cal.CAL_DT
	and cal.RETAIL_YEAR in (2022,2023)
INNER JOIN P_INVENTORYPLANNING_T.dw_category_groupings_adj CAT
	ON ck.LEAF_CATEG_ID = CAT.LEAF_CATEG_ID
	AND cat.site_id = 3

Where 1=1
and cat.LEAF_CATEG_ID = 74469 --- eBikes
and ck.SITE_ID = 3

group by 1,2

