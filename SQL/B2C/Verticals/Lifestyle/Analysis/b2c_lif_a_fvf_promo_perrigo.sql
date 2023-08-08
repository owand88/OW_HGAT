-- JIRA Ticket:     UKPLAN-489

-- Author: 			Robbie Evans
-- Stakeholder: 	Alice Winter
-- Purpose: 		Will aid in decision on whether to extend FVF promo for Perrigo on selected lines or not
-- Date Created: 	08/08/2023



---------------------------------------------------------------------------------------------------
------------------------------------------- GMV ---------------------------------------------------
---------------------------------------------------------------------------------------------------

with sku_list AS
	(
	SELECT item_id
	FROM DW_LSTG_ITEM
	Where ITEM_ID in (
					363880355821,
					134164459787,
					363939900706,
					363939909644,
					134152131491,
					144612766445,
					363880355153,
					144612758578,
					363880355164,
					363939931513,
					363880361049,
					144612766501,
					144612765726,
					134152131464,
					363939961996,
					363880360247,
					134152135076,
					5012616262241,
					5012616262203,
					5012616264290,
					144612768045,
					5012616262227,
					5012616264283,
					5012616262234,
					134152134273,
					134152128111,
					5012616174407,
					134164459804,
					144676488284,
					144612765069,
					363880359072,
					134152130690,
					363880359070,
					134444836367,
					134152131470,
					134152130693,
					144635039381,
					134152135038,
					144635040248,
					363896938732,
					363940072734,
					134164462110,
					134152131445,
					144612765753,
					363940112532,
					363940075831,
					363880360261,
					134152131476,
					134152131472,
					144676576326,
					144612758558,
					144612758551,
					5012616266003,
					363941102564,
					144677401635,
					134196419275,
					363941132692,
					144635039359,
					144635039359,
					144677486907,
					134164459773,
					144612760341,
					134164459800,
					134164459819,
					363880355836,
					363880355131,
					144612760375,
					363880355841,
					363880360257,
					144612765780,
					134152128115,
					134152128106,
					363880360254,
					363880355813,
					363880355087,
					144677449792,
					134152131483,
					134152128958,
					134152128933,
					134152128920,
					363880367147,
					134152130680,
					134196514156,
					363941212329,
					363941211751,
					144677510309,
					144635039347,
					144612768746,
					144612768770,
					363880370941,
					363880370999,
					363880370970,
					144635039373,
					363880359137,
					144938924545,
					134164462093,
					134152134580,
					144635039364,
					134164459846,
					134152131448,
					363880359111,
					134152133255,
					134152131451,
					134152131447
					)
		Group by 1
	)
	
Select 
	case when cal_dt between '2022-02-13' and '2022-08-06' then 'Same time last year'
		when cal_dt between '2022-08-13' and '2023-02-06' then 'prior 6 months'
		when cal_dt between '2023-02-13' and '2023-08-06' then 'Latest 6 months'
		else 'Other'
		End as time_frame
	,ck.ITEM_ID
	,lstg.AUCT_TITLE
	,sum(ck.GMV20_PLAN) as gmv
	,sum(ck.GMV20_SOLD_QUANTITY) as si
	,avg(ck.ITEM_PRICE) as asp
	,0 as vi
	,0 as imp
	
FROM PRS_RESTRICTED_V.SLNG_TRANS_SUPER_FACT ck
INNER JOIN DW_CAL_DT cal
	on ck.gmv_dt = cal.CAL_DT
	and cal.CAL_DT between '2022-02-13' and '2023-08-06'
INNER JOIN sku_list
	on sku_list.item_id = ck.item_id
LEFT JOIN
	(
	select lstg.ITEM_ID
		,lstg.auct_title
	FROM PRS_RESTRICTED_V.SLNG_LSTG_SUPER_FACT lstg
	INNER JOIN sku_list
		on sku_list.item_id = lstg.item_id
	Group by 1,2
	) lstg
		on ck.ITEM_ID = lstg.ITEM_ID
WHERE 1=1
	and ck.BYR_CNTRY_ID = 3
	and ck.SITE_ID = 3
	
GROUP BY 1,2,3
	
	
	
UNION ALL



Select 
	case when cal_dt between '2022-02-13' and '2022-08-06' then 'Same time last year'
		when cal_dt between '2022-08-13' and '2023-02-06' then 'prior 6 months'
		when cal_dt between '2023-02-13' and '2023-08-06' then 'Latest 6 months'
		else 'Other'
		End as time_frame
	,trfc.ITEM_ID
	,lstg.auct_title
	,0 as gmv
	,0 as si
	,0 as asp
	,sum(trfc.TTL_VI_CNT) as VI
	,sum(trfc.SRP_IMPRSN_CNT)+sum(trfc.STORE_IMPRSN_CNT) as IMP
	
FROM PRS_RESTRICTED_V.SLNG_TRFC_SUPER_FACT trfc
INNER JOIN sku_list
	on trfc.ITEM_ID = sku_list.item_id
LEFT JOIN
	(
	select lstg.ITEM_ID
		,lstg.auct_title
	FROM PRS_RESTRICTED_V.SLNG_LSTG_SUPER_FACT lstg
	INNER JOIN sku_list
		on sku_list.item_id = lstg.item_id
	Group by 1,2
	) lstg
		on trfc.ITEM_ID = lstg.ITEM_ID

WHERE 1=1
	and CAL_DT between '2022-02-13' and '2023-08-06'
	and trfc.SITE_ID = 3

GROUP BY 1,2,3


















---------------------------------------------------------------------------------------------------
--------------------------------- Revenue & GMV ---------------------------------------------------
---------------------------------------------------------------------------------------------------




with sku_list AS
	(
	SELECT item_id
	FROM DW_LSTG_ITEM
	Where ITEM_ID in (
					363880355821,
					134164459787,
					363939900706,
					363939909644,
					134152131491,
					144612766445,
					363880355153,
					144612758578,
					363880355164,
					363939931513,
					363880361049,
					144612766501,
					144612765726,
					134152131464,
					363939961996,
					363880360247,
					134152135076,
					5012616262241,
					5012616262203,
					5012616264290,
					144612768045,
					5012616262227,
					5012616264283,
					5012616262234,
					134152134273,
					134152128111,
					5012616174407,
					134164459804,
					144676488284,
					144612765069,
					363880359072,
					134152130690,
					363880359070,
					134444836367,
					134152131470,
					134152130693,
					144635039381,
					134152135038,
					144635040248,
					363896938732,
					363940072734,
					134164462110,
					134152131445,
					144612765753,
					363940112532,
					363940075831,
					363880360261,
					134152131476,
					134152131472,
					144676576326,
					144612758558,
					144612758551,
					5012616266003,
					363941102564,
					144677401635,
					134196419275,
					363941132692,
					144635039359,
					144635039359,
					144677486907,
					134164459773,
					144612760341,
					134164459800,
					134164459819,
					363880355836,
					363880355131,
					144612760375,
					363880355841,
					363880360257,
					144612765780,
					134152128115,
					134152128106,
					363880360254,
					363880355813,
					363880355087,
					144677449792,
					134152131483,
					134152128958,
					134152128933,
					134152128920,
					363880367147,
					134152130680,
					134196514156,
					363941212329,
					363941211751,
					144677510309,
					144635039347,
					144612768746,
					144612768770,
					363880370941,
					363880370999,
					363880370970,
					144635039373,
					363880359137,
					144938924545,
					134164462093,
					134152134580,
					144635039364,
					134164459846,
					134152131448,
					363880359111,
					134152133255,
					134152131451,
					134152131447
					)
		Group by 1
	)

,

dates as 
(
select cal_dt
From DW_CAL_DT
Where cal_dt between '2022-02-13' and '2023-08-06'
group by 1
)



(
SELECT  
	case when cal_dt between '2022-02-13' and '2022-08-06' then 'Same time last year'
		when cal_dt between '2022-08-13' and '2023-02-06' then 'prior 6 months'
		when cal_dt between '2023-02-13' and '2023-08-06' then 'Latest 6 months'
		else 'Other'
		End as time_frame
	,gem2.lstg_id
   ,CASE 
   		WHEN bkt.REV_BKT_ID IN( 29,30 ) THEN 'INS_REV' 
        WHEN bkt.REV_BKT_ID IN( 31,32 ) THEN 'FTR_REV'
        WHEN bkt.REV_BKT_ID IN( 33,34 ) THEN 'FNL_VAL_REV'
        WHEN bkt.REV_BKT_ID IN( 35,36 ) THEN 'OTHR_LSTG_REV'
		ELSE 'OTHER' END  RVNU_BKT
   ,lstg_rev_bkt_desc as fee_type
   ,ACTN_CODE_TYPE_DESC2
	,actncode.ACTN_CODE_DESC
   ,sum(gem2.amt_bc*cast ( cr.curncy_plan_rate as FLOAT)* -1) as revenue_usd
   ,sum(gem2.amt_bc) as revenue_gbp 
   ,0 as gmv_usd
   ,0 as gmv_gbp

FROM ( 

			-- =====================================================
			-- TOTAL DAILY REVENUE
			-- =====================================================

			SELECT  
			  gcr.acct_trans_dt, gcr.actn_code ,gcr.LSTG_ID, gcr.BLNG_CURNCY_ID
			  ,sum(cast ( gcr.amt_bc as FLOAT)) as amt_bc  
			FROM ACCESS_VIEWS.dw_gem2_cmn_rvnu_i gcr
			left join ACCESS_VIEWS.DW_CHECKOUT_TRANS ck
				on ck.TRANSACTION_ID = gcr.CK_TRANS_ID
				and ck.ITEM_ID = gcr.LSTG_ID
				and ck.SELLER_ID = gcr.slr_id
			INNER JOIN sku_list
				on sku_list.item_id = gcr.LSTG_ID
			WHERE 
				gcr.acct_trans_dt >=  '2019-01-01'
				and gcr.lstg_site_id in (3)
				and ! gcr.adj_type_id in( -7, -1,3,5)
				and gcr.BLNG_CURNCY_ID = 3
			GROUP BY 1,2,3,4

			UNION ALL 

			SELECT  
			  gcr.acct_trans_dt, gcr.actn_code ,gcr.LSTG_ID, gcr.BLNG_CURNCY_ID
			  ,sum(cast ( gcr.amt_bc* -1 as FLOAT)) as amt_usd 
			FROM ACCESS_VIEWS.dw_gem2_cmn_adj_rvnu_i gcr
			left join ACCESS_VIEWS.DW_CHECKOUT_TRANS ck
				on ck.TRANSACTION_ID = gcr.CK_TRANS_ID
				and ck.ITEM_ID = gcr.LSTG_ID
				and ck.SELLER_ID = gcr.slr_id 
			INNER JOIN sku_list
				on sku_list.item_id = gcr.LSTG_ID
			 WHERE  
				gcr.acct_trans_dt >=  '2019-01-01'  
				and gcr.lstg_site_id in (3)
				and ! gcr.adj_type_id in( -7, -1,3,5)
				and gcr.iswacko_yn_id=1
				and gcr.BLNG_CURNCY_ID = 3

			 GROUP BY 1,2,3,4

			UNION ALL

			-- =====================================================
			-- ETRS: this is to remove eTRS from revenue and approach is provided by central team
			-- =====================================================

			SELECT  
			  gcr.acct_trans_dt, gcr.actn_code ,gcr.LSTG_ID, gcr.BLNG_CURNCY_ID
			  ,sum(cast ( gcr.amt_bc as FLOAT)) as amt_usd  
			FROM ACCESS_VIEWS.DW_GEM2_CMN_RVNU_I_ETRS gcr
			WHERE 
				gcr.acct_trans_dt >=  '2019-01-01'  
				and ! gcr.lstg_site_id in(3)
				and ! gcr.adj_type_id in( -7, -1,3,5)
				and gcr.BLNG_CURNCY_ID = 3

			GROUP BY 1,2,3,4

			UNION ALL 

			SELECT  
			  gcr.acct_trans_dt, gcr.actn_code ,gcr.LSTG_ID, gcr.BLNG_CURNCY_ID
			  ,sum(cast ( gcr.amt_bc* -1 as FLOAT)) as amt_usd 
			FROM ACCESS_VIEWS.DW_GEM2_CMN_ADJ_RVNU_I_ETRS gcr
			WHERE  
				gcr.acct_trans_dt >=  '2019-01-01'  
				and gcr.lstg_site_id in (3)
				and ! gcr.adj_type_id in( -7, -1,3,5)
				and gcr.iswacko_yn_id=1
				and gcr.BLNG_CURNCY_ID = 3

			 GROUP BY 1,2,3,4
 
) as gem2
inner join ACCESS_VIEWS.dw_acct_actn_code_lkp as actn on gem2.actn_code=actn.actn_code
inner join ACCESS_VIEWS.dw_action_codes as actncode on actn.actn_code=actncode.actn_code
inner join ACCESS_VIEWS.dw_acct_lstg_rev_bkt_lkp as bkt on  (actn.rev_bkt_id=bkt.rev_bkt_id and  lower(rev_grp_code) like lower('%GEM%'))
inner join ACCESS_VIEWS.ssa_curncy_plan_rate_dim as cr on cr.curncy_id=gem2.BLNG_CURNCY_ID
inner join dates as x on gem2.acct_trans_dt=x.cal_dt
inner join sku_list s on s.item_id = gem2.lstg_id


WHERE  
1=1


 GROUP BY 1,2,3,4,5,6
)
-- ==================================================================

UNION ALL

(
SELECT  
case when cal_dt between '2022-02-13' and '2022-08-06' then 'Same time last year'
		when cal_dt between '2022-08-13' and '2023-02-06' then 'prior 6 months'
		when cal_dt between '2023-02-13' and '2023-08-06' then 'Latest 6 months'
		else 'Other'
		End as time_frame
	,ck.item_id
   ,"" AS  RVNU_BKT
   ,"" as fee_type
   ,"" as ACTN_CODE_TYPE_DESC2
   ,"" as ACTN_CODE_DESC

   ,sum(0) as revenue_usd
   ,sum(0) as revenue_gbp
   ,sum(ck.GMV_PLAN_USD) as gmv_usd
   ,sum(ck.GMV_LC_AMT) as gmv_gbp

FROM ACCESS_VIEWS.DW_CHECKOUT_TRANS as ck
inner join ACCESS_VIEWS.dw_category_groupings as cat on  ( (ck.leaf_categ_id=cat.leaf_categ_id and ck.site_id=cat.site_id) and  ! cat.sap_category_id in(5,7,23,41, -999))
inner join ACCESS_VIEWS.ssa_curncy_plan_rate_dim as cr on cr.curncy_id=ck.lstg_curncy_id
inner join dates as x on ck.GMV_DT=x.cal_dt
inner join sku_list s on s.item_id = ck.item_id

			
WHERE  
1=1
and	! ck.SALE_TYPE in(10,15)
and lower(ck.ck_wacko_yn)=lower('N') 
and x.cal_dt>=to_date('2018-01-01')
and ck.slr_cntry_id in (3)

 GROUP BY 1,2,3,4,5,6
)
;