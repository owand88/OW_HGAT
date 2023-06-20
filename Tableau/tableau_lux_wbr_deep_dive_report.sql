-- JIRA:            UKPLAN-22

-- Author: 			Robbie Evans
-- Date:            05/04/2023

-- Stakeholder: 	Wahaaj Shabbir, Alice Bridson, Emma Hamilton, Ines Morais, Keith Metcalfe
-- Description: 	Serves as an appendix to the NA Analytics Team's WBR dashboards. Provides in-depth analysis as to the drivers behind weekly performance metrics.





----------------------------------------------------------------------------------------------------------------------------------------------------------------------- 
------------------------------------------------------------------- TRAFFIC TABLE BASE --------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
drop table if exists p_robevans_t.lux_weekly_dashboard_trfc_base;

create table p_robevans_t.lux_weekly_dashboard_trfc_base as

	select
	trfc.ITEM_ID
	,cal.AGE_FOR_RTL_WEEK_ID
	,sum(trfc.TTL_VI_CNT) as vi
	,sum(trfc.SRP_IMPRSN_CNT) + sum(trfc.STORE_IMPRSN_CNT) as imps

	FROM PRS_RESTRICTED_V.SLNG_TRFC_SUPER_FACT AS trfc
	INNER JOIN DW_CAL_DT CAL
		ON trfc.cal_dt = CAL.CAL_DT
		AND RETAIL_YEAR >= (select retail_year from DW_CAL_DT where AGE_FOR_RTL_WEEK_ID = -1 group by 1)-1
		and AGE_FOR_RTL_WEEK_ID <= -1 
	INNER JOIN DW_CATEGORY_GROUPINGS CAT 
		ON CAT.LEAF_CATEG_ID = trfc.LEAF_CATEG_ID 
		AND CAT.SITE_ID = 3
		AND CAT.SAP_CATEGORY_ID NOT in (5,7,41,23,-999)  
	
	WHERE 1=1
	and (cat.CATEG_LVL4_ID IN (15709,95672,155202,57974,57929)
		OR cat.CATEG_LVL2_ID IN (260324)
		OR ((cat.CATEG_LVL3_ID IN (169291)) OR (cat.CATEG_LVL4_ID IN (52357,163570,169285,45258,2996,45237,169271)))
		OR (cat.META_CATEG_ID = 281 and cat.CATEG_LVL2_ID NOT IN (260324)))
		and trfc.SITE_ID = 3

	Group by 1,2
;



----------------------------------------------------------------------------------------------------------------------------------------------------------------------- 
-------------------------------------------------------------- LISTING & TRAFFIC TABLE BASE ---------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------

drop table if exists p_robevans_t.lux_weekly_dashboard_lstg_base;

create table p_robevans_t.lux_weekly_dashboard_lstg_base as

select
lstg.ITEM_ID
,lstg.AUCT_START_DT
,lstg.AUCT_END_DT
,lstg.RETAIL_YEAR
,lstg.RETAIL_WEEK
,lstg.AGE_FOR_RTL_WEEK_ID
,lstg.SLR_ID
,lstg.focus_category
,lstg.CATEG_LVL2_ID
,lstg.CATEG_LVL2_NAME
,lstg.PRICE_BUCKET
,lstg.item_Cond
,lstg.BRAND
,lstg.MODEL
,lstg.B2C_C2C
,lstg.START_PRICE_LSTG_CURNCY_AMT
,lstg.START_PRICE_PLAN_RATE_USD_AMT
,lstg.RSRV_PRICE_LSTG_CURNCY_AMT
,lstg.RSRV_PRICE_PLAN_RATE_USD_AMT
,sum(trfc.vi) as vi
,sum(trfc.imps) as imps

FROM
(
	select
	lstg.ITEM_ID
	,lstg.AUCT_START_DT
	,lstg.AUCT_END_DT
	,cal.RETAIL_YEAR
	,cal.RETAIL_WEEK
	,cal.AGE_FOR_RTL_WEEK_ID
	,lstg.SLR_ID
	,case
		when cat.CATEG_LVL4_ID IN (15709,95672,155202,57974,57929) then 'Sneakers'
		when cat.CATEG_LVL2_ID IN (260324) then 'Watches'
		when ((cat.CATEG_LVL3_ID IN (169291)) OR (cat.CATEG_LVL4_ID IN (52357,163570,169285,45258,2996,45237,169271))) then 'Handbags'
		when (cat.META_CATEG_ID = 281 and cat.CATEG_LVL2_ID NOT IN (260324)) then 'Jewellery'
		Else 'Other' End as focus_category
	,cat.CATEG_LVL2_ID
	,cat.CATEG_LVL2_NAME
	,CASE
		WHEN Cast(lstg.START_PRICE_LSTG_CURNCY_AMT*LPR.CURNCY_PLAN_RATE AS DECIMAL(18,2))  < 100  THEN 'A. <£86 (<$100)'
		WHEN Cast(lstg.START_PRICE_LSTG_CURNCY_AMT AS DECIMAL(18,2))  < 100 THEN 'B. £86-£100 ($100-£100)'
		WHEN Cast(lstg.START_PRICE_LSTG_CURNCY_AMT AS DECIMAL(18,2))  < 125 THEN 'C. £100-£125'
		WHEN Cast(lstg.START_PRICE_LSTG_CURNCY_AMT AS DECIMAL(18,2))  < 150 THEN 'D. £125-£150'
		WHEN Cast(lstg.START_PRICE_LSTG_CURNCY_AMT*LPR.CURNCY_PLAN_RATE AS DECIMAL(18,2))  < 300  THEN 'E. <£261 (<$300)'
		WHEN Cast(lstg.START_PRICE_LSTG_CURNCY_AMT*LPR.CURNCY_PLAN_RATE AS DECIMAL(18,2))  < 500 THEN 'F. £261-£435 ($300-$500)'
		WHEN Cast(lstg.START_PRICE_LSTG_CURNCY_AMT AS DECIMAL(18,2))  < 500 THEN 'G. £435-£500 ($500-£500)'
		WHEN Cast(lstg.START_PRICE_LSTG_CURNCY_AMT AS DECIMAL(18,2))  < 750 THEN 'H. £500-£750'
		WHEN Cast(lstg.START_PRICE_LSTG_CURNCY_AMT AS DECIMAL(18,2))  < 1000 THEN 'I. £750-£1000'
		WHEN Cast(lstg.START_PRICE_LSTG_CURNCY_AMT AS DECIMAL(18,2))  < 1500 THEN 'J. £1000-£1500'
		WHEN Cast(lstg.START_PRICE_LSTG_CURNCY_AMT AS DECIMAL(18,2))  < 2500 THEN 'K. £1500-£2500'
		WHEN Cast(lstg.START_PRICE_LSTG_CURNCY_AMT AS DECIMAL(18,2))  < 5000 THEN 'L. £2500-£5000'
		WHEN Cast(lstg.START_PRICE_LSTG_CURNCY_AMT AS DECIMAL(18,2))  < 10000 THEN 'M. £5000-£10,000'
		ELSE 'N. £10,000+'
		END AS PRICE_BUCKET
	,CASE
		WHEN lstg.CNDTN_ROLLUP_ID = 1 THEN 'New'
		WHEN lstg.CNDTN_ROLLUP_ID = 2 THEN 'Refurbished' 
		WHEN lstg.CNDTN_ROLLUP_ID = 3 THEN 'Used'
		ELSE 'Not Specified'
		END AS item_Cond
	,CASE
		WHEN CAT.categ_lvl4_id in (15709, 95672,155202,57974,57929) THEN COALESCE(aspects.SNEAKERS_BRAND_GRANULAR,'Others')
		WHEN ((CAT.CATEG_LVL3_ID = 169291) OR (CAT.CATEG_LVL4_ID IN (52357,163570,169285,45237,45258,2996,169271))) THEN COALESCE(aspects.HANDBAGS_BRAND_GRANULAR,'Others')
		WHEN cat.categ_lvl2_id = 260324 THEN COALESCE(aspects.WATCHES_BRAND_GRANULAR,'Others')
-- 		WHEN CAT.META_CATEG_ID = 281 AND CAT.CATEG_LVL2_ID NOT IN (260324) THEN COALESCE(JWL_BRAND.BRAND,'Unbranded')
		WHEN CAT.META_CATEG_ID = 281 AND CAT.CATEG_LVL2_ID NOT IN (260324) THEN COALESCE(aspects.Jewelry_brand_granular,'Others')
		ELSE 'Others' END AS BRAND
	,coalesce(aspects.model_aspect,'Others') as MODEL
	,lstg.B2C_C2C
	,lstg.START_PRICE_LSTG_CURNCY_AMT
	,lstg.START_PRICE_LSTG_CURNCY_AMT*lpr.CURNCY_PLAN_RATE as START_PRICE_PLAN_RATE_USD_AMT
	,lstg.RSRV_PRICE_LSTG_CURNCY_AMT
	,lstg.RSRV_PRICE_LSTG_CURNCY_AMT*lpr.CURNCY_PLAN_RATE as RSRV_PRICE_PLAN_RATE_USD_AMT


	FROM PRS_RESTRICTED_V.SLNG_LSTG_SUPER_FACT AS lstg
	inner  JOIN ACCESS_VIEWS.SSA_CURNCY_PLAN_RATE_DIM LPR 
			ON lstg.LSTG_CURNCY_ID = LPR.CURNCY_ID 

	INNER JOIN DW_CAL_DT CAL
		ON lstg.AUCT_START_DT < CAL.CAL_DT
		AND lstg.AUCT_END_DT >= CAL.CAL_DT
		AND RETAIL_YEAR >= (select retail_year from DW_CAL_DT where AGE_FOR_RTL_WEEK_ID = -1 group by 1)-1
		and AGE_FOR_RTL_WEEK_ID <= -1 
	INNER JOIN DW_CATEGORY_GROUPINGS CAT 
		ON CAT.LEAF_CATEG_ID = lstg.LEAF_CATEG_ID 
		AND CAT.SITE_ID = 3
		AND CAT.SAP_CATEGORY_ID NOT in (5,7,41,23,-999)  
	LEFT JOIN P_CSI_TBS_T.NA_VERTICALS_ASPECTS_PLUS aspects
		ON aspects.item_id=lstg.item_id 
	-- BU Brand list for Jewelry to show other brands
-- 	LEFT JOIN (SELECT BRAND FROM P_AMER_VERTICALS_T.JEWELRY_BRAND_LIST_BU_INPUT GROUP BY 1) JWL_BRAND
-- 		ON JWL_BRAND.BRAND=aspects.JEWELRY_BRAND_GRANULAR
	
	WHERE 1=1
	and (cat.CATEG_LVL4_ID IN (15709,95672,155202,57974,57929)
		OR cat.CATEG_LVL2_ID IN (260324)
		OR ((cat.CATEG_LVL3_ID IN (169291)) OR (cat.CATEG_LVL4_ID IN (52357,163570,169285,45258,2996,45237,169271)))
		OR (cat.META_CATEG_ID = 281 and cat.CATEG_LVL2_ID NOT IN (260324)))
		and lstg.slr_CNTRY_ID = 3

	Group by 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19
) lstg 
LEFT JOIN p_robevans_t.lux_weekly_dashboard_trfc_base trfc
	on lstg.item_id = trfc.item_id
	and lstg.AGE_FOR_RTL_WEEK_ID = trfc.AGE_FOR_RTL_WEEK_ID

Where 1=1

Group by 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19
;


----------------------------------------------------------------------------------------------------------------------------------------------------------------------- 
----------------------------------------------------------------- TRANSACTION TABLE BASE ------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------

drop table if exists p_robevans_t.lux_weekly_dashboard_trans_base;

create table p_robevans_t.lux_weekly_dashboard_trans_base as
select
	ck.ITEM_ID
	,ck.AUCT_END_DT
	,cal.RETAIL_YEAR
	,cal.RETAIL_WEEK
	,cal.AGE_FOR_RTL_WEEK_ID
	,ck.SELLER_ID
	,ck.BUYER_ID
	,case
		when ck.BYR_CNTRY_ID = 3 then 'Domestic'
			Else 'International'
		End as trade_type
	,case
		when cat.CATEG_LVL4_ID IN (15709,95672,155202,57974,57929) then 'Sneakers'
		when cat.CATEG_LVL2_ID IN (260324) then 'Watches'
		when ((cat.CATEG_LVL3_ID IN (169291)) OR (cat.CATEG_LVL4_ID IN (52357,163570,169285,45258,2996,45237,169271))) then 'Handbags'
		when (cat.META_CATEG_ID = 281 and cat.CATEG_LVL2_ID NOT IN (260324)) then 'Jewellery'
			Else 'Other'
		End as focus_category
	,cat.CATEG_LVL2_ID
	,cat.CATEG_LVL2_NAME
	,CASE
		WHEN Cast(ck.item_price*LPR.CURNCY_PLAN_RATE AS DECIMAL(18,2))  < 100  THEN 'A. <£86 (<$100)'
		WHEN Cast(ck.item_price AS DECIMAL(18,2))  < 100 THEN 'B. £86-£100 ($100-£100)'
		WHEN Cast(ck.item_price AS DECIMAL(18,2))  < 125 THEN 'C. £100-£125'
		WHEN Cast(ck.item_price AS DECIMAL(18,2))  < 150 THEN 'D. £125-£150'
		WHEN Cast(ck.item_price*LPR.CURNCY_PLAN_RATE AS DECIMAL(18,2))  < 300  THEN 'E. <£261 (<$300)'
		WHEN Cast(ck.item_price*LPR.CURNCY_PLAN_RATE AS DECIMAL(18,2))  < 500 THEN 'F. £261-£435 ($300-$500)'
		WHEN Cast(ck.item_price AS DECIMAL(18,2))  < 500 THEN 'G. £435-£500 ($500-£500)'
		WHEN Cast(ck.item_price AS DECIMAL(18,2))  < 750 THEN 'H. £500-£750'
		WHEN Cast(ck.item_price AS DECIMAL(18,2))  < 1000 THEN 'I. £750-£1000'
		WHEN Cast(ck.item_price AS DECIMAL(18,2))  < 1500 THEN 'J. £1000-£1500'
		WHEN Cast(ck.item_price AS DECIMAL(18,2))  < 2500 THEN 'K. £1500-£2500'
		WHEN Cast(ck.item_price AS DECIMAL(18,2))  < 5000 THEN 'L. £2500-£5000'
		WHEN Cast(ck.item_price AS DECIMAL(18,2))  < 10000 THEN 'M. £5000-£10,000'
			ELSE 'N. £10,000+'
		END AS PRICE_BUCKET
	,CASE
		WHEN ck.CNDTN_ROLLUP_ID = 1 THEN 'New'
		WHEN ck.CNDTN_ROLLUP_ID = 2 THEN 'Refurbished' 
		WHEN ck.CNDTN_ROLLUP_ID = 3 THEN 'Used'
			ELSE 'Not Specified'
		END AS item_Cond
	,CASE
		WHEN CAT.categ_lvl4_id in (15709, 95672,155202,57974,57929) THEN COALESCE(aspects.SNEAKERS_BRAND_GRANULAR,'Others')
		WHEN ((CAT.CATEG_LVL3_ID = 169291) OR (CAT.CATEG_LVL4_ID IN (52357,163570,169285,45237,45258,2996,169271))) THEN COALESCE(aspects.HANDBAGS_BRAND_GRANULAR,'Others')
		WHEN cat.categ_lvl2_id = 260324 THEN COALESCE(aspects.WATCHES_BRAND_GRANULAR,'Others')
-- 		WHEN CAT.META_CATEG_ID = 281 AND CAT.CATEG_LVL2_ID NOT IN (260324) THEN COALESCE(JWL_BRAND.BRAND,'Unbranded')
		WHEN CAT.META_CATEG_ID = 281 AND CAT.CATEG_LVL2_ID NOT IN (260324) THEN COALESCE(aspects.Jewelry_brand_granular,'Others')
		ELSE 'Others' END AS BRAND
	,coalesce(aspects.model_aspect,'Others') as MODEL
	,CASE 
		WHEN deal.item_id IS NOT NULL OR NERP.ITEM_ID IS NOT NULL THEN 'Promo Manager & Sub Deals' 
		WHEN Lower((CASE  WHEN ck.byr_cntry_id IN(0, -1,1, -999,225,679,1000) AND ck.slr_cntry_id IN(0, -1,1, -999,225,679,1000)  THEN 'Domestic' WHEN ck.byr_cntry_id=ck.slr_cntry_id AND ck.byr_cntry_id IN (3,77) THEN 'Domestic' ELSE 'CBT' end ))=Lower('CBT') THEN 'Exports' 
		WHEN Lower((CASE  WHEN (coupon.item_id) IS NOT NULL THEN 'Y' ELSE 'N' end ))=Lower('Y') THEN 'Coupon' 
		ELSE 'Baseline' 
		end  AS mece_bucket
	,ck.B2C_C2C
	,sum(ck.GMV20_PLAN) as gmv
	,sum(ck.GMV20_SOLD_QUANTITY) as sold_items

	FROM PRS_RESTRICTED_V.SLNG_TRANS_SUPER_FACT AS ck

	 LEFT JOIN ( select item_ID,CNDTN_ROLLUP_ID from ACCESS_VIEWS.LSTG_ITEM_CNDTN group by 1,2 ) AS CNDTN
			ON ck.ITEM_ID = CNDTN.ITEM_ID
	inner  JOIN ACCESS_VIEWS.SSA_CURNCY_PLAN_RATE_DIM LPR 
		ON ck.LSTG_CURNCY_ID = LPR.CURNCY_ID 
	INNER JOIN ACCESS_VIEWS.DW_CAL_DT CAL 
		ON CAL.CAL_DT = ck.gmv_dt 
		and retail_year >= (select retail_year from DW_CAL_DT where AGE_FOR_RTL_WEEK_ID = -1 group by 1)-1
		and AGE_FOR_RTL_WEEK_ID <= -1 

	INNER JOIN DW_CATEGORY_GROUPINGS CAT 
		ON CAT.LEAF_CATEG_ID = ck.LEAF_CATEG_ID 
		AND CAT.SITE_ID = 3
		AND CAT.SAP_CATEGORY_ID NOT in (5,7,41,23,-999)  
		
	LEFT JOIN P_CSI_TBS_T.NA_VERTICALS_ASPECTS_PLUS aspects
		ON aspects.item_id=ck.item_id 
	-- BU Brand list for Jewelry to show other brands
-- 	LEFT JOIN (SELECT BRAND FROM P_AMER_VERTICALS_T.JEWELRY_BRAND_LIST_BU_INPUT GROUP BY 1) JWL_BRAND
-- 		ON JWL_BRAND.BRAND=aspects.JEWELRY_BRAND_GRANULAR

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

	WHERE 1=1
		AND ck.RPRTD_WACKO_YN = 'N'                    
		and (cat.CATEG_LVL4_ID IN (15709,95672,155202,57974,57929)
		OR cat.CATEG_LVL2_ID IN (260324)
		OR ((cat.CATEG_LVL3_ID IN (169291)) OR (cat.CATEG_LVL4_ID IN (52357,163570,169285,45258,2996,45237,169271)))
		OR (cat.META_CATEG_ID = 281 and cat.CATEG_LVL2_ID NOT IN (260324)))
		and ck.slr_CNTRY_ID in (3)

GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17
;





----------------------------------------------------------------------------------------------------------------------------------------------------------------------- 
------------------------------------------------------------ TOP BRANDS & MODELS TABLE --------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------


Drop table if exists p_robevans_t.lux_wbr_deepdive_top_brands;
Create table p_robevans_t.lux_wbr_deepdive_top_brands as

select brand
From (
	select 
	focus_category
	,brand
	,latest_week_ty_gmv
	,latest_week_ly_gmv
	,ytd_ty_gmv
	,ytd_ly_gmv
	,dense_rank() over(partition by focus_category order by latest_week_ty_gmv desc) as latest_week_ty_gmv_rank
	,dense_rank() over(partition by focus_category order by latest_week_ly_gmv desc) as latest_week_ly_gmv_rank
	,dense_rank() over(partition by focus_category order by ytd_ty_gmv desc) as ytd_ty_gmv_rank
	,dense_rank() over(partition by focus_category order by ytd_ly_gmv desc) as ytd_ly_gmv_rank


	From	
		(select 
		focus_category
		,brand
		,sum(case when AGE_FOR_RTL_WEEK_ID = -1 then gmv end) as latest_week_ty_gmv
		,sum(case when AGE_FOR_RTL_WEEK_ID = -53 then gmv end) as latest_week_ly_gmv
		,sum(case when retail_year = (select retail_year from DW_CAL_DT where AGE_FOR_RTL_WEEK_ID = -1 group by 1) then gmv end) as ytd_ty_gmv
		,sum(case when retail_year = (select retail_year from DW_CAL_DT where AGE_FOR_RTL_WEEK_ID = -1 group by 1)-1 then gmv end) as ytd_ly_gmv

		FROM p_robevans_t.lux_weekly_dashboard_trans_base

		Where 1=1
		and retail_year >= (select retail_year from DW_CAL_DT where AGE_FOR_RTL_WEEK_ID = -1 group by 1)-1
		and retail_week <= (select retail_week from DW_CAL_DT where AGE_FOR_RTL_WEEK_ID = -1 group by 1)

		Group by 1,2)
		)
where latest_week_ty_gmv_rank <= 20
	or latest_week_ly_gmv_rank <= 20
	or ytd_ty_gmv_rank <= 20
	or ytd_ly_gmv_rank <= 20

Group by 1

;



Drop table if exists p_robevans_t.lux_wbr_deepdive_top_models;
Create table p_robevans_t.lux_wbr_deepdive_top_models as

select model
From (
	select 
	focus_category
	,model
	,latest_week_ty_gmv
	,latest_week_ly_gmv
	,ytd_ty_gmv
	,ytd_ly_gmv
	,dense_rank() over(partition by focus_category order by latest_week_ty_gmv desc) as latest_week_ty_gmv_rank
	,dense_rank() over(partition by focus_category order by latest_week_ly_gmv desc) as latest_week_ly_gmv_rank
	,dense_rank() over(partition by focus_category order by ytd_ty_gmv desc) as ytd_ty_gmv_rank
	,dense_rank() over(partition by focus_category order by ytd_ly_gmv desc) as ytd_ly_gmv_rank


	From	
		(select 
		focus_category
		,model
		,sum(case when AGE_FOR_RTL_WEEK_ID = -1 then gmv end) as latest_week_ty_gmv
		,sum(case when AGE_FOR_RTL_WEEK_ID = -53 then gmv end) as latest_week_ly_gmv
		,sum(case when retail_year = (select retail_year from DW_CAL_DT where AGE_FOR_RTL_WEEK_ID = -1 group by 1) then gmv end) as ytd_ty_gmv
		,sum(case when retail_year = (select retail_year from DW_CAL_DT where AGE_FOR_RTL_WEEK_ID = -1 group by 1)-1 then gmv end) as ytd_ly_gmv

		FROM p_robevans_t.lux_weekly_dashboard_trans_base

		Where 1=1
		and retail_year >= (select retail_year from DW_CAL_DT where AGE_FOR_RTL_WEEK_ID = -1 group by 1)-1
		and retail_week <= (select retail_week from DW_CAL_DT where AGE_FOR_RTL_WEEK_ID = -1 group by 1)

		Group by 1,2)
		)
where latest_week_ty_gmv_rank <= 20
	or latest_week_ly_gmv_rank <= 20
	or ytd_ty_gmv_rank <= 20
	or ytd_ly_gmv_rank <= 20

Group by 1

;




Drop table if exists p_robevans_t.lux_wbr_deepdive_top_sellers;
Create table p_robevans_t.lux_wbr_deepdive_top_sellers as

select seller_id
From (
	select 
	focus_category
	,seller_id
	,latest_week_ty_gmv
	,latest_week_ly_gmv
	,ytd_ty_gmv
	,ytd_ly_gmv
	,dense_rank() over(partition by focus_category order by latest_week_ty_gmv desc) as latest_week_ty_gmv_rank
	,dense_rank() over(partition by focus_category order by latest_week_ly_gmv desc) as latest_week_ly_gmv_rank
	,dense_rank() over(partition by focus_category order by ytd_ty_gmv desc) as ytd_ty_gmv_rank
	,dense_rank() over(partition by focus_category order by ytd_ly_gmv desc) as ytd_ly_gmv_rank


	From	
		(select 
		focus_category
		,seller_id
		,sum(case when AGE_FOR_RTL_WEEK_ID = -1 then gmv end) as latest_week_ty_gmv
		,sum(case when AGE_FOR_RTL_WEEK_ID = -53 then gmv end) as latest_week_ly_gmv
		,sum(case when retail_year = (select retail_year from DW_CAL_DT where AGE_FOR_RTL_WEEK_ID = -1 group by 1) then gmv end) as ytd_ty_gmv
		,sum(case when retail_year = (select retail_year from DW_CAL_DT where AGE_FOR_RTL_WEEK_ID = -1 group by 1)-1 then gmv end) as ytd_ly_gmv

		FROM p_robevans_t.lux_weekly_dashboard_trans_base

		Where 1=1
		and retail_year >= (select retail_year from DW_CAL_DT where AGE_FOR_RTL_WEEK_ID = -1 group by 1)-1
		and retail_week <= (select retail_week from DW_CAL_DT where AGE_FOR_RTL_WEEK_ID = -1 group by 1)

		Group by 1,2)
		)
where latest_week_ty_gmv_rank <= 20
	or latest_week_ly_gmv_rank <= 20
	or ytd_ty_gmv_rank <= 20
	or ytd_ly_gmv_rank <= 20

Group by 1

;






----------------------------------------------------------------------------------------------------------------------------------------------------------------------- 
------------------------------------------------------------------- FINAL LISTING TABLE -------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------

drop table if exists p_robevans_t.lux_weekly_lstgs;

Create table p_robevans_t.lux_weekly_lstgs as

select
	'Listings' as table_name
	,lstg.retail_year
	,lstg.retail_week
	,case when lstg.retail_week <= (select retail_week from ACCESS_VIEWS.DW_CAL_DT where AGE_FOR_RTL_WEEK_ID = -1 group by 1) then 'YTD' else 'Other' end as ytd_weeks
	,lstg.AGE_FOR_RTL_WEEK_ID
	,focus_category as category
	,case when focus_category = 'Sneakers' and price_bucket not in ('A. <£86 (<$100)') then 'Only Focus Category'
		when focus_category = 'Jewellery' and price_bucket not in ('A. <£86 (<$100)','B. £86-£100 ($100-£100)','C. £100-£125','D. £125-£150','E. <£261 (<$300)') then 'Only Focus Category'
		when focus_category = 'Watches' and price_bucket not in ('A. <£86 (<$100)','B. £86-£100 ($100-£100)','C. £100-£125','D. £125-£150','E. <£261 (<$300)','F. £261-£435 ($300-$500)') then 'Only Focus Category'
		when focus_category = 'Handbags' and price_bucket not in ('A. <£86 (<$100)','B. £86-£100 ($100-£100)','C. £100-£125','D. £125-£150','E. <£261 (<$300)','F. £261-£435 ($300-$500)') then 'Only Focus Category'
		else 'Non-Focus Category'
		end as focus_category_flag
	,lstg.categ_lvl2_name as l2
	,PRICE_BUCKET
	,coalesce((case when c.seller_id = lstg.slr_id then u.comp else 'Other Sellers' End),u.user_slctd_id) as seller_name
	,lstg.item_Cond
	,lstg.B2C_C2C
	,coalesce(a.BRAND, 'Others') as BRAND
	,coalesce(b.MODEL, 'Others') as MODEL
	,0 as mece_bucket
	,0 as trade_type
	,count(distinct lstg.item_id) as LL
	,sum(lstg.vi) as vi
	,sum(lstg.imps) as imps
	,0 as gmv
	,0 as items_sold

	FROM p_robevans_t.lux_weekly_dashboard_lstg_base AS lstg
	LEFT JOIN p_robevans_t.lux_wbr_deepdive_top_brands a
		on lstg.brand = a.brand
	LEFT JOIN p_robevans_t.lux_wbr_deepdive_top_models b
		on lstg.model = b.model
	LEFT JOIN p_robevans_t.lux_wbr_deepdive_top_sellers c
		on lstg.slr_id = c.seller_id
	LEFT JOIN DW_USERS u
		on lstg.slr_id = u.user_id
	
	WHERE 1=1
		AND RETAIL_YEAR >= (select retail_year from DW_CAL_DT where AGE_FOR_RTL_WEEK_ID = -1 group by 1)-1
		and AGE_FOR_RTL_WEEK_ID <= -1 
	GROUP BY 
		1,2,3,4,5,6,7,8,9,10,11,12,13,14
		
	
;	

----------------------------------------------------------------------------------------------------------------------------------------------------------------------- 
---------------------------------------------------------------- FINAL TRANSACTION TABLE ------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------	

drop table if exists p_robevans_t.lux_weekly_txns;

Create table p_robevans_t.lux_weekly_txns as

select
	'GMV' as table_name
	,ck.retail_year
	,ck.retail_week
	,case when ck.retail_week <= (select retail_week from ACCESS_VIEWS.DW_CAL_DT where AGE_FOR_RTL_WEEK_ID = -1 group by 1) then 'YTD' else 'Other' end as ytd_weeks
	,ck.AGE_FOR_RTL_WEEK_ID
	,focus_category as category
	,case when focus_category = 'Sneakers' and price_bucket not in ('A. <£86 (<$100)') then 'Only Focus Category'
		when focus_category = 'Jewellery' and price_bucket not in ('A. <£86 (<$100)','B. £86-£100 ($100-£100)','C. £100-£125','D. £125-£150','E. <£261 (<$300)') then 'Only Focus Category'
		when focus_category = 'Watches' and price_bucket not in ('A. <£86 (<$100)','B. £86-£100 ($100-£100)','C. £100-£125','D. £125-£150','E. <£261 (<$300)','F. £261-£435 ($300-$500)') then 'Only Focus Category'
		when focus_category = 'Handbags' and price_bucket not in ('A. <£86 (<$100)','B. £86-£100 ($100-£100)','C. £100-£125','D. £125-£150','E. <£261 (<$300)','F. £261-£435 ($300-$500)') then 'Only Focus Category'
		else 'Non-Focus Category'
		end as focus_category_flag
	,ck.categ_lvl2_name as l2
	,PRICE_BUCKET
	,coalesce((case when c.seller_id = ck.seller_id then u.comp else 'Other Sellers' End),u.user_slctd_id) as seller_name
	,ck.item_Cond
	,ck.B2C_C2C
	,coalesce(a.BRAND, 'Others') as BRAND
	,coalesce(b.MODEL, 'Others') as MODEL
	,ck.mece_bucket
	,ck.trade_type
	,0 as LL
	,0 as vi
	,0 as imps
	,sum(ck.gmv) as gmv
	,sum(ck.sold_items) as items_sold

	FROM p_robevans_t.lux_weekly_dashboard_trans_base AS ck
	LEFT JOIN p_robevans_t.lux_wbr_deepdive_top_brands a
		on ck.brand = a.brand
	LEFT JOIN p_robevans_t.lux_wbr_deepdive_top_models b
		on ck.model = b.model
	LEFT JOIN p_robevans_t.lux_wbr_deepdive_top_sellers c
		on ck.seller_id = c.seller_id
	LEFT JOIN DW_USERS u
		on ck.seller_id = u.user_id

	WHERE 1=1
		AND RETAIL_YEAR >= (select retail_year from DW_CAL_DT where AGE_FOR_RTL_WEEK_ID = -1 group by 1)-1
		and AGE_FOR_RTL_WEEK_ID <= -1 
	GROUP BY
		1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16
	
;	


----------------------------------------------------------------------------------------------------------------------------------------------------------------------- 
------------------------------------------------------------------- COMBINED TABLE ------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------	

drop table if exists P_ukplan_report_T.lux_weekly_final ;

create table P_ukplan_report_T.lux_weekly_final as

Select *
From p_robevans_t.lux_weekly_lstgs lstg	

UNION ALL

select *
from p_robevans_t.lux_weekly_txns ck
		
;


----------------------------------------------------------------------------------------------------------------------------------------------------------------------- 
------------------------------------------------------------- LATEST WEEK TRANS DATA ----------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------

drop table if exists P_ukplan_report_T.tableau_lux_wbr_deepdive_latest_week_trans_data;

create table P_ukplan_report_T.tableau_lux_wbr_deepdive_latest_week_trans_data as

select ck.item_id
,ck.brand
,ck.categ_lvl2_name
,ck.b2c_c2c
,ck.item_cond
,ck.trade_type
,lstg.auct_titl
,u.USER_SLCTD_ID as seller_name
,sum(ck.gmv) as gmv
,sum(ck.sold_items) as si

from p_robevans_t.lux_weekly_dashboard_trans_base ck
LEFT JOIN ACCESS_VIEWS.DW_LSTG_ITEM lstg
	on ck.item_id = lstg.item_id
LEFT JOIN ACCESS_VIEWS.DW_USERS u
	on ck.seller_id = u.user_id
where AGE_FOR_RTL_WEEK_ID = -1

group by 1,2,3,4,5,6,7,8
;




