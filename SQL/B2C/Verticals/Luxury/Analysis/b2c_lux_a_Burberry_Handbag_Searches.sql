-- Author: 			Robbie Evans
-- Stakeholder: 	Emma Hamilton
-- Purpose: 		A high-value Burberry handbag was mentioned in the series Succession and since gained traction online. There was a request to see if this has resulted in an uptick in searches for this on eBay UK
-- Date Created: 	31/03/2023



select    
src.SESSION_START_DT
,case when lower(src.keyword) like ('%tote%') then 'Yes' else '-' end as tote_search 
,count(*) as src_cnt 

from  access_views.SRCH_KEYWORDS_EXT_FACT src       
inner join
	(
	select lstg.item_id
	,brand
	
	from DW_LSTG_ITEM lstg
	INNER JOIN DW_CAL_DT CAL
		ON lstg.AUCT_START_DT <= cal.CAL_DT
		and lstg.AUCT_END_DT >= cal.CAL_DT
		AND cal.CAL_DT >= '2023-03-01'
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
					cast(trim(lower(aspct_vlu_nm)) as VARCHAR(350)) as aspct_vlu_nm
				from
					item_aspct_clssfctn
				where
					1=1
					AND AUCT_END_DT>='2023-03-01'
					AND lower(ns_type_cd) in (lower('nf'),lower('df' ) ) and upper(prdct_aspct_nm)= upper('BRAND')
					
					qualify (Row_Number() Over (PARTITION BY item_id,auct_end_dt,aspect ORDER BY priority,aspct_vlu_nm DESC)) = 1
				)SB
			GROUP BY 1) brand
				on lstg.item_id = brand.item_id
	Where 1=1
	and lstg.ITEM_SITE_ID = 3
	and lower(brand) like ('%burberry%')
	and (cat.CATEG_LVL3_ID = 169291 OR cat.CATEG_LVL4_ID IN (52357,163570,169285,45258,2996,45237,169271))
	
	Group by 1,2
	) LST
		on src.FIRST_ITEM_ID = lst.item_id--Assume the first item appears is the most relevant to the search input


where src.site_id = 3 
and (src.SESSION_START_DT >= '2023-03-01')

group by 1,2



