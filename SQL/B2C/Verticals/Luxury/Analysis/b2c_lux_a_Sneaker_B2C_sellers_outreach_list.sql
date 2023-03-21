-- Author: 			Robbie Evans
-- Stakeholder: 	Wahaaj Shabbir
-- Purpose: 		To provide a list of B2C sneaker sellers for comms outreach on the new Eligibility 2.0 initiative
-- Date Created: 	21/03/2023


select
	ck.SELLER_ID
	,u.user_slctd_id as seller_name
	,sum(case when cat.CATEG_LVL4_ID IN (15709,95672) and ck.ITEM_PRICE >= 60 then ck.GMV20_SOLD_QUANTITY End) as si_mens_womens_trainers
	,sum(case when cat.CATEG_LVL4_ID IN (15709,95672,155202,57974,57929) and ck.ITEM_PRICE >= 100 and ck.BYR_CNTRY_ID = ck.SLR_CNTRY_ID then ck.GMV20_SOLD_QUANTITY End) as si_sneakers_ag

FROM PRS_RESTRICTED_V.SLNG_TRANS_SUPER_FACT AS CK
INNER JOIN ACCESS_VIEWS.DW_CAL_DT CAL 
	ON CAL.CAL_DT = CK.gmv_dt 
	and AGE_FOR_RTL_WEEK_ID >= -52
	and AGE_FOR_RTL_WEEK_ID <= -1
left join dw_users u
	on ck.seller_id = u.user_id
INNER JOIN DW_CATEGORY_GROUPINGS CAT 
	ON CAT.LEAF_CATEG_ID = CK.LEAF_CATEG_ID 
	AND CAT.SITE_ID = 3
	AND CAT.SAP_CATEGORY_ID NOT IN (5,7,41,23,-999)   

WHERE 1=1
	AND CK.RPRTD_WACKO_YN  =  'N'
	AND CK.SALE_TYPE NOT IN (10,15)
	and ck.SLR_CNTRY_ID = 3
	and cat.CATEG_LVL4_ID IN (15709,95672,155202,57974,57929)
	and ck.B2C_C2C = 'B2C'

GROUP BY 1,2