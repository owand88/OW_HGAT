-- JIRA:            UKPLAN-501

-- Author: 			Robbie Evans
-- Date:            10/08/2023

-- Stakeholder: 	Emma Hamilton, Laura McGuinness
-- Description: 	Stats required for a PR pitch being put together on the rise in Male handbag shoppers





-- With ag as
-- (
-- select
-- 	item_id	
-- from
-- 	access_views.DW_PES_ELGBLT_HIST
-- where
-- 	evltn_end_ts = '2099-12-31 00:00:00'
-- 	and BIZ_PRGRM_NAME = 'PSA_HANDBAGS_UK'	--(UK Handbags AG program)
-- 	and elgbl_yn_ind ='Y'					--(Only eligible items)
-- Group by
-- 	1
-- )



Select
	cal.RETAIL_YEAR
	,d.MACRO_CL_NAME
-- 	,dna.PSTL_CODE
-- 	,dna.CITY   
	,dna.state
	,dna.PRDCTV_GNDR
-- 	,COALESCE(aspects.HANDBAGS_BRAND_GRANULAR,'Others')
	,coalesce(brand.brand,"Unknown") as brand
	,dna.ACX_ANNUAL_INCME_CD                          
	,dna.USER_AGE_GRP_ID
	,count(distinct ck.BUYER_ID) as buyers
	,sum(ck.QUANTITY) as si
	,sum(ck.gmv_plan_usd) as gmv
FROM DW_CHECKOUT_TRANS ck
-- INNER JOIN ag
-- 	on ck.ITEM_ID = ag.item_id
INNER JOIN DW_CAL_DT cal
	on ck.GMV_DT = cal.CAL_DT
	and cal.retail_week between 1 and 31
	and cal.retail_year in (2022,2023)
INNER JOIN P_INVENTORYPLANNING_T.dw_category_groupings_adj CAT
	ON ck.LEAF_CATEG_ID = CAT.LEAF_CATEG_ID
	AND cat.site_id = 3
INNER JOIN DW_COUNTRIES cn
	on ck.BYR_CNTRY_ID = cn.cntry_id
inner  JOIN ACCESS_VIEWS.SSA_CURNCY_PLAN_RATE_DIM LPR 
	ON ck.LSTG_CURNCY_ID = LPR.CURNCY_ID 
LEFT JOIN ACCESS_VIEWS.USER_DNA_DIM c
	ON ck.buyer_id = c.user_id
LEFT JOIN ACCESS_VIEWS.LFSTG_CLSTR_PRMRY_USER d
	on c.primary_user_id = d.primary_user_id
	and ck.GMV_DT between RCRD_EFF_START_DT and RCRD_EFF_END_DT
	and cn.REV_ROLLUP = d.USER_REV_ROLLUP -- align LSS build with user's REV_ROLLUP
left join (Select
			item_id,
			coalesce(max(case  when lower(aspect)=lower('BRAND') then aspct_vlu_nm else NULL end ),'Unknown') as BRAND
		FROM
			(select
				item_id,
				ns_type_cd,
				1 as priority,
				'BRAND' as aspect,
				cast(trim(lower(aspct_vlu_nm)) as VARCHAR(350)) as aspct_vlu_nm
			from
				item_aspct_clssfctn
			where
				1=1
				AND AUCT_END_DT>='2023-03-01'
				AND lower(ns_type_cd) in (lower('nf'),lower('df' ) ) and upper(prdct_aspct_nm)= upper('BRAND')

				qualify (Row_Number() Over (PARTITION BY item_id,auct_end_dt,aspect ORDER BY priority,aspct_vlu_nm DESC)) = 1
			)SB
		GROUP BY 1) brand
			on ck.item_id = brand.item_id
LEFT JOIN
	(
	select user_id
		,PSTL_CODE
		,CITY
		,STATE                         
		,PRDCTV_GNDR
		,ACX_ANNUAL_INCME_CD                          
		,USER_AGE_GRP_ID               
	from PRS_SECURE_V.user_dna
	Group by 1,2,3,4,5,6,7
	) dna
		on ck.BUYER_ID = dna.user_id
LEFT JOIN P_CSI_TBS_T.NA_VERTICALS_ASPECTS_PLUS aspects
	ON aspects.item_id=ck.item_id 
Where 1=1
	and ck.SLR_CNTRY_ID = 3
	and ck.BYR_CNTRY_ID = 3
	and ck.SITE_ID = 3
	and cat.CATEG_LVL4_ID = 52357	--(Men's Bags)
	and ck.ITEM_PRICE*LPR.CURNCY_PLAN_RATE >= 500 --Luc Handbags >= $500
Group by 1,2,3,4,5,6,7


;



----------------------------------------------------------------------------------------------------------
-------------------------------------- X Shop ------------------------------------------------------------
----------------------------------------------------------------------------------------------------------


with lux_byrs as 
(
Select
	ck.buyer_id
FROM DW_CHECKOUT_TRANS ck
-- INNER JOIN ag
-- 	on ck.ITEM_ID = ag.item_id
INNER JOIN DW_CAL_DT cal
	on ck.GMV_DT = cal.CAL_DT
	and cal.retail_week between 1 and 31
	and cal.retail_year in (2023)
inner  JOIN ACCESS_VIEWS.SSA_CURNCY_PLAN_RATE_DIM LPR 
	ON ck.LSTG_CURNCY_ID = LPR.CURNCY_ID 
INNER JOIN P_INVENTORYPLANNING_T.dw_category_groupings_adj CAT
	ON ck.LEAF_CATEG_ID = CAT.LEAF_CATEG_ID
	AND cat.site_id = 3
inner JOIN
	(
	select user_id        
	from PRS_SECURE_V.user_dna
	Where upper(PRDCTV_GNDR) = 'M'
	Group by 1
	) dna
		on ck.BUYER_ID = dna.user_id
Where 1=1
	and ck.SLR_CNTRY_ID = 3
	and ck.BYR_CNTRY_ID = 3
	and ck.SITE_ID = 3
	and cat.CATEG_LVL4_ID = 52357	--(Men's Bags)
	and ck.ITEM_PRICE*LPR.CURNCY_PLAN_RATE >= 500 --Luc Handbags >= $500
Group by 1
)




Select
	cat.NEW_VERTICAL
	,cat.CATEG_LVL2_NAME
-- 	,cat.CATEG_LVL3_NAME
	,count(distinct ck.BUYER_ID) as buyers
	,sum(ck.QUANTITY) as bi
	,sum(ck.gmv_plan_usd) as gmb
FROM DW_CHECKOUT_TRANS ck
INNER JOIN lux_byrs
	on ck.BUYER_ID = lux_byrs.BUYER_ID
INNER JOIN DW_CAL_DT cal
	on ck.GMV_DT = cal.CAL_DT
	and cal.retail_week between 1 and 31
	and cal.retail_year in (2023)
INNER JOIN P_INVENTORYPLANNING_T.dw_category_groupings_adj CAT
	ON ck.LEAF_CATEG_ID = CAT.LEAF_CATEG_ID
	AND cat.site_id = 3
Where 1=1
	and ck.SLR_CNTRY_ID = 3
	and ck.BYR_CNTRY_ID = 3
	and ck.SITE_ID = 3
	and cat.CATEG_LVL4_ID <> 52357	--(Men's Bags)
Group by 1,2