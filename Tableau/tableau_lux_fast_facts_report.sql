---------------------------------Highest Priced Items Sold-----------------------------------

drop table if exists p_robevans_t.lux_facts_dashboard_top_items;

Create table p_robevans_t.lux_facts_dashboard_top_items as

select 
ck.*
,lstg.AUCT_TITLE

From
	(Select 
	cal.retail_year
	, ck.item_id
	, brand
	, ck.AUCT_END_DT
	, ck.ITEM_PRICE
	, case when (cat.CATEG_LVL2_ID = 260324) then 'Watches'
	when (cat.CATEG_LVL3_ID = 169291) OR (cat.CATEG_LVL4_ID IN (52357,163570,169285,45258,2996,45237,169271)) then 'Handbags'
	when cat.CATEG_LVL4_ID IN (15709,95672,155202,57974,57929) then 'Sneakers'
	when (cat.META_CATEG_ID = 281 AND cat.CATEG_LVL2_ID <> 260324) then 'Jewellery'
	Else 'Other'
	End as category
	,dense_rank() over (partition by retail_year, category order by ck.item_price desc) as price_rank
	
	From DW_CHECKOUT_TRANS ck
	INNER JOIN ACCESS_VIEWS.DW_CATEGORY_GROUPINGS CAT 
		ON CAT.LEAF_CATEG_ID = ck.LEAF_CATEG_ID 
		AND CAT.SITE_ID = 3
		AND CAT.SAP_CATEGORY_ID NOT in (5,7,41,23,-999) 
	INNER JOIN DW_CAL_DT cal
		on ck.gmv_dt = cal.CAL_DT
		and cal.RETAIL_YEAR >= 2021
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
	and ck.SLR_CNTRY_ID= 3
	and (
		(cat.CATEG_LVL2_ID = 260324) --Watches
		or (cat.CATEG_LVL3_ID = 169291) OR (cat.CATEG_LVL4_ID IN (52357,163570,169285,45258,2996,45237,169271)) --Handbags
		OR cat.CATEG_LVL4_ID IN (15709,95672,155202,57974,57929) --Sneakers
		OR (cat.META_CATEG_ID = 281 AND cat.CATEG_LVL2_ID <> 260324) --Jewellery
		)
		
	Group by 1,2,3,4,5,6) ck
LEFT JOIN
	(Select lstg.item_id, lstg.auct_end_dt, lstg.AUCT_TITLE
	From PRS_RESTRICTED_V.SLNG_LSTG_SUPER_FACT lstg
	Where AUCT_END_DT >= '2020-12-20'
	Group by 1,2,3) LSTG 
		on ck.item_id = lstg.item_id
		and ck.AUCT_END_DT = lstg.auct_end_dt

Where price_rank <= 20

;



------------------------------------------------Fast Facts------------------------------------------------------------


drop table if exists p_robevans_t.lux_facts_dashboard_kpis;

create table p_robevans_t.lux_facts_dashboard_kpis as

---------------------------------------------------Identify Top Brands and Models--------------------------------------------------------

With top_brands as 
(
select brand
From
	(
	Select 
	cal.retail_year
	, case when (cat.CATEG_LVL2_ID = 260324) then 'Watches'
		when (cat.CATEG_LVL3_ID = 169291) OR (cat.CATEG_LVL4_ID IN (52357,163570,169285,45258,2996,45237,169271)) then 'Handbags'
		when cat.CATEG_LVL4_ID IN (15709,95672,155202,57974,57929) then 'Sneakers'
		when (cat.META_CATEG_ID = 281 AND cat.CATEG_LVL2_ID <> 260324) then 'Jewellery'
		Else 'Other'
		End as category
	, case when (lower(brand) like any ('unknown','no brand','null','%unbranded%') or brand is null) then 'Unknown'
		else brand
		End as brand
	, sum(gmv_plan_usd) as gmv
	, dense_rank() over (partition by retail_year, category order by gmv desc) as price_rank

	FROM DW_CHECKOUT_TRANS ck
	INNER JOIN ACCESS_VIEWS.DW_CAL_DT cal
		on ck.gmv_dt = cal.CAL_DT
		and cal.retail_year >= 2021
	INNER JOIN ACCESS_VIEWS.DW_CATEGORY_GROUPINGS CAT 
			ON CAT.LEAF_CATEG_ID = ck.LEAF_CATEG_ID 
			AND CAT.SITE_ID = 3
			AND CAT.SAP_CATEGORY_ID NOT in (5,7,41,23,-999) 
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

	Group by 1,2,3
	)

where price_rank <= 20

Group by 1
)

,

top_models as 
(
select model
From
	(
	Select 
	cal.retail_year
	, case when (cat.CATEG_LVL2_ID = 260324) then 'Watches'
		when (cat.CATEG_LVL3_ID = 169291) OR (cat.CATEG_LVL4_ID IN (52357,163570,169285,45258,2996,45237,169271)) then 'Handbags'
		when cat.CATEG_LVL4_ID IN (15709,95672,155202,57974,57929) then 'Sneakers'
		when (cat.META_CATEG_ID = 281 AND cat.CATEG_LVL2_ID <> 260324) then 'Jewellery'
		Else 'Other'
		End as category
	, case when (lower(model) like any ('unknown','no model','null') or model is null) then 'Unknown'
		else model
		End as model
	, sum(gmv_plan_usd) as gmv
	, dense_rank() over (partition by retail_year, category order by gmv desc) as price_rank

	FROM DW_CHECKOUT_TRANS ck
	INNER JOIN ACCESS_VIEWS.DW_CAL_DT cal
		on ck.gmv_dt = cal.CAL_DT
		and cal.retail_year >= 2021
	INNER JOIN ACCESS_VIEWS.DW_CATEGORY_GROUPINGS CAT 
			ON CAT.LEAF_CATEG_ID = ck.LEAF_CATEG_ID 
			AND CAT.SITE_ID = 3
			AND CAT.SAP_CATEGORY_ID NOT in (5,7,41,23,-999) 
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

	Group by 1,2,3
	)

where price_rank <= 20

Group by 1
)




------------------------------------------------------GMV Data--------------------------------------------------------

	
Select 
cal.retail_year
, case when (cat.CATEG_LVL2_ID = 260324) then 'Watches'
	when (cat.CATEG_LVL3_ID = 169291) OR (cat.CATEG_LVL4_ID IN (52357,163570,169285,45258,2996,45237,169271)) then 'Handbags'
	when cat.CATEG_LVL4_ID IN (15709,95672,155202,57974,57929) then 'Sneakers'
	when (cat.META_CATEG_ID = 281 AND cat.CATEG_LVL2_ID <> 260324) then 'Jewellery'
	Else 'Other'
	End as category
, brand
, model
, sum(ck.gmv_plan_usd) as gmv
, sum(ck.QUANTITY) as sold_items
, 0 as ll

From DW_CHECKOUT_TRANS ck
INNER JOIN DW_CAL_DT cal
	on ck.gmv_dt = cal.CAL_DT
	and cal.RETAIL_YEAR >= 2021
INNER JOIN ACCESS_VIEWS.DW_CATEGORY_GROUPINGS CAT 
		ON CAT.LEAF_CATEG_ID = ck.LEAF_CATEG_ID 
		AND CAT.SITE_ID = 3
		AND CAT.SAP_CATEGORY_ID NOT in (5,7,41,23,-999) 
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



UNION ALL



Select 
cal.retail_year
, case when (cat.CATEG_LVL2_ID = 260324) then 'Watches'
	when (cat.CATEG_LVL3_ID = 169291) OR (cat.CATEG_LVL4_ID IN (52357,163570,169285,45258,2996,45237,169271)) then 'Handbags'
	when cat.CATEG_LVL4_ID IN (15709,95672,155202,57974,57929) then 'Sneakers'
	when (cat.META_CATEG_ID = 281 AND cat.CATEG_LVL2_ID <> 260324) then 'Jewellery'
	Else 'Other'
	End as category
, brand
, model
, 0 as gmv
, 0 as sold_items
, count(distinct ck.ITEM_ID) as ll

From DW_LSTG_ITEM ck
INNER JOIN DW_CAL_DT cal
	on ck.auct_start_dt <= cal.CAL_DT
	and ck.AUCT_END_DT >= cal.cal_dt
	and cal.RETAIL_YEAR >= 2021
INNER JOIN ACCESS_VIEWS.DW_CATEGORY_GROUPINGS CAT 
		ON CAT.LEAF_CATEG_ID = ck.LEAF_CATEG_ID 
		AND CAT.SITE_ID = 3
		AND CAT.SAP_CATEGORY_ID NOT in (5,7,41,23,-999) 
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