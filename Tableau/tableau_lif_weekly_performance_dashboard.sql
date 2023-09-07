-- JIRA:            UKPLAN-424

-- Author: 			Robbie Evans
-- Date:            24/07/2023

-- Stakeholder: 	Lifestyle Trading Team
-- Description: 	Provides a weekly/QTD/YTD view of the category's performance down to an L4 level and including a view of top sellers and top brands



-- drop table if exists P_ROBEVANS_T.lif_okr_targets;
-- Create table P_ROBEVANS_T.lif_okr_targets
-- (
--     meta_category_name string,
-- 	retail_week decimal(4,0),
--     gmv decimal(38,6)
-- )
-- ;
-- INSERT INTO P_ROBEVANS_T.lif_okr_targets (retail_week, meta_category_name, gmv)
-- VALUES
--     (27, 'Health & Beauty', 7395899.591),
--     (27, 'Sporting Goods', 6392314.021),
--     (28, 'Health & Beauty', 7267229.712),
--     (28, 'Sporting Goods', 6688617.962),
--     (29, 'Health & Beauty', 7287569.906),
--     (29, 'Sporting Goods', 6374636.034),
--     (30, 'Health & Beauty', 7803841.575),
--     (30, 'Sporting Goods', 6678620.37),
--     (31, 'Health & Beauty', 7450629.033),
--     (31, 'Sporting Goods', 6605063.767),
--     (32, 'Health & Beauty', 6987706.727),
--     (32, 'Sporting Goods', 6313873.56),
--     (33, 'Health & Beauty', 7102826.172),
--     (33, 'Sporting Goods', 6031874.348),
--     (34, 'Health & Beauty', 7479772.527),
--     (34, 'Sporting Goods', 5808225.64),
--     (35, 'Health & Beauty', 7128441.194),
--     (35, 'Sporting Goods', 5852573.4),
--     (36, 'Health & Beauty', 6964168.662),
--     (36, 'Sporting Goods', 5622776.292),
--     (37, 'Health & Beauty', 6988569.421),
--     (37, 'Sporting Goods', 5581603.139),
--     (38, 'Health & Beauty', 6959249.909),
--     (38, 'Sporting Goods', 5533749.211),
--     (39, 'Health & Beauty', 7842182.224),
--     (39, 'Sporting Goods', 6058024.255),
--     (40, 'Health & Beauty', 7605679.408),
--     (40, 'Sporting Goods', 5907369.644),
--     (41, 'Health & Beauty', 8862072.238),
--     (41, 'Sporting Goods', 6278538.431),
--     (42, 'Health & Beauty', 8544023.867),
--     (42, 'Sporting Goods', 6095021.295),
--     (43, 'Health & Beauty', 9157872.355),
--     (43, 'Sporting Goods', 6284297.924),
--     (44, 'Health & Beauty', 9606231.766),
--     (44, 'Sporting Goods', 6589908),
--     (45, 'Health & Beauty', 10455942.35),
--     (45, 'Sporting Goods', 6714510.279),
--     (46, 'Health & Beauty', 10931574.94),
--     (46, 'Sporting Goods', 6740480.81),
--     (47, 'Health & Beauty', 11847967.98),
--     (47, 'Sporting Goods', 6730518.107),
--     (48, 'Health & Beauty', 11331411.32),
--     (48, 'Sporting Goods', 7310772.125),
--     (49, 'Health & Beauty', 10520776.01),
--     (49, 'Sporting Goods', 6596158.778),
--     (50, 'Health & Beauty', 7981142.076),
--     (50, 'Sporting Goods', 4970473.621),
--     (51, 'Health & Beauty', 5226949.044),
--     (51, 'Sporting Goods', 3577060.183),
--     (52, 'Health & Beauty', 6319782.613),
--     (52, 'Sporting Goods', 4440150.678);






Drop table if exists p_robevans_t.lifestyle_inv_props;

Create table p_robevans_t.lifestyle_inv_props as

select
lstg.item_id
,auct_end_dt
,cat.new_vertical
,case when new_vertical = 'Lifestyle' and cat.categ_lvl2_id in (11854, 31762, 31769, 36447) and cat.categ_lvl3_id in (260773, 260783, 260774, 36449) and cndtn_rollup_id=2 then 'Personal Electrical Refurb Focus'
when new_vertical = 'Lifestyle' and cat.categ_lvl2_id in (11854, 31762, 31769, 36447) and cat.categ_lvl3_id in (260773, 260783, 260774, 36449) and cndtn_rollup_id not in (2) then 'Personal Electrical Non-Refurb Focus'
when new_vertical = 'Lifestyle' and cat.categ_lvl2_id in (180345) then 'Fragrances Focus'
when new_vertical = 'Lifestyle' and cat.categ_lvl2_id in (180959) then 'Vitamins & Lifestyle Supplements Focus'
when new_vertical = 'Lifestyle' and cat.categ_lvl2_id in (67588) and cat.categ_lvl3_id in (261973) then 'Pharmacy Medicines Focus'
when new_vertical = 'Lifestyle' and cat.categ_lvl2_id in (7294) and cndtn_rollup_id=2 then 'Cycling Refurb Focus'
when new_vertical = 'Lifestyle' and cat.categ_lvl2_id in (7294) and cndtn_rollup_id not in (2) then 'Cycling Non-Refurb Focus'
when new_vertical = 'Lifestyle' and cat.categ_lvl2_id in (1513) then 'Golf Focus'
when new_vertical = 'Lifestyle' and cat.categ_lvl2_id in (11778)  and cndtn_rollup_id=2 then 'Independent Living Refurb Focus'
when new_vertical = 'Lifestyle' and cat.categ_lvl2_id in (11778) and cndtn_rollup_id not in (2) then'Independent Living Non-Refurb Focus'
when new_vertical = 'Lifestyle' and cat.categ_lvl2_id in (15273) then 'Fitness Running & Yoga Focus'
when new_vertical = 'Lifestyle' and cat.categ_lvl2_id in (31786) then 'Make-Up Focus'
when new_vertical = 'Lifestyle' and cat.categ_lvl2_id in (183497) then 'Electronic Smoking, Parts & Accs Focus'
when new_vertical = 'Lifestyle' and cat.categ_lvl2_id in (16034) and cat.CATEG_LVL3_ID in (106983,181403,181381,16038,75232,181395,181390,181404,181405,181378,181411,72891,16039,181401,262434,8504) then 'Camping & Hiking Focus'
when new_vertical = 'Lifestyle' and cat.categ_lvl2_id in (67588) and cat.CATEG_LVL3_ID in (176992) then 'Sexual Wellness Focus'
when new_vertical = 'Lifestyle' and cat.CATEG_LVL3_ID in (87089,23800,87090,36122,71167,71168,112966,22710) then 'Watersports Focus'
Else 'Other'
End as inventory_prop

from PRS_RESTRICTED_V.SLNG_LSTG_SUPER_FACT lstg
inner join
	(
	select meta_categ_id
			,meta_categ_name
			,categ_lvl2_id
			,categ_lvl2_name
			,categ_lvl3_id
			,categ_lvl3_name
			,categ_lvl4_id
			,categ_lvl4_name
			,leaf_categ_id
			,site_id
			,new_vertical
	FROM P_INVENTORYPLANNING_T.dw_category_groupings_adj 
	Where new_vertical = 'Lifestyle'
	) CAT
		ON lstg.LEAF_CATEG_ID = CAT.LEAF_CATEG_ID
		AND cat.site_id = 3
Where 1=1
and lstg.AUCT_END_DT >= '2016-12-25'
and lstg.ITEM_SITE_ID = 3
;











--------------------------------------------------------------------------------------------------------------------------------------------------

Drop table if exists p_robevans_t.lifestyle_subcat_vi;

Create table p_robevans_t.lifestyle_subcat_vi as

SELECT
trfc.ITEM_ID
,cal.AGE_FOR_RTL_WEEK_ID
,sum(trfc.TTL_VI_CNT) as VI
,sum(trfc.SRP_IMPRSN_CNT)+sum(trfc.STORE_IMPRSN_CNT) as IMP

FROM PRS_RESTRICTED_V.SLNG_TRFC_SUPER_FACT trfc	
INNER JOIN P_INVENTORYPLANNING_T.dw_category_groupings_adj CAT
	ON trfc.LEAF_CATEG_ID = CAT.LEAF_CATEG_ID
	AND cat.site_id = 3	
INNER JOIN DW_CAL_DT CAL
	ON trfc.cal_dt = cal.CAL_DT
	and (RETAIL_YEAR >= (select retail_year from ACCESS_VIEWS.DW_CAL_DT where AGE_FOR_RTL_WEEK_ID = -1 group by 1)-1)
	and	AGE_FOR_RTL_WEEK_ID <= -1
			
WHERE 1=1
	AND trfc.SITE_ID = 3
	and cat.NEW_VERTICAL = 'Lifestyle'

GROUP BY 1,2
;
--------------------------------------------------------------------------------------------------------------------------------------------------

drop table if exists p_robevans_t.lifestyle_subcat_listings;

Create table p_robevans_t.lifestyle_subcat_listings as

SELECT
'Listings' as target
,lstg.RETAIL_YEAR
,lstg.retail_week
,lstg.ytd_flag
,lstg.ty_flag
,lstg.AGE_FOR_RTL_WEEK_ID
,lstg.Business_flag
,lstg.cndtn_descr
,lstg.INVENTORY_PROP
,lstg.META_CATEG_NAME
,lstg.META_CATEG_ID
,lstg.CATEG_LVL2_NAME
,lstg.CATEG_LVL2_ID
,lstg.CATEG_LVL3_NAME
,lstg.CATEG_LVL3_ID
,lstg.CATEG_LVL4_NAME
,lstg.CATEG_LVL4_ID
,lstg.new_vertical
,count(distinct lstg.item_id) as ll
,sum(trfc.vi) as VI
,sum(trfc.imp) as IMP

FROM
	(
	SELECT
	lstg.item_id
	,cal.RETAIL_YEAR
	,cal.retail_week
	,case when cal.RETAIL_WEEK <= (select retail_week from DW_CAL_DT where AGE_FOR_RTL_WEEK_ID = -1 group by 1) then 'YTD' else 'Other' end as ytd_flag
	,case when cal.RETAIL_YEAR = (select retail_year from DW_CAL_DT where AGE_FOR_RTL_WEEK_ID = -1 group by 1) then 'Current Year' else 'Last Year' end as ty_flag
	,cal.AGE_FOR_RTL_WEEK_ID
	,lstg.B2C_C2C as Business_flag
	,cd.cndtn_descr
	,inv.INVENTORY_PROP
	,cat.META_CATEG_NAME
	,cat.META_CATEG_ID
	,cat.CATEG_LVL2_NAME
	,cat.CATEG_LVL2_ID
	,cat.CATEG_LVL3_NAME
	,cat.CATEG_LVL3_ID
	,cat.CATEG_LVL4_NAME
	,cat.CATEG_LVL4_ID
	,cat.new_vertical

	From PRS_RESTRICTED_V.SLNG_LSTG_SUPER_FACT lstg
	INNER JOIN P_INVENTORYPLANNING_T.dw_category_groupings_adj CAT
		ON lstg.LEAF_CATEG_ID = CAT.LEAF_CATEG_ID
		AND cat.site_id = 3
	INNER JOIN DW_CAL_DT CAL
		ON lstg.AUCT_START_DT <= cal.cal_dt and lstg.AUCT_END_DT >= cal.CAL_DT
		and (RETAIL_YEAR >= (select retail_year from ACCESS_VIEWS.DW_CAL_DT where AGE_FOR_RTL_WEEK_ID = -1 group by 1)-1)
		and AGE_FOR_RTL_WEEK_ID <= -1
	LEFT JOIN ACCESS_VIEWS.LSTG_ITEM_CNDTN AS CNDTN
		ON lstg.ITEM_ID = CNDTN.ITEM_ID
	LEFT JOIN P_ROBEVANS_T.item_cndtn_descr cd
		on cd.cndtn_rollup_id = CNDTN.CNDTN_ROLLUP_ID
	LEFT JOIN
		(
		select ITEM_ID
			,INVENTORY_PROP
		from p_robevans_t.lifestyle_inv_props
		group by 1,2
		) INV
			on inv.item_id = lstg.item_id
	left join 
		(
		select ITEM_ID
			,incntv_cd
			,incntv_desc
		FROM P_CSI_TBS_T.cpn_trxns
		Where country = 'UK'
		Group by 1,2,3
		) coupon
			ON coupon.item_id = lstg.item_id

	WHERE 1=1
		AND lstg.SLR_CNTRY_ID = 3
		AND lstg.LSTG_SITE_ID = 3
		AND cat.new_vertical = 'Lifestyle'

	GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18
	) lstg

LEFT JOIN p_robevans_t.lifestyle_subcat_vi trfc
	on lstg.ITEM_ID = trfc.item_id
	and lstg.AGE_FOR_RTL_WEEK_ID = trfc.AGE_FOR_RTL_WEEK_ID

Group by 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18
;

--------------------------------------------------------------------------------------------------------------------------------------------------


Drop table if exists p_robevans_t.lifestyle_subcat_gmv;

Create table p_robevans_t.lifestyle_subcat_gmv as

SELECT
'GMV' as target
,cal.RETAIL_YEAR
,cal.retail_week
,case when cal.RETAIL_WEEK <= (select retail_week from DW_CAL_DT where AGE_FOR_RTL_WEEK_ID = -1 group by 1) then 'YTD' else 'Other' end as ytd_flag
,case when cal.RETAIL_YEAR = (select retail_year from DW_CAL_DT where AGE_FOR_RTL_WEEK_ID = -1 group by 1) then 'Current Year' else 'Last Year' end as ty_flag
,cal.AGE_FOR_RTL_WEEK_ID
,ck.B2C_C2C as Business_flag
,cd.cndtn_descr
,inv.INVENTORY_PROP
,CAT.META_CATEG_NAME
,CAT.CATEG_LVL2_NAME
,CAT.CATEG_LVL3_NAME
,CAT.CATEG_LVL4_NAME
,CAT.new_vertical
,coupon.incntv_cd as coupon_code
,coupon.incntv_desc as coupon_desc
,cpn_det.POD_DESC as coupon_team
,cpn_det.PROGRM_DESC as coupon_purpose
,CASE 
		WHEN deal.item_id IS NOT NULL OR NERP.ITEM_ID IS NOT NULL THEN 'Promo Manager & Sub Deals' 
		WHEN Lower((CASE  WHEN ck.byr_cntry_id=ck.slr_cntry_id AND ck.byr_cntry_id IN (3) THEN 'Domestic' ELSE 'CBT' end ))=Lower('CBT') THEN 'Exports' 
		WHEN Lower((CASE  WHEN (coupon.item_id) IS NOT NULL THEN 'Y' ELSE 'N' end ))=Lower('Y') THEN 'Coupon' 
		ELSE 'Baseline' 
		end  AS MECE_Bucket
,sum(case when ck.DOMESTIC_CBT = 'Domestic' then ck.GMV20_PLAN End) as GMV_Dom
,sum(case when ck.DOMESTIC_CBT = 'CBT' then ck.GMV20_PLAN End) as GMV_CBT
,sum(ck.GMV20_PLAN) as GMV
,sum(case when ck.DOMESTIC_CBT = 'Domestic' then ck.GMV20_SOLD_QUANTITY End) as SI_Dom
,sum(case when ck.DOMESTIC_CBT = 'CBT' then ck.GMV20_SOLD_QUANTITY End) as SI_CBT
,sum(ck.GMV20_SOLD_QUANTITY) as SI

FROM PRS_RESTRICTED_V.SLNG_TRANS_SUPER_FACT ck	
INNER JOIN P_INVENTORYPLANNING_T.dw_category_groupings_adj CAT
	ON ck.LEAF_CATEG_ID = CAT.LEAF_CATEG_ID
	AND cat.site_id = 3
INNER JOIN DW_CAL_DT CAL
	ON ck.gmv_dt = cal.CAL_DT
	and (RETAIL_YEAR >= (select retail_year from ACCESS_VIEWS.DW_CAL_DT where AGE_FOR_RTL_WEEK_ID = -1 group by 1)-1)
	and AGE_FOR_RTL_WEEK_ID <= -1
LEFT JOIN ACCESS_VIEWS.LSTG_ITEM_CNDTN AS CNDTN
	ON ck.ITEM_ID = CNDTN.ITEM_ID
LEFT JOIN P_ROBEVANS_T.item_cndtn_descr cd
	on cd.cndtn_rollup_id = CNDTN.CNDTN_ROLLUP_ID
LEFT JOIN	
	(select ITEM_ID
		,INVENTORY_PROP
	from p_robevans_t.lifestyle_inv_props
	group by 1,2
	) INV
		on inv.item_id = ck.item_id

-- Cpn Transactions
left join P_CSI_TBS_T.cpn_trxns   as coupon
	ON coupon.item_id = ck.item_id 
	AND coupon.transaction_id = ck.transaction_id
LEFT join access_views.eip_cpn_dtl cpn_det
	on coupon.INCNTV_CD = cpn_det.INCNTV_CD

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
AND ck.SLR_CNTRY_ID = 3
AND ck.SITE_ID = 3
AND ck.CK_WACKO_YN = 'N'
and cat.NEW_VERTICAL = 'Lifestyle'

GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19
;


----------------------------------------------------------------------------------------------------------------------------------------------
Drop table if exists P_UKPLAN_REPORT_T.LIFESTYLE_SUBCAT_FINAL;

Create table P_UKPLAN_REPORT_T.LIFESTYLE_SUBCAT_FINAL as

SELECT
	lstg.RETAIL_YEAR
	,lstg.retail_week
	,lstg.ytd_flag
	,lstg.ty_flag
	,max_nums.retail_year as maxyear
	,max_nums.retail_week as maxwk
	,max_nums.RTL_QTR_OF_RTL_YEAR_ID as maxquarter
	,lstg.AGE_FOR_RTL_WEEK_ID
	,lstg.Business_flag
	,lstg.cndtn_descr
	,lstg.INVENTORY_PROP
	,lstg.META_CATEG_NAME
	,lstg.CATEG_LVL2_NAME
	,lstg.CATEG_LVL3_NAME
	,lstg.CATEG_LVL4_NAME
	,lstg.new_vertical
	,0 as coupon_code
	,0 as coupon_desc
	,0 as coupon_team
	,0 as coupon_purpose
	,0 as MECE_Bucket
	,LL
	,VI
	,IMP
	,0 as GMV_Dom
	,0 as GMV_CBT
	,0 as GMV
	,0 as SI_Dom
	,0 as SI_CBT
	,0 as SI
	
From p_robevans_t.lifestyle_subcat_listings lstg
LEFT JOIN
	(Select RETAIL_YEAR
	,RETAIL_WEEK
	,RTL_QTR_OF_RTL_YEAR_ID
	From DW_CAL_DT
	Where AGE_FOR_RTL_WEEK_ID = -1
	Group by 1,2,3
	) max_nums

Group by 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24


UNION ALL


Select 
	ck.retail_year
	,ck.retail_week
	,ytd_flag
	,ty_flag
	,max_nums.retail_year as maxyear
	,max_nums.retail_week as maxwk
	,max_nums.RTL_QTR_OF_RTL_YEAR_ID as maxquarter
	,AGE_FOR_RTL_WEEK_ID
	,Business_flag
	,cndtn_descr
	,INVENTORY_PROP
	,META_CATEG_NAME
	,CATEG_LVL2_NAME
	,CATEG_LVL3_NAME
	,CATEG_LVL4_NAME
	,new_vertical
	,coupon_code
	,coupon_desc
	,coupon_team
	,coupon_purpose
	,MECE_Bucket
	,0 as LL
	,0 as VI
	,0 as IMP
	,sum(GMV_Dom) as GMV_Dom
	,sum(GMV_CBT) as GMV_CBT
	,sum(GMV) as GMV
	,sum(SI_Dom) as SI_Dom
	,sum(SI_CBT) as SI_CBT
	,sum(SI) as SI

From p_robevans_t.lifestyle_subcat_gmv ck
LEFT JOIN
	(Select RETAIL_YEAR
	,RETAIL_WEEK
	,RTL_QTR_OF_RTL_YEAR_ID
	From DW_CAL_DT
	Where AGE_FOR_RTL_WEEK_ID = -1
	Group by 1,2,3
	) max_nums
	
Group by 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24
;



---------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------- OKR Targets ----------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------

Drop table if exists P_UKPLAN_REPORT_T.Lifestyle_okr_targets;
Create table P_UKPLAN_REPORT_T.Lifestyle_okr_targets as

Select ck.retail_week
	,ck.meta_categ_name
	,sum(ck.gmv) as gmv_actual
	,sum(okr.gmv) as gmv_target
FROM
	(
	Select retail_week
		,META_CATEG_NAME
		,sum(GMV_Dom) as GMV
	FROM p_robevans_t.lifestyle_subcat_gmv ck
	Where 1=1
		and ck.retail_year = 2023
		and upper(Business_flag) = 'B2C'
		and (retail_week between 27 and 52)
		and meta_categ_name in ('Health & Beauty','Sporting Goods')
	Group by 1,2
	) ck
LEFT JOIN P_ROBEVANS_T.lif_okr_targets okr
	on ck.retail_week = okr.retail_week
	and lower(ck.meta_categ_name) = lower(okr.meta_category_name)
Group by 1,2
;
---------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------- Top Sellers -----------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------

Drop table if exists P_UKPLAN_REPORT_T.lifestyle_subcat_top_sellers;

Create table P_UKPLAN_REPORT_T.lifestyle_subcat_top_sellers as

With top_sellers as
(
Select SELLER_ID
From
	(
	----------Latest Week Top Sellers----------------
	Select 
		cat.META_CATEG_ID
		,cat.CATEG_LVL2_ID
		,cat.CATEG_LVL3_ID
		,cat.CATEG_LVL4_ID
		,inv.INVENTORY_PROP
		,seller_id
		,sum(GMV20_PLAN) as gmv
		,dense_rank() over (partition by cat.META_CATEG_ID order by sum(GMV20_PLAN) desc) as rank_meta
		,dense_rank() over (partition by cat.CATEG_LVL2_ID order by sum(GMV20_PLAN) desc) as rank_L2
		,dense_rank() over (partition by cat.CATEG_LVL3_ID order by sum(GMV20_PLAN) desc) as rank_L3
		,dense_rank() over (partition by cat.CATEG_LVL4_ID order by sum(GMV20_PLAN) desc) as rank_L4
		,dense_rank() over (partition by inv.INVENTORY_PROP order by sum(GMV20_PLAN) desc) as rank_inv
	From PRS_RESTRICTED_V.SLNG_TRANS_SUPER_FACT ck	
	INNER JOIN DW_CAL_DT cal 
		ON ck.GMV_DT = cal.CAL_DT
		AND cal.AGE_FOR_RTL_WEEK_ID = -1
	INNER JOIN P_INVENTORYPLANNING_T.dw_category_groupings_adj CAT
		ON ck.LEAF_CATEG_ID = CAT.LEAF_CATEG_ID
		AND cat.site_id = 3
	LEFT JOIN	
		(select ITEM_ID
			,INVENTORY_PROP
		from p_robevans_t.lifestyle_inv_props
		group by 1,2
		) INV
			on inv.item_id = ck.item_id
	Where 1=1
		and ck.SLR_CNTRY_ID = 3
		and ck.SITE_ID = 3
		and cat.new_vertical = 'Lifestyle'
	Group by 1,2,3,4,5,6
	
	
	UNION ALL

	----------Latest Quarter Top Sellers----------------
	Select 
		cat.META_CATEG_ID
		,cat.CATEG_LVL2_ID
		,cat.CATEG_LVL3_ID
		,cat.CATEG_LVL4_ID
		,inv.INVENTORY_PROP
		,seller_id
		,sum(GMV20_PLAN) as gmv
		,dense_rank() over (partition by cat.META_CATEG_ID order by sum(GMV20_PLAN) desc) as rank_meta
		,dense_rank() over (partition by cat.CATEG_LVL2_ID order by sum(GMV20_PLAN) desc) as rank_L2
		,dense_rank() over (partition by cat.CATEG_LVL3_ID order by sum(GMV20_PLAN) desc) as rank_L3
		,dense_rank() over (partition by cat.CATEG_LVL4_ID order by sum(GMV20_PLAN) desc) as rank_L4
		,dense_rank() over (partition by inv.INVENTORY_PROP order by sum(GMV20_PLAN) desc) as rank_inv
	From PRS_RESTRICTED_V.SLNG_TRANS_SUPER_FACT ck	
	INNER JOIN DW_CAL_DT cal 
		ON ck.GMV_DT = cal.CAL_DT
		AND cal.RTL_QTR_OF_RTL_YEAR_ID = (select RTL_QTR_OF_RTL_YEAR_ID from DW_CAL_DT where AGE_FOR_RTL_WEEK_ID = -1 group by 1)
		and cal.retail_year = (select RETAIL_YEAR from DW_CAL_DT where AGE_FOR_RTL_WEEK_ID = -1 group by 1)
	INNER JOIN P_INVENTORYPLANNING_T.dw_category_groupings_adj CAT
		ON ck.LEAF_CATEG_ID = CAT.LEAF_CATEG_ID
		AND cat.site_id = 3
	LEFT JOIN	
		(select ITEM_ID
			,INVENTORY_PROP
		from p_robevans_t.lifestyle_inv_props
		group by 1,2
		) INV
			on inv.item_id = ck.item_id
	Where 1=1
		and ck.SLR_CNTRY_ID = 3
		and ck.SITE_ID = 3
		and cat.new_vertical = 'Lifestyle'
	Group by 1,2,3,4,5,6
	
	UNION ALL
	
	----------YTD Top Sellers----------------
	Select 
		cat.META_CATEG_ID
		,cat.CATEG_LVL2_ID
		,cat.CATEG_LVL3_ID
		,cat.CATEG_LVL4_ID
		,inv.INVENTORY_PROP
		,seller_id
		,sum(GMV20_PLAN) as gmv
		,dense_rank() over (partition by cat.META_CATEG_ID order by sum(GMV20_PLAN) desc) as rank_meta
		,dense_rank() over (partition by cat.CATEG_LVL2_ID order by sum(GMV20_PLAN) desc) as rank_L2
		,dense_rank() over (partition by cat.CATEG_LVL3_ID order by sum(GMV20_PLAN) desc) as rank_L3
		,dense_rank() over (partition by cat.CATEG_LVL4_ID order by sum(GMV20_PLAN) desc) as rank_L4
		,dense_rank() over (partition by inv.INVENTORY_PROP order by sum(GMV20_PLAN) desc) as rank_inv
	From PRS_RESTRICTED_V.SLNG_TRANS_SUPER_FACT ck	
	INNER JOIN DW_CAL_DT cal 
		ON ck.GMV_DT = cal.CAL_DT
		AND cal.RETAIL_YEAR = (select RETAIL_YEAR from DW_CAL_DT where AGE_FOR_RTL_WEEK_ID = -1 group by 1)
	INNER JOIN P_INVENTORYPLANNING_T.dw_category_groupings_adj CAT
		ON ck.LEAF_CATEG_ID = CAT.LEAF_CATEG_ID
		AND cat.site_id = 3
	LEFT JOIN	
		(select ITEM_ID
			,INVENTORY_PROP
		from p_robevans_t.lifestyle_inv_props
		group by 1,2
		) INV
			on inv.item_id = ck.item_id
	Where 1=1
		and ck.SLR_CNTRY_ID = 3
		and ck.SITE_ID = 3
		and cat.new_vertical = 'Lifestyle'
	Group by 1,2,3,4,5,6
	)
Where rank_meta <= 25
 OR rank_L2 <= 25
 OR rank_L3 <= 25
 OR rank_L4 <= 25
 OR rank_inv <= 25
 
Group by 1
)



select lstg.* 
	,trfc.vi as VI
	,trfc.imp as IMP
FROM
	(
	SELECT
	retail_year
	,max_week
	,max_year
	,max_quarter
	,case when cal.AGE_FOR_RTL_WEEK_ID in (-1,-2,-53) then cal.AGE_FOR_RTL_WEEK_ID else 'Other' End as latest_wk_flag
	,case when (cal.RTL_QTR_OF_RTL_YEAR_ID = (select RTL_QTR_OF_RTL_YEAR_ID from DW_CAL_DT where AGE_FOR_RTL_WEEK_ID = -1 group by 1)) and (retail_week <= (select retail_week from DW_CAL_DT where AGE_FOR_RTL_WEEK_ID = -1 group by 1)) then 'QTD' else 'Other' end as qtd_flag
	,case when cal.RETAIL_WEEK <= (select retail_week from DW_CAL_DT where AGE_FOR_RTL_WEEK_ID = -1 group by 1) then 'YTD' else 'Other' end as ytd_flag
	,case when cal.RETAIL_YEAR = (select retail_year from DW_CAL_DT where AGE_FOR_RTL_WEEK_ID = -1 group by 1) then 'Current Year' else 'Last Year' end as ty_flag
	,case when top_sellers.seller_id = lstg.SLR_ID then lstg.slr_id else 'Other Sellers' end as seller_id
	,case when top_sellers.seller_id = lstg.SLR_ID then u.user_slctd_id else 'Other Sellers' end as seller_name
	,lstg.B2C_C2C as Business_flag
	,cd.cndtn_descr
	,inv.INVENTORY_PROP
	,cat.META_CATEG_NAME
	,cat.CATEG_LVL2_NAME
	,cat.CATEG_LVL3_NAME
	,cat.CATEG_LVL4_NAME
	,cat.new_vertical
	,0 as GMV_Dom
	,0 as GMV_CBT
	,0 as GMV
	,0 as SI_Dom
	,0 as SI_CBT
	,0 as SI
	,count(distinct lstg.item_id) as LL

	FROM PRS_RESTRICTED_V.SLNG_LSTG_SUPER_FACT lstg	
	INNER JOIN DW_CAL_DT CAL
				ON lstg.AUCT_START_DT <= cal.CAL_DT and lstg.AUCT_END_DT >= cal.cal_dt
				and (RETAIL_YEAR >= (select retail_year from ACCESS_VIEWS.DW_CAL_DT where AGE_FOR_RTL_WEEK_ID = -1 group by 1)-1)
				and AGE_FOR_RTL_WEEK_ID <= -1
	INNER JOIN DW_USERS u
				on u.user_id = lstg.slr_id
	INNER JOIN P_INVENTORYPLANNING_T.dw_category_groupings_adj CAT
			ON lstg.LEAF_CATEG_ID = CAT.LEAF_CATEG_ID
			AND cat.site_id = 3
	LEFT JOIN top_sellers on top_sellers.seller_id = lstg.SLR_ID
	LEFT JOIN ACCESS_VIEWS.LSTG_ITEM_CNDTN AS CNDTN
				ON lstg.ITEM_ID = CNDTN.ITEM_ID
	LEFT JOIN P_ROBEVANS_T.item_cndtn_descr cd
				on cd.cndtn_rollup_id = CNDTN.CNDTN_ROLLUP_ID
	LEFT JOIN (
				select ITEM_ID
					,new_vertical as inv_vertical
					,INVENTORY_PROP
				from p_robevans_t.lifestyle_inv_props
				group by 1,2,3
				) INV
					on inv.item_id = lstg.item_id
	LEFT JOIN
		(
		Select retail_week as max_week
		,retail_year as max_year
		,RTL_QTR_OF_RTL_YEAR_ID as max_quarter
		From DW_CAL_DT
		Where AGE_FOR_RTL_WEEK_ID = -1
		Group by 1,2,3
		) max

	WHERE 1=1
	and lstg.ITEM_SITE_ID = 3
	and lstg.SLR_CNTRY_ID = 3
	and lstg.AUCT_END_DT > '2020-12-20'
	and cat.new_vertical = 'Lifestyle'

	GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18
	) lstg
LEFT JOIN
	(
	SELECT
	retail_year
	,case when cal.AGE_FOR_RTL_WEEK_ID in (-1,-2,-53) then cal.AGE_FOR_RTL_WEEK_ID else 'Other' End as latest_wk_flag
	,case when (cal.RTL_QTR_OF_RTL_YEAR_ID = (select RTL_QTR_OF_RTL_YEAR_ID from DW_CAL_DT where AGE_FOR_RTL_WEEK_ID = -1 group by 1)) and (retail_week <= (select retail_week from DW_CAL_DT where AGE_FOR_RTL_WEEK_ID = -1 group by 1)) then 'QTD' else 'Other' end as qtd_flag
	,case when cal.RETAIL_WEEK <= (select retail_week from DW_CAL_DT where AGE_FOR_RTL_WEEK_ID = -1 group by 1) then 'YTD' else 'Other' end as ytd_flag
	,case when cal.RETAIL_YEAR = (select retail_year from DW_CAL_DT where AGE_FOR_RTL_WEEK_ID = -1 group by 1) then 'Current Year' else 'Last Year' end as ty_flag
	,case when top_sellers.seller_id = trfc.seller_id then trfc.seller_id else 'Other Sellers' end as seller_id
	,cd.cndtn_descr
	,inv.INVENTORY_PROP
	,cat.META_CATEG_NAME
	,cat.CATEG_LVL2_NAME
	,cat.CATEG_LVL3_NAME
	,cat.CATEG_LVL4_NAME
	,cat.new_vertical
	,sum(trfc.TTL_VI_CNT) as VI
	,sum(trfc.SRP_IMPRSN_CNT)+sum(trfc.STORE_IMPRSN_CNT) as IMP

	FROM PRS_RESTRICTED_V.SLNG_TRFC_SUPER_FACT trfc	
	INNER JOIN P_INVENTORYPLANNING_T.dw_category_groupings_adj CAT
		ON trfc.LEAF_CATEG_ID = CAT.LEAF_CATEG_ID
		AND cat.site_id = 3	
	INNER JOIN DW_CAL_DT CAL
		ON trfc.cal_dt = cal.CAL_DT
		and (RETAIL_YEAR >= (select retail_year from ACCESS_VIEWS.DW_CAL_DT where AGE_FOR_RTL_WEEK_ID = -1 group by 1)-1)
		and	AGE_FOR_RTL_WEEK_ID <= -1
	left JOIN top_sellers
		on top_sellers.seller_id = trfc.SELLER_ID
	LEFT JOIN ACCESS_VIEWS.LSTG_ITEM_CNDTN AS CNDTN
				ON trfc.ITEM_ID = CNDTN.ITEM_ID
	LEFT JOIN P_ROBEVANS_T.item_cndtn_descr cd
				on cd.cndtn_rollup_id = CNDTN.CNDTN_ROLLUP_ID
	LEFT JOIN
		(
		select ITEM_ID
			,INVENTORY_PROP
		from p_robevans_t.lifestyle_inv_props
		group by 1,2
		) INV
			on inv.item_id = trfc.item_id

	WHERE 1=1
		AND trfc.SITE_ID = 3
		and cat.NEW_VERTICAL = 'Lifestyle'

	GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12,13
	) trfc
		on lstg.retail_year = trfc.retail_year
		and lstg.latest_wk_flag = trfc.latest_wk_flag
		and lstg.qtd_flag = trfc.qtd_flag
		and lstg.ytd_flag = trfc.ytd_flag
		and lstg.ty_flag = trfc.ty_flag
		and lstg.seller_id = trfc.seller_id
		and lstg.cndtn_descr = trfc.cndtn_descr
		and lstg.INVENTORY_PROP = trfc.INVENTORY_PROP
		and lstg.META_CATEG_NAME = trfc.META_CATEG_NAME
		and lstg.CATEG_LVL2_NAME = trfc.CATEG_LVL2_NAME
		and lstg.CATEG_LVL3_NAME = trfc.CATEG_LVL3_NAME
		and lstg.CATEG_LVL4_NAME = trfc.CATEG_LVL4_NAME
		and lstg.new_vertical = trfc.new_vertical


UNION ALL



SELECT
	retail_year
	,max_week
	,max_year
	,max_quarter
	,case when cal.AGE_FOR_RTL_WEEK_ID in (-1,-2,-53) then cal.AGE_FOR_RTL_WEEK_ID else 'Other' End as latest_wk_flag
	,case when (cal.RTL_QTR_OF_RTL_YEAR_ID = (select RTL_QTR_OF_RTL_YEAR_ID from DW_CAL_DT where AGE_FOR_RTL_WEEK_ID = -1 group by 1)) and (retail_week <= (select retail_week from DW_CAL_DT where AGE_FOR_RTL_WEEK_ID = -1 group by 1)) then 'QTD' else 'Other' end as qtd_flag
	,case when cal.RETAIL_WEEK <= (select retail_week from DW_CAL_DT where AGE_FOR_RTL_WEEK_ID = -1 group by 1) then 'YTD' else 'Other' end as ytd_flag
	,case when cal.RETAIL_YEAR = (select retail_year from DW_CAL_DT where AGE_FOR_RTL_WEEK_ID = -1 group by 1) then 'Current Year' else 'Last Year' end as ty_flag
	,case when top_sellers.seller_id = ck.seller_id then ck.seller_id else 'Other Sellers' end as seller_id
	,case when top_sellers.seller_id = ck.seller_id then u.user_slctd_id else 'Other Sellers' end as seller_name
	,ck.B2C_C2C as Business_flag
	,cd.cndtn_descr
	,inv.INVENTORY_PROP
	,cat.META_CATEG_NAME
	,cat.CATEG_LVL2_NAME
	,cat.CATEG_LVL3_NAME
	,cat.CATEG_LVL4_NAME
	,cat.new_vertical
	,sum(case when ck.DOMESTIC_CBT = 'Domestic' then GMV20_PLAN end) as GMV_Dom
	,sum(case when ck.DOMESTIC_CBT = 'CBT' then GMV20_PLAN end) as GMV_CBT
	,sum(ck.GMV20_PLAN) as GMV
	,sum(case when ck.DOMESTIC_CBT = 'Domestic' then GMV20_SOLD_QUANTITY end) as SI_Dom
	,sum(case when ck.DOMESTIC_CBT = 'CBT' then GMV20_SOLD_QUANTITY end) as SI_CBT
	,sum(ck.GMV20_SOLD_QUANTITY) as SI
	,0 as LL
	,0 as VI
	,0 as IMP


FROM PRS_RESTRICTED_V.SLNG_TRANS_SUPER_FACT ck	
INNER JOIN DW_CAL_DT CAL
			ON ck.GMV_DT= cal.cal_dt
			and (RETAIL_YEAR >= (select retail_year from ACCESS_VIEWS.DW_CAL_DT where AGE_FOR_RTL_WEEK_ID = -1 group by 1)-1)
			and AGE_FOR_RTL_WEEK_ID <= -1
INNER JOIN DW_USERS u
			on u.user_id = ck.SELLER_ID
LEFT JOIN top_sellers on top_sellers.seller_id = ck.SELLER_ID
INNER JOIN P_INVENTORYPLANNING_T.dw_category_groupings_adj CAT
		ON ck.LEAF_CATEG_ID = CAT.LEAF_CATEG_ID
		AND cat.site_id = 3
LEFT JOIN ACCESS_VIEWS.LSTG_ITEM_CNDTN AS CNDTN
			ON ck.ITEM_ID = CNDTN.ITEM_ID
LEFT JOIN P_ROBEVANS_T.item_cndtn_descr cd
			on cd.cndtn_rollup_id = CNDTN.CNDTN_ROLLUP_ID
LEFT JOIN (
			select ITEM_ID
				,new_vertical as inv_vertical
				,INVENTORY_PROP
			from p_robevans_t.lifestyle_inv_props group by 1,2,3
		) INV
			on inv.item_id = ck.item_id
LEFT JOIN
		(
		Select retail_week as max_week
		,retail_year as max_year
		,RTL_QTR_OF_RTL_YEAR_ID as max_quarter
		From DW_CAL_DT
		Where AGE_FOR_RTL_WEEK_ID = -1
		Group by 1,2,3
		) max
			
WHERE 1=1
and ck.SITE_ID = 3
and ck.SLR_CNTRY_ID = 3
and ck.CK_WACKO_YN = 'N'
and ck.AUCT_END_DT > '2020-12-20'
and cat.new_vertical = 'Lifestyle'

GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18

;





---------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------- Top Brands ----------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------

Drop table if exists P_UKPLAN_REPORT_T.lifestyle_subcat_top_brands;

Create table P_UKPLAN_REPORT_T.lifestyle_subcat_top_brands as

With top_brands as
(
Select brand
From
	(
	----------Latest Week Top Brands----------------
	Select 
		cat.META_CATEG_ID
		,cat.CATEG_LVL2_ID
		,cat.CATEG_LVL3_ID
		,cat.CATEG_LVL4_ID
		,inv.INVENTORY_PROP
		,brnd.brand
		,sum(GMV20_PLAN) as gmv
		,dense_rank() over (partition by cat.META_CATEG_ID order by sum(GMV20_PLAN) desc) as rank_meta
		,dense_rank() over (partition by cat.CATEG_LVL2_ID order by sum(GMV20_PLAN) desc) as rank_L2
		,dense_rank() over (partition by cat.CATEG_LVL3_ID order by sum(GMV20_PLAN) desc) as rank_L3
		,dense_rank() over (partition by cat.CATEG_LVL4_ID order by sum(GMV20_PLAN) desc) as rank_L4
		,dense_rank() over (partition by inv.INVENTORY_PROP order by sum(GMV20_PLAN) desc) as rank_inv
	From PRS_RESTRICTED_V.SLNG_TRANS_SUPER_FACT ck	
	INNER JOIN DW_CAL_DT cal 
		ON ck.GMV_DT = cal.CAL_DT
		AND cal.AGE_FOR_RTL_WEEK_ID = -1
	INNER JOIN P_INVENTORYPLANNING_T.dw_category_groupings_adj CAT
		ON ck.LEAF_CATEG_ID = CAT.LEAF_CATEG_ID
		AND cat.site_id = 3
	inner join (Select
				item_id,
				coalesce(max(case  when lower(aspect)=lower('BRAND') then aspct_vlu_nm else NULL end ),'-Not Disclosed-') as BRAND
			FROM
				(select
					item_id,
					auct_end_dt,
					ns_type_cd,
					1 as priority,
					'BRAND' as aspect,
					cast(trim(lower(aspct_vlu_nm)) as VARCHAR(350)) as aspct_vlu_nm 
				from
					item_aspct_clssfctn
				where
					AUCT_END_DT>='2016-06-01'
					AND lower(ns_type_cd) in (lower('nf'),lower('df' ) ) and upper(prdct_aspct_nm)= upper('BRAND')
				UNION ALL
				select
					item_id,
					auct_end_dt,
					ns_type_cd,
					2 as priority,
					'BRAND' as aspect,
					cast(trim(lower(aspct_vlu_nm)) as VARCHAR(350)) as aspct_vlu_nm
				from
					item_aspct_clssfctn_cold
				WHERE
					AUCT_END_DT>='2016-06-01'
					AND lower(ns_type_cd) in (lower('nf'),lower('df' ) ) and upper(prdct_aspct_nm)= upper('BRAND')
				)SB
			GROUP BY 1) brnd ON ck.ITEM_ID = brnd.ITEM_ID
	LEFT JOIN	
		(select ITEM_ID
			,INVENTORY_PROP
		from p_robevans_t.lifestyle_inv_props
		group by 1,2
		) INV
			on inv.item_id = ck.item_id
	Where 1=1
		and ck.SLR_CNTRY_ID = 3
		and ck.SITE_ID = 3
		and cat.new_vertical = 'Lifestyle'
	Group by 1,2,3,4,5,6
	
	UNION ALL


	----------Latest Quarter Top Brands----------------
	Select 
		cat.META_CATEG_ID
		,cat.CATEG_LVL2_ID
		,cat.CATEG_LVL3_ID
		,cat.CATEG_LVL4_ID
		,inv.INVENTORY_PROP
		,brnd.brand
		,sum(GMV20_PLAN) as gmv
		,dense_rank() over (partition by cat.META_CATEG_ID order by sum(GMV20_PLAN) desc) as rank_meta
		,dense_rank() over (partition by cat.CATEG_LVL2_ID order by sum(GMV20_PLAN) desc) as rank_L2
		,dense_rank() over (partition by cat.CATEG_LVL3_ID order by sum(GMV20_PLAN) desc) as rank_L3
		,dense_rank() over (partition by cat.CATEG_LVL4_ID order by sum(GMV20_PLAN) desc) as rank_L4
		,dense_rank() over (partition by inv.INVENTORY_PROP order by sum(GMV20_PLAN) desc) as rank_inv
	From PRS_RESTRICTED_V.SLNG_TRANS_SUPER_FACT ck	
	INNER JOIN DW_CAL_DT cal 
		ON ck.GMV_DT = cal.CAL_DT
		AND cal.RTL_QTR_OF_RTL_YEAR_ID = (select RTL_QTR_OF_RTL_YEAR_ID from DW_CAL_DT where AGE_FOR_RTL_WEEK_ID = -1 group by 1)
		and cal.retail_year = (select RETAIL_YEAR from DW_CAL_DT where AGE_FOR_RTL_WEEK_ID = -1 group by 1)
	INNER JOIN P_INVENTORYPLANNING_T.dw_category_groupings_adj CAT
		ON ck.LEAF_CATEG_ID = CAT.LEAF_CATEG_ID
		AND cat.site_id = 3
	inner join (Select
				item_id,
				coalesce(max(case  when lower(aspect)=lower('BRAND') then aspct_vlu_nm else NULL end ),'-Not Disclosed-') as BRAND
			FROM
				(select
					item_id,
					auct_end_dt,
					ns_type_cd,
					1 as priority,
					'BRAND' as aspect,
					cast(trim(lower(aspct_vlu_nm)) as VARCHAR(350)) as aspct_vlu_nm 
				from
					item_aspct_clssfctn
				where
					AUCT_END_DT>='2016-06-01'
					AND lower(ns_type_cd) in (lower('nf'),lower('df' ) ) and upper(prdct_aspct_nm)= upper('BRAND')
				UNION ALL
				select
					item_id,
					auct_end_dt,
					ns_type_cd,
					2 as priority,
					'BRAND' as aspect,
					cast(trim(lower(aspct_vlu_nm)) as VARCHAR(350)) as aspct_vlu_nm
				from
					item_aspct_clssfctn_cold
				WHERE
					AUCT_END_DT>='2016-06-01'
					AND lower(ns_type_cd) in (lower('nf'),lower('df' ) ) and upper(prdct_aspct_nm)= upper('BRAND')
				)SB
			GROUP BY 1) brnd ON ck.ITEM_ID = brnd.ITEM_ID
	LEFT JOIN	
		(select ITEM_ID
			,INVENTORY_PROP
		from p_robevans_t.lifestyle_inv_props
		group by 1,2
		) INV
			on inv.item_id = ck.item_id
	Where 1=1
		and ck.SLR_CNTRY_ID = 3
		and ck.SITE_ID = 3
		and cat.new_vertical = 'Lifestyle'
	Group by 1,2,3,4,5,6
	
	UNION ALL
	
	----------YTD Top Brands----------------
	Select 
		cat.META_CATEG_ID
		,cat.CATEG_LVL2_ID
		,cat.CATEG_LVL3_ID
		,cat.CATEG_LVL4_ID
		,inv.INVENTORY_PROP
		,brnd.brand
		,sum(GMV20_PLAN) as gmv
		,dense_rank() over (partition by cat.META_CATEG_ID order by sum(GMV20_PLAN) desc) as rank_meta
		,dense_rank() over (partition by cat.CATEG_LVL2_ID order by sum(GMV20_PLAN) desc) as rank_L2
		,dense_rank() over (partition by cat.CATEG_LVL3_ID order by sum(GMV20_PLAN) desc) as rank_L3
		,dense_rank() over (partition by cat.CATEG_LVL4_ID order by sum(GMV20_PLAN) desc) as rank_L4
		,dense_rank() over (partition by inv.INVENTORY_PROP order by sum(GMV20_PLAN) desc) as rank_inv
	From PRS_RESTRICTED_V.SLNG_TRANS_SUPER_FACT ck	
	INNER JOIN DW_CAL_DT cal 
		ON ck.GMV_DT = cal.CAL_DT
		AND cal.RETAIL_YEAR = (select RETAIL_YEAR from DW_CAL_DT where AGE_FOR_RTL_WEEK_ID = -1 group by 1)
	INNER JOIN P_INVENTORYPLANNING_T.dw_category_groupings_adj CAT
		ON ck.LEAF_CATEG_ID = CAT.LEAF_CATEG_ID
		AND cat.site_id = 3
	inner join (Select
				item_id,
				coalesce(max(case  when lower(aspect)=lower('BRAND') then aspct_vlu_nm else NULL end ),'-Not Disclosed-') as BRAND
			FROM
				(select
					item_id,
					auct_end_dt,
					ns_type_cd,
					1 as priority,
					'BRAND' as aspect,
					cast(trim(lower(aspct_vlu_nm)) as VARCHAR(350)) as aspct_vlu_nm 
				from
					item_aspct_clssfctn
				where
					AUCT_END_DT>='2016-06-01'
					AND lower(ns_type_cd) in (lower('nf'),lower('df' ) ) and upper(prdct_aspct_nm)= upper('BRAND')
				UNION ALL
				select
					item_id,
					auct_end_dt,
					ns_type_cd,
					2 as priority,
					'BRAND' as aspect,
					cast(trim(lower(aspct_vlu_nm)) as VARCHAR(350)) as aspct_vlu_nm
				from
					item_aspct_clssfctn_cold
				WHERE
					AUCT_END_DT>='2016-06-01'
					AND lower(ns_type_cd) in (lower('nf'),lower('df' ) ) and upper(prdct_aspct_nm)= upper('BRAND')
				)SB
			GROUP BY 1) brnd ON ck.ITEM_ID = brnd.ITEM_ID
	LEFT JOIN	
		(select ITEM_ID
			,INVENTORY_PROP
		from p_robevans_t.lifestyle_inv_props
		group by 1,2
		) INV
			on inv.item_id = ck.item_id
	Where 1=1
		and ck.SLR_CNTRY_ID = 3
		and ck.SITE_ID = 3
		and cat.new_vertical = 'Lifestyle'
	Group by 1,2,3,4,5,6
	)
Where rank_meta <= 25
 OR rank_L2 <= 25
 OR rank_L3 <= 25
 OR rank_L4 <= 25
 OR rank_inv <= 25
 
Group by 1
)



select lstg.* 
	,trfc.vi as VI
	,trfc.imp as IMP
FROM
	(
	SELECT
	retail_year
	,max_week
	,max_year
	,max_quarter
	,case when cal.AGE_FOR_RTL_WEEK_ID in (-1,-2,-53) then cal.AGE_FOR_RTL_WEEK_ID else 'Other' End as latest_wk_flag
	,case when (cal.RTL_QTR_OF_RTL_YEAR_ID = (select RTL_QTR_OF_RTL_YEAR_ID from DW_CAL_DT where AGE_FOR_RTL_WEEK_ID = -1 group by 1)) and (retail_week <= (select retail_week from DW_CAL_DT where AGE_FOR_RTL_WEEK_ID = -1 group by 1)) then 'QTD' else 'Other' end as qtd_flag
	,case when cal.RETAIL_WEEK <= (select retail_week from DW_CAL_DT where AGE_FOR_RTL_WEEK_ID = -1 group by 1) then 'YTD' else 'Other' end as ytd_flag
	,case when cal.RETAIL_YEAR = (select retail_year from DW_CAL_DT where AGE_FOR_RTL_WEEK_ID = -1 group by 1) then 'Current Year' else 'Last Year' end as ty_flag
	,case when lstg.item_id = brnd.item_id then brnd.brand else '-Other Brands-' end as brand
	,lstg.B2C_C2C as Business_flag
	,cd.cndtn_descr
	,inv.INVENTORY_PROP
	,cat.META_CATEG_NAME
	,cat.CATEG_LVL2_NAME
	,cat.CATEG_LVL3_NAME
	,cat.CATEG_LVL4_NAME
	,cat.new_vertical
	,0 as GMV_Dom
	,0 as GMV_CBT
	,0 as GMV
	,0 as SI_Dom
	,0 as SI_CBT
	,0 as SI
	,count(distinct lstg.item_id) as LL

	FROM PRS_RESTRICTED_V.SLNG_LSTG_SUPER_FACT lstg	
	INNER JOIN DW_CAL_DT CAL
				ON lstg.AUCT_START_DT <= cal.CAL_DT and lstg.AUCT_END_DT >= cal.cal_dt
				and (RETAIL_YEAR >= (select retail_year from ACCESS_VIEWS.DW_CAL_DT where AGE_FOR_RTL_WEEK_ID = -1 group by 1)-1)
				and AGE_FOR_RTL_WEEK_ID <= -1
	INNER JOIN P_INVENTORYPLANNING_T.dw_category_groupings_adj CAT
			ON lstg.LEAF_CATEG_ID = CAT.LEAF_CATEG_ID
			AND cat.site_id = 3
	LEFT join (
				Select
					item_id,
					coalesce(max(case  when lower(aspect)=lower('BRAND') then aspct_vlu_nm else NULL end ),'-Not Disclosed-') as BRAND
				FROM
					(select
						item_id,
						auct_end_dt,
						ns_type_cd,
						1 as priority,
						'BRAND' as aspect,
						cast(trim(lower(aspct_vlu_nm)) as VARCHAR(350)) as aspct_vlu_nm 
					from
						item_aspct_clssfctn
					where
						AUCT_END_DT>='2016-06-01'
						AND lower(ns_type_cd) in (lower('nf'),lower('df' ) ) and upper(prdct_aspct_nm)= upper('BRAND')
					UNION ALL
					select
						item_id,
						auct_end_dt,
						ns_type_cd,
						2 as priority,
						'BRAND' as aspect,
						cast(trim(lower(aspct_vlu_nm)) as VARCHAR(350)) as aspct_vlu_nm
					from
						item_aspct_clssfctn_cold
					WHERE
						AUCT_END_DT>='2016-06-01'
						AND lower(ns_type_cd) in (lower('nf'),lower('df' ) ) and upper(prdct_aspct_nm)= upper('BRAND')
					)SB
				inner JOIN top_brands
					on top_brands.brand = sb.aspct_vlu_nm
			GROUP BY 1
			) brnd
				ON lstg.ITEM_ID = brnd.ITEM_ID
	LEFT JOIN ACCESS_VIEWS.LSTG_ITEM_CNDTN AS CNDTN
				ON lstg.ITEM_ID = CNDTN.ITEM_ID
	LEFT JOIN P_ROBEVANS_T.item_cndtn_descr cd
				on cd.cndtn_rollup_id = CNDTN.CNDTN_ROLLUP_ID
	LEFT JOIN (
				select ITEM_ID
					,new_vertical as inv_vertical
					,INVENTORY_PROP
				from p_robevans_t.lifestyle_inv_props
				group by 1,2,3
				) INV
					on inv.item_id = lstg.item_id
	LEFT JOIN
		(
		Select retail_week as max_week
		,retail_year as max_year
		,RTL_QTR_OF_RTL_YEAR_ID as max_quarter
		From DW_CAL_DT
		Where AGE_FOR_RTL_WEEK_ID = -1
		Group by 1,2,3
		) max

	WHERE 1=1
	and lstg.ITEM_SITE_ID = 3
	and lstg.SLR_CNTRY_ID = 3
	and lstg.AUCT_END_DT > '2020-12-20'
	and cat.new_vertical = 'Lifestyle'

	GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17
	) lstg
LEFT JOIN
	(
	SELECT
	retail_year
	,case when cal.AGE_FOR_RTL_WEEK_ID in (-1,-2,-53) then cal.AGE_FOR_RTL_WEEK_ID else 'Other' End as latest_wk_flag
	,case when (cal.RTL_QTR_OF_RTL_YEAR_ID = (select RTL_QTR_OF_RTL_YEAR_ID from DW_CAL_DT where AGE_FOR_RTL_WEEK_ID = -1 group by 1)) and (retail_week <= (select retail_week from DW_CAL_DT where AGE_FOR_RTL_WEEK_ID = -1 group by 1)) then 'QTD' else 'Other' end as qtd_flag
	,case when cal.RETAIL_WEEK <= (select retail_week from DW_CAL_DT where AGE_FOR_RTL_WEEK_ID = -1 group by 1) then 'YTD' else 'Other' end as ytd_flag
	,case when cal.RETAIL_YEAR = (select retail_year from DW_CAL_DT where AGE_FOR_RTL_WEEK_ID = -1 group by 1) then 'Current Year' else 'Last Year' end as ty_flag
	,case when trfc.item_id = brnd.item_id then brnd.brand else '-Other Brands-' end as brand
	,cd.cndtn_descr
	,inv.INVENTORY_PROP
	,cat.META_CATEG_NAME
	,cat.CATEG_LVL2_NAME
	,cat.CATEG_LVL3_NAME
	,cat.CATEG_LVL4_NAME
	,cat.new_vertical
	,sum(trfc.TTL_VI_CNT) as VI
	,sum(trfc.SRP_IMPRSN_CNT)+sum(trfc.STORE_IMPRSN_CNT) as IMP

	FROM PRS_RESTRICTED_V.SLNG_TRFC_SUPER_FACT trfc	
	INNER JOIN P_INVENTORYPLANNING_T.dw_category_groupings_adj CAT
		ON trfc.LEAF_CATEG_ID = CAT.LEAF_CATEG_ID
		AND cat.site_id = 3	
	INNER JOIN DW_CAL_DT CAL
		ON trfc.cal_dt = cal.CAL_DT
		and (RETAIL_YEAR >= (select retail_year from ACCESS_VIEWS.DW_CAL_DT where AGE_FOR_RTL_WEEK_ID = -1 group by 1)-1)
		and	AGE_FOR_RTL_WEEK_ID <= -1
	LEFT join (
				Select
					item_id,
					coalesce(max(case  when lower(aspect)=lower('BRAND') then aspct_vlu_nm else NULL end ),'-Not Disclosed-') as BRAND
				FROM
					(select
						item_id,
						auct_end_dt,
						ns_type_cd,
						1 as priority,
						'BRAND' as aspect,
						cast(trim(lower(aspct_vlu_nm)) as VARCHAR(350)) as aspct_vlu_nm 
					from
						item_aspct_clssfctn
					where
						AUCT_END_DT>='2016-06-01'
						AND lower(ns_type_cd) in (lower('nf'),lower('df' ) ) and upper(prdct_aspct_nm)= upper('BRAND')
					UNION ALL
					select
						item_id,
						auct_end_dt,
						ns_type_cd,
						2 as priority,
						'BRAND' as aspect,
						cast(trim(lower(aspct_vlu_nm)) as VARCHAR(350)) as aspct_vlu_nm
					from
						item_aspct_clssfctn_cold
					WHERE
						AUCT_END_DT>='2016-06-01'
						AND lower(ns_type_cd) in (lower('nf'),lower('df' ) ) and upper(prdct_aspct_nm)= upper('BRAND')
					)SB
				inner JOIN top_brands
					on top_brands.brand = sb.aspct_vlu_nm
			GROUP BY 1
			) brnd
				ON trfc.ITEM_ID = brnd.ITEM_ID
	LEFT JOIN ACCESS_VIEWS.LSTG_ITEM_CNDTN AS CNDTN
				ON trfc.ITEM_ID = CNDTN.ITEM_ID
	LEFT JOIN P_ROBEVANS_T.item_cndtn_descr cd
				on cd.cndtn_rollup_id = CNDTN.CNDTN_ROLLUP_ID
	LEFT JOIN
		(
		select ITEM_ID
			,INVENTORY_PROP
		from p_robevans_t.lifestyle_inv_props
		group by 1,2
		) INV
			on inv.item_id = trfc.item_id

	WHERE 1=1
		AND trfc.SITE_ID = 3
		and cat.NEW_VERTICAL = 'Lifestyle'

	GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12,13
	) trfc
		on lstg.retail_year = trfc.retail_year
		and lstg.latest_wk_flag = trfc.latest_wk_flag
		and lstg.qtd_flag = trfc.qtd_flag
		and lstg.ytd_flag = trfc.ytd_flag
		and lstg.ty_flag = trfc.ty_flag
		and lstg.brand = trfc.brand
		and lstg.cndtn_descr = trfc.cndtn_descr
		and lstg.INVENTORY_PROP = trfc.INVENTORY_PROP
		and lstg.META_CATEG_NAME = trfc.META_CATEG_NAME
		and lstg.CATEG_LVL2_NAME = trfc.CATEG_LVL2_NAME
		and lstg.CATEG_LVL3_NAME = trfc.CATEG_LVL3_NAME
		and lstg.CATEG_LVL4_NAME = trfc.CATEG_LVL4_NAME
		and lstg.new_vertical = trfc.new_vertical


UNION ALL



SELECT
	retail_year
	,max_week
	,max_year
	,max_quarter
	,case when cal.AGE_FOR_RTL_WEEK_ID in (-1,-2,-53) then cal.AGE_FOR_RTL_WEEK_ID else 'Other' End as latest_wk_flag
	,case when (cal.RTL_QTR_OF_RTL_YEAR_ID = (select RTL_QTR_OF_RTL_YEAR_ID from DW_CAL_DT where AGE_FOR_RTL_WEEK_ID = -1 group by 1)) and (retail_week <= (select retail_week from DW_CAL_DT where AGE_FOR_RTL_WEEK_ID = -1 group by 1)) then 'QTD' else 'Other' end as qtd_flag
	,case when cal.RETAIL_WEEK <= (select retail_week from DW_CAL_DT where AGE_FOR_RTL_WEEK_ID = -1 group by 1) then 'YTD' else 'Other' end as ytd_flag
	,case when cal.RETAIL_YEAR = (select retail_year from DW_CAL_DT where AGE_FOR_RTL_WEEK_ID = -1 group by 1) then 'Current Year' else 'Last Year' end as ty_flag
	,case when ck.item_id = brnd.item_id then brnd.brand else '-Other Brands-' end as brand
	,ck.B2C_C2C as Business_flag
	,cd.cndtn_descr
	,inv.INVENTORY_PROP
	,cat.META_CATEG_NAME
	,cat.CATEG_LVL2_NAME
	,cat.CATEG_LVL3_NAME
	,cat.CATEG_LVL4_NAME
	,cat.new_vertical
	,sum(case when ck.DOMESTIC_CBT = 'Domestic' then GMV20_PLAN end) as GMV_Dom
	,sum(case when ck.DOMESTIC_CBT = 'CBT' then GMV20_PLAN end) as GMV_CBT
	,sum(ck.GMV20_PLAN) as GMV
	,sum(case when ck.DOMESTIC_CBT = 'Domestic' then GMV20_SOLD_QUANTITY end) as SI_Dom
	,sum(case when ck.DOMESTIC_CBT = 'CBT' then GMV20_SOLD_QUANTITY end) as SI_CBT
	,sum(ck.GMV20_SOLD_QUANTITY) as SI
	,0 as LL
	,0 as VI
	,0 as IMP

FROM PRS_RESTRICTED_V.SLNG_TRANS_SUPER_FACT ck	
INNER JOIN DW_CAL_DT CAL
			ON ck.GMV_DT= cal.cal_dt
			and (RETAIL_YEAR >= (select retail_year from ACCESS_VIEWS.DW_CAL_DT where AGE_FOR_RTL_WEEK_ID = -1 group by 1)-1)
			and AGE_FOR_RTL_WEEK_ID <= -1
INNER JOIN P_INVENTORYPLANNING_T.dw_category_groupings_adj CAT
		ON ck.LEAF_CATEG_ID = CAT.LEAF_CATEG_ID
		AND cat.site_id = 3
LEFT join (
			Select
				item_id,
				coalesce(max(case  when lower(aspect)=lower('BRAND') then aspct_vlu_nm else NULL end ),'-Not Disclosed-') as BRAND
			FROM
				(select
					item_id,
					auct_end_dt,
					ns_type_cd,
					1 as priority,
					'BRAND' as aspect,
					cast(trim(lower(aspct_vlu_nm)) as VARCHAR(350)) as aspct_vlu_nm 
				from
					item_aspct_clssfctn
				where
					AUCT_END_DT>='2016-06-01'
					AND lower(ns_type_cd) in (lower('nf'),lower('df' ) ) and upper(prdct_aspct_nm)= upper('BRAND')
				UNION ALL
				select
					item_id,
					auct_end_dt,
					ns_type_cd,
					2 as priority,
					'BRAND' as aspect,
					cast(trim(lower(aspct_vlu_nm)) as VARCHAR(350)) as aspct_vlu_nm
				from
					item_aspct_clssfctn_cold
				WHERE
					AUCT_END_DT>='2016-06-01'
					AND lower(ns_type_cd) in (lower('nf'),lower('df' ) ) and upper(prdct_aspct_nm)= upper('BRAND')
				)SB
			inner JOIN top_brands
				on top_brands.brand = sb.aspct_vlu_nm
		GROUP BY 1
		) brnd
			ON ck.ITEM_ID = brnd.ITEM_ID
LEFT JOIN ACCESS_VIEWS.LSTG_ITEM_CNDTN AS CNDTN
			ON ck.ITEM_ID = CNDTN.ITEM_ID
LEFT JOIN P_ROBEVANS_T.item_cndtn_descr cd
			on cd.cndtn_rollup_id = CNDTN.CNDTN_ROLLUP_ID
LEFT JOIN (
			select ITEM_ID
				,new_vertical as inv_vertical
				,INVENTORY_PROP
			from p_robevans_t.lifestyle_inv_props group by 1,2,3
		) INV
			on inv.item_id = ck.item_id
LEFT JOIN
		(
		Select retail_week as max_week
		,retail_year as max_year
		,RTL_QTR_OF_RTL_YEAR_ID as max_quarter
		From DW_CAL_DT
		Where AGE_FOR_RTL_WEEK_ID = -1
		Group by 1,2,3
		) max
			
WHERE 1=1
and ck.SITE_ID = 3
and ck.SLR_CNTRY_ID = 3
and ck.CK_WACKO_YN = 'N'
and ck.AUCT_END_DT > '2020-12-20'
and cat.new_vertical = 'Lifestyle'

GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17

;
