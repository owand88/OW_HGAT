-- JIRA Ticket:     UKPLAN-476

-- Author: 			Robbie Evans
-- Stakeholder: 	Wahaaj Shabbir
-- Purpose: 		eMS requires us to understand how many foerign sellers are listing AG-eligible inventory on the UK site as this will need to be accounted for in the program
-- Date Created: 	28/07/2023




With elig_sneakers
(
select
	item_id
from
	access_views.DW_PES_ELGBLT_HIST
where
	1=1
	and evltn_end_ts = '2099-12-31 00:00:00'
	and BIZ_PRGRM_NAME = 'PSA_SNEAKER_EBAY_UK' -- UK Sneakers AG program
	and elgbl_yn_ind = 'Y' -- eligible items
	and coalesce(auct_end_date, '2099-12-31') >= current_date -- live listing only  
Group by
	1
)



Select
	c.cntry_desc
	,lstg.SLR_ID
	,count(distinct lstg.item_id) as live_listings
FROM
	PRS_RESTRICTED_V.SLNG_LSTG_SUPER_FACT lstg
	INNER JOIN elig_sneakers e
		on lstg.item_id = e.item_id
	LEFT JOIN DW_COUNTRIES c
		on lstg.SLR_CNTRY_ID = c.cntry_id
Where
	1=1
	and lstg.LSTG_SITE_ID = 3
	and lstg.LSTG_STATUS_ID 
Group BY
	1,2

