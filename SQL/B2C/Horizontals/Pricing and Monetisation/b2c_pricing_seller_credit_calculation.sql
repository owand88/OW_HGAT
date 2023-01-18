/*
Jira: UKPLAN-89

Author: Tugrul Ates

Description: This scripts extracts the seller fee and category detail data whic then will be used to calculate seller credits
due to an issue happened on ebay side.

For example, the seller was supposed to pay 5% FvF fee as per their pricing contract with ebay, but they ended up paying 9% FvF.
Therefore, ebay has to issue a credit to that seller.

*/

create VIEW p_InventoryPlanning_t.vw_seller_credit_calculation as

with seller_level_fee_data as 
(
    select
    distinct t1.user_id as seller_id                      -- Seller ID
    ,t3.user_slctd_id as seller_name                      -- Seller Name
    ,t1.item_id                                           -- Item ID (or Listing ID)
    ,t1.ck_trans_id                                       -- Transaction ID (this is 0 for Insertion Fee related rows)
    ,t1.acct_trans_id                                     -- Billing Fee Transaction ID of the Seller
    ,t1.acct_trans_date                                   -- Transaction timestamp
    ,t1.user_cntry_id                                     -- Country ID (3 for UK)
    ,t5.cntry_desc as user_cntry_name                     -- Country Name
	,t1.actn_code                                         -- Fee Action Code (This tells you the type of the fee, i.e., FvF, Fixed fee, Ad fee, etc.)
    ,nvl(t2.actn_code_desc,'') as actn_code_desc          -- Fee Action Code description
   
    ,case 
        when length(t1.blng_curncy_id) = 1 then '00'||t1.blng_curncy_id
        when length(t1.blng_curncy_id) = 2 then '0'||t1.blng_curncy_id
        else t1.blng_curncy_id
    end as export_blng_curncy_id                          -- Billing Currency ID of the Seller. This ID value gets padded with "0" as it is required for the file which should be exported and uploaded to the Oracle system (please see "https://wiki.corp.ebay.com/pages/viewpage.action?pageId=269519945#BulkCredit/DebitProcessSubmitterSteps-BCDFilePreparations" page for details)
	
    ,"O" as export_account_type                           -- This is required for the file which should be exported and uploaded to the Oracle system (please see "https://wiki.corp.ebay.com/pages/viewpage.action?pageId=269519945#BulkCredit/DebitProcessSubmitterSteps-BCDFilePreparations" page for details) 
	,t1.user_id||export_blng_curncy_id as export_external_id -- This is required for the file which should be exported and uploaded to the Oracle system (please see "https://wiki.corp.ebay.com/pages/viewpage.action?pageId=269519945#BulkCredit/DebitProcessSubmitterSteps-BCDFilePreparations" page for details)
	,"" as export_category                                -- This is required for the file which should be exported and uploaded to the Oracle system (please see "https://wiki.corp.ebay.com/pages/viewpage.action?pageId=269519945#BulkCredit/DebitProcessSubmitterSteps-BCDFilePreparations" page for details)
	,t4.iso_code as export_curr_id                        -- This is required for the file which should be exported and uploaded to the Oracle system (please see "https://wiki.corp.ebay.com/pages/viewpage.action?pageId=269519945#BulkCredit/DebitProcessSubmitterSteps-BCDFilePreparations" page for details)
	,t4.iso_code_name as blng_curncy_iso_name             -- Billing Currency ISO name (i.e. GBP, USD, EUR, et.)
	,cast(t1.amt_usd as decimal(18,4)) as amt_usd                   -- Charged Fee in USD currency
    ,cast(t1.amt_blng_curncy as decimal(18,4)) as amt_blng_curncy         -- Charged Fee in the Billing Currency of the Seller. If you need see the charged fee amount in Buyer's local currency, then use "trxn_curncy_amt" column
    ,t1.leaf_categ_id                                     -- Leaf Category ID. This can be joined to "DW_CATEGORY_GROUPINGS" table on "LEAF_CATEG_ID" column to get the category name details
    
    from dw_accounts_all as t1
    left join dw_action_codes as t2
    on t1.actn_code = t2.actn_code
    left join dw_users as t3
    on t1.user_id = t3.user_id
	left join dw_currencies as t4
	on t1.blng_curncy_id = t4.curncy_id
	left join dw_countries as t5
	on t1.user_cntry_id = t5.cntry_id
	
    
    where 1=1
    and t1.user_type = 'SELLER'
    --and t1.user_id = 2204968861
    and t3.user_slctd_id in (select distinct seller_name from p_InventoryPlanning_t.seller_list_for_seller_credit)           --Seller names are passed from "Seller Name for Seller Credit Calcualtion" zeta sheet to here
    and cast(t1.acct_trans_date as date) >= '2022-01-01'
    and t1.wacko_yn = 'N'
    and t1.amt_usd != 0
    and t1.actn_code in (1,  139, 140, 198, 245, 305, 409, 474, 504, 508, 526)
    /*
    actn_code lookup
    ----------------
    1: Insertion Fee
    139: Store Fee
	140: Store Fee Credit
	198: Subtitle Fee
    245: CBT (International Listing) Fee
    305: Gallery Plus Fee
    409: Ad Fee Standard
    474: Ad Fee Advanced
    504: Final Value Fee (FvF)
    508: FvF Fixed Fee per Order
    526: Ad Fee Express
    */
)


,category_detail_data as 
(
select
t1.*
,t2.bsns_vrtcl_name                  -- Business vertical (category) name
,t2.meta_categ_name                  -- Meta category name
,t2.categ_lvl2_name                  -- Level 2 category name
from seller_level_fee_data as t1
left join dw_category_groupings as t2
on t1.leaf_categ_id = t2.leaf_categ_id

where 1=1
and t1.actn_code not in (139,140)    -- Store Fee data does not have any category related ids. That's why we exclude them from this join
and t2.site_id = 3  -- This is to only look at the category definition data for the UK website. Otherwise, you will get the same leaf_categ_id value duplicating in the table for different ebay websites (countries)
)

,trnx_level_fee_data as 
(
select 
*
from category_detail_data
where actn_code in (409,474,504,508,526)
)


,listing_level_fee_data as 
(
select 
*
from category_detail_data
where actn_code in (1,198,245,305)
)

,store_level_fee_data as                --Store Level Fee data does not have category id data available. Therefore, we need to calculate the Store fee data at Seller account level. For this reason, we need to separate the seller fee data and union it later on. Otherwise, the category table join causes an issue with this data
(
select 
*
,'None: Store Level Fees' as bsns_vrtcl_name
,'None: Store Level Fees' as meta_categ_name
,'None: Store Level Fees' as categ_lvl2_name
from seller_level_fee_data
where actn_code in (139, 140)
)

,combined_data as 
(
select * from trnx_level_fee_data
union all 
select * from listing_level_fee_data
union all 
select * from store_level_fee_data
)


,gmv_detail_data as 
(
    select
        t1.*
        ,cast(nvl(t2.item_price_amt, 0) as decimal(18,4)) as item_price_amt                           -- Item price amount
        ,nvl(t2.sold_qty, 0) as sold_qty                                                              -- Sold quantity (aggregated value per transaction id)
        ,cast(nvl(t2.gmv20_usd_amt, 0) as decimal(18,4)) as gmv20_usd_amt	                          -- GMV in USD (according to 2.0 definition and aggregared value, i.e. if the item price was $5, and if the buyer has bought 3 items on that transaction, then the GMV value is 3 x $5 = $15)
        ,cast(nvl(t2.gmv20_lstg_curncy_amt, 0) as decimal(18,4)) as gmv20_lstg_curncy_amt             -- GMV in the seller's listing currency (according to 2.0 definition and aggregated value). This is the FXed value of "gmv20_usd_amt" column
        
    from combined_data as t1
    
    left join prs_restricted_v.slng_trans_super_fact as t2
    on  t1.seller_id = t2.slr_id
	and t1.ck_trans_id = t2.ck_trans_id
	and t1.item_id = t2.item_id
	
    -- where 1=1
    -- and t2.ck_trans_dt >= '2022-01-01'
)


select
    t1.*
   
    ,round(nvl(case 
        when t1.actn_code = 504 then abs(t1.amt_usd) / t1.gmv20_usd_amt       
        else 0 
    end,0),6) as actual_fvf_fee_percentage
 
from gmv_detail_data as t1



