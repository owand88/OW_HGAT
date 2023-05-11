
-- Author: 			Robbie Evans
-- Stakeholder: 	Beth Alexander, Eimear Naughton
-- Purpose: 		Provide compartive CTR and CR data for Peloton (seller) compared to other eBay benchmarks
-- Date Created: 	24/03/2023




create temp table views as

With 2023_items AS
(
Select 
lstg.item_id
,case when lstg.SLR_ID = 2463843441 then 'Peloton' else 'Other' end as seller_flag
,case when cat.CATEG_LVL4_ID = 58102 then 'Exercise Bikes' else 'Other' end as exercise_bikes_flag
,case when cat.CATEG_LVL2_ID = 15273 then 'Fitness Running Yoga' else 'Other' end as fry_flag
,case when cat.META_CATEG_ID = 888 then 'Sporting Goods' else 'Other' end as sporting_goods_flag
,case when lstg.CNDTN_ROLLUP_ID = 2 then 'Refurb' Else 'Other' end as refurb_flag
	
FROM PRS_RESTRICTED_V.SLNG_LSTG_SUPER_FACT lstg
INNER JOIN P_INVENTORYPLANNING_T.dw_category_groupings_adj CAT
	ON lstg.LEAF_CATEG_ID = CAT.LEAF_CATEG_ID
	AND cat.site_id = 3

Where 1=1
and lstg.AUCT_START_DT >= '2023-01-01'
and lstg.LSTG_SITE_ID = 3
and lstg.SLR_CNTRY_ID = 3

Group by 1,2,3,4,5,6
)


select 
seller_flag
,exercise_bikes_flag
,fry_flag
,sporting_goods_flag
,refurb_flag
,sum(srp_imprsn_cnt + store_imprsn_cnt) as IMP
,sum(TTL_VI_CNT) as VI

FROM PRS_restricted_V.SLNG_TRFC_SUPER_FACT ck
INNER JOIN DW_CAL_DT cal
	ON ck.cal_dt = cal.CAL_DT
	and cal.RETAIL_YEAR = 2023
	and cal.AGE_FOR_RTL_WEEK_ID < 0
INNER JOIN 2023_items i
	ON ck.ITEM_ID = i.item_id

where SITE_ID = 3

group by 1,2,3,4,5

;



drop table if exists sales;
create temp table sales as

(
SELECT
case when ck.SELLER_ID = 2463843441 then 'Peloton' else 'Other' end as seller_flag
,case when cat.CATEG_LVL4_ID = 58102 then 'Exercise Bikes' else 'Other' end as exercise_bikes_flag
,case when cat.CATEG_LVL2_ID = 15273 then 'Fitness Running Yoga' else 'Other' end as fry_flag
,case when cat.META_CATEG_ID = 888 then 'Sporting Goods' else 'Other' end as sporting_goods_flag
,case when ck.CNDTN_ROLLUP_ID = 2 then 'Refurb' Else 'Other' end as refurb_flag
,sum(ck.GMV20_SOLD_QUANTITY) as si

from PRS_restricted_V.SLNG_TRANS_SUPER_FACT ck
INNER JOIN P_INVENTORYPLANNING_T.dw_category_groupings_adj  AS CAT
	ON ck.LEAF_CATEG_ID = CAT.LEAF_CATEG_ID
	AND cat.site_id = 3
INNER JOIN DW_CAL_DT cal
	ON ck.GMV_DT = cal.CAL_DT
	and cal.RETAIL_YEAR = 2023
	and cal.AGE_FOR_RTL_WEEK_ID < 0

Where 1=1
and ck.SLR_CNTRY_ID = 3
and ck.RPRTD_WACKO_YN = 'N'
and ck.AUCT_START_DT >= '2023-01-01'

Group by 1,2,3,4,5
)
;



select v.*,s.si
From views v
left join sales s
	on v.seller_flag = s.seller_flag
	and v.exercise_bikes_flag = s.exercise_bikes_flag
	and v.fry_flag = s.fry_flag
	and v.sporting_goods_flag = s.sporting_goods_flag
	and v.refurb_flag = s.refurb_flag
	;
	
	
	
