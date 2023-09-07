-- JIRA Ticket:     UKPLAN-519

-- Author: 			Robbie Evans
-- Stakeholder: 	Wahaaj Shabbir
-- Purpose: 		Sneakers has been in decline for much of 2023. This is due to resale being in decline in the current market on Sneakers. The hypothesis is that our Sneakers declines is as a result of many of our top Sneaker buyers being resellers so need to understand if this is in fact the case or if something else is driving decline.
-- Date Created: 	22/08/2023

with sneaker_buyers as 
( 
select BUYER_ID
	,BUYER_TYPE_DESC
	,case when rank_2022 <= 100 then rank_2022 end as rank2022
	,case when rank_2023 <= 100 then rank_2023 end as rank2023
FROM
	(
	Select BUYER_ID
		,BUYER_TYPE_DESC
		,gmb_YTD_2022
		,gmb_YTD_2023
		,dense_rank() over (order by gmb_YTD_2022 desc) as rank_2022
		,dense_rank() over (order by gmb_YTD_2023 desc) as rank_2023

	From
		(
		select ck.buyer_id
			,seg.BUYER_TYPE_DESC
			,sum(case when retail_year = 2022 and cal.retail_week <= (select retail_week from DW_CAL_DT where AGE_FOR_RTL_WEEK_ID = -1 group by 1) then ck.GMV20_PLAN End) as gmb_YTD_2022
			,sum(case when retail_year = 2023 and cal.retail_week <= (select retail_week from DW_CAL_DT where AGE_FOR_RTL_WEEK_ID = -1 group by 1) then ck.GMV20_PLAN End) as gmb_YTD_2023

		FROM PRS_RESTRICTED_V.SLNG_TRANS_SUPER_FACT ck
		inner join DW_CAL_DT cal
			on ck.gmv_dt = cal.CAL_DT
			and cal.retail_year in (2022,2023)
			and cal.AGE_FOR_RTL_WEEK_ID <= -1
		INNER JOIN P_INVENTORYPLANNING_T.dw_category_groupings_adj CAT
			ON ck.LEAF_CATEG_ID = CAT.LEAF_CATEG_ID
			AND cat.site_id = 3
		inner JOIN ACCESS_VIEWS.SSA_CURNCY_PLAN_RATE_DIM LPR 
			ON ck.LSTG_CURNCY_ID = LPR.CURNCY_ID 
		LEFT JOIN PRS_RESTRICTED_V.USER_DNA_FM_SGMNT seg
			on ck.BUYER_ID = seg.USER_ID
			and ck.CREATED_DT between seg.START_DATE and seg.END_DATE
		LEFT JOIN DW_COUNTRIES c
			on ck.BYR_CNTRY_ID = c.cntry_id

		Where 1=1
			AND ck.SLR_CNTRY_ID = 3										--UK sellers
			and ck.SITE_ID = 3											--Transaction on UK site
			and cat.CATEG_LVL4_ID IN (15709,95672,155202,57974,57929) 	--Only Sneaker categories
			and ck.ITEM_PRICE*lpr.CURNCY_PLAN_RATE >= 100				--Sneakers over $100

		Group by 1,2
		)
	)
where rank_2022 <=100 or rank_2023 <= 100
)






Select buying.buyer_id
	,buying.BUYER_TYPE_DESC
	,buying.rank2022
	,buying.rank2023
	,buying.buyer_name
	,buying.buyer_cntry
	,buying.buyer_seller_type
	,buying.price_tranche
	,buying.CATEG_LVL4_NAME
	,gmb_YTD_2022
	,gmb_YTD_2023
	,bi_YTD_2022
	,bi_YTD_2023
	,gmv_YTD_2022
	,gmv_YTD_2023
	,si_YTD_2022
	,si_YTD_2023

From
	(
	select ck.buyer_id
		,sb.BUYER_TYPE_DESC
		,sb.rank2022
		,sb.rank2023
		,u.user_slctd_id as buyer_name
		,c.cntry_desc as buyer_cntry
		,case when u.USER_DSGNTN_ID = 2 then 'B2C' else 'C2C' End as buyer_seller_type
		,CASE
			WHEN Cast(ck.item_price*LPR.CURNCY_PLAN_RATE AS DECIMAL(18,2))  < 100  THEN 'A. <£86 (<$100)'
			WHEN Cast(ck.item_price AS DECIMAL(18,2))  < 100 THEN 'B. £86-£100 ($100-£100)'
			WHEN Cast(ck.item_price AS DECIMAL(18,2))  < 125 THEN 'C. £100-£125'
			WHEN Cast(ck.item_price AS DECIMAL(18,2))  < 150 THEN 'D. £125-£150'
			WHEN Cast(ck.item_price AS DECIMAL(18,2))  < 200 THEN 'D. £150-£200'
			ELSE 'E. £200+'
			End as price_tranche
		,cat.CATEG_LVL4_NAME
		,cat.CATEG_LVL4_ID
		,sum(case when retail_year = 2022 and cal.retail_week <= (select retail_week from DW_CAL_DT where AGE_FOR_RTL_WEEK_ID = -1 group by 1) then ck.GMV20_PLAN End) as gmb_YTD_2022
		,sum(case when retail_year = 2023 and cal.retail_week <= (select retail_week from DW_CAL_DT where AGE_FOR_RTL_WEEK_ID = -1 group by 1) then ck.GMV20_PLAN End) as gmb_YTD_2023
		,sum(case when retail_year = 2022 and cal.retail_week <= (select retail_week from DW_CAL_DT where AGE_FOR_RTL_WEEK_ID = -1 group by 1) then ck.GMV20_SOLD_QUANTITY End) as bi_YTD_2022
		,sum(case when retail_year = 2023 and cal.retail_week <= (select retail_week from DW_CAL_DT where AGE_FOR_RTL_WEEK_ID = -1 group by 1) then ck.GMV20_SOLD_QUANTITY End) as bi_YTD_2023


	FROM PRS_RESTRICTED_V.SLNG_TRANS_SUPER_FACT ck
	inner join DW_USERS u
		on ck.BUYER_ID = u.user_id
	inner join DW_CAL_DT cal
		on ck.gmv_dt = cal.CAL_DT
		and cal.retail_year in (2022,2023)
		and cal.AGE_FOR_RTL_WEEK_ID <= -1
	INNER JOIN P_INVENTORYPLANNING_T.dw_category_groupings_adj CAT
		ON ck.LEAF_CATEG_ID = CAT.LEAF_CATEG_ID
		AND cat.site_id = 3
	inner  JOIN ACCESS_VIEWS.SSA_CURNCY_PLAN_RATE_DIM LPR 
		ON ck.LSTG_CURNCY_ID = LPR.CURNCY_ID 
	inner join sneaker_buyers sb
		on ck.buyer_id = sb.buyer_id
	LEFT JOIN DW_COUNTRIES c
		on ck.BYR_CNTRY_ID = c.cntry_id

	Where 1=1
		AND ck.SLR_CNTRY_ID = 3										--UK sellers
		and ck.SITE_ID = 3											--Transaction on UK site
		and cat.CATEG_LVL4_ID IN (15709,95672,155202,57974,57929) 	--Only Sneaker categories
		and ck.ITEM_PRICE*lpr.CURNCY_PLAN_RATE >= 100				--Sneakers over $100

	Group by 1,2,3,4,5,6,7,8,9,10
	) buying
LEFT JOIN
	(
	select ck.SELLER_ID as buyer_id
		,CASE
			WHEN Cast(ck.item_price*LPR.CURNCY_PLAN_RATE AS DECIMAL(18,2))  < 100  THEN 'A. <£86 (<$100)'
			WHEN Cast(ck.item_price AS DECIMAL(18,2))  < 100 THEN 'B. £86-£100 ($100-£100)'
			WHEN Cast(ck.item_price AS DECIMAL(18,2))  < 125 THEN 'C. £100-£125'
			WHEN Cast(ck.item_price AS DECIMAL(18,2))  < 150 THEN 'D. £125-£150'
			WHEN Cast(ck.item_price AS DECIMAL(18,2))  < 200 THEN 'D. £150-£200'
			ELSE 'E. £200+'
			End as price_tranche
		,cat.CATEG_LVL4_NAME
		,cat.CATEG_LVL4_ID
		,sum(case when retail_year = 2022 and cal.retail_week <= (select retail_week from DW_CAL_DT where AGE_FOR_RTL_WEEK_ID = -1 group by 1) then ck.GMV20_PLAN End) as gmv_YTD_2022
		,sum(case when retail_year = 2023 and cal.retail_week <= (select retail_week from DW_CAL_DT where AGE_FOR_RTL_WEEK_ID = -1 group by 1) then ck.GMV20_PLAN End) as gmv_YTD_2023
		,sum(case when retail_year = 2022 and cal.retail_week <= (select retail_week from DW_CAL_DT where AGE_FOR_RTL_WEEK_ID = -1 group by 1) then ck.GMV20_SOLD_QUANTITY End) as si_YTD_2022
		,sum(case when retail_year = 2023 and cal.retail_week <= (select retail_week from DW_CAL_DT where AGE_FOR_RTL_WEEK_ID = -1 group by 1) then ck.GMV20_SOLD_QUANTITY End) as si_YTD_2023

	FROM PRS_RESTRICTED_V.SLNG_TRANS_SUPER_FACT ck
	inner join DW_USERS u
		on ck.SELLER_ID = u.user_id
	inner join DW_CAL_DT cal
		on ck.gmv_dt = cal.CAL_DT
		and cal.retail_year in (2022,2023)
		and cal.AGE_FOR_RTL_WEEK_ID <= -1
	INNER JOIN P_INVENTORYPLANNING_T.dw_category_groupings_adj CAT
		ON ck.LEAF_CATEG_ID = CAT.LEAF_CATEG_ID
		AND cat.site_id = 3
	inner  JOIN ACCESS_VIEWS.SSA_CURNCY_PLAN_RATE_DIM LPR 
		ON ck.LSTG_CURNCY_ID = LPR.CURNCY_ID 
	inner join sneaker_buyers sb
		on ck.seller_id = sb.buyer_id

	Where 1=1
		AND ck.SLR_CNTRY_ID = 3										--UK sellers
		and ck.SITE_ID = 3											--Transaction on UK site
		and cat.CATEG_LVL4_ID IN (15709,95672,155202,57974,57929) 	--Only Sneaker categories
		and ck.ITEM_PRICE*lpr.CURNCY_PLAN_RATE >= 100				--Sneakers over $100

	Group by 1,2,3,4
	) selling
		on buying.buyer_id = selling.buyer_id
		and buying.price_tranche = selling.price_tranche
		and buying.categ_lvl4_id = selling.categ_lvl4_id
		
