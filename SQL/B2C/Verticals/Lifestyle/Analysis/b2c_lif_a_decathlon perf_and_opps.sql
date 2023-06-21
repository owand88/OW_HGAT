-- JIRA:            UKPLAN-365

-- Author: 			Robbie Evans
-- Date:            20/05/2023

-- Stakeholder: 	Lizzie Read
-- Description: 	Report showing Decathlon seller YTD performance vs the category, highlighting key opportunities in inventory





drop table if exists p_robevans_t.lifestyle_seller_perf_opportunities_report;

Create table p_robevans_t.lifestyle_seller_perf_opportunities_report as

With seller_cats AS
(
Select 
lstg.LEAF_CATEG_ID
,cat.META_CATEG_NAME
,cat.CATEG_LVL2_NAME
,cat.CATEG_LVL3_NAME
,cat.CATEG_LVL4_NAME

From PRS_RESTRICTED_V.SLNG_LSTG_SUPER_FACT lstg
INNER JOIN ACCESS_VIEWS.DW_CAL_DT cal
	on lstg.AUCT_START_DT <= cal.CAL_DT
	and lstg.AUCT_END_DT >= cal.CAL_DT
	and cal.retail_week between 1 and 19
	and cal.RETAIL_YEAR in (2022,2023)
INNER JOIN P_INVENTORYPLANNING_T.dw_category_groupings_adj cat
	on cat.LEAF_CATEG_ID = lstg.LEAF_CATEG_ID
	and site_id = 3

Where 1=1
and lstg.SLR_ID = 2405446751
and lstg.ITEM_SITE_ID = 3

Group by 1,2,3,4,5
)

,

dates as 
(
Select CAL_DT
,RETAIL_WEEK
,RETAIL_YEAR
,AGE_FOR_RTL_WEEK_ID
From ACCESS_VIEWS.DW_CAL_DT
Where 1=1
and retail_year >= (select RETAIL_YEAR from ACCESS_VIEWS.DW_CAL_DT where AGE_FOR_RTL_WEEK_ID = -1 Group by 1)-1
and retail_week <= (select RETAIL_WEEK from ACCESS_VIEWS.DW_CAL_DT where AGE_FOR_RTL_WEEK_ID = -1 Group by 1)

Group by 1,2,3,4
)


----------------------------------------------------Transactional Data----------------------------------------------------------------

select 
cal.RETAIL_YEAR
,case when ck.seller_id = 2405446751 then 'Decathlon' else' Other' end as seller
,ck.DOMESTIC_CBT
,ck.B2C_C2C
,case when ck.CNDTN_ROLLUP_ID = 1 then 'New'
	when ck.CNDTN_ROLLUP_ID = 2 then 'Refurb'
	when ck.CNDTN_ROLLUP_ID = 3 then 'Used'
	else 'Other'
	End as item_cndtn
,sc.META_CATEG_NAME
,sc.CATEG_LVL2_NAME
,sc.CATEG_LVL3_NAME
,sc.CATEG_LVL4_NAME
,sum(case when ck.seller_id = 2405446751 then ck.GMV20_PLAN End) as decathlon_gmv
,sum(case when ck.seller_id = 2405446751 then ck.GMV20_SOLD_QUANTITY End) as decathlon_si
,sum(ck.GMV20_PLAN) as total_gmv
,sum(case when cal.retail_year = 2023 then ck.GMV20_PLAN end) as total_gmv_2023
,sum(case when cal.retail_year = 2022 then ck.GMV20_PLAN end) as total_gmv_2022
,sum(case when cal.RETAIL_YEAR = 2023 then ck.GMV20_SOLD_QUANTITY end) as total_si_2023
,sum(case when cal.RETAIL_YEAR = 2022 then ck.GMV20_SOLD_QUANTITY end) as total_si_2022
,count(distinct ck.SELLER_ID) as sellers
,0 as decathlon_ll
,0 as total_ll_2023
,0 as decathlon_views
,0 as total_views_2023
,0 as decathlon_watches
,0 as total_watches_2023
,0 as decathlon_impressions
,0 as total_impressions_2023

From PRS_RESTRICTED_V.SLNG_TRANS_SUPER_FACT ck
INNER JOIN dates cal
	on ck.gmv_dt = cal.CAL_DT
INNER JOIN seller_cats sc
	on sc.LEAF_CATEG_ID = ck.LEAF_CATEG_ID

Where 1=1
and ck.SLR_CNTRY_ID = 3

Group by 1,2,3,4,5,6,7,8,9


UNION ALL

----------------------------------------------------Listing Data----------------------------------------------------------------

select 
cal.RETAIL_YEAR
,case when lstg.SLR_ID = 2405446751 then 'Decathlon' else' Other' end as seller
,0 as DOMESTIC_CBT
,lstg.B2C_C2C
,case when lstg.CNDTN_ROLLUP_ID = 1 then 'New'
	when lstg.CNDTN_ROLLUP_ID = 2 then 'Refurb'
	when lstg.CNDTN_ROLLUP_ID = 3 then 'Used'
	else 'Other'
	End as item_cndtn
,sc.META_CATEG_NAME
,sc.CATEG_LVL2_NAME
,sc.CATEG_LVL3_NAME
,sc.CATEG_LVL4_NAME
,0 as decathlon_gmv
,0 as decathlon_si
,0 as total_gmv
,0 as total_gmv_2023
,0 as total_gmv_2022
,0 as total_si_2023
,0 as total_si_2022
,0 as sellers
,count(distinct case when lstg.SLR_ID = 2405446751 then lstg.ITEM_ID End) as decathlon_ll
,count(distinct case when cal.RETAIL_YEAR = 2023 then lstg.ITEM_ID End) as total_ll_2023
,0 as decathlon_views
,0 as total_views_2023
,0 as decathlon_watches
,0 as total_watches_2023
,0 as decathlon_impressions
,0 as total_impressions_2023

From PRS_RESTRICTED_V.SLNG_LSTG_SUPER_FACT lstg
INNER JOIN dates cal
	on lstg.AUCT_START_DT <= cal.CAL_DT
	and lstg.AUCT_END_DT >= cal.CAL_DT
INNER JOIN seller_cats sc
	on sc.LEAF_CATEG_ID = lstg.LEAF_CATEG_ID

Where 1=1
and lstg.SLR_CNTRY_ID = 3
and lstg.ITEM_SITE_ID = 3

Group by 1,2,3,4,5,6,7,8,9


UNION ALL

----------------------------------------------------Activity Data----------------------------------------------------------------

select 
cal.RETAIL_YEAR
,case when trfc.seller_id = 2405446751 then 'Decathlon' else' Other' end as seller
,0 as DOMESTIC_CBT
,lstg.B2C_C2C
,case when lstg.CNDTN_ROLLUP_ID = 1 then 'New'
	when lstg.CNDTN_ROLLUP_ID = 2 then 'Refurb'
	when lstg.CNDTN_ROLLUP_ID = 3 then 'Used'
	else 'Other'
	End as item_cndtn
,sc.META_CATEG_NAME
,sc.CATEG_LVL2_NAME
,sc.CATEG_LVL3_NAME
,sc.CATEG_LVL4_NAME
,0 as decathlon_gmv
,0 as decathlon_si
,0 as total_gmv
,0 as total_gmv_2023
,0 as total_gmv_2022
,0 as total_si_2023
,0 as total_si_2022
,0 as sellers
,0 as decathlon_ll
,0 as total_ll_2023
,sum(case when trfc.SELLER_ID = 2405446751 then trfc.TTL_VI_CNT End) as decathlon_views
,sum(case when retail_year = 2023 then trfc.TTL_VI_CNT end) as total_views_2023
,sum(case when trfc.SELLER_ID = 2405446751 then trfc.watch_cnt End) as decathlon_watches
,sum(case when retail_year = 2023 then trfc.watch_cnt end) as total_watches_2023
,sum(case when trfc.SELLER_ID = 2405446751 then trfc.SRP_IMPRSN_CNT End)+sum(case when trfc.SELLER_ID = 2405446751 then trfc.STORE_IMPRSN_CNT End) as decathlon_impressions
,sum(case when retail_year = 2023 then trfc.SRP_IMPRSN_CNT end)+sum(case when retail_year = 2023 then trfc.STORE_IMPRSN_CNT End) as total_impressions_2023

from PRS_RESTRICTED_V.SLNG_TRFC_SUPER_FACT trfc
Inner join dates cal
	on trfc.CAL_DT = cal.CAL_DT
INNER JOIN seller_cats sc
	on sc.LEAF_CATEG_ID = trfc.LEAF_CATEG_ID
INNER JOIN PRS_RESTRICTED_V.SLNG_LSTG_SUPER_FACT lstg
	on trfc.item_id = lstg.item_id

Where 1=1
and lstg.SLR_CNTRY_ID = 3
and lstg.ITEM_SITE_ID = 3
and trfc.SITE_ID = 3

Group by 1,2,3,4,5,6,7,8,9
;








------------------------------------------------------------------------------------------------------------------------------------------









drop table if exists seller_cats;
create temp table seller_cats as
(
Select 
lstg.LEAF_CATEG_ID
,cat.META_CATEG_NAME
,cat.CATEG_LVL2_NAME
,cat.CATEG_LVL3_NAME
,cat.CATEG_LVL4_NAME

From PRS_RESTRICTED_V.SLNG_LSTG_SUPER_FACT lstg
INNER JOIN ACCESS_VIEWS.DW_CAL_DT cal
	on lstg.AUCT_START_DT <= cal.CAL_DT
	and lstg.AUCT_END_DT >= cal.CAL_DT
	and cal.retail_week between 1 and 19
	and cal.RETAIL_YEAR in (2022,2023)
INNER JOIN P_INVENTORYPLANNING_T.dw_category_groupings_adj cat
	on cat.LEAF_CATEG_ID = lstg.LEAF_CATEG_ID
	and site_id = 3

Where 1=1
and lstg.SLR_ID = 2405446751
and lstg.ITEM_SITE_ID = 3

Group by 1,2,3,4,5
)
;

drop table if exists dates;
create temp table dates as
(
Select CAL_DT
,RETAIL_WEEK
,RETAIL_YEAR
,AGE_FOR_RTL_WEEK_ID
From ACCESS_VIEWS.DW_CAL_DT
Where 1=1
and retail_year >= (select RETAIL_YEAR from ACCESS_VIEWS.DW_CAL_DT where AGE_FOR_RTL_WEEK_ID = -1 Group by 1)
and retail_week <= (select RETAIL_WEEK from ACCESS_VIEWS.DW_CAL_DT where AGE_FOR_RTL_WEEK_ID = -1 Group by 1)

Group by 1,2,3,4
)
;

drop table if exists top_sellers_meta;
create temp table top_sellers_meta as 
(
select *
From
	(
	select 
	ck.CNDTN_ROLLUP_ID
	,sc.META_CATEG_NAME
	,ck.SELLER_ID
	,sum(ck.GMV20_PLAN) as gmv
	,dense_rank() over (partition by CNDTN_ROLLUP_ID, sc.META_CATEG_NAME order by sum(ck.GMV20_PLAN) desc) as rank

	From PRS_RESTRICTED_V.SLNG_TRANS_SUPER_FACT ck
	INNER JOIN dates cal
		on ck.gmv_dt = cal.CAL_DT
	INNER JOIN seller_cats sc
		on sc.LEAF_CATEG_ID = ck.LEAF_CATEG_ID

	Where 1=1
	and ck.SLR_CNTRY_ID = 3
	and upper(ck.B2C_C2C) = 'B2C'
	and upper(ck.DOMESTIC_CBT) = 'DOMESTIC'

	Group by 1,2,3
	)
Where rank <= 25
)
;

drop table if exists top_sellers_l2;
create temp table top_sellers_l2 as 
(
select *
From
	(
	select 
	ck.CNDTN_ROLLUP_ID
	,sc.CATEG_LVL2_NAME
	,ck.SELLER_ID
	,sum(ck.GMV20_PLAN) as gmv
	,dense_rank() over (partition by CNDTN_ROLLUP_ID, sc.CATEG_LVL2_NAME order by sum(ck.GMV20_PLAN) desc) as rank

	From PRS_RESTRICTED_V.SLNG_TRANS_SUPER_FACT ck
	INNER JOIN dates cal
		on ck.gmv_dt = cal.CAL_DT
	INNER JOIN seller_cats sc
		on sc.LEAF_CATEG_ID = ck.LEAF_CATEG_ID

	Where 1=1
	and ck.SLR_CNTRY_ID = 3
	and upper(ck.B2C_C2C) = 'B2C'
	and upper(ck.DOMESTIC_CBT) = 'DOMESTIC'

	Group by 1,2,3
	)
where rank <= 25
)
;

drop table if exists top_sellers_l3;
create temp table top_sellers_l3 as 
(
select *
From
	(
	select 
	ck.CNDTN_ROLLUP_ID
	,sc.CATEG_LVL3_NAME
	,ck.SELLER_ID
	,sum(ck.GMV20_PLAN) as gmv
	,dense_rank() over (partition by CNDTN_ROLLUP_ID, sc.CATEG_LVL3_NAME order by sum(ck.GMV20_PLAN) desc) as rank

	From PRS_RESTRICTED_V.SLNG_TRANS_SUPER_FACT ck
	INNER JOIN dates cal
		on ck.gmv_dt = cal.CAL_DT
	INNER JOIN seller_cats sc
		on sc.LEAF_CATEG_ID = ck.LEAF_CATEG_ID

	Where 1=1
	and ck.SLR_CNTRY_ID = 3
	and upper(ck.B2C_C2C) = 'B2C'
	and upper(ck.DOMESTIC_CBT) = 'DOMESTIC'

	Group by 1,2,3
	)
Where rank <= 25
)
;

drop table if exists top_sellers_l4;
create temp table top_sellers_l4 as
(
select *
From
	(
	select 
	ck.CNDTN_ROLLUP_ID
	,sc.CATEG_LVL4_NAME
	,ck.SELLER_ID
	,sum(ck.GMV20_PLAN) as gmv
	,dense_rank() over (partition by CNDTN_ROLLUP_ID, sc.CATEG_LVL4_NAME order by sum(ck.GMV20_PLAN) desc) as rank

	From PRS_RESTRICTED_V.SLNG_TRANS_SUPER_FACT ck
	INNER JOIN dates cal
		on ck.gmv_dt = cal.CAL_DT
	INNER JOIN seller_cats sc
		on sc.LEAF_CATEG_ID = ck.LEAF_CATEG_ID

	Where 1=1
	and ck.SLR_CNTRY_ID = 3
	and upper(ck.B2C_C2C) = 'B2C'
	and upper(ck.DOMESTIC_CBT) = 'DOMESTIC'

	Group by 1,2,3
	)
Where rank <= 25
)
;




drop table if exists p_robevans_t.lifestyle_seller_perf_opportunities_report_top_sellers;

Create table p_robevans_t.lifestyle_seller_perf_opportunities_report_top_sellers as


select 
'Top 25 Meta' as target
,case when ck.CNDTN_ROLLUP_ID = 1 then 'New'
	when ck.CNDTN_ROLLUP_ID = 2 then 'Refurb'
	when ck.CNDTN_ROLLUP_ID = 3 then 'Used'
	else 'Other'
	End as item_cndtn
,sc.META_CATEG_NAME
-- ,sc.CATEG_LVL2_NAME
-- ,sc.CATEG_LVL3_NAME
-- ,sc.CATEG_LVL4_NAME
,sum(ck.GMV20_PLAN) as total_gmv
,count(distinct ck.seller_id) as sellers

From PRS_RESTRICTED_V.SLNG_TRANS_SUPER_FACT ck
INNER JOIN dates cal
	on ck.gmv_dt = cal.CAL_DT
INNER JOIN seller_cats sc
	on sc.LEAF_CATEG_ID = ck.LEAF_CATEG_ID
INNER JOIN top_sellers_meta m
	on ck.SELLER_ID = m.seller_id
	and m.CNDTN_ROLLUP_ID = ck.CNDTN_ROLLUP_ID
	and m.META_CATEG_NAME = sc.META_CATEG_NAME

Where 1=1

Group by 1,2,3


UNION ALL


select 
'Top 25 L2' as target
,case when ck.CNDTN_ROLLUP_ID = 1 then 'New'
	when ck.CNDTN_ROLLUP_ID = 2 then 'Refurb'
	when ck.CNDTN_ROLLUP_ID = 3 then 'Used'
	else 'Other'
	End as item_cndtn
-- ,sc.META_CATEG_NAME
,sc.CATEG_LVL2_NAME
-- ,sc.CATEG_LVL3_NAME
-- ,sc.CATEG_LVL4_NAME
,sum(ck.GMV20_PLAN) as total_gmv
,count(distinct ck.seller_id) as sellers

From PRS_RESTRICTED_V.SLNG_TRANS_SUPER_FACT ck
INNER JOIN dates cal
	on ck.gmv_dt = cal.CAL_DT
INNER JOIN seller_cats sc
	on sc.LEAF_CATEG_ID = ck.LEAF_CATEG_ID
INNER JOIN top_sellers_l2 m
	on ck.SELLER_ID = m.seller_id
	and m.CNDTN_ROLLUP_ID = ck.CNDTN_ROLLUP_ID
	and m.CATEG_LVL2_NAME = sc.CATEG_LVL2_NAME
	
Where 1=1

Group by 1,2,3


UNION ALL


select 
'Top 25 L3' as target
,case when ck.CNDTN_ROLLUP_ID = 1 then 'New'
	when ck.CNDTN_ROLLUP_ID = 2 then 'Refurb'
	when ck.CNDTN_ROLLUP_ID = 3 then 'Used'
	else 'Other'
	End as item_cndtn
-- ,sc.META_CATEG_NAME
-- ,sc.CATEG_LVL2_NAME
,sc.CATEG_LVL3_NAME
-- ,sc.CATEG_LVL4_NAME
,sum(ck.GMV20_PLAN) as total_gmv
,count(distinct ck.seller_id) as sellers

From PRS_RESTRICTED_V.SLNG_TRANS_SUPER_FACT ck
INNER JOIN dates cal
	on ck.gmv_dt = cal.CAL_DT
INNER JOIN seller_cats sc
	on sc.LEAF_CATEG_ID = ck.LEAF_CATEG_ID
INNER JOIN top_sellers_l3 m
	on ck.SELLER_ID = m.seller_id
	and m.CNDTN_ROLLUP_ID = ck.CNDTN_ROLLUP_ID
	and m.CATEG_LVL3_NAME = sc.CATEG_LVL3_NAME

Where 1=1

Group by 1,2,3


UNION ALL


select 
'Top 25 L4' as target
,case when ck.CNDTN_ROLLUP_ID = 1 then 'New'
	when ck.CNDTN_ROLLUP_ID = 2 then 'Refurb'
	when ck.CNDTN_ROLLUP_ID = 3 then 'Used'
	else 'Other'
	End as item_cndtn
-- ,sc.META_CATEG_NAME
-- ,sc.CATEG_LVL2_NAME
-- ,sc.CATEG_LVL3_NAME
,sc.CATEG_LVL4_NAME
,sum(ck.GMV20_PLAN) as total_gmv
,count(distinct ck.seller_id) as sellers

From PRS_RESTRICTED_V.SLNG_TRANS_SUPER_FACT ck
INNER JOIN dates cal
	on ck.gmv_dt = cal.CAL_DT
INNER JOIN seller_cats sc
	on sc.LEAF_CATEG_ID = ck.LEAF_CATEG_ID
INNER JOIN top_sellers_l4 m
	on ck.SELLER_ID = m.seller_id
	and m.CNDTN_ROLLUP_ID = ck.CNDTN_ROLLUP_ID
	and m.CATEG_LVL4_NAME = sc.CATEG_LVL4_NAME

Where 1=1

Group by 1,2,3
;




drop table if exists p_robevans_t.lifestyle_seller_perf_opportunities_report_seller_rank;
create table p_robevans_t.lifestyle_seller_perf_opportunities_report_seller_rank as

select *
,case when CNDTN_ROLLUP_ID = 1 then 'New'
	when CNDTN_ROLLUP_ID = 2 then 'Refurb'
	when CNDTN_ROLLUP_ID = 3 then 'Used'
	else 'Other'
	End as item_cndtn
from top_sellers_meta                       
where seller_id = 2405446751

UNION ALL

select *
,case when CNDTN_ROLLUP_ID = 1 then 'New'
	when CNDTN_ROLLUP_ID = 2 then 'Refurb'
	when CNDTN_ROLLUP_ID = 3 then 'Used'
	else 'Other'
	End as item_cndtn
from top_sellers_l2                       
where seller_id = 2405446751

UNION ALL

select *
,case when CNDTN_ROLLUP_ID = 1 then 'New'
	when CNDTN_ROLLUP_ID = 2 then 'Refurb'
	when CNDTN_ROLLUP_ID = 3 then 'Used'
	else 'Other'
	End as item_cndtn
from top_sellers_l3                     
where seller_id = 2405446751

UNION ALL

select *
,case when CNDTN_ROLLUP_ID = 1 then 'New'
	when CNDTN_ROLLUP_ID = 2 then 'Refurb'
	when CNDTN_ROLLUP_ID = 3 then 'Used'
	else 'Other'
	End as item_cndtn
from top_sellers_l4                      
where seller_id = 2405446751
