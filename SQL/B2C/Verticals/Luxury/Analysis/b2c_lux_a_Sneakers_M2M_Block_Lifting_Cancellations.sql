-- JIRA:            

-- Author: 			Robbie Evans
-- Date:            17/05/2023

-- Stakeholder: 	Wahaaj Shabbir
-- Description: 	Sneakers AG Cancellations pre vs post M2M block being lifted





-- Block lifted 26 July	
Select 	
RETAIL_YEAR	
,retail_week	
,case when retail_week < 30 and retail_year = 2022 then 'Before Block Lifted' else 'After Block Lifted' end as time_frame	
-- ,CANCELLED_ITEM_FLAG	
,bbe.cncl_yn_ind
-- ,BBE_TRANS_TYPE --cancel requestor (buyer/seller)
-- ,BBE_TRANS_TYPE_SUCESS --whether cancellation successful or not
,cr_lkp.rqst_rsn_desc
,P_BYPASS_IND
,count(distinct ck.TRANSACTION_ID) as orders	
	
From P_PSA_ANALYTICS_T.PSA_TRANSACTIONS_NEW ck	
left join prs_restricted_v.ebay_trans_rltd_event bbe
	on ck.item_id=bbe.item_id and ck.transaction_id=bbe.trans_id
left join po_cncl_rqst_rsn_lkp cr_lkp
	on bbe.cncl_rqst_rsn_cd=cr_lkp.rqst_rsn_cd
	
Where 1=1	
	and upper(HUB_REV_ROLLUP) = 'UK'
	and upper(HUB_CATEGORY) = 'SNEAKERS'
	and upper(BYR_SHIP_CNTRY_REV_ROLLUP) = 'UK'
	
Group by 1,2,3,4,5,6
;	
