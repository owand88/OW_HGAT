-- Author: 			Robbie Evans
-- Stakeholder: 	Wahaaj Shabbir
-- Purpose: 		PSNADs will soon be implemented for AG Sneakers. In order to prepare for this, they need to understand the potential Sneaker PSNAD volumes that can be expected at the Auth Centre
-- Date Created: 	18/07/2023



	select
		cal.retail_week as auth_week
		,case when SELLER_REFUND_FLAG = 'SELLER REFUND' then 'Buyer SNAD' else 'Auth Centre SNAD' end as snad_logger
		,count(distinct hub.ITEM_ID) as quantity


	From
		P_PSA_ANALYTICS_T.psa_hub_data hub
	inner join DW_CAL_DT cal
		on to_date(hub.ATHNTCTN_DATE) = cal.CAL_DT
		and cal.RETAIL_YEAR = 2023
		and cal.RETAIL_WEEK <= 28

	where
		1=1
		AND ATHNTCTN_STATUS_NAME_2 = 'SNAD'
		AND upper(HUB_REV_ROLLUP) = 'UK'
		AND upper(HUB_CATEGORY) = 'SNEAKERS'

	group by 1,2
