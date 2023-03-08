
With elig_sneakers
(
select item_id
from
(
 -- an item/variation can be evaluated multiple items. We only pickup the last evaluation result.
	 select *
	 from  access_views.DW_PES_ELGBLT_HIST
	 where BIZ_PRGRM_NAME = 'PSA_SNEAKER_EBAY_UK' -- Sneakers AG program
	 and cast(evltn_ts as date) <= '2022-12-31' -- this item is evaluated before given date
	 and cast(evltn_end_ts as date) > '2022-12-31' -- the evaluation effetive date after the given date
	 qualify row_number() over(partition by item_id, vrtn_id, biz_prgrm_id, cast(evltn_ts as date) order by evltn_ts desc) = 1
)w
where 
 elgbl_yn_ind ='Y' -- eligible items
and coalesce( auct_end_date, '2099-12-31') >= '2022-01-01'

Group by 1
)



SELECT				
		 case when (LOWER(ADR.ADDR1_TXT) LIKE ANY('%po box%','%parcel locker%','%p.o. box%','%p.o box%') or LOWER(ADR.ADDR2_TXT) LIKE ANY('%po box%','%parcel locker%','%p.o. box%','%p.o box%'))		
		 		then 'Yes'
			else	
				'No'
			End as po_box_flag,	
-- 		case when CLAIM_TYPE_ID = 1 then 'INR'		
-- 			when CLAIM_TYPE_ID = 2 then 'SNAD'	
-- 			End as claim_type,	
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
INNER JOIN elig_sneakers e
	on ck.item_id = e.item_id
-- LEFT JOIN ACCESS_VIEWS.RSLTN_ALL r				
-- 	on ck.item_id = r.item_id			
-- 	and ck.TRANSACTION_ID = r.tran_id			
				
WHERE 1 = 1				
         AND CK.GMV_DT between DATE'2022-01-01' and DATE'2022-12-31'				
         AND CK.SLR_CNTRY_ID = 3				
		 and ck.BYR_CNTRY_ID = 3		
		 and cat.CATEG_LVL4_ID IN (15709,95672,155202,57974,57929)		
		 and ck.ITEM_PRICE >= 100		
		 and ck.RPRTD_WACKO_YN = 'N'		
	
		 		
Group by 1			
