-- JIRA Ticket:     UKPLAN-543

-- Author: 			Robbie Evans
-- Stakeholder: 	Alice Winter
-- Purpose: 		Livewell are wanting to kno which listings of theirs from last year seem to be OOS this year and therefore driving declines
-- Date Created: 	06/09/2023





Select
lstg.*
,ck.sold_items

FROM
(
select 
	cal.retail_year
	,lstg.SLR_ID
	,lstg.ITEM_ID
	,lstg.AUCT_TITLE
	,lstg.AUCT_END_DT
	,case when LSTG_STATUS_ID = 0 then 'Live'
		when lstg_status_id = 1 then 'Ended'
		else 'Other'
		End as lstg_status
	,lstg.OUT_OF_STOCK_STS
	,QTY_SOLD
	
FROM PRS_RESTRICTED_V.SLNG_LSTG_SUPER_FACT lstg
inner JOIN DW_CAL_DT cal
	on lstg.AUCT_START_DT <= cal.CAL_DT
	and lstg.AUCT_END_DT >= cal.CAL_DT
	and cal.retail_year in (2022)

Where 1=1
	and lstg.slr_id = 1379005411

Group by 1,2,3,4,5,6,7,8

UNION ALL

select 
	cal.retail_year
	,lstg.SLR_ID
	,lstg.ITEM_ID
	,lstg.AUCT_TITLE
	,lstg.AUCT_END_DT
	,case when LSTG_STATUS_ID = 0 then 'Live'
		when lstg_status_id = 1 then 'Ended'
		else 'Other'
		End as lstg_status
	,lstg.OUT_OF_STOCK_STS
	,QTY_SOLD
	
FROM PRS_RESTRICTED_V.SLNG_LSTG_SUPER_FACT lstg
inner JOIN DW_CAL_DT cal
	on lstg.AUCT_START_DT <= cal.CAL_DT
	and lstg.AUCT_END_DT >= cal.CAL_DT
	and cal.retail_year in (2023)

Where 1=1
	and lstg.slr_id = 1379005411
	and lstg.LSTG_SITE_ID = 3

Group by 1,2,3,4,5,6,7,8
) lstg
LEFT JOIN
( 
Select ck.item_id
	,cal.retail_year
	,sum(ck.quantity) as sold_items
From DW_CHECKOUT_TRANS ck
INNER JOIN DW_CAL_DT cal
	on ck.gmv_dt = cal.CAL_DT
	and cal.retail_year in (2022,2023)
Where 1=1
	and ck.seller_id = 1379005411
	and ck.site_id = 3
Group by 1,2
) ck
	on lstg.item_id = ck.ITEM_ID
	and lstg.retail_year = ck.retail_year
	