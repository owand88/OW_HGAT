-- Author: 			Robbie Evans
-- Stakeholder: 	Wahaaj Shabbir, Alice Bridson, Emma Hamilton, Ines Morais, Keith Metcalfe
-- Purpose: 		List new AG listings made in the past 7 days so that the Auth Centre team are able to review listings as soon after they have gone live as possible in order to pre-empt any possible PSNAD issues.
-- Date Created: 	05/04/2023




With lux_items AS
(
select
item_id, category
from
	(
	-- an item/variation can be evaluated multiple items. We only pickup the last evaluation result.
	select item_id
	,case when BIZ_PRGRM_NAME = 'PSA_SNEAKER_EBAY_UK' then 'Sneakers'
		when BIZ_PRGRM_NAME = 'PSA_HANDBAGS_UK' then 'Handbags'
		when BIZ_PRGRM_NAME = 'PSA_WATCHES_UK' then 'Watches'
	else 'Other' End as category
	from access_views.DW_PES_ELGBLT_HIST
	where BIZ_PRGRM_NAME in ('PSA_SNEAKER_EBAY_UK','PSA_HANDBAGS_UK','PSA_WATCHES_UK') -- Handbags AG program
	and elgbl_yn_ind ='Y'
	Group by 1,2
	 
	UNION ALL
	 
	Select ITEM_ID, 'Jewellery' as category
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
	Group by 1,2
	)w
where 
1=1
Group by 1,2
)


select lstg.ITEM_ID
,lstg.auct_titl
,lstg.AUCT_START_DT
,lstg.AUCT_END_DT
,lstg.SLR_ID
,psa.category
,brand
,model
,case when lstg.SLR_ID = p.seller_id then p.prev_p_or_snads else 0 end as previous_AG_snad_or_psnad
,case when lstg.SLR_ID = p.seller_id then p.prev_sold_items else 0 end as previous_AG_items
,lstg.item_loc
,case when lstg.LSTG_STATUS_ID = 0 then 'Live'
	when lstg.LSTG_STATUS_ID = 1 then 'Ended'
	when lstg.LSTG_STATUS_ID = 2 then 'Admin Ended'
	when lstg.LSTG_STATUS_ID = 3 then 'Deleted'
	when lstg.LSTG_STATUS_ID = 4 then 'Scheduled'
	end as lstg_status
,case when lstg.AUCT_TYPE_CODE = 1 then 'Auction'
	when lstg.AUCT_TYPE_CODE = 9 then 'Fixed Price'
	else 'Other'
	end as lstg_type
,lstg.START_PRICE_LSTG_CURNCY
,lstg.RSRV_PRICE_LIST_CRNCY
,lstg.CURNT_PRICE_LSTG_CURNCY
,lstg.QTY_SOLD
,lstg.QTY_AVAIL - lstg.QTY_SOLD as QTY_REMAINING
,lstg.stock_photo_used_yn
,lstg.photo_count
,lstg.gallery_url
,lstg.picture_url
,'https://ebay.com/itm/'||lstg.item_id as item_url

From 
	(select *
	from ACCESS_VIEWS.DW_LSTG_ITEM lstg
	Where SLR_CNTRY_ID = 3
	and lstg.AUCT_START_DT >= CURRENT_DATE-7
	and lstg.AUCT_END_DT >= CURRENT_DATE-7
	) lstg
inner join lux_items PSA
		on lstg.ITEM_ID = psa.item_id
LEFT JOIN
	(select 
	seller_id
	,count(distinct case when psnad = 'PSNAD' or SNAD_REMORSE_FLAG = 'SNAD' then item_id end) as prev_p_or_snads
	,count(distinct item_id) as prev_sold_items

	from  P_PSA_ANALYTICS_T.psa_hub_data

	where upper(HUB_REV_ROLLUP) = 'UK'
	and upper(IS_RETURN_FLAG_YN_IND) = 'N'
	and upper(HUB_CATEGORY) = 'HANDBAGS'

	group by 1
	) p 
		on lstg.SLR_ID = p.seller_id
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
						ACCESS_VIEWS.item_aspct_clssfctn
					where
						AUCT_END_DT>='2020-12-07'
						AND lower(ns_type_cd) in (lower('nf'),lower('df' ) ) and upper(prdct_aspct_nm)= upper('BRAND')
					)SB
				Where dup_check = 1
				GROUP BY 1) brand
					on lstg.item_id = brand.item_id
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
						ACCESS_VIEWS.item_aspct_clssfctn
					where
						AUCT_END_DT>='2020-12-07'
						AND lower(ns_type_cd) in (lower('nf'),lower('df' ) ) and upper(prdct_aspct_nm)= upper('MODEL')
					)SB
				Where dup_check = 1
				GROUP BY 1) model
					on lstg.item_id = model.item_id