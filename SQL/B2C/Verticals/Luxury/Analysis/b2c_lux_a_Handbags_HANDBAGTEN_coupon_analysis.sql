-- JIRA Ticket:		UKPLAN-434

-- Author: 			Robbie Evans
-- Stakeholder: 	Emma Hamilton, Alice Bridson, Keith Metcalfe
-- Purpose: 		Provide an in-depth review of the Handbags HANDBAGTEN coupon that ran from 23 to 29 June, answering key business questions
-- Date Created: 	12/07/2023


-- Author: 			Robbie Evans
-- Stakeholder: 	Emma Hamilton, Alice Bridson, Keith Metcalfe
-- Purpose: 		Provide an in-depth review of the Handbags HANDBAGTEN coupon that ran from 23 to 29 June, answering key business questions
-- Date Created: 	12/07/2023


SET cpn_st_dt = '2023-06-23';
SET cpn_end_dt = '2023-06-29';

------------------------------------------------------All coupon data----------------------------------------

select *
from P_OLWAND_T.Coupon_Redemptions
where incntv_cd = 'HANDBAGTEN'
;

----------------------------------------------------------Table of Coupon buyers with their spend during the coupon------------------------------------
drop table if exists buyers_class;
create temp table buyers_class as

Select byr.BUYER_ID
, byr.gmb_usd
, latest_handbags_dt
, latest_ebay_dt
, lux_latest_handbags_dt
, ag_latest_handbags_dt

From (select buyer_id, sum(gmb_usd) as gmb_usd
	from P_OLWAND_T.Coupon_Redemptions
	where incntv_cd = 'HANDBAGTEN'
	Group by 1) byr
LEFT JOIN
	(select ck.BUYER_ID
		, max(case when (cat.CATEG_LVL3_ID = 169291 OR CATEG_LVL4_ID IN (52357,163570,169285,45258,2996,45237,169271)) then ck.gmv_dt End) as latest_handbags_dt
		, max(ck.gmv_dt) as latest_ebay_dt
		, max(case when (cat.CATEG_LVL3_ID = 169291 OR CATEG_LVL4_ID IN (52357,163570,169285,45258,2996,45237,169271)) and ck.ITEM_PRICE*lpr.CURNCY_PLAN_RATE >= 500 then ck.gmv_dt End) as lux_latest_handbags_dt
		, max(case when ck.item_id = ag.item_id then ck.gmv_dt End) as ag_latest_handbags_dt
	from DW_CHECKOUT_TRANS ck
	inner join P_INVENTORYPLANNING_T.DW_CATEGORY_GROUPINGS_ADJ cat
		on ck.LEAF_CATEG_ID = cat.LEAF_CATEG_ID
		and cat.SITE_ID = 3
	inner join DW_CAL_DT cal
		on ck.gmv_dt = cal.CAL_DT
		and cal.cal_dt between date_sub('2023-06-23',730) and date_sub('2023-06-23',1)
	inner  JOIN ACCESS_VIEWS.SSA_CURNCY_PLAN_RATE_DIM LPR 
		ON ck.LSTG_CURNCY_ID = LPR.CURNCY_ID 
	inner join 
		(select buyer_id
		from P_OLWAND_T.Coupon_Redemptions
		where incntv_cd = 'HANDBAGTEN'
		Group by 1) byr
			on ck.BUYER_ID = byr.buyer_id
	LEFT JOIN 
			(
			select item_id
			from access_views.DW_PES_ELGBLT_HIST
			where evltn_end_ts = '2099-12-31 00:00:00'
			and BIZ_PRGRM_NAME = 'PSA_HANDBAGS_UK' -- UK Handbags AG program
			and elgbl_yn_ind ='Y' -- eligible items
			Group by 1
			) ag 
				on ck.item_id = ag.item_id
	Where 1=1
		and ck.SITE_ID = 3
	Group by 1
	) CK
		on byr.buyer_id = ck.BUYER_ID

;



-------------------------------------Overall New vs Reactivated Watches Shoppers----------------------------

select
case when latest_handbags_dt is null and latest_ebay_dt is null then 'New to eBay, Handbags & AG Handbags'
	when latest_handbags_dt is null and latest_ebay_dt is not null then 'Current eBay, New to Handbags & AG Handbags'
	when latest_handbags_dt is not null and ag_latest_handbags_dt is null  then 'Current Handbags, New to AG Handbags'
	when ag_latest_handbags_dt is not null then 'Current AG Handbags'
	else 'Returning'
	End as buyer_class
	,count(distinct buyer_id) as buyers
	,sum(gmb_usd) as gmb
From buyers_class
group by 1


;


-------------------------------------Detailed New vs Reactivated Watches Shoppers----------------------------

select
case when latest_watches_dt is null and latest_ebay_dt is null then 'New to eBay, Handbags & AG Handbags'
	when latest_watches_dt is null and latest_ebay_dt <= '2022-03-15' then 'Reactivated to eBay, New to Handbags'
	when latest_watches_dt is null and latest_ebay_dt > '2022-03-15' then 'Current eBay, New to Handbags'
	when latest_watches_dt <= '2022-03-15' and latest_ebay_dt <= '2022-03-15' then 'Reactivated to eBay, Reactivated to Handbags'
	when latest_watches_dt <= '2022-03-15' and latest_ebay_dt > '2022-03-15' then 'Current eBay, Reactivated to Handbags'
	else 'Current Handbags'
	End as class
	,count(distinct buyer_id) as buyers
	,sum(gmb_usd) as gmb_usd
From buyers_class
Group by 1

;


-------------------------------------Coupon Shoppers Before and After Coupon Period----------------------------

select cal.cal_dt
,case when ck.item_id = ag.item_id then 'AG Handbags'
	when (cat.CATEG_LVL3_ID = 169291 OR CATEG_LVL4_ID IN (52357,163570,169285,45258,2996,45237,169271)) and (ck.item_id <> ag.item_id) then 'Non-AG Handbags'
	Else 'Other Categories'
	end as category
,case when cal.cal_dt between '2023-06-23' and '2023-06-29' then 'During Coupon'
	when cal.cal_dt < '2023-06-23' then 'Before Coupon'
	when cal.cal_dt > '2023-06-29' then 'Post Coupon'
	else 'Other'
	End as Period
,count(distinct byr.buyer_id) as buyers
,sum(ck.gmv_plan_usd) as gmv
,sum(ck.QUANTITY) as bi

From DW_CHECKOUT_TRANS ck
INNER JOIN buyers_class byr
	on ck.BUYER_ID = byr.buyer_id
inner join P_INVENTORYPLANNING_T.DW_CATEGORY_GROUPINGS_ADJ cat
	on ck.LEAF_CATEG_ID = cat.LEAF_CATEG_ID
	and cat.SITE_ID = 3
inner join DW_CAL_DT cal
	on ck.gmv_dt = cal.CAL_DT
	and cal.cal_dt between date_sub('2023-06-23',11) and date_add('2023-06-29',11)
LEFT JOIN 
		(
		select item_id
		from access_views.DW_PES_ELGBLT_HIST
		where evltn_end_ts = '2099-12-31 00:00:00'
		and BIZ_PRGRM_NAME = 'PSA_HANDBAGS_UK' -- UK Handbags AG program
		and elgbl_yn_ind ='Y' -- eligible items
		Group by 1
		) ag 
			on ck.item_id = ag.item_id
	
Where 1=1
and ck.SITE_ID = 3

Group by 1,2,3
;











-------------------------------------Coupon Shoppers Listings Before and After Coupon Period----------------------------


select
-- 	case when lstg.AUCT_START_DT < '2023-06-23' then 'Pre Coupon'
-- 		when lstg.AUCT_START_DT between '2023-06-23' and '2023-06-29' then 'During Coupon'
-- 		when lstg.AUCT_START_DT > '2023-06-29' then 'Post Coupon'
-- 		else 'Other'
-- 		End as period
	case when lstg.START_PRICE_LSTG_CURNCY <= 1000 then 'A. £500-£1000'
		when lstg.START_PRICE_LSTG_CURNCY <= 1500 then 'B. £1000-£1500'
		when lstg.START_PRICE_LSTG_CURNCY <= 2000 then 'C. £1500-£2000'
		when lstg.START_PRICE_LSTG_CURNCY <= 2500 then 'D. £2000-£2500'
		when lstg.START_PRICE_LSTG_CURNCY <= 3000 then 'E. £2500-£3000'
		when lstg.START_PRICE_LSTG_CURNCY <= 3500 then 'F. £3000-£3500'
		when lstg.START_PRICE_LSTG_CURNCY <= 4000 then 'G. £3500-£4000'
		when lstg.START_PRICE_LSTG_CURNCY <= 4500 then 'H. £4000-£4500'
		when lstg.START_PRICE_LSTG_CURNCY <= 5000 then 'I. £4500-£5000'
		else 'J. > £5000' end as
		PRICE_BUCKET
	,count(distinct byr.buyer_id) as sellers
	,count(distinct lstg.ITEM_ID) as listings
	,0 as buyers
	,0 as bought_items

From DW_LSTG_ITEM lstg
INNER JOIN buyers_class byr
	on lstg.SLR_ID = byr.buyer_id
INNER JOIN P_INVENTORYPLANNING_T.DW_CATEGORY_GROUPINGS_ADJ cat
	on lstg.LEAF_CATEG_ID = cat.LEAF_CATEG_ID
	and cat.SITE_ID = 3
INNER JOIN DW_CAL_DT cal
	on lstg.AUCT_START_DT = cal.CAL_DT
INNER JOIN 
		(
		select item_id
		from access_views.DW_PES_ELGBLT_HIST
		where evltn_end_ts = '2099-12-31 00:00:00'
		and BIZ_PRGRM_NAME = 'PSA_HANDBAGS_UK' -- UK Handbags AG program
		and elgbl_yn_ind ='Y' -- eligible items
		Group by 1
		) ag 
			on lstg.item_id = ag.item_id
	
Where 1=1
	and lstg.ITEM_SITE_ID = 3
	and lstg.auct_start_dt between '2023-06-23' and '2023-07-10'
Group by 1



UNION ALL



select
	case when ck.ITEM_PRICE <= 1000 then 'A. £500-£1000'
		when ck.ITEM_PRICE <= 1500 then 'B. £1000-£1500'
		when ck.ITEM_PRICE <= 2000 then 'C. £1500-£2000'
		when ck.ITEM_PRICE <= 2500 then 'D. £2000-£2500'
		when ck.ITEM_PRICE <= 3000 then 'E. £2500-£3000'
		when ck.ITEM_PRICE <= 3500 then 'F. £3000-£3500'
		when ck.ITEM_PRICE <= 4000 then 'G. £3500-£4000'
		when ck.ITEM_PRICE <= 4500 then 'H. £4000-£4500'
		when ck.ITEM_PRICE <= 5000 then 'I. £4500-£5000'
		else 'J. > £5000' end as
		PRICE_BUCKET
	,0 as sellers
	,0 as listings
	,count(distinct ck.buyer_id) as buyers
	,count(distinct ck.ITEM_ID) as bought_items

From DW_CHECKOUT_TRANS ck
INNER JOIN
	(select item_id
	from P_OLWAND_T.Coupon_Redemptions
	where incntv_cd = 'HANDBAGTEN'
	Group by 1) cpn
		on ck.item_id = cpn.item_id
	
Where 1=1

Group by 1








--------------------------------------------------------GMV Surrounding Weeks---------------------------------------------------------


select
	case when ck.gmv_dt < '2023-06-23' then 'Before Coupon'
		when ck.gmv_dt between '2023-06-23' and '2023-06-29' then 'During Coupon'
		else 'After Coupon'
		End as period
	,sum(ck.gmv20_plan) as gmv
	,sum(ck.gmv20_sold_quantity) as si
	,count(distinct ck.buyer_id) as buyers


From PRS_RESTRICTED_V.SLNG_TRANS_SUPER_FACT ck
INNER JOIN 
		(
		select item_id
		from access_views.DW_PES_ELGBLT_HIST
		where evltn_end_ts = '2099-12-31 00:00:00'
		and BIZ_PRGRM_NAME = 'PSA_HANDBAGS_UK' -- UK Handbags AG program
		and elgbl_yn_ind ='Y' -- eligible items
		Group by 1
		) ag 
			on ck.item_id = ag.item_id
	
Where 1=1
and ck.gmv_dt between '2023-06-16' and '2023-07-06'
and ck.CK_WACKO_YN = 'N'
and ck.SLR_CNTRY_ID = 3

Group by 1









--------------------------------------------------Items Bought Before Coupon that were then returned once coupon launched------------------------------


Select 
case when ck.item_id = rtrn.item_id then 'Y' else 'N' end as returned_flag
,count(distinct ck.item_id) as listings
,count(distinct ck.buyer_id) as buyers

From
	(
	Select 
	psa.item_id
	,psa.BUYER_ID

	From P_PSA_ANALYTICS_T.psa_hub_data psa
	inner join buyers_class byr
		on psa.BUYER_ID = byr.buyer_id

	where 1=1
	and upper(HUB_REV_ROLLUP) = 'UK'
	and upper(HUB_CATEGORY) = 'HANDBAGS'
	and IS_RETURN_FLAG_YN_IND = 'N'
	and psa.gmv_dt between date_sub('2023-06-23',28) and '2023-06-22'

	Group by 1,2
	) ck 
	LEFT JOIN
		(
		Select 
		psa.item_id
		,psa.buyer_id

		From P_PSA_ANALYTICS_T.psa_hub_data psa
		inner join buyers_class byr
			on psa.BUYER_ID = byr.buyer_id

		where 1=1
		and upper(HUB_REV_ROLLUP) = 'UK'
		and upper(HUB_CATEGORY) = 'HANDBAGS'
		and IS_RETURN_FLAG_YN_IND = 'Y'
		and psa.RETURN_DATE between '2023-06-23' and '2023-06-29'

		Group by 1,2
		) rtrn
			on ck.item_id = rtrn.item_id
			and ck.buyer_id = rtrn.buyer_id
Group by 1
;





----------------------------------------Lifestage Shopper Segmentation-----------------------------------------

Select
seg.MACRO_CL_NAME
,cpn.gmb_cpn
,cpn.buyers_cpn
,reg.gmb_reg
,reg.buyers_reg

FROM 
	(Select MACRO_CL_NAME
	FROM ACCESS_VIEWS.LFSTG_CLSTR_PRMRY_USER seg
	WHERE upper(USER_REV_ROLLUP) = 'UK'
	Group by 1
	) seg
LEFT JOIN
	(
	SELECT
	MACRO_CL_NAME
	,sum(byr.gmb_usd) as gmb_cpn
	,count(distinct byr.buyer_id) as buyers_cpn

	FROM 
	(select buyer_id
		,max(c.rev_rollup) as rev_rollup
		,sum(gmb_usd) as gmb_usd
		,sum(QTY_BGHT) as bi
		from P_OLWAND_T.Coupon_Redemptions cpn
			INNER JOIN DW_USERS u
				on cpn.buyer_id = u.user_id
			INNER JOIN DW_COUNTRIES c
				on u.USER_CNTRY_ID = c.CNTRY_ID
		where incntv_cd = 'HANDBAGTEN'
		Group by 1) byr
	join ACCESS_VIEWS.USER_DNA_DIM c
		ON byr.buyer_id = c.user_id
	join ACCESS_VIEWS.LFSTG_CLSTR_PRMRY_USER d
		on c.primary_user_id = d.primary_user_id
		and current_date between RCRD_EFF_START_DT and RCRD_EFF_END_DT
		and byr.REV_ROLLUP = d.USER_REV_ROLLUP -- align LSS build with user's REV_ROLLUP

	Where 1=1

	Group by 1
	) cpn
		on seg.MACRO_CL_NAME = cpn.MACRO_CL_NAME
LEFT JOIN
	(
	Select 
	MACRO_CL_NAME
	,sum(ck.GMV20_PLAN) as gmb_reg
	,count(distinct ck.BUYER_ID) as buyers_reg

	FROM PRS_RESTRICTED_V.SLNG_TRANS_SUPER_FACT ck
	INNER JOIN DW_CAL_DT cal
		on ck.gmv_dt = cal.CAL_DT
		and cal.RETAIL_YEAR = 2023
		and cal.cal_dt < '2023-06-23'
	INNER JOIN 
		(
		select item_id
		from access_views.DW_PES_ELGBLT_HIST
		where evltn_end_ts = '2099-12-31 00:00:00'
		and BIZ_PRGRM_NAME = 'PSA_HANDBAGS_UK' -- UK Handbags AG program
		and elgbl_yn_ind ='Y' -- eligible items
		Group by 1
		) ag 
			on ck.item_id = ag.item_id
	INNER JOIN ACCESS_VIEWS.USER_DNA_DIM c
		ON ck.buyer_id = c.user_id
	INNER JOIN ACCESS_VIEWS.LFSTG_CLSTR_PRMRY_USER d
		on c.primary_user_id = d.primary_user_id
		and current_date between RCRD_EFF_START_DT and RCRD_EFF_END_DT
		and ck.REV_ROLLUP = d.USER_REV_ROLLUP -- align LSS build with user's REV_ROLLUP

	Where 1=1
	and ck.SITE_ID = 3
	and ck.SLR_CNTRY_ID = 3

	Group by 1
	) reg 
		on seg.MACRO_CL_NAME = reg.MACRO_CL_NAME
		








----------------------------------------FM Shopper Segmentation-----------------------------------------




Select
cpn.BUYER_TYPE_DESC
,cpn.gmb_cpn
,cpn.buyers_cpn
,reg.gmb_reg
,reg.buyers_reg

FROM 
	(
	select buyer_type_desc
		,sum(gmb_usd) as gmb_cpn
		,count(distinct cpn.buyer_id) as buyers_cpn
		from P_OLWAND_T.Coupon_Redemptions cpn
			INNER JOIN DW_USERS u
				on cpn.buyer_id = u.user_id
			INNER JOIN DW_COUNTRIES c
				on u.USER_CNTRY_ID = c.CNTRY_ID
		where incntv_cd = 'HANDBAGTEN'
		Group by 1
	) cpn
LEFT JOIN
	(
	Select 
	BUYER_TYPE_DESC
	,sum(ck.GMV20_PLAN) as gmb_reg
	,count(distinct ck.BUYER_ID) as buyers_reg

	FROM PRS_RESTRICTED_V.SLNG_TRANS_SUPER_FACT ck
	INNER JOIN DW_CAL_DT cal
		on ck.gmv_dt = cal.CAL_DT
		and cal.RETAIL_YEAR = 2023
		and cal.cal_dt < '2023-06-23'
	INNER JOIN 
		(
		select item_id
		from access_views.DW_PES_ELGBLT_HIST
		where evltn_end_ts = '2099-12-31 00:00:00'
		and BIZ_PRGRM_NAME = 'PSA_HANDBAGS_UK' -- UK Handbags AG program
		and elgbl_yn_ind ='Y' -- eligible items
		Group by 1
		) ag 
			on ck.item_id = ag.item_id
	INNER JOIN
		(
		select USER_ID, BUYER_TYPE_DESC
		FROM PRS_RESTRICTED_V.USER_DNA_FM_SGMNT
		Where END_DATE = '2099-12-31'
		Group by 1,2
		) type
			on ck.BUYER_ID = type.user_id

	Where 1=1
	and ck.SITE_ID = 3
	and ck.SLR_CNTRY_ID = 3

	Group by 1
	) reg 
		on cpn.BUYER_TYPE_DESC = reg.BUYER_TYPE_DESC
		






-------------------------------------------Coupon Shoppers vs Reg AG Handbags Shoppers Price Tranche Analysis-------------------------------------------


select reg.PRICE_BUCKET
,reg_buyers
,reg_bi
,cpn_buyers
,cpn_bi

FROM
	(
	select
		case when ck.ITEM_PRICE <= 1000 then 'A. £500-£1000'
			when ck.ITEM_PRICE <= 1500 then 'B. £1000-£1500'
			when ck.ITEM_PRICE <= 2000 then 'C. £1500-£2000'
			when ck.ITEM_PRICE <= 2500 then 'D. £2000-£2500'
			when ck.ITEM_PRICE <= 3000 then 'E. £2500-£3000'
			when ck.ITEM_PRICE <= 3500 then 'F. £3000-£3500'
			when ck.ITEM_PRICE <= 4000 then 'G. £3500-£4000'
			when ck.ITEM_PRICE <= 4500 then 'H. £4000-£4500'
			when ck.ITEM_PRICE <= 5000 then 'I. £4500-£5000'
			else 'J. > £5000' end as
			PRICE_BUCKET
		,count(distinct ck.buyer_id) as reg_buyers
		,sum(ck.GMV20_SOLD_QUANTITY) as reg_bi

	From PRS_RESTRICTED_V.SLNG_TRANS_SUPER_FACT ck
	INNER JOIN DW_CAL_DT cal
		on ck.gmv_dt = cal.CAL_DT
		and cal.RETAIL_YEAR = 2023
		and cal.CAL_DT < '2023-06-23'
	INNER JOIN 
			(
			select item_id
			from access_views.DW_PES_ELGBLT_HIST
			where evltn_end_ts = '2099-12-31 00:00:00'
			and BIZ_PRGRM_NAME = 'PSA_HANDBAGS_UK' -- UK Handbags AG program
			and elgbl_yn_ind ='Y' -- eligible items
			Group by 1
			) ag 
				on ck.item_id = ag.item_id

	Where 1=1
		and ck.SITE_ID = 3
		and ck.SLR_CNTRY_ID = 3

	Group by 1
	) reg
LEFT JOIN
	(
	select
		case when ck.ITEM_PRICE <= 1000 then 'A. £500-£1000'
			when ck.ITEM_PRICE <= 1500 then 'B. £1000-£1500'
			when ck.ITEM_PRICE <= 2000 then 'C. £1500-£2000'
			when ck.ITEM_PRICE <= 2500 then 'D. £2000-£2500'
			when ck.ITEM_PRICE <= 3000 then 'E. £2500-£3000'
			when ck.ITEM_PRICE <= 3500 then 'F. £3000-£3500'
			when ck.ITEM_PRICE <= 4000 then 'G. £3500-£4000'
			when ck.ITEM_PRICE <= 4500 then 'H. £4000-£4500'
			when ck.ITEM_PRICE <= 5000 then 'I. £4500-£5000'
			else 'J. > £5000' end as
			PRICE_BUCKET
		,count(distinct ck.buyer_id) as cpn_buyers
		,sum(ck.GMV20_SOLD_QUANTITY) as cpn_bi

	From PRS_RESTRICTED_V.SLNG_TRANS_SUPER_FACT ck
	INNER JOIN
		(select item_id
		from P_OLWAND_T.Coupon_Redemptions
		where incntv_cd = 'HANDBAGTEN'
		Group by 1) cpn
			on ck.item_id = cpn.item_id

	Where 1=1

	Group by 1
	) cpn
		on reg.PRICE_BUCKET = cpn.PRICE_BUCKET































select
	cal.RETAIL_YEAR
	,cal.retail_week
	,count(distinct ck.buyer_id) as buyers
	,sum(ck.GMV20_SOLD_QUANTITY) as bi
	,sum(ck.GMV20_PLAN) as gmv

	From PRS_RESTRICTED_V.SLNG_TRANS_SUPER_FACT ck
	INNER JOIN DW_CAL_DT cal
		on ck.gmv_dt = cal.CAL_DT
		and cal.RETAIL_YEAR >= 2022
		and AGE_FOR_RTL_WEEK_ID < 0
	INNER JOIN 
		(
		select item_id
		from access_views.DW_PES_ELGBLT_HIST
		where evltn_end_ts = '2099-12-31 00:00:00'
		and BIZ_PRGRM_NAME = 'PSA_HANDBAGS_UK' -- UK Handbags AG program
		and elgbl_yn_ind ='Y' -- eligible items
		Group by 1
		) ag 
			on ck.item_id = ag.item_id

	Where 1=1
		and ck.SITE_ID = 3
		and ck.SLR_CNTRY_ID = 3

	Group by 1,2
	
	
	
	
	
	






select
	case when ck.gmv_dt < '2023-06-23' then 'Before Coupon'
		when ck.gmv_dt between '2023-06-23' and '2023-06-29' then 'During Coupon'
		else 'After Coupon'
		End as period
	,sum(ck.gmv20_plan) as gmv
	,sum(ck.gmv20_sold_quantity) as si
	,count(distinct ck.buyer_id) as buyers


From PRS_RESTRICTED_V.SLNG_TRANS_SUPER_FACT ck
INNER JOIN 
		(
		select item_id
		from access_views.DW_PES_ELGBLT_HIST
		where evltn_end_ts = '2099-12-31 00:00:00'
		and BIZ_PRGRM_NAME = 'PSA_HANDBAGS_UK' -- UK Handbags AG program
		and elgbl_yn_ind ='Y' -- eligible items
		Group by 1
		) ag 
			on ck.item_id = ag.item_id
	
Where 1=1
and ck.gmv_dt between '2023-06-16' and '2023-07-06'
and ck.CK_WACKO_YN = 'N'
and ck.SLR_CNTRY_ID = 3

Group by 1

---------------------------------------------Traffic----------------------------------------

select
case when trfc.CAL_DT < '2023-06-23' then 'Before Coupon'
		when trfc.CAL_DT between '2023-06-23' and '2023-06-29' then 'During Coupon'
		else 'After Coupon'
		End as period
,sum(trfc.TTL_VI_CNT) as vi
,sum(trfc.SRP_IMPRSN_CNT) as imp

FROM PRS_RESTRICTED_V.SLNG_TRFC_SUPER_FACT trfc
INNER JOIN
		(
		select item_id
		from access_views.DW_PES_ELGBLT_HIST
		where evltn_end_ts = '2099-12-31 00:00:00'
		and BIZ_PRGRM_NAME = 'PSA_HANDBAGS_UK' -- UK Handbags AG program
		and elgbl_yn_ind ='Y' -- eligible items
		Group by 1
		) ag 
			on trfc.item_id = ag.item_id
Where 1=1
and trfc.CAL_DT between '2023-06-16' and '2023-07-06'

Group by 1
;




---------------------------------------------Basket Analysis----------------------------------------------

select
	'Coupon Shoppers' as target	
-- 	,cat.NEW_VERTICAL
-- 	,cat.CATEG_LVL2_NAME
-- 	,cat.CATEG_LVL3_NAME
	,sum(ck.gmv20_plan) as gmv
	,sum(ck.gmv20_sold_quantity) as si
	,count(distinct ck.buyer_id) as buyers

From PRS_RESTRICTED_V.SLNG_TRANS_SUPER_FACT ck
inner join P_INVENTORYPLANNING_T.DW_CATEGORY_GROUPINGS_ADJ cat
	on ck.LEAF_CATEG_ID = cat.LEAF_CATEG_ID
	and cat.SITE_ID = 3
INNER JOIN buyers_class byr
	on ck.BUYER_ID = byr.buyer_id 
Where 1=1
and ck.gmv_dt >= '2023-01-01'
and ck.gmv_dt < '2023-06-23'
and ck.BYR_CNTRY_ID = 3

Group by 1

UNION ALL

select
	'AG Handbag Shoppers' as target
-- 	,cat.NEW_VERTICAL
-- 	,cat.CATEG_LVL2_NAME
-- 	,cat.CATEG_LVL3_NAME
	,sum(ck.gmv20_plan) as gmv
	,sum(ck.gmv20_sold_quantity) as si
	,count(distinct ck.buyer_id) as buyers

From PRS_RESTRICTED_V.SLNG_TRANS_SUPER_FACT ck
inner join P_INVENTORYPLANNING_T.DW_CATEGORY_GROUPINGS_ADJ cat
	on ck.LEAF_CATEG_ID = cat.LEAF_CATEG_ID
	and cat.SITE_ID = 3
INNER JOIN 
	(
	select ck.BUYER_ID
	From PRS_RESTRICTED_V.SLNG_TRANS_SUPER_FACT ck
	INNER JOIN
		(
		select item_id
		from access_views.DW_PES_ELGBLT_HIST
		where evltn_end_ts = '2099-12-31 00:00:00'
		and BIZ_PRGRM_NAME = 'PSA_HANDBAGS_UK' -- UK Handbags AG program
		and elgbl_yn_ind ='Y' -- eligible items
		Group by 1
		) ag 
			on ck.item_id = ag.item_id
	Where ck.GMV_DT >= '2022-01-01'
	and ck.gmv_dt < '2023-06-23'
	Group by 1
	) byr
		on ck.BUYER_ID = byr.buyer_id 
Where 1=1
and ck.gmv_dt >= '2023-01-01'
and ck.BYR_CNTRY_ID = 3

Group by 1
