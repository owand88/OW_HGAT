-- JIRA:            UKPLAN-22

-- Author: 			Robbie Evans
-- Date:            05/04/2023

-- Stakeholder: 	Wahaaj Shabbir, Alice Bridson, Emma Hamilton, Ines Morais, Keith Metcalfe
-- Description: 	Serves as an appendix to the NA Analytics Team's WBR dashboards. Provides in-depth analysis as to the drivers behind weekly performance metrics.





----------------------------------------------------------------------------------------------------------------------------------------------------------------------- 
------------------------------------------------------------------- TRAFFIC TABLE BASE --------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
drop table if exists lux_weekly_dashboard_trfc_base;

create temp table lux_weekly_dashboard_trfc_base as

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

drop table if exists lux_weekly_dashboard_lstg_base;

create temp table lux_weekly_dashboard_lstg_base as

select
lstg.ITEM_ID
,lstg.AUCT_START_DT
,lstg.AUCT_END_DT
,lstg.RETAIL_YEAR
,lstg.RETAIL_WEEK
,lstg.AGE_FOR_RTL_WEEK_ID
,lstg.SLR_ID
,lstg.focus_category
,lstg.CATEG_LVL2_NAME
,lstg.PRICE_BUCKET
,lstg.item_Cond
,lstg.BRAND
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

	Group by 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17
) lstg 
LEFT JOIN lux_weekly_dashboard_trfc_base trfc
	on lstg.item_id = trfc.item_id
	and lstg.AGE_FOR_RTL_WEEK_ID = trfc.AGE_FOR_RTL_WEEK_ID

Where 1=1

Group by 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17
;


----------------------------------------------------------------------------------------------------------------------------------------------------------------------- 
----------------------------------------------------------------- TRANSACTION TABLE BASE ------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------

drop table if exists lux_weekly_dashboard_trans_base;

create temp table lux_weekly_dashboard_trans_base as
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

GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15
;




----------------------------------------------------------------------------------------------------------------------------------------------------------------------- 
---------------------------------------------------------------------- ASPECTS TABLE ----------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------

DROP TABLE IF EXISTS LSTG_BASE;
CREATE TEMPORARY TABLE LSTG_BASE AS  
SELECT  ITEM_ID,AUCT_END_DT 
FROM lux_weekly_dashboard_trans_base
GROUP BY 1,2
UNION 
SELECT ITEM_ID, AUCT_END_DT
FROM lux_weekly_dashboard_lstg_base
GROUP BY 1,2;




DROP TABLE IF EXISTS TEMP2;
CREATE TEMPORARY TABLE TEMP2 AS  
SELECT  
  aspct.item_id
   ,aspct.auct_end_dt
   ,1 AS priority
   ,Upper(tag_name) AS aspect
   ,Cast(Trim(Lower(aspct.tag_value_txt)) AS VARCHAR(350)) AS aspct_vlu_nm 

FROM ACCESS_VIEWS.DW_ATTR_LSTG_TAG_DTL AS aspct
INNER JOIN LSTG_BASE AS item
	ON  (aspct.item_id=item.item_id AND aspct.auct_end_dt=item.auct_end_dt) 

WHERE ((aspct.auct_end_dt>=date_sub(To_Date('2016-09-16'),5))
	AND Lower(tag_name) LIKE ANY ('brand','%modified item%','model')) 
GROUP BY 1,2,3,4,5;
  




DROP TABLE IF EXISTS aspects_temp2;
CREATE TEMPORARY TABLE aspects_temp2 AS  
 SELECT  
  ITEM_ID, AUCT_END_DT, PRIORITY, ASPECT, ASPCT_VLU_NM
 FROM  
( SELECT  
  *
   ,(Row_Number() Over (PARTITION BY item_id,auct_end_dt,aspect ORDER BY priority,aspct_vlu_nm DESC)) AS alias_1781 
 FROM temp2
)alias_1782 
 WHERE alias_1782.alias_1781 = 1;



DROP TABLE IF EXISTS listing_aspects_temp;
CREATE TEMPORARY TABLE listing_aspects_temp AS  
 SELECT  
  item_id
   ,auct_end_dt
   ,Coalesce(Max(CASE  WHEN Lower(aspect)=Lower('BRAND') THEN aspct_vlu_nm ELSE NULL end ),'Unknown') AS BRAND
   ,Coalesce(Max(CASE  WHEN Lower(aspect)=Lower('MODEL') THEN aspct_vlu_nm ELSE NULL end ),'Unknown') AS MODEL
   ,Coalesce(Max(CASE  WHEN Lower(aspect) like Lower('%modified item%') THEN aspct_vlu_nm ELSE NULL end ),'Unknown') AS MODIFIED_ITEM
 FROM aspects_temp2
 GROUP BY 1,2;


DROP TABLE IF EXISTS listing_aspects;
CREATE TEMPORARY TABLE listing_aspects AS  
 SELECT  
  item_id
   ,auct_end_dt
   ,case when (brand is null) or (lower(brand) = 'unknown') or (lower(brand) = 'unbranded') then 'unbranded' else brand end as BRAND
   ,MODEL
   ,MODIFIED_ITEM
 FROM listing_aspects_temp
 GROUP BY 1,2,3,4,5;

----------------------------------------------------------------------------------------------------------------------------------------------------------------------- 
------------------------------------------------------------ TOP BRANDS & MODELS TABLE --------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------

Drop table if exists top_brands;
Create temporary table top_brands as

select distinct brand
from
(
	select *
	From (
		select 
		categ_lvl2_name
		,brand
		,gmv
			,dense_rank() over(partition by categ_lvl2_name order by gmv desc) as brand_rank
		From	
			(select 
			ck.categ_lvl2_name
			,a.brand
			,sum(ck.gmv) as gmv

				FROM lux_weekly_dashboard_trans_base AS ck
				inner JOIN listing_aspects A
					ON A.ITEM_ID=ck.ITEM_ID
					AND A.AUCT_END_DT=ck.AUCT_END_DT 
			Where 1=1
			and AGE_FOR_RTL_WEEK_ID between -52 and -1

			Group by 1,2)
			)
	where brand_rank <= 20

	UNION ALL

	select *
	From (
		select 
		focus_category
		,brand
		,gmv
			,dense_rank() over(partition by focus_category order by gmv desc) as brand_rank
		From	
			(select 
			ck.focus_category
			,a.brand
			,sum(ck.gmv) as gmv

				FROM lux_weekly_dashboard_trans_base AS ck
				inner JOIN listing_aspects A
					ON A.ITEM_ID=ck.ITEM_ID
					AND A.AUCT_END_DT=ck.AUCT_END_DT 
			Where 1=1
			and AGE_FOR_RTL_WEEK_ID between -52 and -1

			Group by 1,2)
			)
	where brand_rank <= 20
)
;



Drop table if exists top_models;
Create temporary table top_models as

select distinct model
FROM
(
	select *
	From (
		select 
		categ_lvl2_name
		,model
		,gmv
			,dense_rank() over(partition by categ_lvl2_name order by gmv desc) as model_rank
		From	
			(select 
			ck.categ_lvl2_name
			,a.model
			,sum(ck.gmv) as gmv

				FROM lux_weekly_dashboard_trans_base AS ck
				inner JOIN listing_aspects A
					ON A.ITEM_ID=ck.ITEM_ID
					AND A.AUCT_END_DT=ck.AUCT_END_DT 
			Where 1=1
			and AGE_FOR_RTL_WEEK_ID between -52 and -1

			Group by 1,2)
			)
	where model_rank <= 20

	UNION ALL

	select *
	From (
		select 
		focus_category
		,model
		,gmv
			,dense_rank() over(partition by focus_category order by gmv desc) as model_rank
		From	
			(select 
			ck.focus_category
			,a.model
			,sum(ck.gmv) as gmv

				FROM lux_weekly_dashboard_trans_base AS ck
				inner JOIN listing_aspects A
					ON A.ITEM_ID=ck.ITEM_ID
					AND A.AUCT_END_DT=ck.AUCT_END_DT 
			Where 1=1
			and AGE_FOR_RTL_WEEK_ID between -52 and -1

			Group by 1,2)
			)
	where model_rank <= 20
)
;




DROP TABLE IF EXISTS listing_aspects;
CREATE TEMPORARY TABLE listing_aspects AS  
 SELECT  
  item_id
   ,auct_end_dt
   ,case when a.brand = b.brand then a.brand else 'Other Brands' end as BRAND
   ,case when a.model = m.model then a.model else 'Other Models' end as MODEL
   ,MODIFIED_ITEM
 FROM listing_aspects_temp a
 LEFT JOIN top_brands b
 	on a.brand = b.brand
LEFT JOIN top_models m
	on a.model = m.model
 GROUP BY 1,2,3,4,5;


----------------------------------------------------------------------------------------------------------------------------------------------------------------------- 
------------------------------------------------------------------- FINAL LISTING TABLE -------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------


drop table if exists lux_weekly_lstgs;

Create temp table lux_weekly_lstgs as

-----------------Focus Category level weekly data-----------------------
select
	'Focus Category' as level
	,'Weekly' as time_period
	,'Total' as total_v_brand
	,lstg.retail_year
	,lstg.retail_week
	,lstg.AGE_FOR_RTL_WEEK_ID
	,focus_category as category
	,PRICE_BUCKET
	,lstg.item_Cond
	,lstg.B2C_C2C
	,case when upper(A.MODIFIED_ITEM) in ('MODIFIED', 'CUSTOMIZED','YES','CUSTOM','CUSTOMISED') then 'Modified' else 'Unmodified' End as modified_flag
	,0 as BRAND
	,0 as MODEL
	,0 as mece_bucket
	,count(distinct lstg.item_id) as LL
	,count(distinct lstg.SLR_ID) as listers
	,sum(lstg.vi) as vi
	,sum(lstg.imps) as imps
	,0 as sellers
	,0 as buyers
	,0 as gmv
	,0 as items_sold

	FROM lux_weekly_dashboard_lstg_base AS lstg
	LEFT JOIN listing_aspects A
		ON A.ITEM_ID=lstg.ITEM_ID
		AND A.AUCT_END_DT=lstg.AUCT_END_DT 
		
	WHERE 1=1
		AND RETAIL_YEAR >= (select retail_year from DW_CAL_DT where AGE_FOR_RTL_WEEK_ID = -1 group by 1)-1
		and AGE_FOR_RTL_WEEK_ID <= -1 
	GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12,13,14
	
	UNION ALL

-----------------L2 level weekly data-----------------------
	select
	'L2' as level
	,'Weekly' as time_period
	,'Total' as total_v_brand
	,lstg.retail_year
	,lstg.retail_week
	,lstg.AGE_FOR_RTL_WEEK_ID
	,categ_lvl2_name as category
	,PRICE_BUCKET
	,lstg.item_Cond
	,lstg.B2C_C2C
	,case when upper(A.MODIFIED_ITEM) in ('MODIFIED', 'CUSTOMIZED','YES','CUSTOM','CUSTOMISED') then 'Modified' else 'Unmodified' End as modified_flag
	,0 as BRAND
	,0 as MODEL
	,0 as mece_bucket
	,count(distinct lstg.item_id) as LL
	,count(distinct lstg.SLR_ID) as listers
	,sum(lstg.vi) as vi
	,sum(lstg.imps) as imps
	,0 as sellers
	,0 as buyers
	,0 as gmv
	,0 as items_sold

	FROM lux_weekly_dashboard_lstg_base AS lstg
	LEFT JOIN listing_aspects A
		ON A.ITEM_ID=lstg.ITEM_ID
		AND A.AUCT_END_DT=lstg.AUCT_END_DT
		
	WHERE 1=1
		AND RETAIL_YEAR >= (select retail_year from DW_CAL_DT where AGE_FOR_RTL_WEEK_ID = -1 group by 1)-1
		and AGE_FOR_RTL_WEEK_ID <= -1 
	GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12,13,14
	
	UNION ALL

-----------------Focus Category level YTD data-----------------------
select
	'Focus Category' as level
	,'YTD' as time_period
	,'Total' as total_v_brand
	,lstg.retail_year
	,0 as retail_week
	,0 as AGE_FOR_RTL_WEEK_ID
	,focus_category as category
	,PRICE_BUCKET
	,lstg.item_Cond
	,lstg.B2C_C2C
	,case when upper(A.MODIFIED_ITEM) in ('MODIFIED', 'CUSTOMIZED','YES','CUSTOM','CUSTOMISED') then 'Modified' else 'Unmodified' End as modified_flag
	,0 as BRAND
	,0 as MODEL
	,0 as mece_bucket
	,count(distinct lstg.item_id) as LL
	,count(distinct lstg.SLR_ID) as listers
	,sum(lstg.vi) as vi
	,sum(lstg.imps) as imps
	,0 as sellers
	,0 as buyers
	,0 as gmv
	,0 as items_sold

	FROM lux_weekly_dashboard_lstg_base AS lstg
	LEFT JOIN listing_aspects A
		ON A.ITEM_ID=lstg.ITEM_ID
		AND A.AUCT_END_DT=lstg.AUCT_END_DT 
		
	WHERE 1=1
		AND RETAIL_YEAR >= (select retail_year from DW_CAL_DT where AGE_FOR_RTL_WEEK_ID = -1 group by 1)-1
		and AGE_FOR_RTL_WEEK_ID <= -1 
	GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12,13,14
	
	UNION ALL

-----------------L2 level YTD data-----------------------
	select
	'L2' as level
	,'YTD' as time_period
	,'Total' as total_v_brand
	,lstg.retail_year
	,0 as retail_week
	,0 as AGE_FOR_RTL_WEEK_ID
	,categ_lvl2_name as category
	,PRICE_BUCKET
	,lstg.item_Cond
	,lstg.B2C_C2C
	,case when upper(A.MODIFIED_ITEM) in ('MODIFIED', 'CUSTOMIZED','YES','CUSTOM','CUSTOMISED') then 'Modified' else 'Unmodified' End as modified_flag
	,0 as BRAND
	,0 as MODEL
	,0 as mece_bucket
	,count(distinct lstg.item_id) as LL
	,count(distinct lstg.SLR_ID) as listers
	,sum(lstg.vi) as vi
	,sum(lstg.imps) as imps
	,0 as sellers
	,0 as buyers
	,0 as gmv
	,0 as items_sold

	FROM lux_weekly_dashboard_lstg_base AS lstg
	LEFT JOIN listing_aspects A
		ON A.ITEM_ID=lstg.ITEM_ID
		AND A.AUCT_END_DT=lstg.AUCT_END_DT
		
	WHERE 1=1
		AND RETAIL_YEAR >= (select retail_year from DW_CAL_DT where AGE_FOR_RTL_WEEK_ID = -1 group by 1)-1
		and AGE_FOR_RTL_WEEK_ID <= -1 
	GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12,13,14
	
	UNION ALL


-----------------Focus Category Brand level Weekly data-----------------------
	select
	'Focus Category' as level
	,'Weekly' as time_period
	,'Brand' as total_v_brand
	,lstg.retail_year
	,lstg.retail_week
	,lstg.AGE_FOR_RTL_WEEK_ID
	,focus_category as category
	,PRICE_BUCKET
	,lstg.item_Cond
	,lstg.B2C_C2C
	,case when upper(A.MODIFIED_ITEM) in ('MODIFIED', 'CUSTOMIZED','YES','CUSTOM','CUSTOMISED') then 'Modified' else 'Unmodified' End as modified_flag
	,A.BRAND
	,A.MODEL
	,0 as mece_bucket
	,count(distinct lstg.item_id) as LL
	,count(distinct lstg.SLR_ID) as listers
	,sum(lstg.vi) as vi
	,sum(lstg.imps) as imps
	,0 as sellers
	,0 as buyers
	,0 as gmv
	,0 as items_sold

	FROM lux_weekly_dashboard_lstg_base AS lstg
	LEFT JOIN listing_aspects A
		ON A.ITEM_ID=lstg.ITEM_ID
		AND A.AUCT_END_DT=lstg.AUCT_END_DT 
		
	WHERE 1=1
		AND RETAIL_YEAR >= (select retail_year from DW_CAL_DT where AGE_FOR_RTL_WEEK_ID = -1 group by 1)-1
		and retail_week >= 1 and retail_week <= (select retail_week from DW_CAL_DT where AGE_FOR_RTL_WEEK_ID = -1 group by 1)
	GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12,13,14
	
	UNION ALL

-----------------L2 Brand level Weekly data-----------------------
	select
	'L2' as level
	,'Weekly' as time_period
	,'Brand' as total_v_brand
	,lstg.retail_year
	,lstg.retail_week
	,lstg.AGE_FOR_RTL_WEEK_ID
	,categ_lvl2_name as category
	,PRICE_BUCKET
	,lstg.item_Cond
	,lstg.B2C_C2C
	,case when upper(A.MODIFIED_ITEM) in ('MODIFIED', 'CUSTOMIZED','YES','CUSTOM','CUSTOMISED') then 'Modified' else 'Unmodified' End as modified_flag
	,A.BRAND
	,A.MODEL
	,0 as mece_bucket
	,count(distinct lstg.item_id) as LL
	,count(distinct lstg.SLR_ID) as listers
	,sum(lstg.vi) as vi
	,sum(lstg.imps) as imps
	,0 as sellers
	,0 as buyers
	,0 as gmv
	,0 as items_sold

	FROM lux_weekly_dashboard_lstg_base AS lstg
	LEFT JOIN listing_aspects A
		ON A.ITEM_ID=lstg.ITEM_ID
		AND A.AUCT_END_DT=lstg.AUCT_END_DT
		
	WHERE 1=1
		AND RETAIL_YEAR >= (select retail_year from DW_CAL_DT where AGE_FOR_RTL_WEEK_ID = -1 group by 1)-1
		and retail_week >= 1 and retail_week <= (select retail_week from DW_CAL_DT where AGE_FOR_RTL_WEEK_ID = -1 group by 1)
	GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12,13,14
	
	UNION ALL

-----------------Focus Category Brand level YTD data-----------------------
	select
	'Focus Category' as level
	,'YTD' as time_period
	,'Brand' as total_v_brand
	,lstg.retail_year
	,0 as retail_week
	,0 as AGE_FOR_RTL_WEEK_ID
	,focus_category as category
	,PRICE_BUCKET
	,lstg.item_Cond
	,lstg.B2C_C2C
	,case when upper(A.MODIFIED_ITEM) in ('MODIFIED', 'CUSTOMIZED','YES','CUSTOM','CUSTOMISED') then 'Modified' else 'Unmodified' End as modified_flag
	,A.BRAND
	,A.MODEL
	,0 as mece_bucket
	,count(distinct lstg.item_id) as LL
	,count(distinct lstg.SLR_ID) as listers
	,sum(lstg.vi) as vi
	,sum(lstg.imps) as imps
	,0 as sellers
	,0 as buyers
	,0 as gmv
	,0 as items_sold

	FROM lux_weekly_dashboard_lstg_base AS lstg
	LEFT JOIN listing_aspects A
		ON A.ITEM_ID=lstg.ITEM_ID
		AND A.AUCT_END_DT=lstg.AUCT_END_DT 
		
	WHERE 1=1
		AND RETAIL_YEAR >= (select retail_year from DW_CAL_DT where AGE_FOR_RTL_WEEK_ID = -1 group by 1)-1
		and retail_week >= 1 and retail_week <= (select retail_week from DW_CAL_DT where AGE_FOR_RTL_WEEK_ID = -1 group by 1)
	GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12,13,14
	
	UNION ALL

-----------------L2 Brand level YTD data-----------------------
	select
	'L2' as level
	,'YTD' as time_period
	,'Brand' as total_v_brand
	,lstg.retail_year
	,0 as retail_week
	,0 as AGE_FOR_RTL_WEEK_ID
	,categ_lvl2_name as category
	,PRICE_BUCKET
	,lstg.item_Cond
	,lstg.B2C_C2C
	,case when upper(A.MODIFIED_ITEM) in ('MODIFIED', 'CUSTOMIZED','YES','CUSTOM','CUSTOMISED') then 'Modified' else 'Unmodified' End as modified_flag
	,A.BRAND
	,A.MODEL
	,0 as mece_bucket
	,count(distinct lstg.item_id) as LL
	,count(distinct lstg.SLR_ID) as listers
	,sum(lstg.vi) as vi
	,sum(lstg.imps) as imps
	,0 as sellers
	,0 as buyers
	,0 as gmv
	,0 as items_sold

	FROM lux_weekly_dashboard_lstg_base AS lstg
	LEFT JOIN listing_aspects A
		ON A.ITEM_ID=lstg.ITEM_ID
		AND A.AUCT_END_DT=lstg.AUCT_END_DT
		
	WHERE 1=1
		AND RETAIL_YEAR >= (select retail_year from DW_CAL_DT where AGE_FOR_RTL_WEEK_ID = -1 group by 1)-1
		and retail_week >= 1 and retail_week <= (select retail_week from DW_CAL_DT where AGE_FOR_RTL_WEEK_ID = -1 group by 1)
	GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12,13,14
	
	;
	
----------------------------------------------------------------------------------------------------------------------------------------------------------------------- 
---------------------------------------------------------------- FINAL TRANSACTION TABLE ------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------	

drop table if exists lux_weekly_txns;

Create temp table lux_weekly_txns as

-----------------Focus Category level weekly data-----------------------
select
	'Focus Category' as level
	,'Weekly' as time_period
	,'Total' as total_v_brand
	,ck.retail_year
	,ck.retail_week
	,ck.AGE_FOR_RTL_WEEK_ID
	,focus_category as category
	,PRICE_BUCKET
	,ck.item_Cond
	,ck.B2C_C2C
	,case when upper(A.MODIFIED_ITEM) in ('MODIFIED', 'CUSTOMIZED','YES','CUSTOM','CUSTOMISED') then 'Modified' else 'Unmodified' End as modified_flag
	,0 as BRAND
	,0 as MODEL
	,ck.mece_bucket
	,0 as LL
	,0 as listers
	,0 as vi
	,0 as imps
	,count(distinct ck.SELLER_ID) as sellers
	,count(distinct ck.BUYER_ID) as buyers
	,sum(ck.gmv) as gmv
	,sum(ck.sold_items) as sold_items

	FROM lux_weekly_dashboard_trans_base AS ck
	LEFT JOIN listing_aspects A
		ON A.ITEM_ID=ck.ITEM_ID
		AND A.AUCT_END_DT=ck.AUCT_END_DT
		
	WHERE 1=1
		AND RETAIL_YEAR >= (select retail_year from DW_CAL_DT where AGE_FOR_RTL_WEEK_ID = -1 group by 1)-1
		and AGE_FOR_RTL_WEEK_ID <= -1 
	GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12,13,14
	
	UNION ALL

-----------------L2 level weekly data-----------------------
	select
	'L2' as level
	,'Weekly' as time_period
	,'Total' as total_v_brand
	,ck.retail_year
	,ck.retail_week
	,ck.AGE_FOR_RTL_WEEK_ID
	,categ_lvl2_name as category
	,PRICE_BUCKET
	,ck.item_Cond
	,ck.B2C_C2C
	,case when upper(A.MODIFIED_ITEM) in ('MODIFIED', 'CUSTOMIZED','YES','CUSTOM','CUSTOMISED') then 'Modified' else 'Unmodified' End as modified_flag
	,0 as BRAND
	,0 as MODEL
	,ck.mece_bucket
	,0 as LL
	,0 as listers
	,0 as vi
	,0 as imps
	,count(distinct ck.SELLER_ID) as sellers
	,count(distinct ck.BUYER_ID) as buyers
	,sum(ck.gmv) as gmv
	,sum(ck.sold_items) as sold_items

	FROM lux_weekly_dashboard_trans_base AS ck
	LEFT JOIN listing_aspects A
		ON A.ITEM_ID=ck.ITEM_ID
		AND A.AUCT_END_DT=ck.AUCT_END_DT
		
	WHERE 1=1
		AND RETAIL_YEAR >= (select retail_year from DW_CAL_DT where AGE_FOR_RTL_WEEK_ID = -1 group by 1)-1
		and AGE_FOR_RTL_WEEK_ID <= -1 
	GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12,13,14
	
	UNION ALL

-----------------Focus Category level YTD data-----------------------
select
	'Focus Category' as level
	,'YTD' as time_period
	,'Total' as total_v_brand
	,ck.retail_year
	,0 as retail_week
	,0 as AGE_FOR_RTL_WEEK_ID
	,focus_category as category
	,PRICE_BUCKET
	,ck.item_Cond
	,ck.B2C_C2C
	,case when upper(A.MODIFIED_ITEM) in ('MODIFIED', 'CUSTOMIZED','YES','CUSTOM','CUSTOMISED') then 'Modified' else 'Unmodified' End as modified_flag
	,0 as BRAND
	,0 as MODEL
	,ck.mece_bucket
	,0 as LL
	,0 as listers
	,0 as vi
	,0 as imps
	,count(distinct ck.SELLER_ID) as sellers
	,count(distinct ck.BUYER_ID) as buyers
	,sum(ck.gmv) as gmv
	,sum(ck.sold_items) as sold_items

	FROM lux_weekly_dashboard_trans_base AS ck
	LEFT JOIN listing_aspects A
		ON A.ITEM_ID=ck.ITEM_ID
		AND A.AUCT_END_DT=ck.AUCT_END_DT
		
	WHERE 1=1
		AND RETAIL_YEAR >= (select retail_year from DW_CAL_DT where AGE_FOR_RTL_WEEK_ID = -1 group by 1)-1
		and AGE_FOR_RTL_WEEK_ID <= -1 
	GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12,13,14
	
	UNION ALL

-----------------L2 level YTD data-----------------------
	select
	'L2' as level
	,'YTD' as time_period
	,'Total' as total_v_brand
	,ck.retail_year
	,0 as retail_week
	,0 as AGE_FOR_RTL_WEEK_ID
	,categ_lvl2_name as category
	,PRICE_BUCKET
	,ck.item_Cond
	,ck.B2C_C2C
	,case when upper(A.MODIFIED_ITEM) in ('MODIFIED', 'CUSTOMIZED','YES','CUSTOM','CUSTOMISED') then 'Modified' else 'Unmodified' End as modified_flag
	,0 as BRAND
	,0 as MODEL
	,ck.mece_bucket
	,0 as LL
	,0 as listers
	,0 as vi
	,0 as imps
	,count(distinct ck.SELLER_ID) as sellers
	,count(distinct ck.BUYER_ID) as buyers
	,sum(ck.gmv) as gmv
	,sum(ck.sold_items) as sold_items

	FROM lux_weekly_dashboard_trans_base AS ck
	LEFT JOIN listing_aspects A
		ON A.ITEM_ID=ck.ITEM_ID
		AND A.AUCT_END_DT=ck.AUCT_END_DT
		
	WHERE 1=1
		AND RETAIL_YEAR >= (select retail_year from DW_CAL_DT where AGE_FOR_RTL_WEEK_ID = -1 group by 1)-1
		and AGE_FOR_RTL_WEEK_ID <= -1 
	GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12,13,14
	
	UNION ALL

-----------------Focus Category Brand level weekly data-----------------------
select
	'Focus Category' as level
	,'Weekly' as time_period
	,'Brand' as total_v_brand
	,ck.retail_year
	,ck.retail_week
	,ck.AGE_FOR_RTL_WEEK_ID
	,focus_category as category
	,PRICE_BUCKET
	,ck.item_Cond
	,ck.B2C_C2C
	,case when upper(A.MODIFIED_ITEM) in ('MODIFIED', 'CUSTOMIZED','YES','CUSTOM','CUSTOMISED') then 'Modified' else 'Unmodified' End as modified_flag
	,A.BRAND
	,A.MODEL
	,ck.mece_bucket
	,0 as LL
	,0 as listers
	,0 as vi
	,0 as imps
	,count(distinct ck.SELLER_ID) as sellers
	,count(distinct ck.BUYER_ID) as buyers
	,sum(ck.gmv) as gmv
	,sum(ck.sold_items) as sold_items

	FROM lux_weekly_dashboard_trans_base AS ck
	LEFT JOIN listing_aspects A
		ON A.ITEM_ID=ck.ITEM_ID
		AND A.AUCT_END_DT=ck.AUCT_END_DT
		
	WHERE 1=1
		AND RETAIL_YEAR >= (select retail_year from DW_CAL_DT where AGE_FOR_RTL_WEEK_ID = -1 group by 1)-1
		and AGE_FOR_RTL_WEEK_ID <= -1 
	GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12,13,14
	
	UNION ALL

-----------------L2 Brand level weekly data-----------------------
	select
	'L2' as level
	,'Weekly' as time_period
	,'Brand' as total_v_brand
	,ck.retail_year
	,ck.retail_week
	,ck.AGE_FOR_RTL_WEEK_ID
	,categ_lvl2_name as category
	,PRICE_BUCKET
	,ck.item_Cond
	,ck.B2C_C2C
	,case when upper(A.MODIFIED_ITEM) in ('MODIFIED', 'CUSTOMIZED','YES','CUSTOM','CUSTOMISED') then 'Modified' else 'Unmodified' End as modified_flag
	,A.BRAND
	,A.MODEL
	,ck.mece_bucket
	,0 as LL
	,0 as listers
	,0 as vi
	,0 as imps
	,count(distinct ck.SELLER_ID) as sellers
	,count(distinct ck.BUYER_ID) as buyers
	,sum(ck.gmv) as gmv
	,sum(ck.sold_items) as sold_items

	FROM lux_weekly_dashboard_trans_base AS ck
	LEFT JOIN listing_aspects A
		ON A.ITEM_ID=ck.ITEM_ID
		AND A.AUCT_END_DT=ck.AUCT_END_DT
		
	WHERE 1=1
		AND RETAIL_YEAR >= (select retail_year from DW_CAL_DT where AGE_FOR_RTL_WEEK_ID = -1 group by 1)-1
		and AGE_FOR_RTL_WEEK_ID <= -1 
	GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12,13,14
	
	UNION ALL
	
	
-----------------Focus Category Brand level YTD data-----------------------
select
	'Focus Category' as level
	,'YTD' as time_period
	,'Brand' as total_v_brand
	,ck.retail_year
	,0 as retail_week
	,0 as AGE_FOR_RTL_WEEK_ID
	,focus_category as category
	,PRICE_BUCKET
	,ck.item_Cond
	,ck.B2C_C2C
	,case when upper(A.MODIFIED_ITEM) in ('MODIFIED', 'CUSTOMIZED','YES','CUSTOM','CUSTOMISED') then 'Modified' else 'Unmodified' End as modified_flag
	,A.BRAND
	,A.MODEL
	,ck.mece_bucket
	,0 as LL
	,0 as listers
	,0 as vi
	,0 as imps
	,count(distinct ck.SELLER_ID) as sellers
	,count(distinct ck.BUYER_ID) as buyers
	,sum(ck.gmv) as gmv
	,sum(ck.sold_items) as sold_items

	FROM lux_weekly_dashboard_trans_base AS ck
	LEFT JOIN listing_aspects A
		ON A.ITEM_ID=ck.ITEM_ID
		AND A.AUCT_END_DT=ck.AUCT_END_DT
		
	WHERE 1=1
		AND RETAIL_YEAR >= (select retail_year from DW_CAL_DT where AGE_FOR_RTL_WEEK_ID = -1 group by 1)-1
		and AGE_FOR_RTL_WEEK_ID <= -1 
	GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12,13,14
	
	UNION ALL

-----------------L2 Brand level YTD data-----------------------
	select
	'L2' as level
	,'YTD' as time_period
	,'Brand' as total_v_brand
	,ck.retail_year
	,0 as retail_week
	,0 as AGE_FOR_RTL_WEEK_ID
	,categ_lvl2_name as category
	,PRICE_BUCKET
	,ck.item_Cond
	,ck.B2C_C2C
	,case when upper(A.MODIFIED_ITEM) in ('MODIFIED', 'CUSTOMIZED','YES','CUSTOM','CUSTOMISED') then 'Modified' else 'Unmodified' End as modified_flag
	,A.BRAND
	,A.MODEL
	,ck.mece_bucket
	,0 as LL
	,0 as listers
	,0 as vi
	,0 as imps
	,count(distinct ck.SELLER_ID) as sellers
	,count(distinct ck.BUYER_ID) as buyers
	,sum(ck.gmv) as gmv
	,sum(ck.sold_items) as sold_items

	FROM lux_weekly_dashboard_trans_base AS ck
	LEFT JOIN listing_aspects A
		ON A.ITEM_ID=ck.ITEM_ID
		AND A.AUCT_END_DT=ck.AUCT_END_DT
		
	WHERE 1=1
		AND RETAIL_YEAR >= (select retail_year from DW_CAL_DT where AGE_FOR_RTL_WEEK_ID = -1 group by 1)-1
		and AGE_FOR_RTL_WEEK_ID <= -1 
	GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12,13,14
	
;

----------------------------------------------------------------------------------------------------------------------------------------------------------------------- 
------------------------------------------------------------------- COMBINED TABLE ------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------	

drop table if exists P_ukplan_report_T.lux_weekly_final ;

create table P_ukplan_report_T.lux_weekly_final as

Select 'Listings' as table_name,*
From lux_weekly_lstgs lstg	

UNION ALL

select 'Transactions' as table_name,*
from lux_weekly_txns ck
		
;


----------------------------------------------------------------------------------------------------------------------------------------------------------------------- 
------------------------------------------------------------------- BUDGETS DATA --------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------

drop table if exists P_ukplan_report_T.tableau_lux_wbr_deepdive_budgets;

create table P_ukplan_report_T.tableau_lux_wbr_deepdive_budgets as

select 
ck.retail_year
,ck.retail_week
,max_week
,max_year
,ck.AGE_FOR_RTL_WEEK_ID
,ck.category
,sum(ck.gmv) as gmv
,sum(bud.budget_gmv) as budget_gmv

From
	(select RETAIL_YEAR
	,RETAIL_WEEK
	,AGE_FOR_RTL_WEEK_ID
	,category
	,sum(gmv) as gmv
	From P_ukplan_report_T.lux_weekly_txns
	where level = 'Focus Category'
	and time_period = 'Weekly'
	and total_v_brand = 'Total'
	and modified_flag = 'Unmodified'
	and (
		(category='Sneakers' and price_bucket <> 'A. <£86 (<$100)')
		or (category='Watches' and price_bucket not in ('A. <£86 (<$100)','B. £86-£100 ($100-£100)','C. £100-£125','D. £125-£150','E. <£261 (<$300)','F. £261-£435 ($300-$500)'))
		or (category='Handbags' and price_bucket not in ('A. <£86 (<$100)','B. £86-£100 ($100-£100)','C. £100-£125','D. £125-£150','E. <£261 (<$300)','F. £261-£435 ($300-$500)'))
		or (category='Jewellery' and price_bucket not in ('A. <£86 (<$100)','B. £86-£100 ($100-£100)','C. £100-£125','D. £125-£150','E. <£261 (<$300)'))
		)
	Group by 1,2,3,4) ck
left join
	(select cal.RETAIL_YEAR
		,cal.RETAIL_WEEK
		,case when b.focused_vertical_lvl1 = 'Jewelry >=$300' then 'Jewellery'
			when b.focused_vertical_lvl1 = 'Watches >=$500' then 'Watches'
			when b.focused_vertical_lvl1 = 'Sneakers >=$100' then 'Sneakers'
			when b.focused_vertical_lvl1 = 'Handbags >=$500' then 'Handbags'
			else 'Other'
			end as category
		,sum(gmv) as budget_gmv
	from P_CSI_TBS_T.FC_GLOBAL_WBR_FCST_BASE_Budget b
	inner join DW_CAL_DT cal
		on b.cal_dt = cal.cal_dt 
		and cal.retail_year = 2023
	where 1=1
	and glbl_rprt_geo_name = 'UK'
	and fc_lvl1 = 'Fashion'
	Group by 1,2,3) bud
		on ck.RETAIL_YEAR = bud.RETAIL_YEAR
		and ck.RETAIL_WEEK = bud.RETAIL_WEEK
		and ck.category = bud.category
left join 
	(select RETAIL_WEEK as max_week
	,retail_year as max_year
	From ACCESS_VIEWS.DW_CAL_DT
	Where AGE_FOR_RTL_WEEK_ID = -1
	Group by 1,2)

Group by 1,2,3,4,5,6
;




----------------------------------------------------------------------------------------------------------------------------------------------------------------------- 
------------------------------------------------------------- LATEST WEEK TRANS DATA ----------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------

drop table if exists P_ukplan_report_T.tableau_lux_wbr_deepdive_latest_week_data;

create table P_ukplan_report_T.tableau_lux_wbr_deepdive_latest_week_data as

-- select ck.*
-- ,lstg.auct_titl
-- ,u.USER_SLCTD_ID as seller_name

-- from P_ukplan_report_T.lux_weekly_dashboard_trans_base ck
-- LEFT JOIN ACCESS_VIEWS.DW_LSTG_ITEM lstg
-- 	on ck.item_id = lstg.item_id
-- LEFT JOIN ACCESS_VIEWS.DW_USERS u
-- 	on ck.seller_id = u.user_id
-- where AGE_FOR_RTL_WEEK_ID in (-1,-2,-53)

-- ;





select
	lstg.item_id
	,lstg2.auct_titl
	,lstg.retail_year
	,lstg.retail_week
	,lstg.age_for_rtl_week_id
	,lstg.SLR_ID
	,u.USER_SLCTD_ID as seller_name
	,0 as buyer_id
	,0 as trade_type
	,lstg.focus_category
	,lstg.CATEG_LVL2_NAME
	,lstg.PRICE_BUCKET
	,lstg.item_Cond
	,lstg.BRAND
	,0 as mece_bucket
	,lstg.B2C_C2C
	,sum(lstg.vi) as vi
	,sum(lstg.imps) as imps
	,0 as gmv
	,0 as sold_items
from
	lux_weekly_dashboard_lstg_base lstg
LEFT JOIN ACCESS_VIEWS.DW_LSTG_ITEM lstg2
	on lstg.item_id = lstg2.item_id
LEFT JOIN ACCESS_VIEWS.DW_USERS u
	on lstg.slr_id = u.user_id
Where
	age_for_rtl_week_id in (-1,-2,-53)
group by
	1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16
	
UNION ALL

SELECT
	item_id
	,0 as auct_titl
	,retail_year
	,retail_week
	,age_for_rtl_week_id
	,seller_id
	,0 as seller_name
	,buyer_id
	,trade_type
	,focus_category
	,CATEG_LVL2_NAME
	,PRICE_BUCKET
	,item_Cond
	,BRAND
	,mece_bucket
	,B2C_C2C
	,0 as vi
	,0 as imps
	,sum(gmv) as gmv
	,sum(sold_items) as sold_items
from
	lux_weekly_dashboard_trans_base
Where
	age_for_rtl_week_id in (-1,-2,-53)
group by
	1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16


		

