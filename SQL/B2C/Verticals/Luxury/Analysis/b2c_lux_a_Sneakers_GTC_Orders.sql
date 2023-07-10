-- JIRA Ticket:     UKPLAN-430

-- Author: 			Robbie Evans
-- Stakeholder: 	Wahaaj Shabbir
-- Purpose: 		With eBay Managed Shipping, sellers will need to relist GTC listings to get the effect of the new process. There is a need to understand the size of impact that this will have.
-- Date Created: 	07/07/2023




With elig_sneakers
(
select item_id
from access_views.DW_PES_ELGBLT_HIST
where evltn_end_ts = '2099-12-31 00:00:00'
and BIZ_PRGRM_NAME = 'PSA_SNEAKER_EBAY_UK' -- UK Sneakers AG program
and elgbl_yn_ind ='Y' -- eligible items
and coalesce( auct_end_date, '2099-12-31') >= current_date -- live listing only  
Group by 1
)



Select
count(distinct case when GTC_IND = 1 then lstg.ITEM_ID End) as gtc_ag_listings
,count(distinct lstg.item_id) as total_ag_listings
,count(distinct case when GTC_IND = 1 then lstg.SLR_ID End) as gtc_ag_sellers
,count(distinct lstg.SLR_ID) as total_ag_sellers
,avg(case when GTC_IND = 1 then lstg.START_PRICE_LSTG_CURNCY_AMT End) as gtc_ag_asp
,avg(lstg.START_PRICE_LSTG_CURNCY_AMT) as total_ag_asp

FROM PRS_RESTRICTED_V.SLNG_LSTG_SUPER_FACT lstg
INNER JOIN elig_sneakers e
	on lstg.item_id = e.item_id

Where 1=1
and lstg.SLR_CNTRY_ID = 3

