-- Author: 			Robbie Evans
-- Stakeholder: 	James Prentice
-- Purpose: 		Show Q1 YoY performance for specified seller broken down by brand to L4 level
-- Date Created: 	06/04/2023


select					
lstg.retail_year					
,lstg.RTL_QTR_OF_RTL_YEAR_ID					
,lstg.CATEG_LVL2_NAME					
,lstg.CATEG_LVL3_NAME					
,lstg.CATEG_LVL4_NAME					
,lstg.brand					
,lstg.seller_name					
,lstg.listings					
,lstg.stock					
,ck.BI					
,ck.GMV					
,ck.buyers					
					
FROM 					
	(SELECT				
	cal.retail_year				
	,cal.RTL_QTR_OF_RTL_YEAR_ID				
	,cat.CATEG_LVL2_NAME				
	,cat.CATEG_LVL3_NAME				
	,cat.CATEG_LVL4_NAME				
	,brand.brand				
	,u.user_slctd_id as seller_name				
	,count(distinct lstg.ITEM_ID) as listings				
	,max(lstg.QTY_AVAIL) as stock				
					
	FROM DW_LSTG_ITEM lstg				
	INNER JOIN DW_CAL_DT cal				
		on lstg.AUCT_START_DT <= cal.CAL_DT			
		and lstg.AUCT_END_DT >= cal.CAL_DT			
		and cal.retail_year in (2022,2023)			
		and cal.RTL_QTR_OF_RTL_YEAR_ID = 1			
	INNER JOIN ACCESS_VIEWS.DW_CATEGORY_GROUPINGS CAT				
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
					AUCT_END_DT>='2020-12-07'
					AND lower(ns_type_cd) in (lower('nf'),lower('df' ) ) and upper(prdct_aspct_nm)= upper('BRAND')
				)SB	
			Where dup_check = 1		
			GROUP BY 1) brand		
				on lstg.item_id = brand.item_id	
	left join DW_USERS u				
		on lstg.SLR_ID = u .user_id			
					
	Where 1=1				
	and lstg.SLR_ID = 355090148				
					
	GRoup by 1,2,3,4,5,6,7				
	) lstg 				
					
LEFT JOIN 					
	(select 				
	cal.retail_year				
	,cal.RTL_QTR_OF_RTL_YEAR_ID				
	,cat.CATEG_LVL2_NAME				
	,cat.CATEG_LVL3_NAME				
	,cat.CATEG_LVL4_NAME				
	,brand.brand				
	,u.user_slctd_id as seller_name				
	,sum(ck.QUANTITY) as BI				
	,sum(ck.gmv_plan_usd) as GMV				
	,count(distinct ck.BUYER_ID) as buyers				
					
	FROM DW_CHECKOUT_TRANS ck				
	INNER JOIN DW_CAL_DT cal				
		on ck.gmv_dt = cal.CAL_DT			
		and cal.retail_year in (2022,2023)			
		and cal.RTL_QTR_OF_RTL_YEAR_ID = 1			
	INNER JOIN ACCESS_VIEWS.DW_CATEGORY_GROUPINGS CAT				
		ON CAT.LEAF_CATEG_ID = ck.LEAF_CATEG_ID 			
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
					AUCT_END_DT>='2020-12-07'
					AND lower(ns_type_cd) in (lower('nf'),lower('df' ) ) and upper(prdct_aspct_nm)= upper('BRAND')
				)SB	
			Where dup_check = 1		
			GROUP BY 1) brand		
				on ck.item_id = brand.item_id	
		left join DW_USERS u			
			on ck.SELLER_ID = u .user_id		
					
		Where 1=1			
		and ck.SELLER_ID = 355090148			
					
		GRoup by 1,2,3,4,5,6,7			
		) ck 			
			on lstg.retail_year = ck.retail_year		
			and lstg.RTL_QTR_OF_RTL_YEAR_ID = ck.RTL_QTR_OF_RTL_YEAR_ID		
			and lstg.CATEG_LVL2_NAME = ck.CATEG_LVL2_NAME		
			and lstg.CATEG_LVL3_NAME = ck.CATEG_LVL3_NAME		
			and lstg.CATEG_LVL4_NAME = ck.CATEG_LVL4_NAME		
			and lstg.brand = ck.brand		
			and lstg.seller_name = ck.seller_name		
