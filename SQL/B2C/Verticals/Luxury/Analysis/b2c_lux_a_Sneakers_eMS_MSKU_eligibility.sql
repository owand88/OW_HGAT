-- JIRA Ticket:     UKPLAN-542

-- Author: 			Robbie Evans
-- Stakeholder: 	Wahaaj Shabbir
-- Purpose: 		Currently sellers of AG-Sneakers may have variations that aren't AG-eligible and are able to send these directly to the buyer. Once eMS launches, all variations will need to go through the Auth Centre if even one is AG-eligible. The team need to understand the size of these variations in the current landscape and what the expected additional volumes going into the Auth Centre would look like.
-- Date Created: 	06/09/2023


---------------------------------------------Breakdown of AG-eligible Listings by variants-------------------------------------

Select *
From
(
Select case when total_variations > 1 then 'MSKU'
		ELSE 'Single SKU'
		End as MSKU_Flag
	,case when eligble_variations = 0 and non_eligble_variations > 0 then 'All Non-Eligible'
		when eligble_variations > 0 and non_eligble_variations > 0 then 'Both Eligible and Non-Eligible'
		when eligble_variations > 0 and non_eligble_variations = 0 then 'All Eligible'
		end ag_elig_flag
	,count(distinct item_id) as lstgs
-- 	,sum(eligble_variations) as elig_variations
-- 	,sum(non_eligble_variations) as non_elig_variations
FROM
(
select ag.ITEM_ID
	,count(distinct case when AG.elgbl_yn_ind ='Y' then ag.vrtn_id END) as eligble_variations
	,count(distinct case when AG.elgbl_yn_ind ='N' then ag.vrtn_id END) as non_eligble_variations
	,count(distinct ag.vrtn_id) as total_variations
from access_views.DW_PES_ELGBLT_HIST AG
left join lstg_item_vrtn b
	on AG.vrtn_id = b.ITEM_VRTN_ID
where 1=1
	and AG.evltn_end_ts = '2099-12-31 00:00:00'
	and AG.biz_prgrm_id in ('bp-8811564603') -- Sneakers AG program
-- 		and AG.elgbl_yn_ind ='Y' -- eligible items
	and coalesce( AG.auct_end_date, '2099-12-31') >= current_date 
	and coalesce( b.AUCT_END_DT, '2099-12-31') >= current_date  	
Group by 1
)
group by 1,2
)
Where ag_elig_flag <> 'All Non-Eligible'


;


-------------------------------------------------Number of Sneakers Received at the Hub every week---------------------------------------------

Select 
cal.retail_week
,sum(TTL_ITEMS) as quantity_received

From P_PSA_ANALYTICS_T.psa_hub_data hub
INNER JOIN DW_CAL_DT cal
	on hub.SHPMT_RCVD_DATE_DT = cal.CAL_DT
	and cal.retail_year = 2023
	and cal.AGE_FOR_RTL_WEEK_ID < 0

Where 1=1
and upper(HUB_REV_ROLLUP) = 'UK'
and upper(IS_RETURN_FLAG_YN_IND) = 'N'
and upper(HUB_CATEGORY) = 'SNEAKERS'
and RY_INBOUND = 2023

Group by 1