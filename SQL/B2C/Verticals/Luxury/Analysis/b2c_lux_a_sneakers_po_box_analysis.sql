SELECT
         case when (LOWER(ADR.ADDR1_TXT) LIKE ANY('%po box%','%parcel locker%','%p.o. box%','%p.o box%') or LOWER(ADR.ADDR2_TXT) LIKE ANY('%po box%','%parcel locker%','%p.o. box%','%p.o box%'))
		 		then 'Yes'
			else
				'No'
			End as po_box_flag,
		 count(distinct ck.BUYER_ID) as distinct_buyers,
		 count(distinct ck.TRANSACTION_ID) as txns,
		 sum(ck.gmv_plan_usd) as gmv,
		 sum(ck.QUANTITY) as sold_items
		 
FROM DW_CHECKOUT_TRANS CK
inner  JOIN ACCESS_VIEWS.SSA_CURNCY_PLAN_RATE_DIM LPR 
		ON ck.LSTG_CURNCY_ID = LPR.CURNCY_ID 
INNER JOIN PRS_SECURE_V.DW_USER_ADDRESSES ADR
                 ON CK.SHIPPING_ADDRESS_ID = ADR.ADDRESS_ID
INNER JOIN DW_CATEGORY_GROUPINGS CAT 
		ON CAT.LEAF_CATEG_ID = ck.LEAF_CATEG_ID 
		AND CAT.SITE_ID = 3
		AND CAT.SAP_CATEGORY_ID NOT in (5,7,41,23,-999) 

WHERE 1 = 1
         AND CK.GMV_DT between DATE'2022-01-01' and DATE'2022-12-31'
         AND CK.SLR_CNTRY_ID = 3
		 and ck.BYR_CNTRY_ID = 3
		 and cat.CATEG_LVL4_ID IN (15709,95672,155202,57974,57929)
		 and ck.ITEM_PRICE*lpr.CURNCY_PLAN_RATE >= 100
		 and ck.RPRTD_WACKO_YN = 'N'

Group by 1