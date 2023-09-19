-- JIRA Ticket:     UKPLAN-559

-- Author: 			Robbie Evans
-- Stakeholder: 	Wahaaj Shabbir
-- Purpose: 		Responsible.us are launching a buyback programme in the UK for pre-loved sneakers in partnership with Crep, with the inventory coming on to ebay. They have created a buy back platform for customers to cash out their pre-loved sneakers but they need help from us around pricing info to enable them to cash people out at the appropriate price.
-- Date Created: 	19/09/2023




create table P_ROBEVANS_T.SNEAKERS_STYLE_CODE_ASPS as

-- UK
SELECT
*
FROM
(
	SELECT
		s.MPN as StyleCode,
		P.SITE_NAME,
		s.BRAND,
		case when s.leaf_categ_id = 155202 then 'Kids'
		     when s.leaf_categ_id = 15709 then 'Men'
			 when s.leaf_categ_id = 95672 then 'Women'
	    end as DEPARTMENT,
		s.RELEASE_DATE,
	-- 	LEFT(release_date,4) as RELEASE_YEAR,
		CASE 
			WHEN CAST(LEFT(release_date,4) AS INT) BETWEEN 1970 AND YEAR(CURRENT_DATE) + 2 THEN LEFT(release_date,4) -- YYYY-MM-DD
			ELSE RIGHT(release_date,4) -- DD-MM-YYYY
		END AS RELEASE_YEAR,

	-- 	CASE WHEN instr(release_date,'.') in (2,3) THEN SUBSTRING(release_date,4,2)
	-- 	 else SUBSTRING(release_date,5,2)
	-- 	END AS MONTH,
		CASE 
			WHEN CAST(LEFT(release_date,4) AS INT) BETWEEN 1970 AND YEAR(CURRENT_DATE) + 2 THEN SUBSTRING(REPLACE(release_date,'.',''),5,2)
			ELSE SUBSTRING(REPLACE(release_date,'.',''),3,2)
		END AS MONTH,
		CASE
			WHEN MONTH = '01' THEN 'JAN'
			WHEN MONTH = '02' THEN 'FEB'
			WHEN MONTH = '03' THEN 'MAR'
			WHEN MONTH = '04' THEN 'APR'
			WHEN MONTH = '05' THEN 'MAY'
			WHEN MONTH = '06' THEN 'JUN'
			WHEN MONTH = '07' THEN 'JUL'
			WHEN MONTH = '08' THEN 'AUG'
			WHEN MONTH = '09' THEN 'SEP'
			WHEN MONTH = '10' THEN 'OCT'
			WHEN MONTH = '11' THEN 'NOV'
			WHEN MONTH = '12' THEN 'DEC'
		END AS RELEASE_MONTH,
		CASE
			WHEN s.IMG_URL IS NOT NULL THEN 1
			ELSE 0
		END AS IMG_IND,
		CASE
			WHEN s.brws_node_id IS NOT NULL THEN 1
			ELSE 0
		END AS BN_IND,
		max(s.Title) as Product_Title,
		max(CASE WHEN AG_IND IS NULL THEN 0 ELSE AG_IND END) AS ag_IND,
		
		SUM(NEW_FP_L90D_SOLD_QTY) as NEW_L90D_SOLD_QTY,
		SUM(NEW_FP_L90D_GMV_USD_AMT) as NEW_L90D_GMV_USD_AMT,
		SUM(USED_L90D_GMV_USD_AMT) AS USED_L90D_GMV_USD_AMT,
		SUM(USED_L90D_SOLD_QTY) AS USED_L90D_SOLD_QTY,
		SUM(RFRBSHD_L90D_SOLD_QTY) as RFRBSHD_L90D_SOLD_QTY,
		SUM(RFRBSHD_L90D_SOLD_QTY) as RFRBSHD_L90D_GMV_USD_AMT,

		row_number() over (partition by MPN order by product_title) as row_num
	FROM P_CATVERTICALS_T.Sneakers_MLG_Level S --P_CATVERTICALS_T.SNEAKERS_CAT S --replace the old table P_CATVERTICALS_T.SNEAKERS_CAT S
	JOIN CTLG_PROD_FACT P
		ON LOWER(S.MPN) = LOWER(P.MPN_TXT)
		AND P.LEAF_CATEG_ID IN (15709,95672)
		AND P.SITE_NAME = 'UK' -- 
		AND P.LIVE_IND = 1

	WHERE 1=1
	--AND lower(S.MPN) = 'dm7866001' 
	AND S.IN_UK = 1
	GROUP BY 1,2,3,4,5,6,7,8,9,10 --,11,12,13,14,15
)
WHERE 1=1
	AND row_num = 1 -- dedupe for each styelcode
-- 	AND (BN_IND = 1 AND US_BN_URL_IND = 1) -- only get ebay.com browse node url
-- 	OR BN_IND = 0
