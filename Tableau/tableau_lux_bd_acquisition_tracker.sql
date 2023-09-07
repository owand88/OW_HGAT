-- JIRA:            UKPLAN-530

-- Author: 			Robbie Evans
-- Date:            07/09/2023

-- Stakeholder: 	Penelope Faith, Alice Bridson, Emma Hamilton, Ines Morais, Keith Metcalfe
-- Description: 	Provides a view of the Luxury BD team's acquisition actuals vs target





drop table if exists P_ukplan_report_T.lux_bd_acquisition_report;

Create table P_ukplan_report_T.lux_bd_acquisition_report as

with lux_bd_sellers as 
( 
select slrs.*,AGE_FOR_RTL_WEEK_ID as age_for_end_week
FROM	
(
	select seller_id
		,retail_year as start_year
		,retail_week as start_week
		,CASE
			WHEN (retail_week + 51) > 52 THEN (retail_year + 1)
			ELSE retail_year
		END AS end_year
		,CASE
			WHEN (retail_week + 51) > 52 THEN (retail_week + 51 - 52)
			ELSE (retail_week + 51)
		END AS end_week
	from p_eupricing_t.uk_new_sellers 

	where lower(vertical_platform) = 'luxury'
		and lower(acq_tag) = 'direct'
	Group by 1,2,3,4
	) slrs
INNER JOIN
	(
	select RETAIL_YEAR
		,RETAIL_WEEK
		,AGE_FOR_RTL_WEEK_ID
	FROM DW_CAL_DT
	Group by 1,2,3
	) cal 
		on slrs.end_year = cal.RETAIL_YEAR
		and slrs.end_week = cal.RETAIL_WEEK
Where 1=1
	and cal.AGE_FOR_RTL_WEEK_ID >= -52
)
	
	

Select ck.* 
	,trgts.target_gmv

FROM 
(
	Select cal.retail_week
		,cal.retail_year
		,cal.RTL_QTR_OF_RTL_YEAR_ID
		,slrs.seller_id
		,u.user_slctd_id as seller_name
		,u.comp as company_name
		,slrs.end_year
		,slrs.end_week
		,slrs.age_for_end_week
		,case 
			when cat.META_CATEG_ID = 281 and cat.CATEG_LVL2_ID NOT IN (260324) then 'Jewellery'
			when cat.CATEG_LVL2_ID IN (260324) then 'Watches'
			when (cat.CATEG_LVL3_ID IN (169291)) OR (cat.CATEG_LVL4_ID IN (52357,163570,169285,45258,2996,45237,169271)) then 'Handbags'
				else 'Other'
		end as lux_category
		,cat.CATEG_LVL2_NAME
		,cat.CATEG_LVL3_NAME
		,sum(case when cal.retail_year < slrs.end_year then ck.gmv_plan_usd
			when cal.retail_year = slrs.end_year and cal.retail_week <= slrs.end_week then ck.gmv_plan_usd else 0 End) as gmv

	FROM DW_CHECKOUT_TRANS ck
	INNER JOIN DW_CAL_DT cal
		on ck.gmv_dt = cal.CAL_DT
		and cal.AGE_FOR_RTL_WEEK_ID >= -52
		and cal.AGE_FOR_RTL_WEEK_ID <= -1
	INNER JOIN lux_bd_sellers slrs
		on ck.SELLER_ID = slrs.seller_id
	INNER JOIN P_INVENTORYPLANNING_T.dw_category_groupings_adj CAT
		ON ck.LEAF_CATEG_ID = CAT.LEAF_CATEG_ID
		AND cat.site_id = 3
	LEFT JOIN DW_USERS u
		on ck.SELLER_ID = u.user_id

	Where 1=1
		and ck.SITE_ID = 3
		and (cat.CATEG_LVL2_ID IN (260324)
			OR ((cat.CATEG_LVL3_ID IN (169291)) OR (cat.CATEG_LVL4_ID IN (52357,163570,169285,45258,2996,45237,169271)))
			OR (cat.META_CATEG_ID = 281 and cat.CATEG_LVL2_ID NOT IN (260324)))
	Group by 1,2,3,4,5,6,7,8,9,10,11,12
) ck 
LEFT JOIN p_inventoryplanning_t.lux_bd_quarterly_targets trgts
	on ck.RTL_QTR_OF_RTL_YEAR_ID = trgts.quarter
	and ck.lux_category = trgts.luxury_category
	and ck.retail_year = trgts.year
	
	