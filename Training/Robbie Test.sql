
drop table P_hroon_T.fashion_fs_brand_gmv;

CREATE TABLE P_hroon_T.fashion_fs_brand_gmv AS

(select * from (select
Brand,   
seller_id,
user_slctd_id,
case when categ_lvl2_id in (20710, 69197, 185066) then 'Electronics' -- added smart home
			when meta_categ_id in (26395) then 'Lifestyle'
			when categ_lvl2_id in (386, 238, 1202, 49019, 183446, 80546, 222, 11731, 1082, 767, 233, 2613, 1188, 1039, 11743, 19169, 2562, 2616, 436, 14737, 2631, 2624, 717, 16486, 61573,64808,92074) then 'Home & Garden'
			when categ_lvl3_id in (35000) then 'Home & Garden'
			when categ_lvl3_id in (3244) then 'Parts & Accessories'
			when categ_lvl2_id in (46576) then 'Parts & Accessories'

		else bsns_vrtcl_name end as new_vertical, 
case
when new_vertical IN ('Fashion') and ck.seller_id in (1004518967, 1116359067, 1599568314, 2156906101, 2223541034, 2203382417, 2230844235, 2129545231, 1017786302, 2218694613, 1050673299, 2113121719, 2093879780, 2046232928, 2058765911, 2223531706, 2179520841, 2211386878, 2231253037, 2266744200, 2272670953, 2131028358, 2272728376, 1936088739, 2231804389, 197683561, 138458180, 1199345580) THEN 'Brands & Fashion Resellers'
when new_vertical IN ('Fashion') and ck.seller_id in (101279071, 1005423641, 723091993, 1111733881, 610344306, 2015049389, 1136851517, 967443711, 355090148, 45344114, 1770304695, 1154701832, 1026266931, 2116751100, 1009683250, 401545409, 503512974, 141590080, 295921530, 915563161, 646712244, 181394076, 111510900, 1148413875, 1097220710, 139292398) THEN 'Brands & Sports Resellers'
when new_vertical IN ('Fashion') and ck.seller_id in (1267463842, 805182197, 1433943842, 1857212717, 2029720769, 2200461040, 1813944635, 1305944975, 506722441, 2052062494, 1970767757, 1055749680, 1107614733, 1061091565, 1033934866, 1393163493, 874193483, 841375365, 1239686221, 192970522, 2279936869, 341779737, 1032063194) THEN 'Medium Brands'
when new_vertical IN ('Fashion') and ck.seller_id in (342506678, 921304420, 1161124858, 320515737, 105889204, 1534266810, 1011746456, 1042880022, 1306673682) THEN 'Small Brands'
		else 'other'
					END AS INVENTORY_PROP,
					meta_Categ_name,
					categ_lvl2_name,
case when BYR_CNTRY_ID = 3 then 'UK BUYER' else 'INTERNATIONAL BUYER' end as buyer_flag,
case when SLR_CNTRY_ID = BYR_CNTRY_ID and slr_cntry_id = 3 then 'DOM' else 'INT' end as dom_flag,
	SUM(CK.ITEM_PRICE*QUANTITY* LPR.CURNCY_PLAN_RATE) AS GMV, 
	SUM(QUANTITY) AS BI,
	count(distinct(ck.item_id)) as converted_lll,
	GMV/BI as ASP

FROM DW_CHECKOUT_TRANS AS CK

inner  JOIN ACCESS_VIEWS.SSA_CURNCY_PLAN_RATE_DIM LPR 
	ON CK.LSTG_CURNCY_ID = LPR.CURNCY_ID 
INNER JOIN ACCESS_VIEWS.DW_CAL_DT CAL 
	ON CAL.CAL_DT = CK.CREATED_DT 
	and retail_year in (2021) and AGE_FOR_RTL_WEEK_ID >= -5 and AGE_FOR_RTL_WEEK_ID <= -1
left join (select
						upper(ASPCT_VLU_NM) as BRAND,
						aspct.item_id,
						aspct.auct_end_dt,
						lower(PRDCT_ASPCT_NM) as lcase_aspect_name
						from
						ITEM_ASPCT_CLSSFCTN ASPCT
						where 
						lower(PRDCT_ASPCT_NM) in ('brand' ) and NS_TYPE_CD='df' 
						 and  aspct.auct_end_dt  >=  date '2020-07-01'
					  group by 1,2,3,4) bbase
					ON ck.ITEM_ID = bbase.ITEM_ID AND ck.AUCT_END_dt = bbase.AUCT_END_DT
left outer join dw_users u
	on ck.seller_id = u.user_id
INNER JOIN DW_CATEGORY_GROUPINGS CAT 
	ON CAT.LEAF_CATEG_ID = CK.LEAF_CATEG_ID 
	AND CAT.SITE_ID = 3
	AND CAT.SAP_CATEGORY_ID NOT IN (5,7,41,23,-999)   

WHERE 1=1
	AND CK.CK_WACKO_YN  =  'N'
	and meta_categ_id =11450
	AND CK.SALE_TYPE NOT IN (10,15)
-- 	and ck.byr_cntry_id =3 
	GROUP BY 1,2,3,4,5,6,7,8,9

) where INVENTORY_PROP not in ('other'))
	
-- WITH DATA PRIMARY INDEX(seller_id, RETAIL_WEEK, RETAIL_YEAR, categ_lvl2_id);
;



---------------------------------------------------------------------------------------------------------------------------
drop table if exists P_hroon_T.fashion_fs_brand_lstg;
---------------------------------------------------------------------------------------------------------------------------
CREATE TABLE P_hroon_T.fashion_fs_brand_lstg AS

(select * from (SELECT
Brand,   
slr_id,
user_slctd_id,
case when categ_lvl2_id in (20710, 69197, 185066) then 'Electronics' -- added smart home
			when meta_categ_id in (26395) then 'Lifestyle'
			when categ_lvl2_id in (386, 238, 1202, 49019, 183446, 80546, 222, 11731, 1082, 767, 233, 2613, 1188, 1039, 11743, 19169, 2562, 2616, 436, 14737, 2631, 2624, 717, 16486, 61573,64808,92074) then 'Home & Garden'
			when categ_lvl3_id in (35000) then 'Home & Garden'
			when categ_lvl3_id in (3244) then 'Parts & Accessories'
			when categ_lvl2_id in (46576) then 'Parts & Accessories'

		else bsns_vrtcl_name end as new_vertical, 
case
when new_vertical IN ('Fashion') and ck.slr_id in (1004518967, 1116359067, 1599568314, 2156906101, 2223541034, 2203382417, 2230844235, 2129545231, 1017786302, 2218694613, 1050673299, 2113121719, 2093879780, 2046232928, 2058765911, 2223531706, 2179520841, 2211386878, 2231253037, 2266744200, 2272670953, 2131028358, 2272728376, 1936088739, 2231804389, 197683561, 138458180, 1199345580) THEN 'Brands & Fashion Resellers'
when new_vertical IN ('Fashion') and ck.slr_id in (101279071, 1005423641, 723091993, 1111733881, 610344306, 2015049389, 1136851517, 967443711, 355090148, 45344114, 1770304695, 1154701832, 1026266931, 2116751100, 1009683250, 401545409, 503512974, 141590080, 295921530, 915563161, 646712244, 181394076, 111510900, 1148413875, 1097220710, 139292398) THEN 'Brands & Sports Resellers'
when new_vertical IN ('Fashion') and ck.slr_id in (1267463842, 805182197, 1433943842, 1857212717, 2029720769, 2200461040, 1813944635, 1305944975, 506722441, 2052062494, 1970767757, 1055749680, 1107614733, 1061091565, 1033934866, 1393163493, 874193483, 841375365, 1239686221, 192970522, 2279936869, 341779737, 1032063194) THEN 'Medium Brands'
when new_vertical IN ('Fashion') and ck.slr_id in (342506678, 921304420, 1161124858, 320515737, 105889204, 1534266810, 1011746456, 1042880022, 1306673682) THEN 'Small Brands'
else 'other'
					END AS INVENTORY_PROP,
meta_Categ_name,
categ_lvl2_name,
count(distinct(ck.item_id)) as LL

FROM DW_LSTG_ITEM CK 

INNER JOIN DW_CATEGORY_GROUPINGS CAT ON CAT.LEAF_CATEG_ID = Ck.LEAF_CATEG_ID AND CAT.SITE_ID = CK.ITEM_SITE_ID and cat.site_id = 3 
INNER JOIN DW_COUNTRIES CN ON CN.CNTRY_ID = CK.SLR_CNTRY_ID
INNER JOIN ACCESS_VIEWS.GLBL_RPRT_GEO_DIM GEO ON CN.REV_ROLLUP_ID = GEO.REV_ROLLUP_ID 
INNER JOIN DW_CAL_DT CAL ON CK.AUCT_START_DT < CAL.CAL_DT AND CK.AUCT_END_DT >= CAL.CAL_DT AND RETAIL_YEAR in (2021) 
left join (select
	upper(ASPCT_VLU_NM) as BRAND,
	aspct.item_id,
    aspct.auct_end_dt,
    lower(PRDCT_ASPCT_NM) as lcase_aspect_name
    from
    ITEM_ASPCT_CLSSFCTN ASPCT
    where 
    lower(PRDCT_ASPCT_NM) in ('brand' ) and NS_TYPE_CD='df' 
--      and  aspct.auct_end_dt  >=  date '2020-07-01'
) bbase	ON ck.ITEM_ID = bbase.ITEM_ID AND ck.AUCT_END_dt = bbase.AUCT_END_DT
left outer join dw_users u
on ck.slr_id = u.user_id

WHERE ck.WACKO_YN = 'N'                      
AND CK.AUCT_TYPE_CODE NOT IN (10,15)
	and meta_categ_id =11450
AND CK.ITEM_SITE_ID = 3
-- and new_vertical = 'fashion'
and ck.auct_end_Dt > CURRENT_DATE
group by 1,2,3,4,5,6,7
 ) where INVENTORY_PROP not in ('other'));
-- WITH DATA PRIMARY INDEX(slr_id, categ_lvl2_id, retail_year,retail_week);
 
--  COLLECT STATS P_hroon_T.aw_new_seller_base COLUMN(retail_year,retail_week,slr_id);

---------------------------------------------------------------------------------------------------------------------------
drop table if exists P_hroon_T.fashion_fs_brand;
-- select* from P_hroon_T.fashion_fs_brand;
--------------------------------------------------------------------------------------------------------------------------- 

CREATE table P_hroon_T.fashion_fs_brand  as

 (SELECT brand, seller_id, user_slctd_id,new_Vertical, INVENTORY_PROP, meta_categ_name, categ_lvl2_name, buyer_flag, dom_flag, GMV, BI, converted_lll, ASP, ll 

FROM (
 
	SELECT brand, seller_id, user_slctd_id, new_Vertical, INVENTORY_PROP, meta_categ_name, categ_lvl2_name, buyer_flag, dom_flag, GMV, BI, converted_lll, ASP, cast(0 as decimal(38,10)) AS ll
		FROM P_hroon_T.fashion_fs_brand_gmv

UNION ALL

	SELECT  brand, slr_id as seller_id, user_slctd_id, new_Vertical, INVENTORY_PROP, meta_categ_name, categ_lvl2_name,  NULL as buyer_flag, NULL as dom_flag, 0 AS GMV, 0 AS BI, 0 AS converted_lll, 0 AS ASP, ll
		FROM P_hroon_T.fashion_fs_brand_lstg
		
		) unio

GROUP BY brand,seller_id, user_slctd_id, new_Vertical, INVENTORY_PROP, meta_categ_name, categ_lvl2_name,  buyer_flag, dom_flag, GMV, BI, converted_lll, ASP, ll 
 )
 ; 
 
--  WITH DATA PRIMARY INDEX(seller_id, categ_lvl2_id, retail_year,retail_week);