-- Author: 			Robbie Evans
-- Stakeholder: 	Hanne Melin Olbe, Hersh Malhotra, Mark Trotter-Vigouroux
-- Purpose: 		Required to pull Robotic Brand sales data for Finance team
-- Date Created: 	20/04/2023




Select lstg.brand
,lstg.type
,cal.RETAIL_YEAR
,cat.CATEG_LVL4_NAME
,sum(ck.GMV20_PLAN) as GMV
,sum(ck.GMV20_LSTG_CURNCY_AMT) as GMV_GBP
,sum(ck.GMV20_SOLD_QUANTITY) as Units

FROM PRS_RESTRICTED_V.SLNG_TRANS_SUPER_FACT ck
INNER JOIN DW_CAL_DT cal
	on ck.gmv_dt = cal.CAL_DT
	and cal.retail_year in (2020,2021,2022)
INNER JOIN P_INVENTORYPLANNING_T.dw_category_groupings_adj  AS CAT
	ON ck.LEAF_CATEG_ID = CAT.LEAF_CATEG_ID
	AND cat.site_id = 3
INNER JOIN
		(
		select lstg.item_id
		, lstg.DF_BRAND_TXT as brand
		, type.type

		From PRS_RESTRICTED_V.SLNG_LSTG_SUPER_FACT lstg
		INNER JOIN DW_CAL_DT cal
			on lstg.AUCT_START_DT <= cal.CAL_DT
			and lstg.AUCT_END_DT >= cal.CAL_DT
			and cal.retail_year in (2020,2021,2022)
		inner join (Select
						item_id,
						coalesce(max(aspct_vlu_nm),'Unknown') as TYPE
					FROM
						(select
							item_id,
							ns_type_cd,
							1 as priority,
							'TYPE' as aspect,
							cast(trim(lower(aspct_vlu_nm)) as VARCHAR(350)) as aspct_vlu_nm
						from
							access_views.item_aspct_clssfctn
						where
							1=1
							AND lower(ns_type_cd) in (lower('nf'),lower('df' ) ) and upper(prdct_aspct_nm)= upper('TYPE')

							qualify (Row_Number() Over (PARTITION BY item_id,aspect ORDER BY aspct_vlu_nm DESC)) = 1
						)SB
					Where lower(aspct_vlu_nm) like '%robot%'
					GROUP BY 1) type
						on lstg.item_id = type.item_id
		INNER JOIN P_INVENTORYPLANNING_T.dw_category_groupings_adj  AS CAT
			ON lstg.LEAF_CATEG_ID = CAT.LEAF_CATEG_ID
			AND cat.site_id = 3
			and cat.CATEG_LVL4_ID = 20614

		Where 1=1
		and lstg.SLR_CNTRY_ID = 3
		and lstg.ITEM_SITE_ID = 3

		Group by 1,2,3
		) lstg
			on ck.ITEM_ID = lstg.item_id

Where 1=1
and ck.SLR_CNTRY_ID = 3
and ck.RPRTD_WACKO_YN = 'N'

Group by 1,2,3,4

;
