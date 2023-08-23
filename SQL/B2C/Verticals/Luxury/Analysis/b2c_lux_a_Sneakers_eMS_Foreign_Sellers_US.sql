-- JIRA Ticket:     UKPLAN-507

-- Author: 			Robbie Evans
-- Stakeholder: 	Jenny Ke, Minh Tran-Lee
-- Purpose: 		eMS requires us to understand how many foreign sellers are listing AG-eligible inventory on the US site as this will need to be accounted for in the program
-- Date Created: 	16/08/2023




With elig_sneakers
(
select
	item_id	
from
	access_views.DW_PES_ELGBLT_HIST
where
	evltn_end_ts = '2099-12-31 00:00:00'
	and BIZ_PRGRM_NAME in ('AG_EMS_SNEAKER_EBAY_US','AG_SNEAKER_EBAY_US')					--US Sneakers AG programs
	and elgbl_yn_ind ='Y'																	--Only eligible items
	and coalesce( auct_end_date, '2099-12-31') >= current_date								--Only live listings  
	and AG_IND = 1
Group by
	1
)


Select
	lstg.SLR_ID
	,sc.cntry_desc as seller_country
	,ic.cntry_desc as item_country
	,count(distinct lstg.item_id) as ll
	
FROM DW_LSTG_ITEM lstg
INNER JOIN elig_sneakers e
	on lstg.item_id = e.item_id
LEFT JOIN DW_COUNTRIES sc 
	on lstg.SLR_CNTRY_ID = sc.cntry_id
LEFT JOIN DW_COUNTRIES ic
	on lstg.ITEM_CNTRY_ID = ic.cntry_id
	
Where 1=1
	and lstg.GTC_UP_FLAG = 1		--Only include GTC listings
	and lstg.ITEM_SITE_ID = 0		--Only listings made on the UK site
	and lstg.LSTG_STATUS_ID = 0		--Only listings that are currently live

Group BY
	1,2,3

