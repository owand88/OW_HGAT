-- JIRA Ticket:     UKPLAN-520

-- Author: 			Robbie Evans
-- Stakeholder: 	Wahaaj Shabbir
-- Purpose: 		There is a hypothesis that a primary driver of the Lux Sneaker declines in 2023 vs 2022 has been as a result of fewer new Sneaker styles being sold on eBay. Need to test this hypothesis by looking at the sales and listings of Sneaker styles by their launch date
-- Date Created: 	21/09/2023






----------------------------------------------------------------------------------
-----------------------------CREATING FILE SAFE----------------------------------
---------------------------------------------------------------------------------
-- select CONCAT(STRING(DATE_FORMAT(CURRENT_DATE,'dd')), UPPER(date_format(CURRENT_DATE,'MMM')),STRING(date_format(CURRENT_DATE,'yyyy')));

-- %refresh_var(${current_dt});

DROP TABLE IF EXISTS p_robevans_t.SNEAKERS_RC_MODELS_${current_dt};
CREATE TABLE p_robevans_t.SNEAKERS_RC_MODELS_${current_dt} AS
SELECT * FROM ACCESS_VIEWS.CTLG_SNEAKER_AG_DTL;



----------------------------------------------------------------------------------
-----------------------------STEP 1. CLEANING THE MODEL LIST----------------------
----------------------------------------------------------------------------------

----------CLEANING MPN COLUMN-----------
DROP TABLE IF EXISTS p_robevans_t.STYLE_CODE; 
CREATE TABLE p_robevans_t.STYLE_CODE AS
SELECT MPN2,MPN3,MLG_FLAG,GOAT_FLAG,STOCKX_FLAG,ASPECT_NAME,MODEL_TITLE,
CASE WHEN UPPER(BRAND) IN ('NIKE','JORDAN') AND Lower(MODEL_TITLE) LIKE '%jordan%' THEN 'Jordan' ELSE BRAND END AS BRAND, LAUNCH_DATE
FROM 
	(
	SELECT
		REGEXP_REPLACE(UPPER(STYLE_CD),'[^A-Z0-9]+','') AS MPN2, ---KEEP ONLY ALPHA NUMERIC VALUES
		CONCAT('%',REGEXP_REPLACE(UPPER(STYLE_CD),'[^A-Z0-9]+',''),'%') AS MPN3, ---KEEP ONLY ALPHA NUMERIC VALUES
		MAX(MLG_FLAG) as MLG_FLAG,
		MAX(GOAT_FLAG) as GOAT_FLAG,
		MAX(STOCKX_FLAG) AS STOCKX_FLAG,
		MAX(REGEXP_REPLACE(MODEL_TXT,'\'|\"','')) AS ASPECT_NAME, ---REMOVES SPECIAL CHARACTERS BEFORE OR AFTER WORDS
		MAX(COALESCE(REGEXP_REPLACE(CASE WHEN TITLE_TXT='hite' THEN NULL ELSE TITLE_TXT END,'\'|\"',''),REGEXP_REPLACE(MODEL_TXT,'\'|\"',''))) AS MODEL_TITLE, ---REMOVES SPECIAL CHARACTERS BEFORE OR AFTER WORDS
		MAX(REGEXP_REPLACE(BRAND_TXT,'[^A-Za-z0-9]+','')) AS BRAND, ---KEEP ONLY ALPHA NUMERIC VALUES
		MAX(RELEASE_DT) AS LAUNCH_DATE  ---DEDUPING IN CASE A MODEL HAS TWO REALEASE DATES
	FROM p_robevans_t.SNEAKERS_RC_MODELS_${current_dt}
	WHERE 1=1
		AND STYLE_CD IS NOT NULL
		AND LENGTH(REGEXP_REPLACE(UPPER(STYLE_CD),'[^A-Z0-9]+',''))>=5 -- Removing MPNs with less than 5 characters length(removes approx 1K models)
	GROUP BY 1,2
	)a;



----------------------------------------------------------------------------------
-----------------------------STEP 2. CREATING LISTING BASE------------------------
----------------------------------------------------------------------------------
DROP TABLE IF EXISTS p_robevans_t.SNKR_RC_LSTG;
CREATE TABLE p_robevans_t.SNKR_RC_LSTG AS 
SELECT
	ITEM_ID,
	AUCT_END_DT,
	AUCT_START_DT,
	AUCT_TITL AS AUCT_TITL_OLD,
	CASE WHEN (ARRAY_CONTAINS(SPLIT(UPPER(AUCT_TITL)," "), 'LAKERS'))=1  THEN CONCAT(AUCT_TITL," Laker") ELSE AUCT_TITL END AS AUCT_TITL, --- THIS IS DONE TO TAKE CARE OF A SPECIFIC CASE
	SLR_ID,
	  CASE 
	  WHEN BIN_PRICE_USD >= RSRV_PRICE_USD AND BIN_PRICE_USD >= START_PRICE_USD THEN BIN_PRICE_USD 
	  WHEN RSRV_PRICE_USD >= BIN_PRICE_USD AND RSRV_PRICE_USD >= START_PRICE_USD THEN RSRV_PRICE_USD
	  WHEN START_PRICE_USD >= BIN_PRICE_USD AND START_PRICE_USD >= BIN_PRICE_USD THEN START_PRICE_USD
	  ELSE START_PRICE_USD 
	  END AS ITEM_PRICE_LSTG,
	CASE WHEN lstg.LEAF_CATEG_ID = 15709 THEN 'Men Shoes' ELSE 'Women Shoes' END AS SHOE_GENDER,
	CASE WHEN AUCT_TYPE_CODE IN (7, 9) THEN 'FP' ELSE 'Auction' END AS SALE_TYPE,
	QTY_AVAIL,
	Current_Date AS UPDATE_DATE,
	1 AS LL
FROM ACCESS_VIEWS.DW_LSTG_ITEM lstg
INNER JOIN DW_CAL_DT cal
	on AUCT_START_DT <= cal.CAL_DT
	and AUCT_END_DT >= cal.CAL_DT
	and cal.retail_year in (2022,2023)
	and cal.AGE_FOR_RTL_WEEK_ID < 0
INNER JOIN P_INVENTORYPLANNING_T.dw_category_groupings_adj CAT
	ON lstg.LEAF_CATEG_ID = CAT.LEAF_CATEG_ID
	AND cat.site_id = 3
WHERE 1=1
	AND ! AUCT_TYPE_CODE IN(10, 12, 13, 15)
	AND UPPER(WACKO_YN) = 'N'
	AND SLR_CNTRY_ID IN (3) ---UK SELLER LISTINGS ONLY
	AND CATEG_LVL4_ID IN (15709,95672,155202,57974,57929) ---Only Sneaker listings
	AND ITEM_SITE_ID IN (3) ---LISTINGS ON UK SITE
; 


---------------------------------------------------------------------------------------------------------------
-----------------------------STEP 3A. CREATING MPN to ITEM mapping through PRODUCT IDS-------------------------
---------------------------------------------------------------------------------------------------------------

DROP TABLE IF EXISTS p_robevans_t.SNEAKER_ITEM_MPN_PRODUCT_MATCH;
CREATE TABLE p_robevans_t.SNEAKER_ITEM_MPN_PRODUCT_MATCH STORED AS ORC AS
SELECT ITM.ITEM_ID,
	ITM.AUCT_END_DT,
	ITM.ITEM_PRICE_LSTG,
	MPN.ASPECT_NAME,
	MPN.LAUNCH_DATE,
	MPN.BRAND,
	MPN.MPN2,
	MPN.MLG_FLAG,
	MPN.GOAT_FLAG,
	MPN.STOCKX_FLAG,
	MPN.ASPECT_NAME AS ASPCT_VLU_NM_MODIF,
	MPN.MODEL_TITLE,
	1 AS exact_match_flag,
	0 as PRIORITY,
	1 AS PRIORITY2, ----PRIORITY IS 
	-99 AS SORT_ORDER
from p_robevans_t.SNKR_RC_LSTG ITM    -- item level table
INNER JOIN ACCESS_VIEWS.CTLG_ITEM_FACT CTLG_ITM  -- item level table
	ON ITM.ITEM_ID=CTLG_ITM.ITEM_ID
INNER JOIN ACCESS_VIEWS.CTLG_PROD_FACT epid  -- Product reference id level table
	ON epid.Prod_ref_id=CTLG_ITM.PROD_REF_ID
	AND SITE_ID = 3
INNER JOIN p_robevans_t.STYLE_CODE mpn
	ON REGEXP_REPLACE(UPPER(epid.mpn_TXT),'[^A-Z0-9]+','')=mpn.MPN2

;



----------------------------------------------------------------------------------
-----------------------------STEP 3B. CREATING ASPECT BASE-------------------------
----------------------------------------------------------------------------------
----TABLES USED--
/*1. DW LISTINGG FOR TITLE
2. ASPECT FROM ITEM ASPECT
3. CATELOG TABLE FOR TITLE AND MPN
-REMOVING SPACES FOR MPN SEARCH AND RETAINING SPACS FOR KW SEARCH
*/

----------------------AUCTION TITLE-----------------
DROP TABLE IF EXISTS p_robevans_t.SNKR_RC_LSTG_ASPCT;
CREATE TABLE p_robevans_t.SNKR_RC_LSTG_ASPCT AS -- Temporary
----MPN FROM CTLG_ITEM_FACT---------
SELECT 
	LC.ITEM_ID,
	LC.AUCT_END_DT,
	ITEM.ITEM_PRICE_LSTG,
	CAST('CLTG_MPN' AS VARCHAR (1000))AS PRDCT_ASPCT_NM,
	CAST('DF' AS VARCHAR (1000)) AS NS_TYPE_CD,
	0 AS PRIORITY,
	REGEXP_REPLACE(UPPER(LC.MPN_TXT), '[^A-Z0-9\ ]+',' ') AS KW,
	REGEXP_REPLACE(UPPER(LC.MPN_TXT),'[^A-Z0-9]+','') AS ASPCT_VLU_NM_MODIF

FROM ACCESS_VIEWS.CTLG_ITEM_FACT LC
INNER JOIN p_robevans_t.SNKR_RC_LSTG ITEM
	ON LC.ITEM_ID = ITEM.ITEM_ID 
	AND LC.AUCT_END_DT = ITEM.AUCT_END_DT 
INNER JOIN P_INVENTORYPLANNING_T.dw_category_groupings_adj CAT
	ON LC.LEAF_CATEG_ID = CAT.LEAF_CATEG_ID
	AND cat.site_id = 3

WHERE 1=1
	AND LC.ITEM_SITE_ID IN (3)
	AND CATEG_LVL4_ID IN (15709,95672,155202,57974,57929) ---Only Sneaker listings
	AND LC.SLR_CNTRY_ID IN (3)

UNION ALL

----ALL ASPECTS FROM ITEM ASPECT CLASSIFICATION---------
SELECT 
	ASPCT.ITEM_ID,
	ASPCT.AUCT_END_DT,
	ITEM.ITEM_PRICE_LSTG,
	ASPCT.PRDCT_ASPCT_NM,
	ASPCT.NS_TYPE_CD,
	1 AS PRIORITY,
	REGEXP_REPLACE(UPPER(ASPCT.ASPCT_VLU_NM), '[^A-Z0-9\ ]+',' ') AS KW,
	REGEXP_REPLACE(UPPER(ASPCT.ASPCT_VLU_NM), '[^A-Z0-9]+', '') AS ASPCT_VLU_NM_MODIF
FROM ACCESS_VIEWS.ITEM_ASPCT_CLSSFCTN ASPCT
INNER JOIN p_robevans_t.SNKR_RC_LSTG ITEM
	ON ASPCT.ITEM_ID = ITEM.ITEM_ID 
	AND ASPCT.AUCT_END_DT = ITEM.AUCT_END_DT
WHERE 1=1
	AND UPPER(NS_TYPE_CD) IN ('NF', 'DF')
	AND UPPER(PRDCT_ASPCT_NM) IN ( 'MPN' ,'IDSET_MPN','MANUFACTURER PRODUCT ID', 'STYLE CODE','PRODUCTTITLE')


UNION ALL

----LISTING TITLE AS ASPECT FROM SNEAKERS LISTING TABLE (CREATED ABOVE)---------
SELECT 
	ITEM_ID,
	AUCT_END_DT,
	ITEM_PRICE_LSTG,
	CAST('TITLE' AS VARCHAR (1000))AS PRDCT_ASPCT_NM,
	CAST('TITL' AS VARCHAR (1000)) AS NS_TYPE_CD,
	1 AS PRIORITY,
	REGEXP_REPLACE(UPPER(AUCT_TITL), '[^A-Z0-9\ ]+',' ') AS KW,
	REGEXP_REPLACE(UPPER(AUCT_TITL), '[^A-Z0-9]+','') AS ASPCT_VLU_NM_MODIF
FROM p_robevans_t.SNKR_RC_LSTG

UNION ALL

----CATELOG TITLE FROM CTLG_ITEM_FACT---------
SELECT 
	LC.ITEM_ID,
	LC.AUCT_END_DT,
	ITEM.ITEM_PRICE_LSTG,
	CAST('CLTG_TITLE' AS VARCHAR (1000))AS PRDCT_ASPCT_NM,
	CAST('DF' AS VARCHAR (1000)) AS NS_TYPE_CD,
	1 AS PRIORITY,
	REGEXP_REPLACE(UPPER(LC.ITEM_TITLE_TXT), '[^A-Z0-9\ ]+',' ') AS KW,
	REGEXP_REPLACE(UPPER(LC.ITEM_TITLE_TXT), '[^A-Z0-9]+', '') AS ASPCT_VLU_NM_MODIF

FROM ACCESS_VIEWS.CTLG_ITEM_FACT LC
INNER JOIN P_INVENTORYPLANNING_T.dw_category_groupings_adj CAT
	ON LC.LEAF_CATEG_ID = CAT.LEAF_CATEG_ID
	AND cat.site_id = 3
INNER JOIN p_robevans_t.SNKR_RC_LSTG ITEM
	ON LC.ITEM_ID = ITEM.ITEM_ID 
	AND LC.AUCT_END_DT = ITEM.AUCT_END_DT 
	AND LC.ITEM_SITE_ID IN (3)
	AND CATEG_LVL4_ID IN (15709,95672,155202,57974,57929) ---Only Sneaker listings
	AND LC.SLR_CNTRY_ID IN (3)

;

select count(*) from p_robevans_t.SNKR_RC_LSTG_ASPCT;
-- 43,692,243
----------------------------------------------------------------------------------
-----------------------------STEP 4. MATCHING MODELS TO ITEMS---------------------
----------------------------------------------------------------------------------


---------------------------4.a MPN MATCH-----------------
DROP TABLE IF EXISTS p_robevans_t.MPN_MATCH_exact;
CREATE TABLE p_robevans_t.MPN_MATCH_exacT AS -- Temporary
SELECT 
	LSTG_ASPECT_BASE.ITEM_ID,
	LSTG_ASPECT_BASE.AUCT_END_DT,
	LSTG_ASPECT_BASE.ITEM_PRICE_LSTG,
	EXACT_MPN_MATCH.ASPECT_NAME,
	EXACT_MPN_MATCH.MODEL_TITLE,
	EXACT_MPN_MATCH.LAUNCH_DATE,
	EXACT_MPN_MATCH.BRAND,
	EXACT_MPN_MATCH.MPN2,
	EXACT_MPN_MATCH.MLG_FLAG,
	EXACT_MPN_MATCH.GOAT_FLAG,
	EXACT_MPN_MATCH.STOCKX_FLAG,
	ASPCT_VLU_NM_MODIF,
	CASE WHEN EXACT_MPN_MATCH.MPN2 IS NOT NULL THEN 1 ELSE 0 END AS exact_match_flag,
	PRIORITY,
	CASE
		WHEN LSTG_ASPECT_BASE.NS_TYPE_CD = 'DF' AND UPPER(LSTG_ASPECT_BASE.PRDCT_ASPCT_NM) IN ( 'CLTG_MPN', 'MPN' ,'IDSET_MPN','MANUFACTURER PRODUCT ID', 'STYLE CODE') THEN 0
		WHEN LSTG_ASPECT_BASE.PRIORITY = 1 AND LSTG_ASPECT_BASE.NS_TYPE_CD = 'TITL' THEN 1
		WHEN LSTG_ASPECT_BASE.NS_TYPE_CD = 'DF' AND UPPER(LSTG_ASPECT_BASE.PRDCT_ASPCT_NM) = 'CLTG_TITLE' THEN 2
		WHEN LSTG_ASPECT_BASE.NS_TYPE_CD = 'DF' AND UPPER(LSTG_ASPECT_BASE.PRDCT_ASPCT_NM) = 'PRODUCTTITLE' THEN 3
		ELSE 4 END AS PRIORITY2, ----PRIORITY IS 
	-99 AS SORT_ORDER
FROM p_robevans_t.SNKR_RC_LSTG_ASPCT LSTG_ASPECT_BASE ---LISTING BASE
INNER JOIN p_robevans_t.STYLE_CODE EXACT_MPN_MATCH
	ON LSTG_ASPECT_BASE.ASPCT_VLU_NM_MODIF = EXACT_MPN_MATCH.MPN2
	AND LSTG_ASPECT_BASE.NS_TYPE_CD = 'DF' 
	AND UPPER(LSTG_ASPECT_BASE.PRDCT_ASPCT_NM) IN ( 'CLTG_MPN', 'MPN' ,'IDSET_MPN','MANUFACTURER PRODUCT ID', 'STYLE CODE')

QUALIFY ROW_NUMBER() OVER(PARTITION BY ITEM_ID ORDER BY PRIORITY, PRIORITY2 ) = 1

;


SELECT exact_match_flag,PRIORITY,PRIORITY2,COUNT(*),COUNT(DISTINCT ITEM_ID),SUM(CASE WHEN MPN2 IS NOT NULL THEN 1 ELSE 0 END) AS MPN_CNT FROM p_robevans_t.MPN_MATCH_exacT
group by 1,2,3;
/*
exact_match_flag	PRIORITY	PRIORITY2	count(1)	count(DISTINCT ITEM_ID)	MPN_CNT
1	0	0	2964685	2964685	2964685
*/



DROP TABLE IF EXISTS p_robevans_t.ASPCT_MATCH_NON_EXACT_BASE;
CREATE TABLE p_robevans_t.ASPCT_MATCH_NON_EXACT_BASE AS  -- Temporary

SELECT ASPCT_VLU_NM_MODIF,
	ASPCT.ITEM_ID,
	AUCT_END_DT,
	ITEM_PRICE_LSTG,
	MIN(PRIORITY) as PRIORITY,
	MIN(CASE WHEN NS_TYPE_CD = 'DF' AND UPPER(PRDCT_ASPCT_NM) IN ( 'CLTG_MPN', 'MPN' ,'IDSET_MPN','MANUFACTURER PRODUCT ID', 'STYLE CODE') THEN 0
		ELSE 1 END) AS PRIORITY2
FROM  p_robevans_t.SNKR_RC_LSTG_ASPCT ASPCT
LEFT JOIN
	(
	SELECT ITEM_ID
	FROM p_robevans_t.MPN_MATCH_exact
	GROUP BY 1
	) MPN_MATCH
		ON ASPCT.ITEM_ID=MPN_MATCH.ITEM_ID
WHERE 1=1
	AND MPN_MATCH.ITEM_ID IS NULL
	AND ASPCT_VLU_NM_MODIF IS NOT NULL
group by 1,2,3,4
;


-- select COUNT(*),COUNT(DISTINCT ITEM_ID) FROM p_robevans_t.ASPCT_MATCH_NON_EXACT_BASE;

DROP TABLE IF EXISTS p_robevans_t.MPN_LIKE_MATCH;
CREATE TABLE p_robevans_t.MPN_LIKE_MATCH AS -- Temporary

SELECT 
	LSTG_ASPECT_BASE.ITEM_ID,
	LSTG_ASPECT_BASE.AUCT_END_DT,
	LSTG_ASPECT_BASE.ITEM_PRICE_LSTG,
	STYLE_CODE_LIST.ASPECT_NAME,
	STYLE_CODE_LIST.LAUNCH_DATE,
	STYLE_CODE_LIST.BRAND,
	STYLE_CODE_LIST.MPN2,
	STYLE_CODE_LIST.MLG_FLAG,
	STYLE_CODE_LIST.GOAT_FLAG,
	STYLE_CODE_LIST.STOCKX_FLAG,
	ASPCT_VLU_NM_MODIF,
	0 as exact_match_flag,
	PRIORITY,
	PRIORITY2, ----PRIORITY IS 
	-99 AS SORT_ORDER

FROM p_robevans_t.STYLE_CODE STYLE_CODE_LIST
INNER JOIN p_robevans_t.ASPCT_MATCH_NON_EXACT_BASE LSTG_ASPECT_BASE ---LISTING BASE
	ON LSTG_ASPECT_BASE.ASPCT_VLU_NM_MODIF LIKE MPN3

QUALIFY ROW_NUMBER() OVER(PARTITION BY ITEM_ID ORDER BY PRIORITY, PRIORITY2 ) = 1


-- select count(*) from p_robevans_t.ASPCT_MATCH_NON_EXACT_BASE




-----------------------------Creating new listing table with all matched MPNs------------------------------

DROP TABLE IF EXISTS  p_robevans_t.SNKR_RC_SNKR_LSTG_BASE_V2;
CREATE TABLE p_robevans_t.SNKR_RC_SNKR_LSTG_BASE_V2 
SELECT 
	MATCHED.ITEM_ID,
	MATCHED.AUCT_END_DT,
	L.AUCT_START_DT,
	L.SHOE_GENDER,
	L.SALE_TYPE,
	L.QTY_AVAIL,
	L.UPDATE_DATE,
	L.LL,
	L.SLR_ID,
	MATCHED.ITEM_PRICE_LSTG,
	MATCHED.ASPECT_NAME,
	MATCHED.LAUNCH_DATE,
	BRAND.BRAND,
	MATCHED.MPN2,
	MATCHED.MLG_FLAG,MATCHED.GOAT_FLAG,MATCHED.STOCKX_FLAG,
	MATCHED.ASPCT_VLU_NM_MODIF,
	MATCHED.MODEL_TITLE,
	MATCHED.PRIORITY,
	MATCHED.PRIORITY2,
	MATCHED.SORT_ORDER
FROM 
	(
	SELECT 
		ITEM_ID,
		AUCT_END_DT,
		ITEM_PRICE_LSTG,
		ASPECT_NAME,
		LAUNCH_DATE,
		BRAND,
		MPN2,
		MLG_FLAG,GOAT_FLAG,STOCKX_FLAG,
		ASPCT_VLU_NM_MODIF,
		MODEL_TITLE,
		0 AS PRIORITY,
		0 AS PRIORITY2,
		SORT_ORDER
	FROM p_robevans_t.MPN_MATCH_exacT

	UNION ALL

	SELECT 
		ITEM_ID,
		AUCT_END_DT,
		ITEM_PRICE_LSTG,
		ASPECT_NAME,
		LAUNCH_DATE,
		BRAND,
		MPN2,
		MLG_FLAG,GOAT_FLAG,STOCKX_FLAG,
		ASPCT_VLU_NM_MODIF,
		MODEL_TITLE,
		PRIORITY,
		PRIORITY2,
		SORT_ORDER
	FROM p_robevans_t.SNEAKER_ITEM_MPN_PRODUCT_MATCH

-- 	UNION ALL

-- 	SELECT 
-- 		MATCH.ITEM_ID,
-- 		MATCH.AUCT_END_DT,
-- 		MATCH.ITEM_PRICE_LSTG,
-- 		MATCH.ASPECT_NAME,
-- 		MATCH.LAUNCH_DATE,
-- 		MATCH.BRAND,
-- 		MATCH.MPN2,
-- 		MATCH.MLG_FLAG,
-- 		MATCH.GOAT_FLAG,
-- 		MATCH.STOCKX_FLAG,
-- 		MATCH.ASPCT_VLU_NM_MODIF,
-- 		MPN.MODEL_TITLE,
-- 		1 AS PRIORITY,
-- 		MATCH.PRIORITY2,
-- 		MATCH.SORT_ORDER
-- 	FROM p_robevans_t.MPN_LIKE_MATCH MATCH
-- 	LEFT JOIN p_robevans_t.STYLE_CODE MPN
-- 		ON MPN.MPN2=MATCH.MPN2
-- 	WHERE UPPER(MATCH.MPN2)!='RETRO' 
	) MATCHED
INNER JOIN p_robevans_t.SNKR_RC_LSTG L
	ON L.ITEM_ID=MATCHED.ITEM_ID
	AND L.AUCT_END_DT=MATCHED.AUCT_END_DT
LEFT JOIN
	(
	SELECT MPN2
		,MIN(BRAND) as BRAND
	FROM p_robevans_t.STYLE_CODE GROUP BY 1
	)brand
		ON MATCHED.MPN2=brand.MPN2

WHERE 1=1
	AND ((PRIORITY = 0) OR (PRIORITY = 1 AND PRIORITY2 = 1))
	AND MODEL_TITLE IS NOT NULL

QUALIFY ROW_NUMBER() Over(PARTITION BY ITEM_ID ORDER BY  PRIORITY,PRIORITY2, SORT_ORDER ) = 1

;

drop TABLE if exists p_robevans_t.SNKR_RC_SNKR_LSTG_BASE;
CREATE TABLE p_robevans_t.SNKR_RC_SNKR_LSTG_BASE
CLUSTERED BY (ITEM_ID,AUCT_END_DT) 
SORTED BY (AUCT_END_DT)
INTO 4000 BUCKETS

-- select *
-- from p_robevans_t.SNKR_RC_SNKR_LSTG_BASE_V1
-- -- WHERE AUCT_START_DT<=CURRENT_DATE-8
-- UNION ALL
-- select *
-- from p_robevans_t.SNKR_RC_SNKR_LSTG_BASE_V2
-- -- WHERE AUCT_START_DT>CURRENT_DATE-8;
-- ;



-- -- 
-- DROP TABLE IF EXISTS p_robevans_t.SNKR_RC_SNKR_LSTG_BASE_V1;
-- CREATE TABLE p_robevans_t.SNKR_RC_SNKR_LSTG_BASE_V1 AS
-- select * from p_robevans_t.SNKR_RC_SNKR_LSTG_BASE;


-------------------------------------------------------------------------------------END-----------------------------------------------------------------------------------------

SELECT CURRENT_TIMESTAMP;

------------------------------------------------------------------------------------------------
---------------------Sales of models in the latest 26 weeks-------------------------------------
------------------------------------------------------------------------------------------------

-------------------ITEM VARIATION LEVEL TRANSACTION BASE-----------------------------------
DROP TABLE IF EXISTS TRANS_BASE;
CREATE TEMPORARY TABLE TRANS_BASE AS
/*				
INSERT INTO TRANS_BASE*/
SELECT
	case when age_from_launch_date <= (30*6) then 'Y'
		else 'N'
		End as new_drop_flag,
	PRICE_BUCKET,
	sum(GMV_USD_2023) as GMV_USD_2023,
	sum(GMV_USD_2022) as GMV_USD_2022,
	sum(SI_2023) as SI_2023,
	sum(SI_2022) as SI_2022
FROM
(
SELECT
-- 	GMV_DT AS CAL_DT,
-- 	CK.ITEM_ID,
-- 	LSTG.AUCT_END_DT,
-- 	LSTG.AUCT_START_DT,
-- 	-- 			  CK.TRANSACTION_ID,
-- 	L.AUCT_TITL,
-- 	LSTG.LAUNCH_DATE,
-- 	LSTG.ITEM_PRICE_LSTG,
-- 	LSTG.BRAND AS BRAND,
-- 	LSTG.ASPECT_NAME as MODEL,
-- 	LSTG.MODEL_TITLE,
-- 	LSTG.SHOE_GENDER,
-- 	LSTG.MPN2,
	CASE
		WHEN Cast(ck.item_price*LPR.CURNCY_PLAN_RATE AS DECIMAL(18,2))  < 100  THEN 'A. <£86 (<$100)'
		WHEN Cast(ck.item_price AS DECIMAL(18,2))  < 100 THEN 'B. £86-£100 ($100-£100)'
		Else 'C. >= £100'
		END AS PRICE_BUCKET,
	FLOOR((GMV_DT-LAUNCH_DATE)/7) AS AGE_FROM_LAUNCH_WEEK,
	GMV_DT-LAUNCH_DATE AS AGE_FROM_LAUNCH_DATE,
-- 	GMV_DT-CURRENT_DATE AS AGE_FROM_CURRENT_DATE,
-- 	SELLER_ID,
-- 	CK.ITEM_VRTN_ID,	
-- 	LSTG.SALE_TYPE,
-- 	CK.BUYER_ID,
	SUM(case when cal.RETAIL_YEAR = 2023 then CK.GMV_LC_AMT*lpr.CURNCY_PLAN_RATE end) AS GMV_USD_2023,
	SUM(case when cal.RETAIL_YEAR = 2022 then CK.GMV_LC_AMT*lpr.CURNCY_PLAN_RATE end) AS GMV_USD_2022,
	SUM(case when cal.RETAIL_YEAR = 2023 then CK.core_item_cnt end) AS SI_2023,
	SUM(case when cal.RETAIL_YEAR = 2022 then CK.core_item_cnt end) AS SI_2022,

	SUM(CK.CORE_ITEM_CNT) AS SI 
FROM p_robevans_t.SNKR_RC_SNKR_LSTG_BASE_V2 Lstg ---- Table that has New release models mapped to items in DW
INNER JOIN DW_LSTG_ITEM L --to get auction title
	ON L.ITEM_ID=Lstg.ITEM_ID
INNER JOIN DW_CHECKOUT_TRANS CK --to get transactional data
	ON  Lstg.ITEM_ID=CK.ITEM_ID	
	AND Lstg.AUCT_END_DT=CK.AUCT_END_DT
INNER JOIN access_views.ssa_curncy_plan_rate_dim AS lpr -- currency plan rate to get final item price
	ON lpr.curncy_id=ck.lstg_curncy_id
-- INNER JOIN ACCESS_VIEWS.DW_USERS SLR --- to get seller name
-- 	ON CK.SELLER_ID=SLR.USER_ID
-- INNER JOIN ACCESS_VIEWS.DW_USERS BYR --to get buyer name
-- 	ON CK.BUYER_ID=BYR.USER_ID
-- LEFT JOIN prs_restricted_v.dna_cust_seller_sgmntn_hist AS hist --to get seller segment during the time of transaction
-- 	ON CK.GMV_DT BETWEEN  hist.cust_slr_sgmntn_beg_dt AND hist.cust_slr_sgmntn_end_dt 
-- 	AND hist.slr_id = l.slr_id
-- 	AND hist.cust_sgmntn_grp_cd BETWEEN  36 AND 41
-- LEFT JOIN prs_restricted_v.cust_sgmntn AS lkp
-- 	ON hist.cust_sgmntn_cd=lkp.cust_sgmntn_cd
INNER JOIN ACCESS_VIEWS.DW_CAL_DT CAL
	ON CAL.CAL_DT=CK.GMV_DT
	and cal.retail_year in (2022,2023)
	and cal.retail_week <= (select retail_week from DW_CAL_DT where AGE_FOR_RTL_WEEK_ID = -1 group by 1)

WHERE 1=1
-- 				AND  ((CK.GMV_DT BETWEEN LAUNCH_DATE-28 AND LAUNCH_DATE+49) --considering transactions in pre 4weeks and post 6 	
-- 						OR (CK.GMV_DT BETWEEN CURRENT_DATE-30 AND CURRENT_DATE-1))
-- 				AND CK.GMV_DT BETWEEN '2022-01-01' AND CURRENT_DATE-1
	AND ! ck.sale_type IN(10,12,14,15) 
	AND UPPER(ck.ck_wacko_yn)='N'
	AND ck.slr_cntry_id = 3  ---Only UK Sellers
	AND ck.site_id = 3

GROUP BY 1,2,3
)
Group by 1,2



















----------------------------------------------------Demand-------------------------------------




SELECT
	match_check,
	case when age_from_launch_date <= (30*6) then 'Y'
		else 'N'
		End as new_drop_flag,
	PRICE_BUCKET,
	sum(GMV_USD_2023) as GMV_USD_2023,
	sum(GMV_USD_2022) as GMV_USD_2022,
	sum(SI_2023) as SI_2023,
	sum(SI_2022) as SI_2022,
	sum(lstg_count_2023) as lstg_count_2023,
	sum(lstg_count_2022) as lstg_count_2022
FROM
(
SELECT
	case when ck.item_id = lstg.item_id then 'Matched' else' Unmatched' end as match_check,
	CASE
		WHEN Cast(ck.item_price*LPR.CURNCY_PLAN_RATE AS DECIMAL(18,2))  < 100  THEN 'A. <£86 (<$100)'
		WHEN Cast(ck.item_price AS DECIMAL(18,2))  < 100 THEN 'B. £86-£100 ($100-£100)'
		Else 'C. >= £100'
		END AS PRICE_BUCKET,
	FLOOR((GMV_DT-LAUNCH_DATE)/7) AS AGE_FROM_LAUNCH_WEEK,
	GMV_DT-LAUNCH_DATE AS AGE_FROM_LAUNCH_DATE,
	SUM(case when cal.RETAIL_YEAR = 2023 then CK.GMV_LC_AMT*lpr.CURNCY_PLAN_RATE end) AS GMV_USD_2023,
	SUM(case when cal.RETAIL_YEAR = 2022 then CK.GMV_LC_AMT*lpr.CURNCY_PLAN_RATE end) AS GMV_USD_2022,
	SUM(case when cal.RETAIL_YEAR = 2023 then CK.core_item_cnt end) AS SI_2023,
	SUM(case when cal.RETAIL_YEAR = 2022 then CK.core_item_cnt end) AS SI_2022,
	count(distinct case when cal.RETAIL_YEAR = 2023 then CK.item_id end) AS lstg_count_2023,
	count(distinct case when cal.RETAIL_YEAR = 2022 then CK.item_id end) AS lstg_count_2022

FROM DW_CHECKOUT_TRANS CK
INNER JOIN P_INVENTORYPLANNING_T.dw_category_groupings_adj CAT
	ON ck.LEAF_CATEG_ID = CAT.LEAF_CATEG_ID
	AND cat.site_id = 3
INNER JOIN access_views.ssa_curncy_plan_rate_dim AS lpr -- currency plan rate to get final item price
	ON lpr.curncy_id=ck.lstg_curncy_id
INNER JOIN ACCESS_VIEWS.DW_CAL_DT CAL
	ON CAL.CAL_DT=CK.GMV_DT
	and cal.retail_year in (2022,2023)
	and cal.retail_week <= (select retail_week from DW_CAL_DT where AGE_FOR_RTL_WEEK_ID = -1 group by 1)
LEFT JOIN
	(select ITEM_ID
		,max(launch_date) as launch_date
	From p_robevans_t.SNKR_RC_SNKR_LSTG_BASE_V2
	Group by 1
	) Lstg ---- Table that has New release models mapped to items in DW
		on ck.item_id = lstg.item_id

WHERE 1=1
	AND ! ck.sale_type IN(10,12,14,15) 
	AND UPPER(ck.ck_wacko_yn)='N'
	AND ck.slr_cntry_id = 3  ---Only UK Sellers
	AND ck.site_id = 3
	and cat.CATEG_LVL4_ID IN (15709,95672,155202,57974,57929) 

GROUP BY 1,2,3,4
)
Group by 1,2,3






----------------------------------------------------Supply-------------------------------------

select RETAIL_YEAR,
	PRICE_BUCKET,
	case when age_from_launch_date <= (30*6) then 'Y'
		else 'N'
		End as new_drop_flag,	
	sum(ll) as ll
FROM
(
select 
	cal.RETAIL_YEAR,
	CASE
		WHEN item_price_lstg < 100  THEN 'A. <$100'
		Else 'B. >= $100'
		END AS PRICE_BUCKET,
	auct_start_dt-LAUNCH_DATE AS AGE_FROM_LAUNCH_DATE,
	count(distinct lstg.item_id) as ll
from p_robevans_t.SNKR_RC_SNKR_LSTG_BASE_V2 lstg
inner join DW_CAL_DT cal
	on lstg.auct_start_dt = cal.CAL_DT
	and cal.RETAIL_YEAR in (2022,2023)
	and cal.RETAIL_WEEK <= (select retail_week from DW_CAL_DT where AGE_FOR_RTL_WEEK_ID = -1 group by 1)
Where launch_date is not null
Group by 1,2,3
)
GRoup by 1,2,3