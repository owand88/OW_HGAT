/*
Jira: UKPLAN-89

Author: Tugrul Ates

Date: 2022-12-19

Description: This scripts extracts the seller fee and category detail data whic then will be used to calculate seller credits
due to an issue happened on ebay side.

For example, the seller was supposed to pay 5% FvF fee as per their pricing contract with ebay, but they ended up paying 9% FvF.
Therefore, ebay has to issue a credit to that seller.

Report Parameters:
- Seller name
- Start date
- End date
- Agreed FvF%
- Agreed Fixed Fee (£) (with default value of £0.25)

Report Filters:
- Vertical
- Meta category
- L2 category

TO-DOs:
-------
* Allow users to choose their Country ID (or country name)
* Do not restrict the action codes for this data, allow users to filter them on the dashboard
* Add Account Currency Code (this is also the local charged currency code for billing)
* Speak to Ege to understand the cost offer thresholds (i.e. upto £400 the cost is 9% and 2% over £400 spend, etc.)
* Add the columns that are required in the export file
* Test commit line to check Jira-Github integration
*/

create view p_InventoryPlanning_t.vw_seller_credit_calculation as

with seller_fee_data as 
(
    select
    distinct t1.user_id as seller_id                         -- Seller ID
    ,t3.user_slctd_id as seller_name                                    -- Seller Name
    ,t1.item_id                                           -- Item ID (or Listing ID)
    ,t1.ck_trans_id                                       -- Transaction ID (this is 0 for Insertion Fee related rows)
    ,t1.acct_trans_id                                     -- Billing Fee Transaction ID of the Seller
    ,t1.acct_trans_date                                   -- Transaction timestamp
    ,t1.user_cntry_id                                     -- Country ID (3 for UK)
    ,t1.actn_code                                         -- Fee Action Code (This tells you the type of the fee, i.e., FvF, Fixed fee, Ad fee, etc.)
    ,nvl(t2.actn_code_desc,'') as actn_code_desc          -- Fee Action Code description
   
    ,case 
        when length(t1.blng_curncy_id) = 1 then '00'||t1.blng_curncy_id
        when length(t1.blng_curncy_id) = 2 then '0'||t1.blng_curncy_id
        else t1.blng_curncy_id
    end as blng_curncy_id                                 -- Billing Currency ID of the Seller
   
    ,cast(t1.amt_usd as decimal(18,4))                                           -- Charged Fee in USD currency
    ,cast(t1.amt_blng_curncy as decimal(18,4))                                   -- Charged Fee in the Billing Currency of the Seller. If you need see the charged fee amount in Buyer's local currency, then use "trxn_curncy_amt" column
    ,t1.leaf_categ_id                                     -- Leaf Category ID. This can be joined to "DW_CATEGORY_GROUPINGS" table on "LEAF_CATEG_ID" column to get the category name details
    
    from dw_accounts_all as t1
    left join dw_action_codes as t2
    on t1.actn_code = t2.actn_code
    inner join dw_users as t3
    on t1.user_id = t3.user_id
    
    where 1=1
    and t1.user_type = 'SELLER'
    --and t1.user_id = 2204968861
    --and t3.user_slctd_id = <Parameters.Seller Name>
    and cast(t1.acct_trans_date as date) >= '2022-01-01'
    --and cast(t1.acct_trans_date as date) <= <Parameters.End Date>
    and t1.wacko_yn = 'N'
    and t1.amt_usd != 0
    and t1.actn_code in (1, 409, 474, 504, 508, 526)
    /*
    actn_code lookup
    ----------------
    1: Insertion Fee
    409: Ad Fee Standard
    474: Ad Fee Advanced
    504: Final Value Fee (FvF)
    508: FvF Fixed Fee per Order
    526: Ad Fee Express
    */
)

,gmv_detail_data as 
(
    select
        t1.*
        ,cast(nvl(t2.item_price_amt, 0) as decimal(18,4)) as item_price_amt                          -- Item price amount
        ,nvl(t2.sold_qty, 0) as sold_qty                                      -- Sold quantity (aggregated value per transaction id)
        ,cast(nvl(t2.gmv20_usd_amt, 0) as decimal(18,4)) as gmv20_usd_amt	                          -- GMV in USD (according to 2.0 definition and aggregared value, i.e. if the item price was $5, and if the buyer has bought 3 items on that transaction, then the GMV value is 3 x $5 = $15)
        ,cast(nvl(t2.gmv20_lstg_curncy_amt, 0) as decimal(18,4)) as gmv20_lstg_curncy_amt            -- GMV in the seller's listing currency (according to 2.0 definition and aggregated value). This is the FXed value of "gmv20_usd_amt" column
        
    from seller_fee_data as t1
    
    left join prs_restricted_v.slng_trans_super_fact as t2
    on t1.item_id = t2.item_id
    and t1.ck_trans_id = t2.ck_trans_id
    and t1.seller_id = t2.slr_id
    
    where 1=1
    and t2.ck_trans_dt >= '2022-01-01'
    --and t2.ck_trans_dt <= <Parameters.End Date>
)

,category_detail_data as 
(
select
t1.*
,t2.bsns_vrtcl_name                  -- Business vertical (category) name
,t2.meta_categ_name                  -- Meta category name
,t2.categ_lvl2_name                  -- Level 2 category name
from gmv_detail_data as t1
left join dw_category_groupings as t2
on t1.leaf_categ_id = t2.leaf_categ_id

where 1=1
and t2.site_id = 3  -- This is to only look at the category definition data for the UK website. Otherwise, you will get the same leaf_categ_id value duplicating in the table for different ebay websites (countries)
)



select
    t1.*
   
    ,round(nvl(case 
        when t1.actn_code = 504 then abs(t1.amt_usd) / t1.gmv20_usd_amt       
        else 0 
    end,0),6) as actual_fvf_fee_percentage
   
    -- ,nvl(case
    --     when t1.actn_code = 504 then cast((1 - ${agreed_fvf_fee_percentage} / actual_fvf_fee_percentage) * abs(t1.amt_usd) as decimal(18,4))        -- As "t1.amt_usd" is all negative values in the table, we need to use their absolute values for this calculation
    --     else 0
    -- end,0) as seller_fvf_fee_credit_usd_amt
   
    -- ,nvl(case
    --     when t1.actn_code = 504 then cast((1 - ${agreed_fvf_fee_percentage} / actual_fvf_fee_percentage) * abs(t1.amt_blng_curncy) as decimal(18,4))         -- As "t1.amt_blng_curncy" is all negative values in the table, we need to use their absolute values for this calculation
    --     else 0
    -- end,0) as seller_fvf_fee_credit_lstg_curcny_amt
   
    -- ,nvl(case
    --     when t1.actn_code = 508 then  cast(abs(t1.amt_blng_curncy) - ${agreed_fixed_fee_listing_currency_amount} as decimal(18,4))        -- As "t1.amt_blng_curncy" is all negative values in the table, we need to use their absolute values for this calculation
    --     else 0
    -- end,0) as seller_fixed_fee_credit_lstg_curcny_amt

from category_detail_data as t1



