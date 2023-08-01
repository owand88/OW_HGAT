-- JIRA Ticket:     UKPLAN-430

-- Author: 			Robbie Evans
-- Stakeholder: 	Wahaaj Shabbir
-- Purpose: 		With eBay Managed Shipping, sellers will need to relist GTC listings to get the effect of the new process. There is a need to understand the size of impact that this will have.
-- Date Created: 	07/07/2023


---------------------------------------Avg Listing Duration of live GTC listings-------------------------------

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




-- SELECT
-- 	lstg_drtn
-- 	,count(distinct item_id) as ll
-- FROM
-- 	(
	Select
		lstg.ITEM_ID
		,case when lstg.RLST_IND = 1 then 'Relisted' else 'New' End as relist_flag
		,DATEDIFF(CURRENT_DATE, lstg.auct_start_dt) AS lstg_drtn
	FROM
		PRS_RESTRICTED_V.SLNG_LSTG_SUPER_FACT lstg
	INNER JOIN
		elig_sneakers e
			on lstg.item_id = e.item_id
	Where
		1=1
		and lstg.SLR_CNTRY_ID = 3		--Only UK sellers
		and lstg.GTC_IND = 1			--Only include GTC listings
		and lstg.LSTG_SITE_ID = 3		--Only listings made on the UK site
		and lstg.LSTG_STATUS_ID = 0		--Only listings that are currently live
	Group BY
		1,2,3
-- 	)
-- GROUP BY
-- 	1
;



---------------------------------------Avg Listing Duration (time before relisting) of Relisted GTC listings-------------------------------



drop table if exists relisted_lstgs;

create temp table relisted_lstgs as
(
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
	lstg.item_id
FROM
	PRS_RESTRICTED_V.SLNG_LSTG_SUPER_FACT lstg
INNER JOIN
	elig_sneakers e
		on lstg.item_id = e.item_id
INNER JOIN
	DW_CAL_DT cal
		on lstg.AUCT_START_DT <= cal.CAL_DT
		and lstg.AUCT_END_DT >= cal.CAL_DT
		and cal.retail_year = 2022
Where
	1=1
	and lstg.SLR_CNTRY_ID = 3		--Only UK sellers
	and lstg.GTC_IND = 1			--Only include GTC listings
	and lstg.LSTG_SITE_ID = 3		--Only listings made on the UK site
-- 	and lstg.LSTG_STATUS_ID = 0		--Only listings that are currently live
	and lstg.RLST_IND = 1
Group BY
	1
)
;


select
	relist_flag
	,percentile(lstg_drtn, 0.25) AS lower_quartile
	,percentile(lstg_drtn, 0.50) AS median
	,percentile(lstg_drtn, 0.75) AS upper_quartile
FROM
	(
	select
		p.PARENT_ITEM_ID
		,case when lstg.RLST_IND = 1 then 'Relisted' else 'New' End as relist_flag
		,DATEDIFF(lstg.AUCT_END_DT, lstg.auct_start_dt) AS lstg_drtn
	From
		ACCESS_VIEWS.DW_LSTG_GEN p
	inner join
		relisted_lstgs r
			on p.item_id = r.item_id
	INNER JOIN
		PRS_RESTRICTED_V.SLNG_LSTG_SUPER_FACT lstg
			on p.PARENT_ITEM_ID = lstg.ITEM_ID

	Where 1=1
		and lstg.GTC_IND = 1
	Group by 1,2,3
	)
GROUP BY
	1