-- JIRA Ticket:     UKPLAN-446

-- Author: 			Robbie Evans
-- Stakeholder: 	Wahaaj Shabbir
-- Purpose: 		Ahead of the eMS launch for Sneakers in UK, need to understand the volume of listings and sellers impacted at each ramp stage as the process rolls out.
-- Date Created: 	12/07/2023



select 
case when (trim(lower(lstg.item_zip)) like 'gy%' OR trim(lower(lstg.item_zip)) like 'bt%') then 'Channel Islands' ---Must exclude Channel Islands as not AG eligible
	else 'Rest of UK' end as item_loc
,case when lstg.SLR_ID = slr.SLR_ID then 'Beta Ramp Sellers'
	else 'Other Sellers' end as beta_sellers_flag
,count(distinct lstg.item_id) as live_listings
,count(distinct lstg.SLR_ID) as seller_count

From DW_LSTG_ITEM lstg
INNER JOIN 
	(
	select item_id
	from access_views.DW_PES_ELGBLT_HIST
	where evltn_end_ts = '2099-12-31 00:00:00'
	and BIZ_PRGRM_NAME = 'PSA_SNEAKER_EBAY_UK' -- UK Sneakers AG program
	and elgbl_yn_ind ='Y' -- eligible items
	Group by 1
	) ag 
		on lstg.item_id = ag.item_id
LEFT JOIN
	(
	SELECT user_id as slr_id ---Beta launch seller cohort
	From DW_USERS 
	Where user_id in (
					1055061407,
					1397384139,
					1043109755,
					1479069056,
					1183218560,
					1555901602,
					236769109,
					1281178189,
					1009683250,
					750406513,
					1633641721,
					2416797447,
					2231234088,
					134271887,
					182186079,
					2105251860,
					2048417966,
					1547326162,
					1093603614,
					1034142459,
					165780290
					)
	Group by 1
	) slr 
		on lstg.SLR_ID = slr.SLR_ID

WHERE 1=1
and lstg.AUCT_START_DT <= CURRENT_DATE
and lstg.AUCT_END_DT >= CURRENT_DATE
and lstg.SLR_CNTRY_ID = 3
and lstg.ITEM_SITE_ID = 3

Group by 1,2