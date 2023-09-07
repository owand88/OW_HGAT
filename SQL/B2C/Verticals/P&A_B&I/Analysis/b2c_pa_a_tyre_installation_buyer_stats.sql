-- UKPLAN-490
-- --Requestd by Ian

-- Working on the Tyre Fitting Proposition with marketing and need the following information

-- •	WoW H2 forecast for tyre category L4 
-- • 1.	YoY Variance across 3 Brand specs of tyres:   Budget / Mid Range / Premium – want to show the increase or decline YoY over the past 2 years (YTD) on these classifications
-- • 2. What % of our current tyre buyers are getting tyres fitted – (A split between personal / business would be great)


-- 1. Tyre Brand Growth
select * from P_ukplan_report_T.tableau_pa_tyre_BRAND_KPIs_seller
limit 100;

Select retail_year,
retail_week,
BRAND,
BRAND_MAPPING,
SUM( GMV_PLAN) GMV,
SUM(SI) SI
FROM P_ukplan_report_T.tableau_pa_tyre_BRAND_KPIs_seller
WHERE RETAIL_WEEK BETWEEN 1 AND 30
GROUP BY 1,2,3,4;


-- 2. Tyre buyer and installation adoption 

-- ALL BUYERS: 
drop table if exists   p_InventoryPlanning_t.tyres_install_marketing_stats_all_buyer ; 
create table  p_InventoryPlanning_t.tyres_install_marketing_stats_all_buyer
as 
(
SELECT	
  U.USER_SLCTD_ID,
  ck.SELLER_ID,
  ck.BUYER_ID,
  TRANSACTION_ID,
   CK.CREATED_DT,
   ck.item_id, 
CASE WHEN Retail_year  IN (2018,2019) AND RETAIL_WEEK =1 THEN 2019
WHEN Retail_year  IN (2019,2020) AND RETAIL_WEEK =1 THEN 2020
WHEN Retail_year  IN (2020,2021) AND RETAIL_WEEK =53 THEN 2020
WHEN Retail_year  IN (2021,2022) AND RETAIL_WEEK =52 THEN 2021
ELSE Retail_year end as Retail_year ,
cal.AGE_FOR_QTR_ID,
cal.QTR_OF_YEAR_ID,
cal.RETAIL_week,
case when categ_lvl2_id in (20710, 69197, 185066) then 'Electronics'
		when meta_categ_id in (26395) then 'Lifestyle'
		when CATEG_LVL3_ID in (260325) then 'Lifestyle'
		when categ_lvl2_id in (386, 238, 1202, 49019, 183446, 80546, 222, 11731, 1082, 767, 233, 2613, 1188, 1039, 11743, 19169, 2562, 2616, 436, 14737, 2631, 2624, 717, 16486, 61573, 246) then 'Home & Garden'
		when categ_lvl3_id in (35000, 98989) then 'Home & Garden'
		when categ_lvl3_id in (3244) then 'Parts & Accessories'
		when categ_lvl3_id in (124982, 259225,180969, 260509) then 'Business & Industrial'
		when categ_lvl2_id in (46576) then 'Parts & Accessories'
		--when bsns_vrtcl_name in ('Collectibles') and meta_categ_id in (220, 237, 550)  then 'Collectibles B2C'
		--when bsns_vrtcl_name in ('Collectibles') and categ_lvl2_id in (180250) then 'Collectibles B2C' 
		else bsns_vrtcl_name end as vertical,
meta_categ_id, 
CATEG_LVL2_ID, 
categ_lvl2_name, 
categ_lvl3_name, 
categ_lvl3_id,
categ_lvl4_name, 
categ_lvl4_id,
 QUANTITY,
 item_price,
 GMV_PLAN_USD as  GMV_20
--case when CNDTN_ROLLUP_ID = 1 then 'New' when   CNDTN_ROLLUP_ID = 3 then 'Used' else  CNDTN_ROLLUP_ID  end as Condition,
--SUM(CAST(CK.QUANTITY AS DECIMAL(18,2))* CAST(CK.ITEM_PRICE AS DECIMAL(18,2))*CAST(LPR.CURNCY_PLAN_RATE AS DECIMAL(18,2))) AS GMV,
--sum(QUANTITY) as BI
			FROM   DW_CHECKOUT_TRANS ck
			INNER join ( select distinct BUYER_ID from  p_InventoryPlanning_t.tyres_install_txn ) as  t  on ck.BUYER_ID=t.BUYER_ID
			--INNER JOIN ( select CURNCY_PLAN_RATE,CURNCY_ID from  ACCESS_VIEWS.SSA_CURNCY_PLAN_RATE_DIM group by 1,2)AS LPR 				ON LPR.CURNCY_ID = CK.LSTG_CURNCY_ID
			INNER JOIN ACCESS_VIEWS.DW_CAL_DT CAL ON CAL.CAL_DT = CK.GMV_DT   and retail_year >=2023  and  age_for_rtl_week_id <=-1
			INNER JOIN DW_CATEGORY_GROUPINGS CAT ON CAT.LEAF_CATEG_ID = ck.LEAF_CATEG_ID AND CAT.SITE_ID in(3) AND CAT.SAP_CATEGORY_ID NOT IN (5,7,41,23,-999)
			--ON CAT.LEAF_CATEG_ID = ck.LEAF_CATEG_ID AND CAT.SITE_ID in(3) AND CAT.SAP_CATEGORY_ID NOT IN (5,7,41,23,-999)

			inner JOIN lstg_item_cndtn CNDTN ON ck.item_id = CNDTN.item_id  AND ck.auct_end_dt = CNDTN.AUCT_END_DT
			left outer JOIN DW_USERs U ON U.USER_ID= ck.SELLER_ID 
			
			WHERE 1=1
				and CK.SALE_TYPE NOT IN (10,15)
				--and buyer_id ='1861757700'
				and ck.site_id = 3
				and slr_cntry_id = 3
				--and CATEG_LVL4_ID =179680 
				and SLR_CNTRY_ID=BYR_CNTRY_ID
		
);


DROP TABLE IF EXISTS   p_InventoryPlanning_t.tyres_install_BUYER_MARKETING ;
CREATE TABLE    p_InventoryPlanning_t.tyres_install_BUYER_MARKETING  AS  (
select 
buyer_id, 
B2B_Buyer,
case when GMV_INSTALL <=0 then 0 else 1 end as install_buyer,
case when GMV_TYRES >=10 then 1 else 0 end as tyre_buyer,
sum(GMV_INSTALL ) GMV_INSTALL ,
sum(GMV_TYRES ) as GMV_TYRES
from (
			SELECT a.*,
			case when  A.BUYER_ID=B.PRIMARY_USER_ID then 'Y' else 'N' end as B2B_Buyer
			 FROM ( 
			SELECT 
			BUYER_ID,
			SUM( CASE WHEN   categ_lvl3_name  ='Vehicle Services & Repairs'  THEN GMV_20 ELSE 0 END ) AS GMV_INSTALL , 
			SUM( CASE WHEN   CATEG_LVL4_ID =179680  THEN GMV_20 ELSE 0 END ) AS GMV_TYRES
			FROM  p_InventoryPlanning_t.tyres_install_marketing_stats_all_buyer
			WHERE RETAIL_YEAR =2023 GROUP BY 1 ) A
			LEFT JOIN ( SELECT DISTINCT PRIMARY_USER_ID FROM p_eupricing_t.ymm_b2b_buyers )  B ON A.BUYER_ID=B.PRIMARY_USER_ID
			WHERE  gmv_tyres <>0  )
group by 1,2, 3,4  ); 



select B2B_Buyer
, sum(install_buyer) install_buyer
, sum(tyre_buyer) tyre_buyer ,
sum(GMV_INSTALL ) GMV_INSTALL ,
sum(GMV_TYRES ) as GMV_TYRES
from 
p_InventoryPlanning_t.tyres_install_BUYER_MARKETING 
group by 1 ;

