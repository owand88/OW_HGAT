-- Author: 			Robbie Evans
-- Stakeholder: 	Lizzie Read
-- Purpose: 		Seller Moorelargeoutlet (3rd largest cycling seller) went into administartion and will be leaving eBay. Want to know which categories/brands/skus were its top sellers so other sellers can be encuraged to list to avoid inventory gaps
-- Date Created: 	22/03/2023



select 
cal.retail_year
,cal.RETAIL_WEEK
,ck.ITEM_ID
,lstg.auct_titl
,u.user_slctd_id as seller_name
,brand.brand
,cat.CATEG_LVL2_NAME
,cat.CATEG_LVL3_NAME
,cat.CATEG_LVL4_NAME
,sum(ck.GMV20_SOLD_QUANTITY) as sold_items
,sum(ck.GMV20_PLAN) as GMV

from PRS_RESTRICTED_V.SLNG_TRANS_SUPER_FACT ck
INNER JOIN DW_CAL_DT cal
	on ck.gmv_dt = cal.CAL_DT
	and cal.RETAIL_YEAR >= 2022
	and AGE_FOR_RTL_WEEK_ID < 0
INNER JOIN ACCESS_VIEWS.DW_CATEGORY_GROUPINGS CAT 
	ON CAT.LEAF_CATEG_ID = ck.LEAF_CATEG_ID 
	AND CAT.SITE_ID = 3
	AND CAT.SAP_CATEGORY_ID NOT in (5,7,41,23,-999) 
INNER JOIN DW_USERS u
	on ck.SELLER_ID = u.user_id
LEFT JOIN DW_LSTG_ITEM lstg
	on ck.ITEM_ID = lstg.ITEM_ID
left join (Select
			item_id,
			coalesce(max(aspct_vlu_nm),'Unknown') as BRAND
		FROM
			(select
				item_id,
				ns_type_cd,
				1 as priority,
				'BRAND' as aspect,
				cast(trim(lower(aspct_vlu_nm)) as VARCHAR(350)) as aspct_vlu_nm, 
				(Row_Number() Over (PARTITION BY item_id,auct_end_dt,aspect ORDER BY priority,aspct_vlu_nm DESC)) AS dup_check
			from
				item_aspct_clssfctn
			where
				AUCT_END_DT>='2020-12-07'
				AND lower(ns_type_cd) in (lower('nf'),lower('df' ) ) and upper(prdct_aspct_nm)= upper('BRAND')
			)SB
		Where dup_check = 1
		GROUP BY 1) brand
			on ck.item_id = brand.item_id

Where 1=1
and ck.SELLER_ID = 1042471095
and ck.RPRTD_WACKO_YN = 'N'

Group by 1,2,3,4,5,6,7,8,9




------------------------------------------------------------------------------------------------------------------------





select 
brand.brand
,cat.CATEG_LVL4_NAME
,case when ck.seller_id = 1042471095 then 'Moorelargeoutlet' else 'Others' End as seller_flag
,sum(ck.GMV20_SOLD_QUANTITY) as sold_items
,sum(ck.GMV20_PLAN) as GMV
,count(distinct ck.SELLER_ID) as seller_cnt

from PRS_RESTRICTED_V.SLNG_TRANS_SUPER_FACT ck
INNER JOIN DW_CAL_DT cal
	on ck.gmv_dt = cal.CAL_DT
	and cal.AGE_FOR_RTL_WEEK_ID >= -52
	and AGE_FOR_RTL_WEEK_ID < 0
INNER JOIN ACCESS_VIEWS.DW_CATEGORY_GROUPINGS CAT 
	ON CAT.LEAF_CATEG_ID = ck.LEAF_CATEG_ID 
	AND CAT.SITE_ID = 3
	AND CAT.SAP_CATEGORY_ID NOT in (5,7,41,23,-999) 
-- INNER JOIN DW_USERS u
-- 	on ck.SELLER_ID = u.user_id
-- LEFT JOIN DW_LSTG_ITEM lstg
-- 	on ck.ITEM_ID = lstg.ITEM_ID
inner join (Select
			item_id,
			coalesce(max(aspct_vlu_nm),'Unknown') as BRAND
		FROM
			(select
				item_id,
				ns_type_cd,
				1 as priority,
				'BRAND' as aspect,
				cast(trim(lower(aspct_vlu_nm)) as VARCHAR(350)) as aspct_vlu_nm, 
				(Row_Number() Over (PARTITION BY item_id,auct_end_dt,aspect ORDER BY priority,aspct_vlu_nm DESC)) AS dup_check
			from
				item_aspct_clssfctn
			where
				AUCT_END_DT>='2020-12-07'
				AND lower(ns_type_cd) in (lower('nf'),lower('df' ) ) and upper(prdct_aspct_nm)= upper('BRAND')
			)SB
		Where dup_check = 1
		and aspct_vlu_nm in ( 
							'bridgford',
							'barracuda',
							'flite',
							'freespirit',
							'unbranded',
							'sonic',
							'vitesse',
							'bmx',
							'holcros',
							'lombardo',
							'emmelle',
							'ndcent',
							'cudass',
							'bi-tech',
							'lake',
							'one23',
							'shimano'
							)
		GROUP BY 1) brand
			on ck.item_id = brand.item_id

Where 1=1
and lower(cat.CATEG_LVL2_NAME) like '%cycling%'
and ck.RPRTD_WACKO_YN = 'N'
and ck.SLR_CNTRY_ID = 3

Group by 1,2,3

