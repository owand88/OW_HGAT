Select a.*,b.GMV,b.sold_items
From
(Select
ck.slr_id,
case when u.comp is null then u.user_slctd_id else u.comp End as company_name,
	case when U.USER_DSGNTN_ID=2  then 'B2C' else 'C2C' end as bus_flag,
  case when UPPER(BRND.ASPCT_VLU_NM_BRAND) in ('MODIFIED', 'CUSTOMIZED','YES') then 'Modified' else 'Unmodified' End as modified,
	count(distinct ck.item_id) as LL

FROM DW_LSTG_ITEM AS ck
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

INNER JOIN DW_COUNTRIES CN ON CN.CNTRY_ID = ck.SLR_CNTRY_ID
INNER JOIN ACCESS_VIEWS.GLBL_RPRT_GEO_DIM GEO ON CN.REV_ROLLUP_ID = GEO.REV_ROLLUP_ID 
INNER JOIN DW_CAL_DT CAL
	ON ck.AUCT_START_DT < CAL.CAL_DT
	AND ck.AUCT_END_DT >= CAL.CAL_DT
	AND AGE_FOR_RTL_WEEK_ID >= -52 and AGE_FOR_RTL_WEEK_ID <= -1
inner join dw_users u
	on ck.slr_id = u.user_id
	and U.USER_DSGNTN_ID=2

INNER JOIN DW_CATEGORY_GROUPINGS CAT 
	ON CAT.LEAF_CATEG_ID = ck.LEAF_CATEG_ID 
	AND CAT.SITE_ID = 3
	AND CAT.SAP_CATEGORY_ID NOT in (5,7,41,23,-999) 
inner  JOIN ACCESS_VIEWS.SSA_CURNCY_PLAN_RATE_DIM LPR 
		ON ck.LSTG_CURNCY_ID = LPR.CURNCY_ID 

WHERE 1=1
AND  ck.AUCT_end_dt >= '2018-01-01'
and ck.wacko_YN = 'N'                      
AND ck.AUCT_TYPE_CODE NOT in (10,15)
and cat.META_CATEG_ID = 281
and cat.CATEG_LVL2_ID NOT IN (260324)
and ck.slr_CNTRY_ID = 3
and (case when ck.START_PRICE_LSTG_CURNCY > ck.RSRV_PRICE_LIST_CRNCY then ck.START_PRICE_LSTG_CURNCY else ck.RSRV_PRICE_LIST_CRNCY End) >= 500
GROUP BY 1,2,3,4
) a

LEFT JOIN

(
select
	ck.seller_id,
  case when u.comp is null then u.user_slctd_id else u.comp End as company_name,
		case when U.USER_DSGNTN_ID=2  then 'B2C' else 'C2C' end as bus_flag,
    case when UPPER(BRND.ASPCT_VLU_NM_BRAND) in ('MODIFIED', 'CUSTOMIZED','YES') then 'Modified' else 'Unmodified' End as modified,
	SUM(ck.gmv_plan_usd) AS GMV,
	sum(ck.QUANTITY) as sold_items
	
FROM DW_CHECKOUT_TRANS AS ck
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

inner  JOIN ACCESS_VIEWS.SSA_CURNCY_PLAN_RATE_DIM LPR 
	ON ck.LSTG_CURNCY_ID = LPR.CURNCY_ID 
INNER JOIN ACCESS_VIEWS.DW_CAL_DT CAL 
	ON CAL.CAL_DT = ck.gmv_dt 
	AND AGE_FOR_RTL_WEEK_ID >= -52 and AGE_FOR_RTL_WEEK_ID <= -1

inner join dw_users u
	on ck.seller_id = u.user_id
	and U.USER_DSGNTN_ID=2
	
INNER JOIN DW_CATEGORY_GROUPINGS CAT 
	ON CAT.LEAF_CATEG_ID = ck.LEAF_CATEG_ID 
	AND CAT.SITE_ID = 3
	AND CAT.SAP_CATEGORY_ID NOT in (5,7,41,23,-999)   

WHERE 1=1
AND ck.AUCT_end_dt >= '2018-01-01'                    
and cat.META_CATEG_ID = 281
and cat.CATEG_LVL2_ID NOT IN (260324)
and ck.slr_CNTRY_ID = 3
and ck.byr_cntry_id = 3
and ck.ITEM_PRICE >= 500
		GROUP BY 1,2,3,4
) b
	on a.slr_id = b.seller_id
	and a.bus_flag = b.bus_flag
  and a.modified = b.modified
	
Where 1=1
and modified = 'Unmodified'