Select 
item_condition,
SELLER_ID,
SELLER_NAME,
ITEM_CNDTN_TXT,
BRAND,
PRICE_TRANCHE,
seller_segment,
PSNAD,
count(distinct item_id) as sold_items,
sum(TTL_ITEMS) as quantity

From P_PSA_ANALYTICS_T.psa_hub_data

Where 1=1
and upper(HUB_REV_ROLLUP) = 'UK'
and upper(IS_RETURN_FLAG_YN_IND) = 'N'
and upper(HUB_CATEGORY) = 'HANDBAGS'
and SHPMT_RCVD_DATE_DT between '2022-02-18' and '2023-02-17'

Group by 1,2,3,4,5,6,7,8