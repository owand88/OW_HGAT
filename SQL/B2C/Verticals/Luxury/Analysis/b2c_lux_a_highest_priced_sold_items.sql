
select 
ck.*
,lstg.AUCT_TITLE

From
	(Select 
	cal.retail_year
	, ck.item_id
	, ck.AUCT_END_DT
	, ck.ITEM_PRICE
	, case when (cat.CATEG_LVL2_ID = 260324) then 'Watches'
	when (cat.CATEG_LVL3_ID = 169291) OR (cat.CATEG_LVL4_ID IN (52357,163570,169285,45258,2996,45237,169271)) then 'Handbags'
	Else 'Other'
	End as category
	,dense_rank() over (partition by retail_year, category order by ck.item_price desc) as price_rank
	
	From DW_CHECKOUT_TRANS ck
	INNER JOIN ACCESS_VIEWS.DW_CATEGORY_GROUPINGS CAT 
		ON CAT.LEAF_CATEG_ID = ck.LEAF_CATEG_ID 
		AND CAT.SITE_ID = 3
		AND CAT.SAP_CATEGORY_ID NOT in (5,7,41,23,-999) 
	INNER JOIN DW_CAL_DT cal
		on ck.gmv_dt = cal.CAL_DT
		and cal.RETAIL_YEAR in (2021,2022)
	Where 1=1
	and ck.SLR_CNTRY_ID= 3
	and ((cat.CATEG_LVL2_ID = 260324) or (cat.CATEG_LVL3_ID = 169291) OR (cat.CATEG_LVL4_ID IN (52357,163570,169285,45258,2996,45237,169271)))
	Group by 1,2,3,4,5) ck
LEFT JOIN
	(Select lstg.item_id, lstg.auct_end_dt, lstg.AUCT_TITLE
	From PRS_RESTRICTED_V.SLNG_LSTG_SUPER_FACT lstg
	Where AUCT_END_DT >= '2020-12-20'
	Group by 1,2,3) LSTG 
		on ck.item_id = lstg.item_id
		and ck.AUCT_END_DT = lstg.auct_end_dt

Where price_rank <= 20

	
	