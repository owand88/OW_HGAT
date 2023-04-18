-- Author: 			Robbie Evans
-- Stakeholder: 	Alice Winter
-- Purpose: 		To show the proportion of sales that came from Coupons and other Deals/Promos for a particular seller
-- Date Created: 	28/03/2023




select 
cal.CAL_DT
,CASE 
WHEN deal.item_id IS NOT NULL OR NERP.ITEM_ID IS NOT NULL THEN 'Promo Manager & Sub Deals' 
WHEN Lower((CASE  WHEN ck.byr_cntry_id IN(0, -1,1, -999,225,679,1000) AND ck.slr_cntry_id IN(0, -1,1, -999,225,679,1000)  THEN 'Domestic' WHEN ck.byr_cntry_id=ck.slr_cntry_id AND ck.byr_cntry_id IN (3,77) THEN 'Domestic' ELSE 'CBT' end ))=Lower('CBT') THEN 'Exports' 
WHEN Lower((CASE  WHEN (coupon.item_id) IS NOT NULL THEN 'Y' ELSE 'N' end ))=Lower('Y') THEN 'Coupon' 
ELSE 'Baseline' 
end  AS mece_bucket
,sum(ck.GMV20_SOLD_QUANTITY) as sold_items
,sum(ck.GMV20_PLAN) as GMV

from PRS_RESTRICTED_V.SLNG_TRANS_SUPER_FACT ck
INNER JOIN DW_CAL_DT cal
	on ck.gmv_dt = cal.CAL_DT
	and cal.cal_dt = '2023-03-27'
INNER JOIN DW_USERS u
	on ck.SELLER_ID = u.user_id

-- Cpn Transactions
left join P_CSI_TBS_T.cpn_trxns   as coupon
ON coupon.item_id = ck.item_id 
AND coupon.transaction_id = ck.transaction_id

-- Deals transactions (Promo manager deals)
left join
(
select item_id,transaction_id
from access_views.glb_deals_trans_cube_final 
WHERE DEAL_SITE_ID IN(0,100,3,77) AND UNIT_SBSDY_USD_PLAN_AMT>0
GROUP BY 1,2) as deal ---Subsidized Regular Deals 
on deal.item_id=ck.item_id and ck.transaction_id=DEAL.transaction_id

-- NERP DEALS
LEFT JOIN (
SELECT ITEM_ID, CK_TRANS_ID
FROM P_CSI_TBS_T.nerp_data_verticals_wbr
WHERE Upper(FLAG_NEW) IN ('LOAD_AS_UNSUB','SPOTLIGHT_NOT_AVAILABLE')
GROUP BY 1,2
)NERP
ON NERP.ITEM_ID = CK.ITEM_ID
AND NERP.CK_TRANS_ID = CK.TRANSACTION_ID

Where 1=1
and lower(u.user_slctd_id) = 'bodybuildingwarehouse'
and ck.RPRTD_WACKO_YN = 'N'

Group by 1,2

;