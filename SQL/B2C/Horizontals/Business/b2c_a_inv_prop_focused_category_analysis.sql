Select
	case when cat.categ_lvl2_id in (20710, 69197, 185066) then 'Electronics' 
      when cat.meta_categ_id in (26395) then 'Lifestyle'
      when cat.categ_lvl3_id in (260325) then 'Lifestyle'
      when cat.categ_lvl2_id in (386, 238, 1202, 2624, 61573) then 'Home & Garden'
      when cat.categ_lvl3_id in (35000, 98989) then 'Home & Garden'
      when cat.categ_lvl3_id in (3244) then 'Parts & Accessories'
      when cat.categ_lvl3_id in (124982, 259225,180969, 260509) then 'Business & Industrial'
      when cat.categ_lvl2_id in (46576) then 'Parts & Accessories'
      when cat.categ_lvl2_id in (63, 29223) then 'Collectibles'
      else cat.bsns_vrtcl_name end as new_vertical
	,case when ck.ITEM_ID = inv.item_id then 'Inv Prop' else 'Non-Inv Prop' End as inv_prop_flag
	,sum(case when ck.ITEM_ID = fv.LSTG_ID and ck.BYR_CNTRY_ID = ck.SLR_CNTRY_ID and ck.B2C_C2C = 'B2C' then ck.GMV20_PLAN End) as fc_b2c_dom_gmv
	,sum(case when ck.ITEM_ID = fv.LSTG_ID then ck.GMV20_PLAN End) as fc_gmv
	,sum(case when ck.BYR_CNTRY_ID = ck.SLR_CNTRY_ID and ck.B2C_C2C = 'B2C' then ck.GMV20_PLAN End) as total_b2c_dom_gmv
	,sum(ck.GMV20_PLAN) as total_gmv

	From PRS_RESTRICTED_V.SLNG_TRANS_SUPER_FACT ck
	INNER JOIN DW_CAL_DT CAL
		ON ck.GMV_DT = cal.CAL_DT
		AND RETAIL_YEAR = 2023
		and AGE_FOR_RTL_WEEK_ID <= -1 
	INNER JOIN DW_CATEGORY_GROUPINGS CAT 
		ON CAT.LEAF_CATEG_ID = ck.LEAF_CATEG_ID 
		AND CAT.SITE_ID = 3
		AND CAT.SAP_CATEGORY_ID NOT in (5,7,41,23,-999) 
	LEFT JOIN (select ITEM_ID from P_awang_ops_t.item_invent_lstg where inventory_prop <> 'OTHERS' group by 1) INV
		ON ck.ITEM_ID = INV.ITEM_ID
	LEFT JOIN
		(select LSTG_ID, FOCUSED_VERTICAL_LVL1
		From FOCUSED_VERT_TXN
		Where gmv_dt >= '2022-12-20'
		Group by 1,2) fv
			on ck.item_id = fv.LSTG_ID

	Where 1=1
	and ck.SLR_CNTRY_ID = 3
	and ck.RPRTD_WACKO_YN = 'N'
	
	Group by 1,2