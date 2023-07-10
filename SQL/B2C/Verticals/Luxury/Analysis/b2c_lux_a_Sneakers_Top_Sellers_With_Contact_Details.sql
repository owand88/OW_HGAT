-- JIRA:            UKPLAN-400

-- Author: 			Robbie Evans
-- Date:            13/06/2023

-- Stakeholder: 	Wahaaj Shabbir
-- Description: 	Top 100 B2C Sneaker (FC) sellers including their contact details for seller outreach comms






select ck.SELLER_ID
,ck.USER_SLCTD_ID
,u.SELLR_EMAIL_ELGBL_YN
,u.EMAIL
,u.USER_NAME
,u.COMP
,u.DAYPHONE
,sum(ck.GMV2_PLAN) as gmv

FROM ACCESS_VIEWS.FOCUSED_VERT_TXN ck
INNER JOIN DW_CAL_DT cal
	on ck.GMV_DT = cal.CAL_DT
	and cal.RETAIL_YEAR = 2023
	and cal.AGE_FOR_RTL_WEEK_ID < 0
LEFT JOIN prs_secure_v.MDM_USER_PII u
	on ck.SELLER_ID = u.USER_ID

Where 1=1
and FOCUSED_VERTICAL_LVL1 = 'Sneakers >=$100'
and ck.SLR_CNTRY_ID = 3
and ck.B2C_C2C = 'B2C'
and upper(ck.CK_WACKO_YN) = 'N'

Group by 1,2,3,4,5,6,7

Order by gmv desc

Limit 200
