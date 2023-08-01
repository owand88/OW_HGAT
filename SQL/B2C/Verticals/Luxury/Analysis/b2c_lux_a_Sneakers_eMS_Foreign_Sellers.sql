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
	evltn_end_ts = '2099-12-31 00:00:00'
	and BIZ_PRGRM_NAME = 'PSA_SNEAKER_EBAY_UK'					--UK Sneakers AG program
	and elgbl_yn_ind ='Y'										--Only eligible items
	and coalesce( auct_end_date, '2099-12-31') >= current_date	--Only live listings  
Group by
	1
)


Select
	lstg.SLR_ID
	,sc.cntry_desc as seller_country
	,lstg.ITEM_CNTRY_DESC as item_country
-- 	,avg(DATEDIFF(CURRENT_DATE(), lstg.auct_start_dt)) AS curr_lstg_drtn
	,count(distinct lstg.item_id) as ll
FROM
	PRS_RESTRICTED_V.SLNG_LSTG_SUPER_FACT lstg
INNER JOIN
	elig_sneakers e
		on lstg.item_id = e.item_id
LEFT JOIN
	DW_COUNTRIES sc 
		on lstg.SLR_CNTRY_ID = sc.cntry_id
Where
	1=1
-- 	and lstg.SLR_CNTRY_ID = 3		--Only UK sellers
	and lstg.GTC_IND = 1			--Only include GTC listings
	and lstg.LSTG_SITE_ID = 3		--Only listings made on the UK site
	and lstg.LSTG_STATUS_ID = 0		--Only listings that are currently live
Group BY
	1,2,3
