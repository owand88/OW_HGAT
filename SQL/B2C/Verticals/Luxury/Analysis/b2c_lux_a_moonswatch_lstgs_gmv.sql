
------------------------------------------------------------------Moonswatch Transactions----------------------------------------------------------------


select 
ITEM_ID,
AUCT_TITL,
checkout_status,
BUSINESS,
CBT,
SUM(GMV) AS GMV,
SUM(SI) AS QUANTITY

from 
	(SELECT 
	ck.ITEM_ID,
	lstg.AUCT_TITL,
	case when ck.CHECKOUT_STATUS = 0 then 'Not Started'
		ck.CHECKOUT_STATUS = 1 then 'Incomplete'
		ck.CHECKOUT_STATUS = 2 then 'Complete'
		ck.CHECKOUT_STATUS = 3 then 'Disabled'
		else 'Other'
		End as checkout_status,
	CASE WHEN HIST.USEGM_ID = 206 THEN 'B2C' ELSE 'C2C' END AS BUSINESS,
	CASE WHEN CN.REV_ROLLUP <> CN2.REV_ROLLUP THEN 'CBT' ELSE 'DOM' END CBT,
	SUM(CK.ITEM_PRICE*CK.QUANTITY*CR.CURNCY_PLAN_RATE) AS GMV,
	SUM(CK.QUANTITY) AS SI
	
	FROM ACCESS_VIEWS.DW_CK_TRANS_FREQ ck
	INNER JOIN ACCESS_VIEWS.DW_CATEGORY_GROUPINGS CAT ON CK.LEAF_CATEG_ID = CAT.LEAF_CATEG_ID AND CK.SITE_ID = CAT.SITE_ID	AND cat.SAP_CATEGORY_ID NOT IN (5,7,23,41,-999) 	
	INNER JOIN ACCESS_VIEWS.SSA_CURNCY_PLAN_RATE_DIM CR ON CR.CURNCY_ID = CK.LSTG_CURNCY_ID	
	INNER JOIN ACCESS_VIEWS.DW_COUNTRIES CN ON CN.CNTRY_ID = CK.SLR_CNTRY_ID AND CN.REV_ROLLUP IN ('UK')
	INNER JOIN ACCESS_VIEWS.DW_COUNTRIES CN2 ON CN2.CNTRY_ID = CK.BYR_CNTRY_ID
	LEFT JOIN ACCESS_VIEWS.DW_USEGM_HIST HIST ON HIST.USER_ID = CK.SELLER_ID AND HIST.USEGM_GRP_ID = 48 AND CK.CREATED_DT BETWEEN HIST.BEG_DATE AND HIST.END_DATE 
	inner JOIN
		(select lstg.item_id, lstg.AUCT_TITL, lstg.auct_end_dt
		from ACCESS_VIEWS.DW_LSTG_ITEM lstg
		INNER JOIN ACCESS_VIEWS.DW_CATEGORY_GROUPINGS CAT ON lstg.LEAF_CATEG_ID = CAT.LEAF_CATEG_ID AND lstg.ITEM_SITE_ID = CAT.SITE_ID	AND cat.SAP_CATEGORY_ID NOT IN (5,7,23,41,-999) 	
		Where auct_start_dt >= '2023-03-07'
		and cat.CATEG_LVL2_ID = 260324
		and lower(lstg.AUCT_TITL) like ('%moon%')
		Group by 1,2,3
		)	lstg 
			on ck.ITEM_ID = lstg.item_id
			and ck.AUCT_END_DT = lstg.auct_end_dt
	WHERE	CK.SALE_TYPE NOT IN  (10,15) 				
	AND CK.CK_WACKO_YN='N'		
	AND ck.auct_end_DT >= '2023-03-07'
	AND ck.created_dt >= '2023-03-07'
	and cat.CATEG_LVL2_ID = 260324
	GROUP BY 1,2,3,4,5,6
	)z

GROUP BY 1,2,3,4,5
;




------------------------------------------------------------------Moonswatch Listings----------------------------------------------------------------

select 
cal.cal_dt
,case when lower(brand) = 'swatch' then 'Swatch'
	when lower(brand) = 'omega' then 'Omega'
	else 'Other' end as brand
,lstg.item_id
,lstg.auct_titl
,lstg.slr_id


From DW_LSTG_ITEM_FREQ lstg
INNER JOIN ACCESS_VIEWS.DW_CATEGORY_GROUPINGS CAT
	ON lstg.LEAF_CATEG_ID = CAT.LEAF_CATEG_ID
	AND lstg.ITEM_SITE_ID = CAT.SITE_ID
	AND cat.SAP_CATEGORY_ID NOT IN (5,7,23,41,-999)
INNER JOIN DW_CAL_DT cal
	on lstg.auct_start_dt <= cal.cal_dt
	and lstg.auct_end_dt >= cal.CAL_DT
	and cal.cal_dt >= '2023-02-28'
	and cal.cal_dt <= '2023-03-09'
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
				cast(trim(lower(aspct_vlu_nm)) as VARCHAR(350)) as aspct_vlu_nm, 
				(Row_Number() Over (PARTITION BY item_id,auct_end_dt,aspect ORDER BY priority,aspct_vlu_nm DESC)) AS dup_check
			from
				item_aspct_clssfctn
			where
				AUCT_END_DT>='2023-02-01'
				AND lower(ns_type_cd) in (lower('nf'),lower('df' ) ) and upper(prdct_aspct_nm)= upper('BRAND')
			)SB
		Where dup_check = 1
		GROUP BY 1,2) brand ON lstg.ITEM_ID = brand.ITEM_ID AND lstg.AUCT_END_dt = brand.AUCT_END_DT

Where 1=1
and cat.CATEG_LVL2_ID = 260324
and lstg.slr_cntry_id = 3
and lstg.item_site_id = 3
and lower(lstg.auct_titl) like any ('%moonswatch%','%moon swatch%')
-- and lower(brand) like any ('%swatch%','%omega%')

group by 1,2,3,4,5
;



------------------------------------------------------------------Moonswatch Searches----------------------------------------------------------------




select    
src.SESSION_START_DT
,case when lower(brand) like ('%swatch%') then 'Swatch'
	when lower(brand) like ('%omega%') then 'Omega'
	Else 'Other' End as brand
,case when lower(src.query) like ('%moon%') then 'Yes' else '-' end as possible_moon_lstg 
,count(*) as src_cnt 

from  access_views.srch_cnvrsn_event_fact src       
inner join
	(
	select lstg.item_id
	,brand
	
	from DW_LSTG_ITEM lstg
	INNER JOIN DW_CAL_DT CAL
		ON lstg.AUCT_START_DT <= cal.CAL_DT
		and lstg.AUCT_END_DT >= cal.CAL_DT
		AND cal.CAL_DT >= '2023-02-28'
		and cal.cal_dt <= '2023-03-09'
	INNER JOIN DW_CATEGORY_GROUPINGS CAT 
		ON CAT.LEAF_CATEG_ID = lstg.LEAF_CATEG_ID 
		AND CAT.SITE_ID = 3
		AND CAT.SAP_CATEGORY_ID NOT in (5,7,41,23,-999) 
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
					item_aspct_clssfctn
				where
					AUCT_END_DT>='2023-03-07'
					AND lower(ns_type_cd) in (lower('nf'),lower('df' ) ) and upper(prdct_aspct_nm)= upper('BRAND')
				)SB
			Where dup_check = 1
-- 			and lower(aspct_vlu_nm) in ('omega','swatch','omega x swatch','swatch x omega','omegaxswatch','swatchxomega','omega and swatch','swatch and omega')
			GROUP BY 1) brand
				on lstg.item_id = brand.item_id
	Where 1=1
	and lstg.ITEM_SITE_ID = 3
	and lstg.auct_titl like any ('%moonswatch%','%moon swatch%')
	and cat.CATEG_LVL2_ID = 260324
	
	Group by 1,2
	) LST
		on substring(src.items,1,instr(src.items,',')-1) = lst.item_id--Assume the first item appears is the most relevant to the search input


where src.site_id = 3 
and (src.SESSION_START_DT >= '2023-02-28' and src.SESSION_START_DT <= '2023-03-09')

group by 1,2,3

