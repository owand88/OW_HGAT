-- JIRA:            UKPLAN-246

-- Author: 			Robbie Evans
-- Date:            20/04/2023

-- Stakeholder: 	All UK Verticals
-- Description: 	A dashboard that highlights business selelrs who have blocked accounts and the scenarios around why they are blocked





drop table if exists P_ukplan_report_T.blocked_sellers_report_seller_list;

create table P_ukplan_report_T.blocked_sellers_report_seller_list as
(
Select
ck.seller_id as slr_id,
u.user_slctd_id as seller_name,
cat.new_vertical, 
cat.categ_lvl2_name,
cat.meta_Categ_name,
SUM(CAST(CK.gmv_plan_usd AS DECIMAL(18,2))) AS GMV_YTD

FROM   DW_CHECKOUT_TRANS ck
INNER JOIN P_INVENTORYPLANNING_T.dw_category_groupings_adj CAT
	ON ck.LEAF_CATEG_ID = CAT.LEAF_CATEG_ID
	AND cat.site_id = 3
LEFT OUTER JOIN dw_users u
	on ck.seller_Id = u.user_id     
INNER JOIN ACCESS_VIEWS.DW_CAL_DT CAL
	ON CAL.CAL_DT = CK.gmv_dt
	and retail_year >= (select retail_year from DW_CAL_DT where AGE_FOR_RTL_WEEK_ID = -1 group by 1) --change here for time period if needed 

WHERE 1=1
	and CK.SALE_TYPE NOT IN (10,15) 
	and ck.site_id = 3
	and slr_cntry_id = 3
	and user_dsgntn_id =  2 -- Business users only

GROUP BY 1,2,3,4,5
)
;
 
 

 
 --------------------------------------------------------------------------------------------------------------------
--This table creates a list of all new issues created in the past week and description of those issues (e.g. seller opts into managed payments, seller restriction applied, etc)

drop table if exists P_ukplan_report_T.blocked_sellers_report_scenarios;
create table P_ukplan_report_T.blocked_sellers_report_scenarios as
(
select 
s.new_vertical
, i.user_id
, s.seller_name
, case when  i.user_id  = fss.seller_id then 'Focus'
	else 'Non-focus'
	end as focus_flag
, case when i.user_id  = fss.seller_id then am_name
	else ' - '
	end as CM_flag
, i.SRC_CRE_DT as issue_date
, scenario_desc
, i.scenario_id
, status_desc
, sum(s.GMV_YTD) as GMV_YTD

from access_views.DW_USER_ISSUE I

left join access_views.DW_USER_ISSUE_LKP_SCENARIO lkp
	on i.SCENARIO_ID=lkp.SCENARIO_ID
left join ACCESS_VIEWS.DW_USER_ISSUE_LKP_STATUS st
	on st.status_id = i.status_id
LEFT JOIN P_awang_ops_T.seller_ops_83 fss
	on i.user_id = fss.seller_id
inner join dw_cal_dt cal
	on cal.cal_dt = i.src_cre_dt
	and age_for_rtl_week_id = -1
INNER JOIN
	(select 
	new_vertical
	,slr_id
	,sum(GMV_YTD) as GMV_YTD
	from P_ukplan_report_T.blocked_sellers_report_seller_list
	group by 1,2) s
		on s.slr_id = i.user_id

where 1=1
and scenario_desc not in ('UNKNOWN') 

group by 1,2,3,4,5,6,7,8,9
)
;

-------------------------------------------------------------------------------------
--This table creates a list of all updates to seller "states" in the past week and reason behind those updates


drop table if exists P_ukplan_report_T.blocked_sellers_report_seller_state;
create table P_ukplan_report_T.blocked_sellers_report_seller_state  as
(
SELECT  new_vertical
, sh.ID AS USER_ID
, u.user_slctd_id as seller_name
, case when sh.id = fss.seller_id then 'Focus'
	else 'Non-focus'
	end as focus_flag
, user_cre_date as User_created_date
, TOP_RATED_SELLER_UK_YN
, lf.GMV_YTD as GMV_YTD
, sh.CHANGE_TIME
, fs.USER_STS_DESC AS FROM_STATE
, ts.USER_STS_DESC AS TO_STATE
, crsn.STATE_CHG_RSN_NAME AS CHANGE_REASON
, cn.ADMIN_NODE_NAME AS MAC_RULE_NAME

FROM DW_USER_STATE_HISTORY sh
LEFT JOIN DW_USER_STATUS_CODES fs
	ON sh.FROM_STATE = fs.USER_STS_CODE 
LEFT JOIN DW_USER_STATUS_CODES ts
	ON sh.TO_STATE = ts.USER_STS_CODE
LEFT JOIN DW_USER_STATE_CHG_RSN_LKP crsn
	ON sh.REASON_CODE = crsn.STATE_CHG_RSN_ID 
LEFT JOIN EBAY_TS_V.MAC_ACTIVITY mac
	ON sh.MAC_ACTVTY_ID = mac.MAC_ACTIVITY_ID
INNER JOIN
	(select 
	new_vertical
	,slr_id
	,sum(GMV_YTD) as GMV_YTD
	from P_ukplan_report_T.blocked_sellers_report_seller_list
	group by 1,2) lf
		on sh.id = lf.slr_id
LEFT JOIN (select distinct seller_id from P_awang_ops_T.seller_ops_83) fss
	on sh.id = fss.seller_id
LEFT JOIN EBAY_CS_V.CSM_NODE cn
	ON mac.RULE_ID = cn.ADMIN_NODE_ID
	AND mac.CSM_HIER_ID = cn.CSM_HIER_ID
left join dw_users u
	on u.user_id = sh.id
	and ACCT_TYPE_CD = 1
inner join dw_cal_dt cal
	on cal.cal_dt = to_date(sh.change_time)
	and age_for_rtl_week_id = -1

where cn.ADMIN_NODE_NAME not in ('Account_Deletion')
/*and ts.USER_STS_DESC not in */
and u.user_site_id = 3
group by 1,2,3,4,5,6,7,8,9,10,11,12
);
