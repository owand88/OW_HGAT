-- Author: 			Robbie Evans
-- Stakeholder: 	Emma Hamilton
-- Purpose: 		Lux Handbags data required for PR Team
-- Date Created: 	28/03/2023


----------------------------------------------------------------------------------------------------------------------------------------

--------1) Top 20 handbag models sold since April 2022 and ASP of each item



select *
FROM
(
select
-- retail_year
-- ,retail_week
-- ,case when lower(brand) like '%chanel%' then 'Chanel'
-- 	when lower(brand) like '%loewe%' then 'Loewe'
-- 	when lower(brand) like '%louis vuitton%' then 'Louis Vuitton'
-- 	when lower(brand) like any ('%hermes%','%hermès%') then 'Hermes'
-- 	when lower(brand) like '%mulberry%' then 'Mulberry'
-- 	else 'Other' End as brand_normalised
CASE
		WHEN Cast(ck.ITEM_PRICE*lpr.CURNCY_PLAN_RATE AS DECIMAL(18,2))  < 500 THEN '<£435 ($500)'
		ELSE '>=£435 ($500)' END AS
	PRICE_BUCKET
,model
,brand
-- 	,CASE WHEN CNDTN_ROLLUP_ID = 1 THEN 'New' WHEN CNDTN_ROLLUP_ID = 2 THEN 'Refurbished'  WHEN CNDTN_ROLLUP_ID = 3 THEN 'Used' ELSE 'Not Specified' END AS item_Cond
-- 		,case when U.USER_DSGNTN_ID=2  then 'B2C' else 'C2C' end as bus_flag
-- 		,case when ck.BYR_CNTRY_ID = ck.SLR_CNTRY_ID then 'Domestic' else 'CBT' end as trade_flag
,	CASE WHEN UPPER(BRND.ASPCT_VLU_NM_BRAND) in ('MODIFIED', 'CUSTOMIZED','YES') THEN 'MODIFIED' ELSE 'NO' end AS MODIFIED_ITEM
,	avg(ck.ITEM_PRICE) as asp
,	SUM(ck.gmv_plan_usd) AS GMV
,	SUM(QUANTITY) AS BI
,	dense_rank() over (partition by price_bucket order by BI desc) as bi_rank
,	dense_rank() over (partition by price_bucket order by gmv desc) as gmv_rank

FROM DW_CHECKOUT_TRANS AS ck

LEFT JOIN ( select item_ID,CNDTN_ROLLUP_ID from ACCESS_VIEWS.LSTG_ITEM_CNDTN group by 1,2 ) AS CNDTN
        ON ck.ITEM_ID = CNDTN.ITEM_ID
LEFT JOIN 
                    (
                    SELECT ITEM_ID,
                           AUCT_END_DT,
                           COALESCE(MAX(ASPCT.ASPCT_VLU_NM),'UNKNOWN') AS ASPCT_VLU_NM_BRAND
                            FROM
                            ITEM_ASPCT_CLSSFCTN ASPCT
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
                        ITEM_ASPCT_CLSSFCTN_COLD ASPCT_COLD
                        WHERE UPPER(ASPCT_COLD.NS_TYPE_CD) IN ('NF','DF') 
                        AND ASPCT_COLD.AUCT_END_DT>='2018-12-26'
                        AND UPPER(ASPCT_COLD.PRDCT_ASPCT_NM) LIKE ('%MODIFIED ITEM%')
                        GROUP BY 1,2
                    ) BRND ON CK.ITEM_ID = BRND.ITEM_ID AND CK.AUCT_END_DT = BRND.AUCT_END_DT

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
					item_aspct_clssfctn
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
					item_aspct_clssfctn_cold
				WHERE
					AUCT_END_DT>='2016-06-01'
					AND lower(ns_type_cd) in (lower('nf'),lower('df' ) ) and upper(prdct_aspct_nm)= upper('BRAND')
				)SB
			Where 
			1=1
-- 			and lower(aspct_vlu_nm) like any ('%chanel%','%hermes%','%louis vuitton%','%mulberry%','%loewe%','%hermès%')
			GROUP BY 1,2) bbase ON ck.ITEM_ID = bbase.ITEM_ID AND ck.AUCT_END_dt = bbase.AUCT_END_DT

inner join (Select
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
					item_aspct_clssfctn
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
					item_aspct_clssfctn_cold
				WHERE
					AUCT_END_DT>='2016-06-01'
					AND lower(ns_type_cd) in (lower('nf'),lower('df' ) ) and upper(prdct_aspct_nm)= upper('MODEL')
				)SB1
			Where 1=1
			and aspct_vlu_nm is not null
			and lower(aspct_vlu_nm) <> 'unknown'
			GROUP BY 1,2) bbase1 ON ck.ITEM_ID = bbase1.ITEM_ID AND ck.AUCT_END_dt = bbase1.AUCT_END_DT

		
inner  JOIN ACCESS_VIEWS.SSA_CURNCY_PLAN_RATE_DIM LPR 
	ON ck.LSTG_CURNCY_ID = LPR.CURNCY_ID 
INNER JOIN ACCESS_VIEWS.DW_CAL_DT CAL 
	ON CAL.CAL_DT = ck.gmv_dt 
	and cal_dt >= '2022-04-01' and AGE_FOR_RTL_WEEK_ID <= -1 

-- left outer join dw_users u
-- 	on ck.seller_id = u.user_id
	
INNER JOIN DW_CATEGORY_GROUPINGS CAT 
	ON CAT.LEAF_CATEG_ID = ck.LEAF_CATEG_ID 
	AND CAT.SITE_ID = 3
	AND CAT.SAP_CATEGORY_ID NOT in (5,7,41,23,-999)   

WHERE 1=1
AND  ck.AUCT_end_dt >= '2018-01-01'                    
and  ((cat.CATEG_LVL3_ID IN (169291)) OR (cat.CATEG_LVL4_ID IN (52357,163570,169285,45258,2996,45237,169271)))
and ck.slr_CNTRY_ID in (3)

GROUP BY 1,2,3,4
)
where bi_rank <= 100 or gmv_rank <= 100
;



----------------------------------------------------------------------------------------------------------------------------------------

--------2) Price fluctuations for Chanel, Hermes, Louis Vuitton, Mulberry and Loewe (2022 and 2023) 

select
RETAIL_YEAR
,RETAIL_WEEK
,case when lower(brand) like '%chanel%' then 'Chanel'
	when lower(brand) like '%loewe%' then 'Loewe'
	when lower(brand) like '%louis vuitton%' then 'Louis Vuitton'
	when lower(brand) like any ('%hermes%','%hermès%') then 'Hermes'
	when lower(brand) like '%mulberry%' then 'Mulberry'
	else 'Other' End as brand_normalised
,CASE
		WHEN Cast(ck.ITEM_PRICE*lpr.CURNCY_PLAN_RATE AS DECIMAL(18,2))  < 500 THEN '<£435 ($500)'
		ELSE '>=£435 ($500)' END AS
	PRICE_BUCKET
-- 	CASE WHEN CNDTN_ROLLUP_ID = 1 THEN 'New' WHEN CNDTN_ROLLUP_ID = 2 THEN 'Refurbished'  WHEN CNDTN_ROLLUP_ID = 3 THEN 'Used' ELSE 'Not Specified' END AS item_Cond,
-- 		case when U.USER_DSGNTN_ID=2  then 'B2C' else 'C2C' end as bus_flag,
-- 		case when ck.BYR_CNTRY_ID = ck.SLR_CNTRY_ID then 'Domestic' else 'CBT' end as trade_flag,
,	CASE WHEN UPPER(BRND.ASPCT_VLU_NM_BRAND) in ('MODIFIED', 'CUSTOMIZED','YES') THEN 'MODIFIED' ELSE 'NO' end AS MODIFIED_ITEM
,	avg(ck.ITEM_PRICE) as asp
,	SUM(ck.gmv_plan_usd) AS GMV
,	SUM(QUANTITY) AS BI

FROM DW_CHECKOUT_TRANS AS ck

--  LEFT JOIN ( select item_ID,CNDTN_ROLLUP_ID from ACCESS_VIEWS.LSTG_ITEM_CNDTN group by 1,2 ) AS CNDTN
--         ON ck.ITEM_ID = CNDTN.ITEM_ID
LEFT JOIN 
                    (
                    SELECT ITEM_ID,
                           AUCT_END_DT,
                           COALESCE(MAX(ASPCT.ASPCT_VLU_NM),'UNKNOWN') AS ASPCT_VLU_NM_BRAND
                            FROM
                            ITEM_ASPCT_CLSSFCTN ASPCT
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
                        ITEM_ASPCT_CLSSFCTN_COLD ASPCT_COLD
                        WHERE UPPER(ASPCT_COLD.NS_TYPE_CD) IN ('NF','DF') 
                        AND ASPCT_COLD.AUCT_END_DT>='2018-12-26'
                        AND UPPER(ASPCT_COLD.PRDCT_ASPCT_NM) LIKE ('%MODIFIED ITEM%')
                        GROUP BY 1,2
                    ) BRND ON CK.ITEM_ID = BRND.ITEM_ID AND CK.AUCT_END_DT = BRND.AUCT_END_DT

inner join (Select
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
					item_aspct_clssfctn
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
					item_aspct_clssfctn_cold
				WHERE
					AUCT_END_DT>='2016-06-01'
					AND lower(ns_type_cd) in (lower('nf'),lower('df' ) ) and upper(prdct_aspct_nm)= upper('BRAND')
				)SB
			Where 
			1=1
			and lower(aspct_vlu_nm) like any ('%chanel%','%hermes%','%louis vuitton%','%mulberry%','%loewe%','%hermès%')
			GROUP BY 1,2) bbase ON ck.ITEM_ID = bbase.ITEM_ID AND ck.AUCT_END_dt = bbase.AUCT_END_DT

-- left join (Select
-- 				item_id,
-- 				Auct_end_dt,
-- 				coalesce(max(case  when lower(aspect)=lower('MODEL') then aspct_vlu_nm else NULL end ),'Unknown') as MODEL
-- 			FROM
-- 				(select
-- 					item_id,
-- 					auct_end_dt,
-- 					ns_type_cd,
-- 					1 as priority,
-- 					'MODEL' as aspect,
-- 					cast(trim(lower(aspct_vlu_nm)) as VARCHAR(350)) as aspct_vlu_nm 
-- 				from
-- 					item_aspct_clssfctn
-- 				where
-- 					AUCT_END_DT>='2016-06-01'
-- 					AND lower(ns_type_cd) in (lower('nf'),lower('df' ) ) and upper(prdct_aspct_nm)= upper('MODEL')
-- 				UNION ALL
-- 				select
-- 					item_id,
-- 					auct_end_dt,
-- 					ns_type_cd,
-- 					2 as priority,
-- 					'MODEL' as aspect,
-- 					cast(trim(lower(aspct_vlu_nm)) as VARCHAR(350)) as aspct_vlu_nm
-- 				from
-- 					item_aspct_clssfctn_cold
-- 				WHERE
-- 					AUCT_END_DT>='2016-06-01'
-- 					AND lower(ns_type_cd) in (lower('nf'),lower('df' ) ) and upper(prdct_aspct_nm)= upper('MODEL')
-- 				)SB1
-- 			GROUP BY 1,2) bbase1 ON ck.ITEM_ID = bbase1.ITEM_ID AND ck.AUCT_END_dt = bbase1.AUCT_END_DT

		
inner  JOIN ACCESS_VIEWS.SSA_CURNCY_PLAN_RATE_DIM LPR 
	ON ck.LSTG_CURNCY_ID = LPR.CURNCY_ID 
INNER JOIN ACCESS_VIEWS.DW_CAL_DT CAL 
	ON CAL.CAL_DT = ck.gmv_dt 
	and cal.cal_dt >= '2022-04-01' and AGE_FOR_RTL_WEEK_ID <= -1 

left outer join dw_users u
	on ck.seller_id = u.user_id
	
INNER JOIN DW_CATEGORY_GROUPINGS CAT 
	ON CAT.LEAF_CATEG_ID = ck.LEAF_CATEG_ID 
	AND CAT.SITE_ID = 3
	AND CAT.SAP_CATEGORY_ID NOT in (5,7,41,23,-999)   

WHERE 1=1
AND  ck.AUCT_end_dt >= '2018-01-01'                    
and  ((cat.CATEG_LVL3_ID IN (169291)) OR (cat.CATEG_LVL4_ID IN (52357,163570,169285,45258,2996,45237,169271)))
and ck.slr_CNTRY_ID in (3)

GROUP BY 1,2,3,4,5

;


----------------------------------------------------------------------------------------------------------------------------------------

--------3) Search fluctuations for Chanel, Hermes, Louis Vuitton, Mulberry and Loewe (2022 and 2023). PR have asked for any insights throughout the year that would be interesting to include, so trying to link points 2 and 3 with key events that happened for the brands.

select    
cal.RETAIL_YEAR
,cal.RETAIL_WEEK
,case when lower(brand) like '%chanel%' then 'Chanel'
	when lower(brand) like '%loewe%' then 'Loewe'
	when lower(brand) like '%louis vuitton%' then 'Louis Vuitton'
	when lower(brand) like any ('%hermes%','%hermès%') then 'Hermes'
	when lower(brand) like '%mulberry%' then 'Mulberry'
	else 'Other' End as brand_normalised
,count(*) as src_cnt 

from  access_views.SRCH_KEYWORDS_EXT_FACT src    
inner join DW_CAL_DT cal
	on src.SESSION_START_DT = cal.CAL_DT
	and cal.retail_year in (2022,2023)
	and cal.AGE_FOR_RTL_WEEK_ID <= -1
inner join
	(
	select lstg.item_id
	,lstg.DF_BRAND_TXT as brand
	
	from PRS_RESTRICTED_V.SLNG_LSTG_SUPER_FACT lstg
	INNER JOIN DW_CAL_DT CAL
		ON lstg.AUCT_START_DT <= cal.CAL_DT
		and lstg.AUCT_END_DT >= cal.CAL_DT
		and cal.retail_year in (2022,2023)
		and cal.AGE_FOR_RTL_WEEK_ID <= -1
	INNER JOIN DW_CATEGORY_GROUPINGS CAT 
		ON CAT.LEAF_CATEG_ID = lstg.LEAF_CATEG_ID 
		AND CAT.SITE_ID = 3
		AND CAT.SAP_CATEGORY_ID NOT in (5,7,41,23,-999)
			
	Where 1=1
	and lstg.ITEM_SITE_ID = 3
	and (cat.CATEG_LVL3_ID = 169291 OR cat.CATEG_LVL4_ID IN (52357,163570,169285,45258,2996,45237,169271))
	
	Group by 1,2
	) LST
		on src.FIRST_ITEM_ID = lst.item_id--Assume the first item appears is the most relevant to the search input


where src.site_id = 3 

group by 1,2,3







----------------------------------------------------------------------------------------------------------------------------------------

--------4) Increase in secondhand bag searches since April 2022 (launch of handbags AG)


select    
cal.RETAIL_YEAR
,cal.RETAIL_WEEK
,PRICE_BUCKET
,count(*) as src_cnt 

from  access_views.SRCH_KEYWORDS_EXT_FACT src    
inner join DW_CAL_DT cal
	on src.SESSION_START_DT = cal.CAL_DT
	and cal.retail_year in (2022,2023)
	and cal.AGE_FOR_RTL_WEEK_ID <= -1
inner join
	(
	select lstg.item_id
	,case when lstg.START_PRICE_LSTG_CURNCY_AMT*lpr.CURNCY_PLAN_RATE < 500 THEN '<£435 ($500)'
		ELSE '>=£435 ($500)' END AS
	PRICE_BUCKET
	
	from PRS_RESTRICTED_V.SLNG_LSTG_SUPER_FACT lstg
	INNER JOIN DW_CAL_DT CAL
		ON lstg.AUCT_START_DT <= cal.CAL_DT
		and lstg.AUCT_END_DT >= cal.CAL_DT
		and cal.retail_year in (2022,2023)
		and cal.AGE_FOR_RTL_WEEK_ID <= -1
	INNER JOIN DW_CATEGORY_GROUPINGS CAT 
		ON CAT.LEAF_CATEG_ID = lstg.LEAF_CATEG_ID 
		AND CAT.SITE_ID = 3
		AND CAT.SAP_CATEGORY_ID NOT in (5,7,41,23,-999)
	inner  JOIN ACCESS_VIEWS.SSA_CURNCY_PLAN_RATE_DIM LPR 
		ON lstg.LSTG_CURNCY_ID = LPR.CURNCY_ID 
	
	Where 1=1
	and lstg.ITEM_SITE_ID = 3
	and (cat.CATEG_LVL3_ID = 169291 OR cat.CATEG_LVL4_ID IN (52357,163570,169285,45258,2996,45237,169271))
	
	Group by 1,2
	) LST
		on src.FIRST_ITEM_ID = lst.item_id--Assume the first item appears is the most relevant to the search input


where src.site_id = 3 
and lower(src.KEYWORD) like any ('used%','%secondhand%','%second hand%','%preloved%','%preowned%','%pre owned%','%refurb%','% used%')

group by 1,2,3