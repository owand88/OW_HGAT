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




Select lstg.SLR_ID
,u.USER_DSGNTN_ID as seller_name
,case when (case when lstg.START_PRICE_LSTG_CURNCY_AMT > lstg.RSRV_PRICE_LSTG_CURNCY_AMT then lstg.START_PRICE_LSTG_CURNCY_AMT else lstg.RSRV_PRICE_LSTG_CURNCY_AMT End) <60 then '<£60'
	when (case when lstg.START_PRICE_LSTG_CURNCY_AMT > lstg.RSRV_PRICE_LSTG_CURNCY_AMT then lstg.START_PRICE_LSTG_CURNCY_AMT else lstg.RSRV_PRICE_LSTG_CURNCY_AMT End) between 60 and 100 then '£60-£100'
	Else '>£100' End as lstg_price_tranche
,count(distinct lstg.item_id) as ll

From PRS_RESTRICTED_V.SLNG_LSTG_SUPER_FACT lstg
inner join elig_sneakers e
	on lstg.ITEM_ID = e.item_id
LEFT JOIN DW_USERS u 
	on lstg.SLR_ID = u.user_id

Where 1=1
and lstg.SLR_CNTRY_ID = 3
and lstg.B2C_C2C = 'B2C'

Group by 1,2,3