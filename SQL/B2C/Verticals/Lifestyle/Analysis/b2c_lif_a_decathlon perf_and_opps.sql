-- JIRA:            UKPLAN-365

-- Author: 			Robbie Evans
-- Date:            20/05/2023

-- Stakeholder: 	Lizzie Read
-- Description: 	Report showing Decathlon seller YTD performance vs the category, highlighting key opportunities in inventory





With seller_cats AS
(
Select 
lstg.LEAF_CATEG_ID

From PRS_RESTRICTED_V.SLNG_LSTG_SUPER_FACT lstg
INNER JOIN ACCESS_VIEWS.DW_CAL_DT cal
	on lstg.AUCT_START_DT <= cal.CAL_DT
	and lstg.AUCT_END_DT >= cal.CAL_DT
	and cal.retail_week between 1 and 19
	and cal.RETAIL_YEAR in (2022,2023)

Where 1=1
and lstg.SLR_ID = 2405446751
and lstg.ITEM_SITE_ID = 3

Group by 1
)






select 
cal.RETAIL_YEAR
,cal.RETAIL_WEEK
,case when ck.seller_id = 2405446751 then 'Decathlon' else' Other' end as seller
,ck.DOMESTIC_CBT
,ck.B2C_C2C
,case when ck.CNDTN_ROLLUP_ID = 1 then 'New'
	when ck.CNDTN_ROLLUP_ID = 2 then 'Refurb'
	when ck.CNDTN_ROLLUP_ID = 3 then 'Used'
	else 'Other'
	End as item_cndtn
,cat.META_CATEG_NAME
,cat.CATEG_LVL2_NAME
,cat.CATEG_LVL3_NAME
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

From PRS_RESTRICTED_V.SLNG_TRANS_SUPER_FACT ck
INNER JOIN ACCESS_VIEWS.DW_CAL_DT cal
	on ck.gmv_dt = cal.CAL_DT
	and cal.retail_week between 1 and 19
	and cal.RETAIL_YEAR in (2022,2023)
INNER JOIN P_INVENTORYPLANNING_T.dw_category_groupings_adj CAT 
	ON CAT.LEAF_CATEG_ID = ck.LEAF_CATEG_ID 
	AND CAT.SITE_ID = 3
INNER JOIN seller_cats sc
	on sc.LEAF_CATEG_ID = ck.LEAF_CATEG_ID

Where 1=1
and ck.SLR_CNTRY_ID = 3

Group by 1,2,3,4,5,6,7,8,9


UNION ALL


select 
cal.RETAIL_YEAR
,cal.RETAIL_WEEK
,case when lstg.SLR_ID = 2405446751 then 'Decathlon' else' Other' end as seller
,0 as DOMESTIC_CBT
,lstg.B2C_C2C
,case when lstg.CNDTN_ROLLUP_ID = 1 then 'New'
	when lstg.CNDTN_ROLLUP_ID = 2 then 'Refurb'
	when lstg.CNDTN_ROLLUP_ID = 3 then 'Used'
	else 'Other'
	End as item_cndtn
,cat.META_CATEG_NAME
,cat.CATEG_LVL2_NAME
,cat.CATEG_LVL3_NAME
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

From PRS_RESTRICTED_V.SLNG_LSTG_SUPER_FACT lstg
INNER JOIN ACCESS_VIEWS.DW_CAL_DT cal
	on lstg.AUCT_START_DT <= cal.CAL_DT
	and lstg.AUCT_END_DT >= cal.CAL_DT
	and cal.retail_week between 1 and 19
	and cal.RETAIL_YEAR in (2022,2023)
INNER JOIN P_INVENTORYPLANNING_T.dw_category_groupings_adj CAT 
	ON CAT.LEAF_CATEG_ID = lstg.LEAF_CATEG_ID 
	AND CAT.SITE_ID = 3
INNER JOIN seller_cats sc
	on sc.LEAF_CATEG_ID = lstg.LEAF_CATEG_ID

Where 1=1
and lstg.SLR_CNTRY_ID = 3
and lstg.ITEM_SITE_ID = 3

Group by 1,2,3,4,5,6,7,8,9