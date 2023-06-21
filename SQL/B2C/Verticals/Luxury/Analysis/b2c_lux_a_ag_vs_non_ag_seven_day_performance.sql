-- JIRA:            UKPLAN-246

-- Author: 			Robbie Evans
-- Date:            20/04/2023

-- Stakeholder: 	All Lux UK
-- Description: 	Shows UK Lux category perfromance for the past 7 sevens with a filter for AG




With lstg1 AS
(Select ck.item_id, lstg.AUCT_TITL as auct_title
From
	(
	select item_id
	From DW_CHECKOUT_TRANS ck
	INNER JOIN ACCESS_VIEWS.DW_CATEGORY_GROUPINGS CAT1 
		ON CAT1.LEAF_CATEG_ID = ck.LEAF_CATEG_ID 
		AND CAT1.SITE_ID = 3
		AND CAT1.SAP_CATEGORY_ID NOT in (5,7,41,23,-999) 
	Where 1=1
	and ck.SLR_CNTRY_ID = 3
	and ck.SITE_ID = 3
	and ((cat1.CATEG_LVL3_ID in (260325)) or (cat1.CATEG_LVL4_ID in (15709,95672)) or (cat1.categ_lvl3_id = 169291) OR (cat1.categ_lvl4_id = 52357))
	and ck.CREATED_DT >= CURRENT_DATE - 7
	and ck.ITEM_PRICE >= 75
	Group by 1
	) ck 
Left Join DW_LSTG_ITEM lstg
	on ck.item_id = lstg.ITEM_ID
	 
Group by 1,2)

select 
ck.CREATED_DT
,case when ck.ITEM_ID = psa.item_id then 'AG' else 'Non-AG' end as ag_flag
,case when CATEG_LVL4_ID IN (15709,95672,155202,57974,57929) then 'Sneakers'
	when META_CATEG_ID = 281 AND CATEG_LVL2_ID <> 260324 then 'Jewellery'
	when (CATEG_LVL3_ID = 169291 OR CATEG_LVL4_ID IN (52357,163570,169285,45258,2996,45237,169271)) then 'Handbags'
	when CATEG_LVL2_ID = 260324 then 'Watches'
	else 'Other'
	End as category
,ck.RPRTD_WACKO_YN
,lstg1.auct_title
,ck.item_id
,format_number(ck.ITEM_PRICE,0) as selling_price
,brand
,model
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
,CASE WHEN UPPER(BRND.ASPCT_VLU_NM_BRAND) IN ('MODIFIED', 'CUSTOMIZED','YES') THEN 'MODIFIED' ELSE 'NO' end AS MODIFIED_ITEM
,format_number(sum(ck.gmv_plan_usd),0) as gmv
,format_number(sum(ck.QUANTITY),0) as si

From ACCESS_VIEWS.DW_CHECKOUT_TRANS ck
INNER JOIN lstg1
	on lstg1.item_id = ck.item_id
left join
	(select item_id
	from
		(
		-- an item/variation can be evaluated multiple items. We only pickup the last evaluation result.
		Select ITEM_ID
		From (
			select hist.item_id, hist.ELGBL_YN_IND, Row_Number() Over (partition by hist.item_id order by hist.EVLTN_TS desc)
			from access_views.DW_PES_ELGBLT_HIST hist
			inner join lstg1
				on hist.item_id = lstg1.item_id
			where hist.BIZ_PRGRM_NAME in ('PSA_SNEAKER_EBAY_UK','PSA_HANDBAGS_UK','PSA_WATCHES_UK') -- Handbags AG program
			qualify (Row_Number() Over (partition by item_id order by EVLTN_TS desc)) = 1
			)
		Where ELGBL_YN_IND = 'Y'

		UNION ALL

		Select ITEM_ID
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
		Group by 1
		)
	where 
	1=1
	Group by 1
			) PSA
				on ck.ITEM_ID = psa.item_id
INNER JOIN ACCESS_VIEWS.DW_CAL_DT cal on ck.created_dt = cal.CAL_DT
	and AGE_FOR_DT_ID >= -7
Left JOIN ACCESS_VIEWS.DW_COUNTRIES cntry
	on cntry.CNTRY_ID = ck.SLR_CNTRY_ID
Left JOIN ACCESS_VIEWS.DW_COUNTRIES cntry1
	on cntry1.CNTRY_ID = ck.BYR_CNTRY_ID
Left Join ACCESS_VIEWS.DW_CK_LKP_PYMT_MTHD pay
	on pay.pymt_mthd_id = ck.PAYMENT_METHOD
INNER JOIN ACCESS_VIEWS.DW_CATEGORY_GROUPINGS CAT 
	ON CAT.LEAF_CATEG_ID = ck.LEAF_CATEG_ID 
	AND CAT.SITE_ID = 3
	AND CAT.SAP_CATEGORY_ID NOT in (5,7,41,23,-999) 
LEFT JOIN ACCESS_VIEWS.DW_USERS u
	on u.user_id = ck.seller_id
LEFT JOIN ACCESS_VIEWS.DW_USERS u1
	on u1.user_id = ck.BUYER_ID
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
			GROUP BY 1,2) bbase ON ck.ITEM_ID = bbase.ITEM_ID AND ck.AUCT_END_dt = bbase.AUCT_END_DT

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
			GROUP BY 1,2) bbase1 ON ck.ITEM_ID = bbase1.ITEM_ID AND ck.AUCT_END_dt = bbase1.AUCT_END_DT
LEFT JOIN 
                    (
                    SELECT ITEM_ID,
                           AUCT_END_DT,
                           COALESCE(MAX(ASPCT.ASPCT_VLU_NM),'UNKNOWN') AS ASPCT_VLU_NM_BRAND
                            FROM
                            ACCESS_VIEWS.ITEM_ASPCT_CLSSFCTN ASPCT
                            WHERE
                            UPPER(ASPCT.NS_TYPE_CD) IN ('NF','DF') 
                            AND ASPCT.AUCT_END_DT>='2018-12-26'
                            AND UPPER(ASPCT.PRDCT_ASPCT_NM) LIKE ('%MODIFIED ITEM%')
                            GROUP BY 1,2
                            
                        UNION 
                        
                        SELECT  ITEM_ID,
                           AUCT_END_DT,
                          COALESCE(MAX(ASPCT_COLD.ASPCT_VLU_NM),'UNKNOWN') AS ASPCT_VLU_NM_BRAND
                        FROM
                        ACCESS_VIEWS.ITEM_ASPCT_CLSSFCTN_COLD ASPCT_COLD
                        WHERE UPPER(ASPCT_COLD.NS_TYPE_CD) IN ('NF','DF') 
                        AND ASPCT_COLD.AUCT_END_DT>='2018-12-26'
                        AND UPPER(ASPCT_COLD.PRDCT_ASPCT_NM) LIKE ('%MODIFIED ITEM%')
                        GROUP BY 1,2
                    ) BRND ON CK.ITEM_ID = BRND.ITEM_ID AND CK.AUCT_END_DT = BRND.AUCT_END_DT


Where 1=1
and ck.SITE_ID = 3
and ((cat.CATEG_LVL3_ID in (260325)) or (cat.CATEG_LVL4_ID in (15709,95672)) or (cat.categ_lvl3_id = 169291) OR (cat.categ_lvl4_id = 52357))
and ck.ITEM_PRICE >= 100
and ck.SLR_CNTRY_ID = 3

Group by 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20

