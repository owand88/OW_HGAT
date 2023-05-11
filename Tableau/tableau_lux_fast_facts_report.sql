-- JIRA:            UKPLAN-214

-- Author: 			Robbie Evans
-- Date:            05/04/2023

-- Stakeholder: 	Wahaaj Shabbir, Alice Bridson, Emma Hamilton, Ines Morais, Keith Metcalfe
-- Description: 	Provides facts relating to the Luxury Focus Categories surrounding highest priced items sold as well as quantity of items sold/new listings made per minute/hour/day



---------------------------------Highest Priced Items Sold-----------------------------------


drop table if exists P_ukplan_report_T.lux_facts_dashboard_top_items;

Create table P_ukplan_report_T.lux_facts_dashboard_top_items as

select 
ck.*
,lstg.AUCT_TITLE

From
	(Select 
	cal.retail_year
	, case when ck.item_id = psa.item_id then 'AG' else 'Non-AG' end as ag_flag
	, ck.item_id
	, brand
	, ck.AUCT_END_DT
	, ck.ITEM_PRICE
	, cs.CNTRY_DESC as seller_country
	, cb.CNTRY_DESC as buyer_country
	, case when (cat.CATEG_LVL2_ID = 260324) then 'Watches'
	when (cat.CATEG_LVL3_ID = 169291) OR (cat.CATEG_LVL4_ID IN (52357,163570,169285,45258,2996,45237,169271)) then 'Handbags'
	when cat.CATEG_LVL4_ID IN (15709,95672,155202,57974,57929) then 'Sneakers'
	when (cat.META_CATEG_ID = 281 AND cat.CATEG_LVL2_ID <> 260324) then 'Jewellery'
	Else 'Other'
	End as category
	,ck.gmv_dt as purchase_dt
	,dense_rank() over (partition by retail_year, category order by ck.item_price desc) as price_rank
	
	From DW_CHECKOUT_TRANS ck
	INNER JOIN P_INVENTORYPLANNING_T.dw_category_groupings_adj CAT
		ON ck.LEAF_CATEG_ID = CAT.LEAF_CATEG_ID
		AND cat.site_id = 3
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
	left join ACCESS_VIEWS.DW_COUNTRIES cb
		on ck.BYR_CNTRY_ID = cb.CNTRY_ID
	left join ACCESS_VIEWS.DW_COUNTRIES cs
		on ck.slr_cntry_id = cs.CNTRY_ID
	left join
		(select item_id
		from
			(
			Select ITEM_ID
			From (
				select hist.item_id, hist.ELGBL_YN_IND, Row_Number() Over (partition by hist.item_id order by hist.EVLTN_TS desc)
				from access_views.DW_PES_ELGBLT_HIST hist
				where hist.BIZ_PRGRM_NAME in ('PSA_SNEAKER_EBAY_UK','PSA_HANDBAGS_UK','PSA_WATCHES_UK') -- Handbags AG program
				qualify (Row_Number() Over (partition by item_id order by EVLTN_TS desc)) = 1
				)
			Where ELGBL_YN_IND = 'Y'

			UNION ALL

			Select ITEM_ID
			From ACCESS_VIEWS.DW_LSTG_ITEM lstg
			INNER JOIN P_INVENTORYPLANNING_T.dw_category_groupings_adj CAT
					ON lstg.LEAF_CATEG_ID = CAT.LEAF_CATEG_ID
					AND cat.site_id = 3
				AND CAT.SAP_CATEGORY_ID NOT in (5,7,41,23,-999) 
				and cat.META_CATEG_ID = 281
				and cat.CATEG_LVL2_ID NOT IN (260324)
			Where 1=1
				and SLR_CNTRY_ID = 3
				and lstg.AUCT_START_DT >= CURRENT_DATE-7
				and lstg.AUCT_END_DT >= CURRENT_DATE-7
				and (case when lstg.START_PRICE_LSTG_CURNCY > lstg.RSRV_PRICE_LIST_CRNCY then lstg.START_PRICE_LSTG_CURNCY else lstg.RSRV_PRICE_LIST_CRNCY End) >= 500
			Group by 1
			)
		where 
		1=1
		Group by 1
				) PSA
					on ck.ITEM_ID = psa.item_id
	
	Where 1=1
	and ck.SLR_CNTRY_ID= 3
	and (
		(cat.CATEG_LVL2_ID = 260324) --Watches
		or (cat.CATEG_LVL3_ID = 169291) OR (cat.CATEG_LVL4_ID IN (52357,163570,169285,45258,2996,45237,169271)) --Handbags
		OR cat.CATEG_LVL4_ID IN (15709,95672,155202,57974,57929) --Sneakers
		OR (cat.META_CATEG_ID = 281 AND cat.CATEG_LVL2_ID <> 260324) --Jewellery
		)
		
	Group by 1,2,3,4,5,6,7,8,9,10) ck
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




---------------------------------------------------Identify Top Brands and Models--------------------------------------------------------
drop table if exists P_ukplan_report_T.lux_facts_dashboard_kpis_top_brands;

Create table P_ukplan_report_T.lux_facts_dashboard_kpis_top_brands as

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
	INNER JOIN P_INVENTORYPLANNING_T.dw_category_groupings_adj CAT
			ON ck.LEAF_CATEG_ID = CAT.LEAF_CATEG_ID
			AND cat.site_id = 3
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
;




drop table if exists P_ukplan_report_T.lux_facts_dashboard_kpis_top_models;

Create table P_ukplan_report_T.lux_facts_dashboard_kpis_top_models as

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
	INNER JOIN P_INVENTORYPLANNING_T.dw_category_groupings_adj CAT
			ON ck.LEAF_CATEG_ID = CAT.LEAF_CATEG_ID
			AND cat.site_id = 3
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
;



------------------------------------------------------GMV Data--------------------------------------------------------
drop table if exists P_ukplan_report_T.lux_facts_dashboard_kpis;

create table P_ukplan_report_T.lux_facts_dashboard_kpis as
	
Select 
cal.retail_year
, case when (cat.CATEG_LVL2_ID = 260324) then 'Watches'
	when (cat.CATEG_LVL3_ID = 169291) OR (cat.CATEG_LVL4_ID IN (52357,163570,169285,45258,2996,45237,169271)) then 'Handbags'
	when cat.CATEG_LVL4_ID IN (15709,95672,155202,57974,57929) then 'Sneakers'
	when (cat.META_CATEG_ID = 281 AND cat.CATEG_LVL2_ID <> 260324) then 'Jewellery'
	Else 'Other'
	End as category
, case when ck.item_id = psa.item_id then 'AG' else 'Non-AG' End as ag_flag
, brand
, model
, days_in_ty
, days_in_ly
, sum(ck.gmv_plan_usd) as gmv
, sum(ck.QUANTITY) as sold_items
, 0 as ll

From DW_CHECKOUT_TRANS ck
INNER JOIN DW_CAL_DT cal
	on ck.gmv_dt = cal.CAL_DT
	and cal.RETAIL_YEAR >= 2021
INNER JOIN P_INVENTORYPLANNING_T.dw_category_groupings_adj CAT
		ON ck.LEAF_CATEG_ID = CAT.LEAF_CATEG_ID
		AND cat.site_id = 3
left JOIN
	(select count(distinct cal_dt) as days_in_ty
	from ACCESS_VIEWS.DW_CAL_DT 
	Where AGE_FOR_RTL_WEEK_ID <= -1
	and AGE_FOR_RTL_YEAR_ID = 0) ty
left JOIN
	(select count(distinct cal_dt) as days_in_ly
	from ACCESS_VIEWS.DW_CAL_DT 
	Where AGE_FOR_RTL_YEAR_ID = -1) ly
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
				LEFT JOIN P_ukplan_report_T.lux_facts_dashboard_kpis_top_brands tb	
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
				LEFT JOIN P_ukplan_report_T.lux_facts_dashboard_kpis_top_models tb	
						on a.model = tb.model
				)
				model
					on ck.item_id = model.item_id
left join
	(select item_id
	from
		(
		Select ITEM_ID
		From (
			select hist.item_id, hist.ELGBL_YN_IND, Row_Number() Over (partition by hist.item_id order by hist.EVLTN_TS desc)
			from access_views.DW_PES_ELGBLT_HIST hist
			where hist.BIZ_PRGRM_NAME in ('PSA_SNEAKER_EBAY_UK','PSA_HANDBAGS_UK','PSA_WATCHES_UK') -- Handbags AG program
			qualify (Row_Number() Over (partition by item_id order by EVLTN_TS desc)) = 1
			)
		Where ELGBL_YN_IND = 'Y'

		UNION ALL

		Select ITEM_ID
		From ACCESS_VIEWS.DW_LSTG_ITEM lstg
		INNER JOIN P_INVENTORYPLANNING_T.dw_category_groupings_adj CAT
			ON lstg.LEAF_CATEG_ID = CAT.LEAF_CATEG_ID
			AND cat.site_id = 3
			and cat.META_CATEG_ID = 281
			and cat.CATEG_LVL2_ID NOT IN (260324)
		Where 1=1
			and SLR_CNTRY_ID = 3
			and lstg.AUCT_START_DT >= CURRENT_DATE-7
			and lstg.AUCT_END_DT >= CURRENT_DATE-7
			and (case when lstg.START_PRICE_LSTG_CURNCY > lstg.RSRV_PRICE_LIST_CRNCY then lstg.START_PRICE_LSTG_CURNCY else lstg.RSRV_PRICE_LIST_CRNCY End) >= 500
		Group by 1
		)
	where 
	1=1
	Group by 1
			) PSA
				on ck.item_id = psa.item_id

Where 1=1
and ck.SLR_CNTRY_ID = 3

Group by 1,2,3,4,5,6,7



UNION ALL



Select 
cal.retail_year
, case when (cat.CATEG_LVL2_ID = 260324) then 'Watches'
	when (cat.CATEG_LVL3_ID = 169291) OR (cat.CATEG_LVL4_ID IN (52357,163570,169285,45258,2996,45237,169271)) then 'Handbags'
	when cat.CATEG_LVL4_ID IN (15709,95672,155202,57974,57929) then 'Sneakers'
	when (cat.META_CATEG_ID = 281 AND cat.CATEG_LVL2_ID <> 260324) then 'Jewellery'
	Else 'Other'
	End as category
, case when ck.item_id = psa.item_id then 'AG' else 'Non-AG' End as ag_flag
, brand
, model
, days_in_ty
, days_in_ly
, 0 as gmv
, 0 as sold_items
, count(distinct ck.ITEM_ID) as ll

From DW_LSTG_ITEM ck
INNER JOIN DW_CAL_DT cal
	on ck.auct_start_dt <= cal.CAL_DT
	and ck.AUCT_END_DT >= cal.cal_dt
	and cal.RETAIL_YEAR >= 2021
INNER JOIN P_INVENTORYPLANNING_T.dw_category_groupings_adj CAT
		ON ck.LEAF_CATEG_ID = CAT.LEAF_CATEG_ID
		AND cat.site_id = 3
left JOIN
	(select count(distinct cal_dt) as days_in_ty
	from ACCESS_VIEWS.DW_CAL_DT 
	Where AGE_FOR_RTL_WEEK_ID <= -1
	and AGE_FOR_RTL_YEAR_ID = 0) ty
left JOIN
	(select count(distinct cal_dt) as days_in_ly
	from ACCESS_VIEWS.DW_CAL_DT 
	Where AGE_FOR_RTL_YEAR_ID = -1) ly
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
				LEFT JOIN P_ukplan_report_T.lux_facts_dashboard_kpis_top_brands tb	
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
				LEFT JOIN P_ukplan_report_T.lux_facts_dashboard_kpis_top_models tb	
						on a.model = tb.model
				)
				model
					on ck.item_id = model.item_id
left join
	(select item_id
	from
		(
		Select ITEM_ID
		From (
			select hist.item_id, hist.ELGBL_YN_IND, Row_Number() Over (partition by hist.item_id order by hist.EVLTN_TS desc)
			from access_views.DW_PES_ELGBLT_HIST hist
			where hist.BIZ_PRGRM_NAME in ('PSA_SNEAKER_EBAY_UK','PSA_HANDBAGS_UK','PSA_WATCHES_UK') -- Handbags AG program
			qualify (Row_Number() Over (partition by item_id order by EVLTN_TS desc)) = 1
			)
		Where ELGBL_YN_IND = 'Y'

		UNION ALL

		Select ITEM_ID
		From ACCESS_VIEWS.DW_LSTG_ITEM lstg
		INNER JOIN ACCESS_VIEWS.DW_CATEGORY_GROUPINGS CAT 
			ON CAT.LEAF_CATEG_ID = lstg.LEAF_CATEG_ID 
			AND CAT.SITE_ID = 3
			AND CAT.SAP_CATEGORY_ID NOT in (5,7,41,23,-999) 
			and cat.META_CATEG_ID = 281
			and cat.CATEG_LVL2_ID NOT IN (260324)
		Where 1=1
			and SLR_CNTRY_ID = 3
			and lstg.AUCT_START_DT >= CURRENT_DATE-7
			and lstg.AUCT_END_DT >= CURRENT_DATE-7
			and (case when lstg.START_PRICE_LSTG_CURNCY > lstg.RSRV_PRICE_LIST_CRNCY then lstg.START_PRICE_LSTG_CURNCY else lstg.RSRV_PRICE_LIST_CRNCY End) >= 500
		Group by 1
		)
	where 
	1=1
	Group by 1
			) PSA
				on ck.item_id = psa.item_id

Where 1=1
and ck.SLR_CNTRY_ID = 3
and ck.item_site_id = 3

Group by 1,2,3,4,5,6,7