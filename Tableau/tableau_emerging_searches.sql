/*
Jira: UKPLAN-256
Author: Bonnie Chu
Date: 2023-04-12
Description: Report to show emerging searches (and top searches in latest week) on UK site for category managers to identify inventory opportunities.
*/
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- View used in Tableau dashboard [Create 1 view from CTE]
-- Changed from initial methodology of building 1 view from 'union all' 4 views >> failed to run on Zeta ["Error running query: org.apache.spark.sql.AnalysisException: Query analysis exceeds max time configured: 600 seconds, abort.;"]
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
drop view if exists P_ukplan_report_T.searches;
create view P_ukplan_report_T.searches as (
-- All seraches on UK site in latest 4 full weeks
with base as (
	select    
	cal.age_for_rtl_week_id
	,cal.retail_year
	,cal.retail_week
	,cal.retail_wk_end_date
	,cat.adjusted_vertical
	,cat.categ_lvl2_name
	,cat.categ_lvl2_id
	,lower(src.query) as act_srch
	,count(*) as src_cnt 
	
	from  access_views.srch_cnvrsn_event_fact src       

	inner join prs_restricted_v.slng_lstg_super_fact lstg
	on src.site_id=3                                                                
	and substring(src.items,1,instr(src.items,',')-1) = lstg.item_id--Assume the first item appears is the most relevant to the search input

	inner join (select new_vertical as adjusted_vertical,categ_lvl2_id,categ_lvl2_name,leaf_categ_id,move_to,site_id 
				from P_INVENTORYPLANNING_T.dw_category_groupings_adj
				group by 1,2,3,4,5,6) cat
	on lstg.leaf_categ_id=cat.leaf_categ_id
	and lstg.item_site_id=cat.site_id and cat.site_id=3
	and lstg.leaf_categ_id=cat.move_to

	inner join access_views.dw_cal_dt cal
	on src.session_start_dt = cal.cal_dt and cal.age_for_rtl_week_id between -4 and -1--observe last full 4 weeks trend

	group by 1,2,3,4,5,6,7,8
)
-- LW Top 500 Searches (Overall)
,top_overall as (
	with top_LW as (
		select 
		retail_year
		,retail_week
		,retail_wk_end_date
		,act_srch
		,adjusted_vertical
		,categ_lvl2_name
		,sum(src_cnt) as search_vol
		from base
		where age_for_rtl_week_id = -1
		group by 1,2,3,4,5,6
		qualify (row_number() over (order by search_vol desc))<=500
	)
	,LW as (
		select 
		retail_year
		,retail_week
		,retail_wk_end_date
		,row_number() over (order by search_vol desc) as rank
		,act_srch as search_input
		,adjusted_vertical
		,categ_lvl2_name as L2
		,search_vol as search_vol_LW
		from top_LW
	)
	,LW_1 as (
		select 
		a.act_srch as search_input
		,a.adjusted_vertical
		,a.categ_lvl2_name as L2
		,sum(a.src_cnt) as search_vol_LW_1
		from base a
		left join LW 
		on a.act_srch=LW.search_input and a.adjusted_vertical=LW.adjusted_vertical and a.categ_lvl2_name=LW.L2
		where a.age_for_rtl_week_id = -2
		group by 1,2,3
	)
	,LW_2 as (
		select 
		a.act_srch as search_input
		,a.adjusted_vertical
		,a.categ_lvl2_name as L2
		,sum(a.src_cnt) as search_vol_LW_2
		from base a
		left join LW 
		on a.act_srch=LW.search_input and a.adjusted_vertical=LW.adjusted_vertical and a.categ_lvl2_name=LW.L2
		where a.age_for_rtl_week_id = -3
		group by 1,2,3
	)
	,LW_3 as (
	select 
		a.act_srch as search_input
		,a.adjusted_vertical
		,a.categ_lvl2_name as L2
		,sum(a.src_cnt) as search_vol_LW_3
		from base a
		left join LW 
		on a.act_srch=LW.search_input and a.adjusted_vertical=LW.adjusted_vertical and a.categ_lvl2_name=LW.L2
		where a.age_for_rtl_week_id = -4
		group by 1,2,3
	)
	select
	'top_overall' as dashboard_view
	,LW.retail_year
	,LW.retail_week
	,LW.retail_wk_end_date
	,'Overall '||LW.rank as vertical_rank
	,LW.rank
	,LW.search_input
	,LW.adjusted_vertical
	,LW.L2
	,LW.search_vol_LW as search_LW
	,coalesce(LW_1.search_vol_LW_1,0) as search_LW_1
	,coalesce(LW_2.search_vol_LW_2,0) as search_LW_2
	,coalesce(LW_3.search_vol_LW_3,0) as search_LW_3
	,case when LW.search_vol_LW is not null and LW_1.search_vol_LW_1 is not null then (LW.search_vol_LW / LW_1.search_vol_LW_1) - 1
		  when LW.search_vol_LW is not null and LW_1.search_vol_LW_1 is null then (LW.search_vol_LW / 0.00000000000000000001) - 1
		  else 0.00000000000000000001 end as LW_LW_1_pct_diff
	from LW
	left join LW_1
	on LW.search_input=LW_1.search_input and LW.adjusted_vertical=LW_1.adjusted_vertical and LW.L2=LW_1.L2
	left join LW_2
	on LW.search_input=LW_2.search_input and LW.adjusted_vertical=LW_2.adjusted_vertical and LW.L2=LW_2.L2
	left join LW_3
	on LW.search_input=LW_3.search_input and LW.adjusted_vertical=LW_3.adjusted_vertical and LW.L2=LW_3.L2
)
-- LW Top 500 Searches (by Vertical)
,top_vertical as (
	with top_LW as (
		select 
		retail_year
		,retail_week
		,retail_wk_end_date
		,act_srch
		,adjusted_vertical
		,categ_lvl2_name
		,sum(src_cnt) as search_vol
		from base
		where age_for_rtl_week_id = -1
		group by 1,2,3,4,5,6
		qualify (row_number() over (partition by adjusted_vertical order by search_vol desc))<=500
	)
	,LW as (
		select 
		retail_year
		,retail_week
		,retail_wk_end_date
		,adjusted_vertical||' '||row_number() over (partition by adjusted_vertical order by search_vol desc) as vertical_rank
		,row_number() over (partition by adjusted_vertical order by search_vol desc) as rank
		,act_srch as search_input
		,adjusted_vertical
		,categ_lvl2_name as L2
		,search_vol as search_vol_LW
		from top_LW
	)
	,LW_1 as (
		select 
		a.act_srch as search_input
		,a.adjusted_vertical
		,a.categ_lvl2_name as L2
		,sum(a.src_cnt) as search_vol_LW_1
		from base a
		left join LW 
		on a.act_srch=LW.search_input and a.adjusted_vertical=LW.adjusted_vertical and a.categ_lvl2_name=LW.L2
		where a.age_for_rtl_week_id = -2
		group by 1,2,3
	)
	,LW_2 as (
		select 
		a.act_srch as search_input
		,a.adjusted_vertical
		,a.categ_lvl2_name as L2
		,sum(a.src_cnt) as search_vol_LW_2
		from base a
		left join LW 
		on a.act_srch=LW.search_input and a.adjusted_vertical=LW.adjusted_vertical and a.categ_lvl2_name=LW.L2
		where a.age_for_rtl_week_id = -3
		group by 1,2,3
	)
	,LW_3 as (
		select 
		a.act_srch as search_input
		,a.adjusted_vertical
		,a.categ_lvl2_name as L2
		,sum(a.src_cnt) as search_vol_LW_3
		from base a
		left join LW 
		on a.act_srch=LW.search_input and a.adjusted_vertical=LW.adjusted_vertical and a.categ_lvl2_name=LW.L2
		where a.age_for_rtl_week_id = -4
		group by 1,2,3
	)
	select
	'top_vertical' as dashboard_view
	,LW.retail_year
	,LW.retail_week
	,LW.retail_wk_end_date
	,LW.vertical_rank
	,LW.rank
	,LW.search_input
	,LW.adjusted_vertical
	,LW.L2
	,LW.search_vol_LW as search_LW
	,coalesce(LW_1.search_vol_LW_1,0) as search_LW_1
	,coalesce(LW_2.search_vol_LW_2,0) as search_LW_2
	,coalesce(LW_3.search_vol_LW_3,0) as search_LW_3
	,case when LW.search_vol_LW is not null and LW_1.search_vol_LW_1 is not null then (LW.search_vol_LW / LW_1.search_vol_LW_1) - 1
		  when LW.search_vol_LW is not null and LW_1.search_vol_LW_1 is null then (LW.search_vol_LW / 0.00000000000000000001) - 1
		  else 0.00000000000000000001 end as LW_LW_1_pct_diff
	from LW
	left join LW_1
	on LW.search_input=LW_1.search_input and LW.adjusted_vertical=LW_1.adjusted_vertical and LW.L2=LW_1.L2
	left join LW_2
	on LW.search_input=LW_2.search_input and LW.adjusted_vertical=LW_2.adjusted_vertical and LW.L2=LW_2.L2
	left join LW_3
	on LW.search_input=LW_3.search_input and LW.adjusted_vertical=LW_3.adjusted_vertical and LW.L2=LW_3.L2
)
--LW Emerging seaches (Overall)
,emerge_overall as (
	with top as (
		select percentile(cast(src as bigint), 0.9999) as top_pc--Top 0.01% searches in latest week
		from
		(select
		act_srch
		,sum(src_cnt) as src
		from base
		where age_for_rtl_week_id = -1
		group by 1)
	)
	,diff as (
		select
		lat.retail_year
		,lat.retail_week
		,lat.retail_wk_end_date
		,agg.act_srch as search_input
		,agg.adjusted_vertical
		,agg.categ_lvl2_name as L2
		,top.top_pc
		,agg.LW
		,agg.LW_1
		,agg.LW_2
		,agg.LW_3

		,case when agg.LW is not null and agg.LW_1 is not null then (agg.LW / agg.LW_1) - 1
			  when agg.LW is not null and agg.LW_1 is null then (agg.LW / 0.00000000000000000001) - 1
			  else 0.00000000000000000001 end as LW_LW_1_pct_diff

		from
			(select  
			act_srch
			,adjusted_vertical
			,categ_lvl2_name
			,sum(case when age_for_rtl_week_id = -4 then src_cnt end) as LW_3
			,sum(case when age_for_rtl_week_id = -3 then src_cnt end) as LW_2
			,sum(case when age_for_rtl_week_id = -2 then src_cnt end) as LW_1
			,sum(case when age_for_rtl_week_id = -1 then src_cnt end) as LW
			from base
			group by 1,2,3) agg

		cross join top
		
		cross join 
			(select 
			distinct retail_year
			,retail_week 
			,retail_wk_end_date 
			from base
			where age_for_rtl_week_id=-1) lat
		
		where agg.LW>=top.top_pc
	)
	select
	'emerge_overall' as dashboard_view
	,retail_year
	,retail_week
	,retail_wk_end_date
	,'Overall '||row_number() over (order by LW desc) as vertical_rank
	,row_number() over (order by LW desc) as rank
	,search_input
	,adjusted_vertical
	,L2
	,LW as search_LW
	,coalesce(LW_1,0) as search_LW_1
	,coalesce(LW_2,0) as search_LW_2
	,coalesce(LW_3,0) as search_LW_3
	,LW_LW_1_pct_diff
	from diff
	where LW_LW_1_pct_diff>0--include only searches that are more popular in LW compared to LW-1
)
--LW Emerging seaches (by Vertical)
,emerge_vertical as (
	with top as (
		select 
		adjusted_vertical
		,percentile(cast(src as bigint), 0.9999) as top_pc--Top 0.01% searches in each vertical in latest week
		from
		(select
		adjusted_vertical
		,act_srch
		,sum(src_cnt) as src
		from base
		where age_for_rtl_week_id = -1
		group by 1,2)
		group by 1
	)
	,diff as (
		select 
		lat.retail_year
		,lat.retail_week
		,lat.retail_wk_end_date
		,agg.act_srch as search_input
		,agg.adjusted_vertical
		,agg.categ_lvl2_name as L2
		,top.top_pc
		,agg.LW
		,agg.LW_1
		,agg.LW_2
		,agg.LW_3

		,case when agg.LW is not null and agg.LW_1 is not null then (agg.LW / agg.LW_1) - 1
			  when agg.LW is not null and agg.LW_1 is null then (agg.LW / 0.00000000000000000001) - 1
			  else 0.00000000000000000001 end as LW_LW_1_pct_diff

		from
			(select  
			act_srch
			,adjusted_vertical
			,categ_lvl2_name
			,sum(case when age_for_rtl_week_id = -4 then src_cnt end) as LW_3
			,sum(case when age_for_rtl_week_id = -3 then src_cnt end) as LW_2
			,sum(case when age_for_rtl_week_id = -2 then src_cnt end) as LW_1
			,sum(case when age_for_rtl_week_id = -1 then src_cnt end) as LW
			from base
			group by 1,2,3) agg

		cross join top
		on agg.adjusted_vertical=top.adjusted_vertical

		cross join 
			(select 
			distinct retail_year
			,retail_week 
			,retail_wk_end_date 
			from base
			where age_for_rtl_week_id=-1) lat

		where agg.LW>=top.top_pc
	)
	select
	'emerge_vertical' as dashboard_view
	,retail_year
	,retail_week
	,retail_wk_end_date
	,adjusted_vertical||' '||row_number() over (partition by adjusted_vertical order by LW desc) as vertical_rank
	,row_number() over (partition by adjusted_vertical order by LW desc) as rank
	,search_input
	,adjusted_vertical
	,L2
	,LW as search_LW
	,coalesce(LW_1,0) as search_LW_1
	,coalesce(LW_2,0) as search_LW_2
	,coalesce(LW_3,0) as search_LW_3
	,LW_LW_1_pct_diff
	from diff
	where LW_LW_1_pct_diff>0--include only searches that are more popular in LW compared to LW-1
)
select * from top_overall
union all
select * from top_vertical
union all
select * from emerge_overall
union all
select * from emerge_vertical
);

--select * from P_ukplan_report_T.searches;