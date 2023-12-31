-- JIRA:            UKPLAN-183

-- Author: 			Robbie Evans
-- Date:            05/04/2023

-- Stakeholder: 	Wahaaj Shabbir, Alice Bridson, Emma Hamilton, Ines Morais, Keith Metcalfe
-- Description: 	List new AG listings made in the past 7 days so that the Auth Centre team are able to review listings as soon after they have gone live as possible in order to pre-empt any possible PSNAD issues.





---------------------------------------Latest AG Listings Sheet------------------------------------------------------

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
		INNER JOIN P_INVENTORYPLANNING_T.dw_category_groupings_adj CAT 
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











---------------------------------------High Value Item Sales Sheet------------------------------------------------------



select 
ck.CREATED_DT
,case when ck.ITEM_ID = psa.item_id then 'AG' else 'Non-AG' end as ag_flag
,ck.item_id
,brnd.brand
,mdl.model
,CASE WHEN UPPER(mi.modified_item) IN ('MODIFIED', 'CUSTOMIZED','YES') THEN 'MODIFIED' ELSE 'NO' end AS MODIFIED_ITEM
,case when cat.CATEG_LVL4_ID IN (15709,95672,155202,57974,57929) then 'Sneakers'
		when cat.META_CATEG_ID = 281 AND cat.CATEG_LVL2_ID <> 260324 then 'Jewellery'
		when (cat.CATEG_LVL3_ID = 169291 OR cat.CATEG_LVL4_ID IN (52357,163570,169285,45258,2996,45237,169271)) then 'Handbags'
		when cat.CATEG_LVL2_ID = 260324 then 'Watches'
		else 'Other'
		End as category
,lstg.auct_titl as auct_title
,ck.ITEM_PRICE as selling_price
,ck.seller_id
,u.user_slctd_id as selleR_name
,case when u.USER_DSGNTN_ID = 2 then 'B2C'
	when u.USER_DSGNTN_ID = 1 then 'C2C' Else 'Undefined' End as B2C_C2C
,cntry.CNTRY_DESC as seller_country
,ck.BUYER_ID
,u1.user_slctd_id as buyer_name
,cntry1.CNTRY_DESC as buyer_country
,case when ck.SLR_CNTRY_ID <> ck.BYR_CNTRY_ID then 'CBT' Else 'Domestic' End as CBT_Domestic
,case when ck.CHECKOUT_STATUS = 0 then 'Not Started'
	when ck.CHECKOUT_STATUS = 1 then 'Incomplete'
	when ck.CHECKOUT_STATUS = 2 and ck.gmv_dt is not null then 'Complete and Paid'
	when ck.CHECKOUT_STATUS = 2 and ck.gmv_dt is null then 'Complete Awaiting Payment'
	when ck.CHECKOUT_STATUS = 3 then 'Disabled'
	else 'Other' End as checkout_status
,pay.pymt_mthd_desc
,sum(ck.gmv_plan_usd) as gmv
,sum(ck.QUANTITY) as si


From ACCESS_VIEWS.DW_CHECKOUT_TRANS ck
INNER JOIN P_INVENTORYPLANNING_T.dw_category_groupings_adj CAT
		ON ck.LEAF_CATEG_ID = CAT.LEAF_CATEG_ID
		AND cat.site_id = 3
INNER JOIN ACCESS_VIEWS.DW_CAL_DT cal
	on ck.CREATED_DT = cal.CAL_DT
	and cal.CAL_DT >= CURRENT_DATE - 7
Left Join ACCESS_VIEWS.DW_LSTG_ITEM lstg
	on ck.item_id = lstg.ITEM_ID
left join
	(select item_id
	from
		(
		-- an item/variation can be evaluated multiple items. We only pickup the last evaluation result.
		Select ITEM_ID
		From (
			select hist.item_id, hist.ELGBL_YN_IND, Row_Number() Over (partition by hist.item_id order by hist.EVLTN_TS desc)
			from access_views.DW_PES_ELGBLT_HIST hist
			where hist.BIZ_PRGRM_NAME in ('PSA_SNEAKER_EBAY_UK','PSA_HANDBAGS_UK','PSA_WATCHES_UK') -- Handbags AG program
			qualify (Row_Number() Over (partition by item_id order by EVLTN_TS desc)) = 1
			)
		Where ELGBL_YN_IND = 'Y'

		UNION ALL

		Select ITEM_ID
		From ACCESS_VIEWS.DW_LSTG_ITEM lstg
		INNER JOIN P_INVENTORYPLANNING_T.dw_category_groupings_adj CAT 
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
		Group by 1
		)
	where 
	1=1
	Group by 1
			) PSA
				on ck.ITEM_ID = psa.item_id
left join (Select
				item_id,
				Auct_end_dt,
				coalesce(max(case  when lower(aspect)=lower('BRAND') then aspct_vlu_nm else NULL end ),'Unknown') as BRAND
			FROM
				(select
					item_id,
					auct_end_dt,
					ns_type_cd,
					1 as priority,
					'BRAND' as aspect,
					cast(trim(lower(aspct_vlu_nm)) as VARCHAR(350)) as aspct_vlu_nm 
				from
					ACCESS_VIEWS.item_aspct_clssfctn
				where
					AUCT_END_DT>='2016-06-01'
					AND lower(ns_type_cd) in (lower('nf'),lower('df' ) ) and upper(prdct_aspct_nm)= upper('BRAND')
				UNION ALL
				select
					item_id,
					auct_end_dt,
					ns_type_cd,
					2 as priority,
					'BRAND' as aspect,
					cast(trim(lower(aspct_vlu_nm)) as VARCHAR(350)) as aspct_vlu_nm
				from
					ACCESS_VIEWS.item_aspct_clssfctn_cold
				WHERE
					AUCT_END_DT>='2016-06-01'
					AND lower(ns_type_cd) in (lower('nf'),lower('df' ) ) and upper(prdct_aspct_nm)= upper('BRAND')
				)SB
			GROUP BY 1,2) brnd ON ck.ITEM_ID = brnd.ITEM_ID AND ck.AUCT_END_dt = brnd.AUCT_END_DT

left join (Select
				item_id,
				Auct_end_dt,
				coalesce(max(case  when lower(aspect)=lower('MODEL') then aspct_vlu_nm else NULL end ),'Unknown') as MODEL
			FROM
				(select
					item_id,
					auct_end_dt,
					ns_type_cd,
					1 as priority,
					'MODEL' as aspect,
					cast(trim(lower(aspct_vlu_nm)) as VARCHAR(350)) as aspct_vlu_nm 
				from
					ACCESS_VIEWS.item_aspct_clssfctn
				where
					AUCT_END_DT>='2016-06-01'
					AND lower(ns_type_cd) in (lower('nf'),lower('df' ) ) and upper(prdct_aspct_nm)= upper('MODEL')
				UNION ALL
				select
					item_id,
					auct_end_dt,
					ns_type_cd,
					2 as priority,
					'MODEL' as aspect,
					cast(trim(lower(aspct_vlu_nm)) as VARCHAR(350)) as aspct_vlu_nm
				from
					ACCESS_VIEWS.item_aspct_clssfctn_cold
				WHERE
					AUCT_END_DT>='2016-06-01'
					AND lower(ns_type_cd) in (lower('nf'),lower('df' ) ) and upper(prdct_aspct_nm)= upper('MODEL')
				)SB1
			GROUP BY 1,2) mdl ON ck.ITEM_ID = mdl.ITEM_ID AND ck.AUCT_END_dt = mdl.AUCT_END_DT
left join (Select
				item_id,
				Auct_end_dt,
				coalesce(max(aspct_vlu_nm),'Unknown') as MODIFIED_ITEM
			FROM
				(select
					item_id,
					auct_end_dt,
					ns_type_cd,
					1 as priority,
					'MODIFIED ITEM' as aspect,
					cast(trim(lower(aspct_vlu_nm)) as VARCHAR(350)) as aspct_vlu_nm 
				from
					ACCESS_VIEWS.item_aspct_clssfctn
				where
					AUCT_END_DT>='2016-06-01'
					AND lower(ns_type_cd) in (lower('nf'),lower('df' ) ) and upper(prdct_aspct_nm) like ('%MODIFIED ITEM%')
				UNION ALL
				select
					item_id,
					auct_end_dt,
					ns_type_cd,
					2 as priority,
					'MODIFIED ITEM' as aspect,
					cast(trim(lower(aspct_vlu_nm)) as VARCHAR(350)) as aspct_vlu_nm
				from
					ACCESS_VIEWS.item_aspct_clssfctn_cold
				WHERE
					AUCT_END_DT>='2016-06-01'
					AND lower(ns_type_cd) in (lower('nf'),lower('df' ) ) and upper(prdct_aspct_nm) like ('%MODIFIED ITEM%')
				)SB1
			GROUP BY 1,2) mi ON ck.ITEM_ID = mi.ITEM_ID AND ck.AUCT_END_dt = mi.AUCT_END_DT
Left JOIN ACCESS_VIEWS.DW_COUNTRIES cntry
	on cntry.CNTRY_ID = ck.SLR_CNTRY_ID
Left JOIN ACCESS_VIEWS.DW_COUNTRIES cntry1
	on cntry1.CNTRY_ID = ck.BYR_CNTRY_ID
Left Join ACCESS_VIEWS.DW_CK_LKP_PYMT_MTHD pay
	on pay.pymt_mthd_id = ck.PAYMENT_METHOD
LEFT JOIN ACCESS_VIEWS.DW_USERS u
	on u.user_id = ck.seller_id
LEFT JOIN ACCESS_VIEWS.DW_USERS u1
	on u1.user_id = ck.BUYER_ID
	
	
Where 1=1
and ck.SLR_CNTRY_ID = 3
and ck.SITE_ID = 3
and (
	(cat.CATEG_LVL2_ID = 260324) --Watches
	or (cat.CATEG_LVL3_ID = 169291) OR (cat.CATEG_LVL4_ID IN (52357,163570,169285,45258,2996,45237,169271)) --Handbags
	OR cat.CATEG_LVL4_ID IN (15709,95672,155202,57974,57929) --Sneakers
	OR (cat.META_CATEG_ID = 281 AND cat.CATEG_LVL2_ID <> 260324) --Jewellery
	)
and ck.ITEM_PRICE >= 75
and ck.CHECKOUT_STATUS = 2

	 
Group by 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19