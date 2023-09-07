-- JIRA Ticket:     UKPLAN-524
-- Author: 			Robbie Evans
-- Stakeholder: 	Hannah Richards
-- Purpose: 		GMV performance of a stationery event from 2022
-- Date Created: 	24/08/2023





with re as 
( 
select re.event_name
	,re.rpp_event_id
	,ri.ITEM_ID
from ACCESS_VIEWS.rpp_event re
inner join ACCESS_VIEWS.RPP_ITEM ri on ri.rpp_crtn_id = re.rpp_crtn_id

Where re.RPP_EVENT_ID = '6304ca482868210424055a07'

Group by 1,2,3
)





select 
re.RPP_EVENT_ID
,re.event_name
,count(distinct ck.TRANSACTION_ID) as TRANSACTIONS
,SUM(gmv_plan_usd) AS GMV
,sum(ck.quantity) as SI

FROM access_views.DW_CHECKOUT_TRANS ck  
INNER JOIN ACCESS_VIEWS.DW_CAL_DT AS CAL
        ON CAL.CAL_DT = CK.gmv_dt
        AND CAL.cal_dt between '2022-08-26' and '2022-09-02'
inner join re
	on re.item_id = ck.ITEM_ID

group by 1,2
;
