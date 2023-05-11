
-- Author: 			Robbie Evans
-- Stakeholder: 	Alice Bridson, Emma Hamilton, Ines Morais, Penelope Faith
-- Purpose: 		To identify inventory gaps/opportunities in the Lux Focus Categories based on search/listings and conversion data
-- Date Created: 	24/03/2023




drop table if exists p_robevans_t.lux_assortment_planning;

create table p_robevans_t.lux_assortment_planning as

With time_frame AS
(
select *
From ACCESS_VIEWS.DW_CAL_DT
Where AGE_FOR_DT_ID >= -180
and AGE_FOR_DT_ID <= 0
)
,
top_brands as
(
select brand
From
	(
	Select 
	category
	, case when (lower(brand) like any ('unknown','no brand','null','%unbrand%') or brand is null) then 'Unknown'
		else brand
		End as brand
	, sum(gmv_plan_usd) as gmv
	, dense_rank() over (partition by category order by gmv desc) as price_rank

	FROM DW_CHECKOUT_TRANS ck
	INNER JOIN time_frame cal
		on ck.gmv_dt = cal.CAL_DT
	INNER JOIN ACCESS_VIEWS.DW_CATEGORY_GROUPINGS CAT 
			ON CAT.LEAF_CATEG_ID = ck.LEAF_CATEG_ID 
			AND CAT.SITE_ID = 3
			AND CAT.SAP_CATEGORY_ID NOT in (5,7,41,23,-999) 
			and (
				(cat.CATEG_LVL2_ID = 260324) --Watches
				or (cat.CATEG_LVL3_ID = 169291) OR (cat.CATEG_LVL4_ID IN (52357,163570,169285,45258,2996,45237,169271)) --Handbags
		-- 		OR cat.CATEG_LVL4_ID IN (15709,95672,155202,57974,57929) --Sneakers
				OR (cat.META_CATEG_ID = 281 AND cat.CATEG_LVL2_ID <> 260324) --Jewellery
				)
	inner join
		(select item_id, category
		From
			(select item_id
			,case when BIZ_PRGRM_NAME = 'PSA_SNEAKER_EBAY_UK' then 'Sneakers'
				when BIZ_PRGRM_NAME = 'PSA_HANDBAGS_UK' then 'Handbags'
				when BIZ_PRGRM_NAME = 'PSA_WATCHES_UK' then 'Watches'
				Else 'Other' End as category
			 from access_views.DW_PES_ELGBLT_HIST
			where biz_prgrm_name in ('PSA_SNEAKER_EBAY_UK','PSA_HANDBAGS_UK','PSA_WATCHES_UK')
				and ELGBL_YN_IND = 'Y'
		-- 		and coalesce( auct_end_date, '2099-12-31') >= CURRENT_DATE-7
			Group by 1,2

			UNION ALL

			Select ITEM_ID
			,'Jewellery' as category
			From PRS_RESTRICTED_V.SLNG_LSTG_SUPER_FACT lstg
			inner join time_frame cal
				on lstg.AUCT_START_DT <= cal.cal_dt
				and lstg.AUCT_END_DT >= cal.cal_dt
			where (case when START_PRICE_LSTG_CURNCY_AMT > RSRV_PRICE_LSTG_CURNCY_AMT then START_PRICE_LSTG_CURNCY_AMT else RSRV_PRICE_LSTG_CURNCY_AMT End) >= 500
			and SLR_CNTRY_ID = 3
			and LSTG_SITE_ID = 3
			and META_CATEG_ID = 281
			AND CATEG_LVL2_ID <> 260324
			Group by 1,2)
		Group by 1,2
		) PSA
			on ck.ITEM_ID = psa.item_id
	left join (Select
					item_id,
					coalesce(max(case  when lower(aspect)=lower('BRAND') then aspct_vlu_nm else NULL end ),'Unknown') as BRAND
				FROM
					(select
						item_id,
						ns_type_cd,
						1 as priority,
						'BRAND' as aspect,
						cast(trim(lower(aspct_vlu_nm)) as VARCHAR(350)) as aspct_vlu_nm, 
						(Row_Number() Over (PARTITION BY item_id,auct_end_dt,aspect ORDER BY priority,aspct_vlu_nm DESC)) AS dup_check
					from
						item_aspct_clssfctn
					where
						AUCT_END_DT>='2020-12-07'
						AND lower(ns_type_cd) in (lower('nf'),lower('df' ) ) and upper(prdct_aspct_nm)= upper('BRAND')
					)SB
				Where dup_check = 1
				GROUP BY 1) brand
					on ck.item_id = brand.item_id

	Where 1=1
	and ck.SLR_CNTRY_ID = 3
	and ck.RPRTD_WACKO_YN = 'N'

	Group by 1,2
	)

where price_rank <=100

Group by 1
)
,
top_models as
(
select model
From
	(
	Select 
	category
	, case when (lower(model) like any ('unknown','no model','null') or model is null) then 'Unknown'
		else model
		End as model
	, sum(gmv_plan_usd) as gmv
	, dense_rank() over (partition by category order by gmv desc) as price_rank

	FROM DW_CHECKOUT_TRANS ck
	INNER JOIN time_frame cal
		on ck.gmv_dt = cal.CAL_DT
	INNER JOIN ACCESS_VIEWS.DW_CATEGORY_GROUPINGS CAT 
			ON CAT.LEAF_CATEG_ID = ck.LEAF_CATEG_ID 
			AND CAT.SITE_ID = 3
			AND CAT.SAP_CATEGORY_ID NOT in (5,7,41,23,-999) 
			and (
				(cat.CATEG_LVL2_ID = 260324) --Watches
				or (cat.CATEG_LVL3_ID = 169291) OR (cat.CATEG_LVL4_ID IN (52357,163570,169285,45258,2996,45237,169271)) --Handbags
		-- 		OR cat.CATEG_LVL4_ID IN (15709,95672,155202,57974,57929) --Sneakers
				OR (cat.META_CATEG_ID = 281 AND cat.CATEG_LVL2_ID <> 260324) --Jewellery
				)
	inner join
		(select item_id, category
		From
			(select item_id
			,case when BIZ_PRGRM_NAME = 'PSA_SNEAKER_EBAY_UK' then 'Sneakers'
				when BIZ_PRGRM_NAME = 'PSA_HANDBAGS_UK' then 'Handbags'
				when BIZ_PRGRM_NAME = 'PSA_WATCHES_UK' then 'Watches'
				Else 'Other' End as category
			 from access_views.DW_PES_ELGBLT_HIST
			where biz_prgrm_name in ('PSA_SNEAKER_EBAY_UK','PSA_HANDBAGS_UK','PSA_WATCHES_UK')
				and ELGBL_YN_IND = 'Y'
		-- 		and coalesce( auct_end_date, '2099-12-31') >= CURRENT_DATE-7
			Group by 1,2

			UNION ALL

			Select ITEM_ID
			,'Jewellery' as category
			From PRS_RESTRICTED_V.SLNG_LSTG_SUPER_FACT lstg
			inner join time_frame cal
				on lstg.AUCT_START_DT <= cal.cal_dt
				and lstg.AUCT_END_DT >= cal.cal_dt
			where (case when START_PRICE_LSTG_CURNCY_AMT > RSRV_PRICE_LSTG_CURNCY_AMT then START_PRICE_LSTG_CURNCY_AMT else RSRV_PRICE_LSTG_CURNCY_AMT End) >= 500
			and SLR_CNTRY_ID = 3
			and LSTG_SITE_ID = 3
			and META_CATEG_ID = 281
			AND CATEG_LVL2_ID <> 260324
			Group by 1,2)
		Group by 1,2
		) PSA
			on ck.ITEM_ID = psa.item_id
left join (Select
					item_id,
					coalesce(max(case  when lower(aspect)=lower('MODEL') then aspct_vlu_nm else NULL end ),'Unknown') as MODEL
				FROM
					(select
						item_id,
						ns_type_cd,
						1 as priority,
						'MODEL' as aspect,
						cast(trim(lower(aspct_vlu_nm)) as VARCHAR(350)) as aspct_vlu_nm, 
						(Row_Number() Over (PARTITION BY item_id,auct_end_dt,aspect ORDER BY priority,aspct_vlu_nm DESC)) AS dup_check
					from
						item_aspct_clssfctn
					where
						AUCT_END_DT>='2020-12-07'
						AND lower(ns_type_cd) in (lower('nf'),lower('df' ) ) and upper(prdct_aspct_nm)= upper('MODEL')
					)SB
				Where dup_check = 1
				GROUP BY 1) model
					on ck.item_id = model.item_id

	Where 1=1
	and ck.SLR_CNTRY_ID = 3
	and ck.RPRTD_WACKO_YN = 'N'

	Group by 1,2
	)

where price_rank <=100

Group by 1
)
,
top_brands_models_items AS
(
Select 
ck.item_id
, category
, case when (ck.item_id = brand.item_id) and (lower(brand) like any ('%unbrand%','no brand','unknown')) then 'no brand'
		when (ck.ITEM_ID = brand.item_id) then brand
		else 'no brand'
		end as brand
, case when (ck.item_id = model.item_id) and (lower(model) like any ('%no model%','unknown')) then 'no model'
		when (ck.ITEM_ID = model.item_id) then model
		else 'no model'
		end as model

From DW_LSTG_ITEM ck
INNER JOIN time_frame cal
	on ck.auct_start_dt <= cal.CAL_DT
	and ck.AUCT_END_DT >= cal.cal_dt
INNER JOIN DW_CATEGORY_GROUPINGS CAT 
		ON CAT.LEAF_CATEG_ID = ck.LEAF_CATEG_ID 
		AND CAT.SITE_ID = 3
		AND CAT.SAP_CATEGORY_ID NOT in (5,7,41,23,-999) 
		and (
			(cat.CATEG_LVL2_ID = 260324) --Watches
			or (cat.CATEG_LVL3_ID = 169291) OR (cat.CATEG_LVL4_ID IN (52357,163570,169285,45258,2996,45237,169271)) --Handbags
	-- 		OR cat.CATEG_LVL4_ID IN (15709,95672,155202,57974,57929) --Sneakers
			OR (cat.META_CATEG_ID = 281 AND cat.CATEG_LVL2_ID <> 260324) --Jewellery
			)
	inner join
		(select item_id, category
		From
			(select item_id
			,case when BIZ_PRGRM_NAME = 'PSA_SNEAKER_EBAY_UK' then 'Sneakers'
				when BIZ_PRGRM_NAME = 'PSA_HANDBAGS_UK' then 'Handbags'
				when BIZ_PRGRM_NAME = 'PSA_WATCHES_UK' then 'Watches'
				Else 'Other' End as category
			 from access_views.DW_PES_ELGBLT_HIST
			where biz_prgrm_name in ('PSA_SNEAKER_EBAY_UK','PSA_HANDBAGS_UK','PSA_WATCHES_UK')
				and ELGBL_YN_IND = 'Y'
		-- 		and coalesce( auct_end_date, '2099-12-31') >= CURRENT_DATE-7
			Group by 1,2

			UNION ALL

			Select ITEM_ID
			,'Jewellery' as category
			From PRS_RESTRICTED_V.SLNG_LSTG_SUPER_FACT lstg
			inner join time_frame cal
				on lstg.AUCT_START_DT <= cal.cal_dt
				and lstg.AUCT_END_DT >= cal.cal_dt
			where (case when START_PRICE_LSTG_CURNCY_AMT > RSRV_PRICE_LSTG_CURNCY_AMT then START_PRICE_LSTG_CURNCY_AMT else RSRV_PRICE_LSTG_CURNCY_AMT End) >= 500
			and SLR_CNTRY_ID = 3
			and LSTG_SITE_ID = 3
			and META_CATEG_ID = 281
			AND CATEG_LVL2_ID <> 260324
			Group by 1,2)
		Group by 1,2
		) PSA
			on ck.ITEM_ID = psa.item_id
left join (
			Select a.ITEM_ID
			,case when a.brand = tb.brand then a.brand else 'Outside Top 20 Brands' end as brand
			FROM
				(Select ITEM_ID
				,case when (lower(brand) like any ('unknown','no brand','null','%unbranded%') or brand is null) then 'Unknown'
					else brand
					End as brand
				From
						(
						Select
							item_id,
							coalesce(max(case  when lower(aspect)=lower('BRAND') then aspct_vlu_nm else NULL end ),'Unknown') as BRAND
						FROM
							(select
								item_id,
								ns_type_cd,
								1 as priority,
								'BRAND' as aspect,
								cast(trim(lower(aspct_vlu_nm)) as VARCHAR(350)) as aspct_vlu_nm, 
								(Row_Number() Over (PARTITION BY item_id,auct_end_dt,aspect ORDER BY priority,aspct_vlu_nm DESC)) AS dup_check
							from
								item_aspct_clssfctn
							where
								AUCT_END_DT>='2020-12-07'
								AND lower(ns_type_cd) in (lower('nf'),lower('df' ) ) and upper(prdct_aspct_nm)= upper('BRAND')
							)SB
						Where dup_check = 1
						GROUP BY 1
						)
					) a 
				LEFT JOIN top_brands tb	
						on a.brand = tb.brand
				)
				brand
					on ck.item_id = brand.item_id
left join (
			Select a.ITEM_ID
			,case when a.model = tb.model then a.model else 'Outside Top 20 Models' end as model
			FROM
				(Select ITEM_ID
				,case when (lower(model) like any ('unknown','no model','null') or model is null) then 'Unknown'
					else model
					End as model
				From
						(
						Select
							item_id,
							coalesce(max(case  when lower(aspect)=lower('MODEL') then aspct_vlu_nm else NULL end ),'Unknown') as MODEL
						FROM
							(select
								item_id,
								ns_type_cd,
								1 as priority,
								'MODEL' as aspect,
								cast(trim(lower(aspct_vlu_nm)) as VARCHAR(350)) as aspct_vlu_nm, 
								(Row_Number() Over (PARTITION BY item_id,auct_end_dt,aspect ORDER BY priority,aspct_vlu_nm DESC)) AS dup_check
							from
								item_aspct_clssfctn
							where
								AUCT_END_DT>='2020-12-07'
								AND lower(ns_type_cd) in (lower('nf'),lower('df' ) ) and upper(prdct_aspct_nm)= upper('MODEL')
							)SB
						Where dup_check = 1
						GROUP BY 1
						)
					) a 
				LEFT JOIN top_models tb	
						on a.model = tb.model
				)
				model
					on ck.item_id = model.item_id

Where 1=1
and ck.SLR_CNTRY_ID = 3

Group by 1,2,3,4

)








-----------------------------------------------------FINAL OUTPUT TABLE--------------------------------------------------


Select src.* 
,lstg.listings
,lstg.sellers
,ck.gmv
,ck.sold_items
,ck.buyers

FROM
(
	select    
	i.category
	, i.brand
	, i.model
	,sum(SRP2VI_FLAG) as SRP2VI
	,sum(SRP2PRCHSD_FLAG) as SRP2PRCHSD
	,sum(NULL_LOW_FLAG) as NULL_LOW_FLAG
	,count(*) as total_searches 
	,count(distinct SESSION_SKEY) as visits

	from  access_views.SRCH_KEYWORDS_EXT_FACT src 
	INNER JOIN time_frame cal
			ON src.SESSION_START_DT = cal.cal_dt
	INNER JOIN top_brands_models_items i
			on src.FIRST_ITEM_ID = i.item_id

	where src.site_id = 3
	
	group by 1,2,3
) src
-------------------------------------------JOIN TO LISTING TABLE------------------------------------------------------
LEFT JOIN
(
	select    
	i.category
	, i.brand
	, i.model
	,count(distinct ck.item_id) as listings
	,count(distinct ck.SLR_ID) as sellers

	from  access_views.DW_LSTG_ITEM ck 
	INNER JOIN time_frame cal
			on ck.AUCT_START_DT <= cal.CAL_DT
			and ck.AUCT_END_DT >= cal.CAL_DT
	INNER JOIN top_brands_models_items i
			on ck.ITEM_ID = i.item_id

	where ck.ITEM_SITE_ID = 3 
	and ck.SLR_CNTRY_ID = 3

	group by 1,2,3
	) LSTG 
		on src.category = lstg.category
		and src.brand = lstg.brand
		and src.model = lstg.model
-------------------------------------------JOIN TO TRANSACTION TABLE------------------------------------------------------
LEFT JOIN
(
	select    
	i.category
	, i.brand
	, i.model
	,sum(ck.gmv_plan_usd) as gmv
	,sum(ck.quantity) as sold_items
	,count(distinct ck.buyer_id) as buyers

	from  access_views.DW_CHECKOUT_TRANS ck 
	INNER JOIN time_frame cal
			on ck.gmv_dt = cal.cal_dt
	INNER JOIN top_brands_models_items i
			on ck.ITEM_ID = i.item_id

	where 1=1 
	AND ck.SLR_CNTRY_ID = 3

	group by 1,2,3
	) ck 
		on src.category = ck.category
		and src.brand = ck.brand
		and src.model = ck.model
