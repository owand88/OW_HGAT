-- Top 750 seller List-- 20727

/* Pro Trader requested L2 cohorts
Cat_2_ID Cat_2_Name
67659	Natural & Alternative Remedies
67660	Natural & Alternative Remedies
67661	Natural & Alternative Remedies
67662	Natural & Alternative Remedies
67663	Natural & Alternative Remedies
67664	Natural & Alternative Remedies
67665	Natural & Alternative Remedies
67666	Natural & Alternative Remedies
67667	Natural & Alternative Remedies
67668	Natural & Alternative Remedies
67669	Natural & Alternative Remedies
67670	Natural & Alternative Remedies
67671	Natural & Alternative Remedies
15273	Fitness Running Yoga
*/


-- 1. PUll all sellers
 drop table if exists p_InventoryPlanning_t.pro_trader_swimming_seller  ;
 create table p_InventoryPlanning_t.pro_trader_swimming_seller  as(
SELECT	Retail_year
--	,		retail_week	
,		ck.seller_id
--	,		USER_SLCTD_ID
,  cat.CATEG_LVL2_NAME
,  cat.CATEG_LVL2_ID
--   ,case when CNDTN_ROLLUP_ID = 1 then 'New' when   CNDTN_ROLLUP_ID = 3 then 'Used'  when   CNDTN_ROLLUP_ID = 2 then 'Refurb' else  'Other'  end as Condition
,  SUM(gmv_plan_usd) AS GMV_usd
, sum(QUANTITY) as BI
FROM   DW_CHECKOUT_TRANS ck -- SELECT * FROM   DW_CHECKOUT_TRANS  where seller_id= 45524941
INNER JOIN ( select CURNCY_PLAN_RATE,CURNCY_ID from  ACCESS_VIEWS.SSA_CURNCY_PLAN_RATE_DIM group by 1,2)AS SSA
				ON SSA.CURNCY_ID = CK.LSTG_CURNCY_ID
INNER JOIN ACCESS_VIEWS.DW_CAL_DT CAL ON CAL.CAL_DT = CK.gmv_DT   and retail_year >=2022 and age_for_rtl_week_id <= -1  --change here for time period if needed
INNER JOIN ( select meta_categ_id, CATEG_LVL2_ID, categ_lvl2_name, categ_lvl3_name, categ_lvl3_id,categ_lvl4_name, categ_lvl4_id, LEAF_CATEG_ID,SITE_ID,
			 BSNS_VRTCL_NAME  ,SAP_CATEGORY_ID,
case when categ_lvl2_id in (20710, 69197, 185066) then 'Electronics' 
when meta_categ_id in (26395) then 'Lifestyle'
when categ_lvl2_id in (386, 238, 1202, 49019, 183446, 80546, 222, 11731, 1082, 767, 233, 2613, 1188, 1039, 11743, 19169, 2562, 2616, 436, 14737, 2631, 2624, 717, 16486, 61573,64808,92074, 246) then 'Home & Garden'
when categ_lvl3_id in (35000, 98989) then 'Home & Garden'
when categ_lvl3_id in (3244) then 'Parts & Accessories'
when categ_lvl3_id in (124982, 259225,180969, 260509) then 'Business & Industrial'
when categ_lvl2_id in (46576) then 'Parts & Accessories'
else bsns_vrtcl_name end as new_vertical
		from DW_CATEGORY_GROUPINGS where SAP_CATEGORY_ID NOT IN (5,7,41,23,-999)  group by 1,2,3,4,5,6,7,8 ,9,10,11,12)  AS CAT ON CAT.LEAF_CATEG_ID = ck.LEAF_CATEG_ID AND CAT.SITE_ID in(3) 
		AND CAT.SAP_CATEGORY_ID NOT IN (5,7,41,23,-999)
			inner JOIN lstg_item_cndtn cond ON ck.item_id = cond.item_id  AND ck.auct_end_dt = cond.AUCT_END_DT
			left outer JOIN DW_USERs U ON U.USER_ID= ck.seller_id 
			INNER  JOIN 
				DW_USEGM_HIST HIST ON 
				HIST.USER_ID=ck.Seller_ID AND 
				HIST.USEGM_GRP_ID  = 48 AND
				HIST.USEGM_ID = 206 and
				CASE WHEN ck.CREATED_DT < '2009-10-11' THEN CAST('2009-10-11' AS DATE) ELSE ck.CREATED_DT END BETWEEN HIST.BEG_DATE AND HIST.END_DATE  
						WHERE 1=1
				and CK.SALE_TYPE NOT IN (10,15)
				--and ck.site_id = 3
				and slr_cntry_id = 3
				and BYR_CNTRY_ID=3
				--and seller_id =1193121968
				and CREATED_DT >='2018-01-01'
				and  categ_lvl2_id in (67659,
										67660,
										67661,
										67662,
										67663,
										67664,
										67665,
										67666,
										67667,
										67668,
										67669,
										67670,
										67671,
										15273)
				and u.USER_DSGNTN_ID =2 
				and HIST.USEGM_ID = 206		
				GROUP BY 1,2,3,4);
				-- 6486 
Select * from p_InventoryPlanning_t.pro_trader_swimming_seller  ;

--2. Rank 750 sellers 
 drop table if exists p_InventoryPlanning_t.pro_trader_swimming_cohort ;
 create table p_InventoryPlanning_t.pro_trader_swimming_cohort  as(
select * from (
select rank () over ( partition by categ_lvl2_id order by GMV_usd desc) as rank ,* from p_InventoryPlanning_t.pro_trader_swimming_seller ) where rank <=750);
 Select * from  p_InventoryPlanning_t.pro_trader_swimming_cohort ;



-- Top 750 by L3
drop table if exists p_InventoryPlanning_t.pro_trader_swimming_L3 ;
 create table p_InventoryPlanning_t.pro_trader_swimming_L3  as(
SELECT	Retail_year
--	,		retail_week	
,ck.seller_id
,u.USER_SLCTD_ID
--	,		USER_SLCTD_ID
,  cat.CATEG_LVL2_NAME
,  cat.CATEG_LVL2_ID
,  cat.CATEG_LVL3_NAME
,  cat.CATEG_LVL3_ID
--   ,case when CNDTN_ROLLUP_ID = 1 then 'New' when   CNDTN_ROLLUP_ID = 3 then 'Used'  when   CNDTN_ROLLUP_ID = 2 then 'Refurb' else  'Other'  end as Condition
,  SUM(gmv_plan_usd) AS GMV_usd
, sum(QUANTITY) as BI
FROM   DW_CHECKOUT_TRANS ck -- SELECT * FROM   DW_CHECKOUT_TRANS  where seller_id= 45524941
INNER JOIN ( select CURNCY_PLAN_RATE,CURNCY_ID from  ACCESS_VIEWS.SSA_CURNCY_PLAN_RATE_DIM group by 1,2) AS SSA
				ON SSA.CURNCY_ID = CK.LSTG_CURNCY_ID
INNER JOIN ACCESS_VIEWS.DW_CAL_DT CAL ON CAL.CAL_DT = CK.gmv_DT   and retail_year >=2022 and age_for_rtl_week_id <= -1  --change here for time period if needed
INNER JOIN ( select meta_categ_id, CATEG_LVL2_ID, categ_lvl2_name, categ_lvl3_name, categ_lvl3_id,categ_lvl4_name, categ_lvl4_id, LEAF_CATEG_ID,SITE_ID,
			 BSNS_VRTCL_NAME  ,SAP_CATEGORY_ID,
case when categ_lvl2_id in (20710, 69197, 185066) then 'Electronics' 
when meta_categ_id in (26395) then 'Lifestyle'
when categ_lvl2_id in (386, 238, 1202, 49019, 183446, 80546, 222, 11731, 1082, 767, 233, 2613, 1188, 1039, 11743, 19169, 2562, 2616, 436, 14737, 2631, 2624, 717, 16486, 61573,64808,92074, 246) then 'Home & Garden'
when categ_lvl3_id in (35000, 98989) then 'Home & Garden'
when categ_lvl3_id in (3244) then 'Parts & Accessories'
when categ_lvl3_id in (124982, 259225,180969, 260509) then 'Business & Industrial'
when categ_lvl2_id in (46576) then 'Parts & Accessories'
else bsns_vrtcl_name end as new_vertical
		from DW_CATEGORY_GROUPINGS where SAP_CATEGORY_ID NOT IN (5,7,41,23,-999)  group by 1,2,3,4,5,6,7,8 ,9,10,11,12)  AS CAT ON CAT.LEAF_CATEG_ID = ck.LEAF_CATEG_ID AND CAT.SITE_ID in(3) 
		AND CAT.SAP_CATEGORY_ID NOT IN (5,7,41,23,-999)
			inner JOIN lstg_item_cndtn cond ON ck.item_id = cond.item_id  AND ck.auct_end_dt = cond.AUCT_END_DT
			inner join ( select distinct seller_id from   p_InventoryPlanning_t.pro_trader_swimming_cohort) n on ck.seller_id=n.seller_id
			left outer JOIN DW_USERs U ON U.USER_ID= ck.seller_id  
			INNER  JOIN 
				DW_USEGM_HIST HIST ON 
				HIST.USER_ID=ck.Seller_ID AND 
				HIST.USEGM_GRP_ID  = 48 AND
				HIST.USEGM_ID = 206 and
				CASE WHEN ck.CREATED_DT < '2009-10-11' THEN CAST('2009-10-11' AS DATE) ELSE ck.CREATED_DT END BETWEEN HIST.BEG_DATE AND HIST.END_DATE  
						WHERE 1=1
				and CK.SALE_TYPE NOT IN (10,15)
				--and ck.site_id = 3
				and slr_cntry_id = 3
				and BYR_CNTRY_ID=3
				--and seller_id =1193121968
				and CREATED_DT >='2018-01-01'
				and  categ_lvl2_id in (67659,
										67660,
										67661,
										67662,
										67663,
										67664,
										67665,
										67666,
										67667,
										67668,
										67669,
										67670,
										67671,
										15273)
				and u.USER_DSGNTN_ID =2 
				and HIST.USEGM_ID = 206		
				GROUP BY 1,2,3,4,5,6,7);

-- Extract the Top 750 sellers at Cat_2 level
				
				with top_750_sellers_per_cat2_level as 
				(select 
				retail_year
				,seller_id
				,categ_lvl2_id
				,sum(gmv_usd) as total_lvl2_gmv
				,row_number() over (partition by retail_year, categ_lvl2_id order by total_lvl2_gmv desc) as row_rank   -- This will rank each seller at Cat_2 level based on their GMV USD value (in descending order)
				from  p_InventoryPlanning_t.pro_trader_swimming_L3
				group by 1,2,3)
				
				select 
				t1.*
				from p_InventoryPlanning_t.pro_trader_swimming_L3 as t1
				inner join top_750_sellers_per_cat2_level as t2
				on t1.retail_year = t2.retail_year
				and t1.seller_id = t2.seller_id
				and t1.categ_lvl2_id = t2.categ_lvl2_id
				where t2.row_rank <= 750
				
				
	