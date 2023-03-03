-- Author: Robbie Evans
-- Created Date: 01/03/2023
-- Created For: Wahaaj Shabbir
-- Purpose: To illustrate the number of sellers as well as their significance to overall Sneakers AG figures, on sellers residing in the Channel Islands and Northern Island

----------------------------------------------------------------------------------------------------------------------------------------------------------

-- Overall Data for the Analysis

SELECT
         case when trim(lower(shp.ITEM_ZIP_TXT)) like 'gy%' then 'Channel Islands'
				when trim(lower(shp.ITEM_ZIP_TXT)) like 'bt%' then 'Northern Ireland'
				else 'UK'
				end as seller_loc,
		 count(distinct ck.SELLER_ID) as num_sellers,
		 count(distinct ck.TRANSACTION_ID) as num_txns,
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
INNER JOIN SSA_SHPMT_TRANS_FACT shp
	on ck.TRANSACTION_ID = shp.ck_trans_id
	and ck.item_id = shp.lstg_id

WHERE 1 = 1
         AND CK.GMV_DT between DATE'2022-01-01' and DATE'2022-12-31'
         AND CK.SLR_CNTRY_ID = 3 -- For AG both buyer and seller must reside in the UK
		 and ck.BYR_CNTRY_ID = 3 -- For AG both buyer and seller must reside in the UK
		 and cat.CATEG_LVL4_ID IN (15709,95672,155202,57974,57929) -- Sneakers categories
		 and ck.ITEM_PRICE >= 100 -- AG Sneakers must be at least £100
		 and ck.RPRTD_WACKO_YN = 'N'

Group by 1
;
------------------------------------------------------------------------------------------------------------------

-- Seller level data

SELECT
         ck.SELLER_ID,
		 count(distinct ck.TRANSACTION_ID) as num_txns,
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
INNER JOIN SSA_SHPMT_TRANS_FACT shp
	on ck.TRANSACTION_ID = shp.ck_trans_id
	and ck.item_id = shp.lstg_id

WHERE 1 = 1
         AND CK.GMV_DT between DATE'2022-01-01' and DATE'2022-12-31'
         AND CK.SLR_CNTRY_ID = 3 -- For AG both buyer and seller must reside in the UK
		 and ck.BYR_CNTRY_ID = 3 -- For AG both buyer and seller must reside in the UK
		 and cat.CATEG_LVL4_ID IN (15709,95672,155202,57974,57929) -- Sneakers categories
		 and ck.ITEM_PRICE >= 100 -- AG Sneakers must be at least £100
		 and ck.RPRTD_WACKO_YN = 'N'
		 and trim(lower(shp.ITEM_ZIP_TXT)) like any ('gy%','bt%')

Group by 1

Order by sold_items desc
