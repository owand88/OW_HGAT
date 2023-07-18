-- Author: 			Robbie Evans
-- Stakeholder: 	Penelope Faith
-- Purpose: 		Gain an understanding of the demographics of Mulberry Handbag shoppers
-- Date Created: 	18/07/2023



Select
	case when lower(ck.brand) like '%mulberry%' then 'Mulberry' else 'Other Brands' End as brand
	,d.MACRO_CL_NAME
	,count(distinct ck.BUYER_ID) as buyers
	,sum(ck.QTY) as si
FROM ACCESS_VIEWS.FOCUSED_VERT_TXN ck
INNER JOIN DW_CAL_DT cal
	on ck.GMV_DT = cal.CAL_DT
	and cal.AGE_FOR_RTL_WEEK_ID >= -52
INNER JOIN DW_COUNTRIES cn
	on ck.BYR_CNTRY_ID = cn.cntry_id
INNER JOIN ACCESS_VIEWS.USER_DNA_DIM c
	ON ck.buyer_id = c.user_id
INNER JOIN ACCESS_VIEWS.LFSTG_CLSTR_PRMRY_USER d
	on c.primary_user_id = d.primary_user_id
	and ck.GMV_DT between RCRD_EFF_START_DT and RCRD_EFF_END_DT
	and cn.REV_ROLLUP = d.USER_REV_ROLLUP -- align LSS build with user's REV_ROLLUP
Where 1=1
	and ck.FOCUSED_VERTICAL_LVL1 = 'Handbags >=$500'
	and ck.SLR_CNTRY_ID = 3
	and ck.BYR_CNTRY_ID = 3
	and upper(ck.REGION_DESC) = 'UK'
Group by 1,2

