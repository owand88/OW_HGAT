-- JIRA Ticket:     UKPLAN-521

-- Author: 			Robbie Evans
-- Stakeholder: 	Wahaaj Shabbir
-- Purpose: 		Top sellers list needed for the Sneakers AG eMS Beta launch. Need a mix of sellers including those that charge shipping fees, those that don't, B2C, C2C
-- Date Created: 	23/08/2023




With elig_sneakers
(
select
	item_id	
from
	access_views.DW_PES_ELGBLT_HIST
where
	evltn_end_ts = '2099-12-31 00:00:00'
	and BIZ_PRGRM_ID in ('bp-8811564603')					--UK Sneakers AG programs
	and elgbl_yn_ind ='Y'									--Only eligible items
	and AG_IND = 1
Group by
	1
)



select SELLER_ID
	,seller_name
	,company_name
	,B2C_C2C
	,top_rated_seller_uk_yn
	,EMAIL_SPECL_PROMOSOFFERSEVENTS
	,EMAIL
	,sum(delivery_fees_YTD_GBP) as delivery_fees_YTD_GBP
	,sum(gmv_YTD_GBP) as gmv_YTD_GBP
	,count(distinct case when delivery_fees_YTD_GBP = 0 then TRANSACTION_ID end) as free_delivery_transactions
	,count(distinct TRANSACTION_ID) as total_transactions

FROM
(
Select
	ck.SELLER_ID
	,ck.TRANSACTION_ID
	,u.user_slctd_id as seller_name
	,u.comp as company_name
	,ck.B2C_C2C
	,u.top_rated_seller_uk_yn
	,u.EMAIL_SPECL_PROMOSOFFERSEVENTS
	,u.EMAIL
	,sum(ck.oms_shpng_cost_lc_amt) as delivery_fees_YTD_GBP
	,sum(ck.GMV20_LC_AMT) as gmv_YTD_GBP
	
FROM PRS_RESTRICTED_V.SLNG_TRANS_SUPER_FACT ck
INNER JOIN elig_sneakers e
	on ck.item_id = e.item_id
INNER JOIN DW_CAL_DT cal
	on ck.gmv_dt = cal.CAL_DT
	and cal.RETAIL_YEAR = 2023
	and cal.AGE_FOR_RTL_WEEK_ID < 0
INNER JOIN PRS_SECURE_V.DW_USERS u
	on ck.SELLER_ID = u.user_id
	
Where 1=1
	and ck.SLR_CNTRY_ID = 3

Group BY
	1,2,3,4,5,6,7,8
)

Group by 1,2,3,4,5,6,7


