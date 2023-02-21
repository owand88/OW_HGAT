SELECT
seller_id
,case when b.USER_DSGNTN_ID = 2 then 'B2C' else 'C2C' End as SELLER_TYPE
,RETAIL_YEAR
,CATEG_LVL2_NAME
,BRAND_CLEAN
,BRAND_RAW
,PRICE_TRANCHE
,SLR_UK_FLAG
,METAL_LIST
,METAL
,METAL_PURITY
,MAIN_STONE
,MAIN_STONE_LIST
,BRAND
,SECONDARY_STONE
,SECONDARY_STONE_LIST
,SUM(GMV_USD) AS GMV_USD
,SUM(SI) AS SI
,SUM(LL) AS LL
FROM
(
	SELECT
	SELLER_ID
	,RETAIL_YEAR
	,CATEG_LVL2_NAME
	,BRAND as BRAND_RAW
	,BRAND_CLEAN
	,ASP_BUCKET AS PRICE_TRANCHE
	,CASE 	WHEN SLR_CNTRY_ID=3 THEN 'UK' ELSE 'NON-UK' END AS SLR_UK_FLAG
	,CASE WHEN LOWER(METAL) in ('gold') or LOWER(METAL) like any ("%yellow gold%","%yellow gold plated%","%white gold%","%white gold plated%","%rose gold%","%multi-tone gold%","%platinum%","%platinum plated%","%silver%","%fine silver%","%sterling silver%","%palladium%","%palladium plated%","%rhodium%","%rhodium plated%") THEN LOWER(METAL)
		ELSE "others" END AS METAL_LIST
	,CASE WHEN LOWER(METAL) in ('gold') or LOWER(METAL) like any ("%yellow gold%","%yellow gold plated%","%white gold%","%white gold plated%","%rose gold%","%multi-tone gold%","%platinum%","%platinum plated%","%silver%","%fine silver%","%sterling silver%","%palladium%","%palladium plated%","%rhodium%","%rhodium plated%") THEN 'eligible'
		ELSE "others" END AS METAL
	,CASE WHEN (LOWER(METAL_PURITY) LIKE ANY("%9k%","%10k%","%12k%","%14k%","%18k%","%20k%","%21k%","%22k%","%24k%","%925%","%950%","%900%","%999%","%935%","%750%","%585%","%9ct%","%10ct%","%12ct%","%14ct%","%18ct%","%20ct%","%21ct%","%22ct%","%24ct%","%9 ct%","%10 ct%","%12 ct%","%14 ct%","%18 ct%","%20 ct%","%21 ct%","%22 ct%","%24 ct%","%9carat%","%9 carat%","%10carat%","%10 carat%","%12carat%","%12 carat%","%14carat%","%14 carat%","%18carat%","%18 carat%","%20carat%","%20 carat%","%21carat%","%21 carat%","%22carat%","%22 carat%","%24carat%","%24 carat%","%sterling%","%platinum%")) THEN "eligible" ELSE "others" END AS METAL_PURITY
	,CASE WHEN LOWER(MAIN_STONE) like any ("%diamond%","no stone","%sapphire%","%emerald%","%ruby%","unspecified","unknown","%alexandrite%","%spinel%","%tourmaline%","%topaz%","%tanzanite%","%peridot%","%garnet%","%aquamarine%","%morganite%","%chrysoberyl%","%moissanite%","%mother of pearl/abalone%") THEN 'Approved main stones'
		WHEN MAIN_STONE IS NULL THEN "null"
		ELSE "others" END AS MAIN_STONE
	,CASE WHEN LOWER(MAIN_STONE) like any ("%diamond%","no stone","%sapphire%","%emerald%","%ruby%","unspecified","unknown","%alexandrite%","%spinel%","%tourmaline%","%topaz%","%tanzanite%","%peridot%","%garnet%","%aquamarine%","%morganite%","%chrysoberyl%","%moissanite%","%mother of pearl/abalone%") THEN LOWER(MAIN_STONE)
		WHEN MAIN_STONE IS NULL THEN "null"
		ELSE "others" END AS MAIN_STONE_LIST
	,CASE WHEN LOWER(SECONDARY_STONE) like any ("%diamond%","no stone","%sapphire%","%emerald%","%ruby%","unspecified","unknown","%alexandrite%","%spinel%","%tourmaline%","%topaz%","%tanzanite%","%peridot%","%garnet%","%aquamarine%","%morganite%","%chrysoberyl%","%moissanite%","%mother of pearl/abalone%") THEN 'eligible' WHEN SECONDARY_STONE IS NULL THEN "null"
	WHEN LOWER(SECONDARY_STONE) like any ("%pearl%","%turquoise%","%amethyst%","%opal%","%citrine%","%jade%","%jadeite%","%south sea pearl%","%quartz%","%tahitian pearl%","%amber%","%akoya pearl%","%smoky quartz%","%freshwater pearl%","%rose quartz%","%fire opal%","%jadeite jade%","%jade jadeite%","%pearls%","%mabe pearl%","%rutilated quartz%","%lemon quartz%","%nephrite%","%green amethyst/prasiolite%","%rock crystal%","%doublet opal%","%boulder opal%","%black opal%","%ametrine%","%freshwater cultured pearl%","%welo opal%","%rhinestone%","%tiger's eye%","%tiger eye%") THEN 'ineligible' else 'other eligible' END AS SECONDARY_STONE
	,CASE WHEN LOWER(SECONDARY_STONE) like any ("%diamond%","no stone","%sapphire%","%emerald%","%ruby%","unspecified","unknown","%alexandrite%","%spinel%","%tourmaline%","%topaz%","%tanzanite%","%peridot%","%garnet%","%aquamarine%","%morganite%","%chrysoberyl%","%moissanite%","%mother of pearl/abalone%") THEN LOWER(SECONDARY_STONE) WHEN SECONDARY_STONE IS NULL THEN "null"
	WHEN LOWER(SECONDARY_STONE) like any ("%pearl%","%turquoise%","%amethyst%","%opal%","%citrine%","%jade%","%jadeite%","%south sea pearl%","%quartz%","%tahitian pearl%","%amber%","%akoya pearl%","%smoky quartz%","%freshwater pearl%","%rose quartz%","%fire opal%","%jadeite jade%","%jade jadeite%","%pearls%","%mabe pearl%","%rutilated quartz%","%lemon quartz%","%nephrite%","%green amethyst/prasiolite%","%rock crystal%","%doublet opal%","%boulder opal%","%black opal%","%ametrine%","%freshwater cultured pearl%","%welo opal%","%rhinestone%","%tiger's eye%","%tiger eye%") THEN 'ineligible' else 'other eligible' END AS SECONDARY_STONE_LIST
			,CASE	WHEN BRAND_CLEAN IN ("TIFFANY & CO.","CARTIER",'CHANEL','VAN CLEEF',"BVLGARI","BULGARI",'CHOPARD') THEN "AUTHORISED BRANDS"
			WHEN BRAND_CLEAN IN ("PANDORA","LINK",'GEORGE JENSEN', 'PIAGET','VIVIENNE WESTWOOD', 'SWAROVSKI', 'CLOGAU','BOODLES','GRAFF','ASKEW') THEN "NOT ELIGIBLE BRANDS"
			WHEN BRAND_CLEAN IN ('unbranded') then 'unbranded'
			WHEN BRAND_CLEAN IN ('null') then 'null'
			ELSE "OTHERS" END AS BRAND
	,SUM(GMV) AS GMV_USD
	,SUM(SI) AS SI
	,0 AS LL
	FROM  p_robevans_t.JEWELRY_PSA_ASPECT_EXPLORATION_TRANS_Aug_ATTR a
	INNER JOIN ACCESS_VIEWS.DW_CAL_DT cal
		on a.created_dt = cal.CAL_DT
		and cal.retail_year in (2021,2022)
	WHERE ORDER_CREATED_FLAG=1
	AND SITE_ID IN (3)
	GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15
	
	UNION ALL
	
	SELECT
	SLR_ID AS SELLER_ID
	,null as RETAIL_YEAR
	,CATEG_LVL2_NAME
	,BRAND as BRAND_RAW
	,BRAND_CLEAN
	,ASP_BUCKET AS PRICE_TRANCHE
	,CASE 	WHEN SLR_CNTRY_ID=3 THEN 'UK' ELSE 'NON-UK' END AS SLR_UK_FLAG
	,CASE WHEN LOWER(METAL) in ('gold') or LOWER(METAL) like any ("%yellow gold%","%yellow gold plated%","%white gold%","%white gold plated%","%rose gold%","%multi-tone gold%","%platinum%","%platinum plated%","%silver%","%fine silver%","%sterling silver%","%palladium%","%palladium plated%","%rhodium%","%rhodium plated%") THEN LOWER(METAL)
		ELSE "others" END AS METAL_LIST
	,CASE WHEN LOWER(METAL) in ('gold') or LOWER(METAL) like any ("%yellow gold%","%yellow gold plated%","%white gold%","%white gold plated%","%rose gold%","%multi-tone gold%","%platinum%","%platinum plated%","%silver%","%fine silver%","%sterling silver%","%palladium%","%palladium plated%","%rhodium%","%rhodium plated%") THEN 'eligible'
		ELSE "others" END AS METAL
	,CASE WHEN (LOWER(METAL_PURITY) LIKE ANY("%9k%","%10k%","%12k%","%14k%","%18k%","%20k%","%21k%","%22k%","%24k%","%925%","%950%","%900%","%999%","%935%","%750%","%585%","%9ct%","%10ct%","%12ct%","%14ct%","%18ct%","%20ct%","%21ct%","%22ct%","%24ct%","%9 ct%","%10 ct%","%12 ct%","%14 ct%","%18 ct%","%20 ct%","%21 ct%","%22 ct%","%24 ct%","%9carat%","%9 carat%","%10carat%","%10 carat%","%12carat%","%12 carat%","%14carat%","%14 carat%","%18carat%","%18 carat%","%20carat%","%20 carat%","%21carat%","%21 carat%","%22carat%","%22 carat%","%24carat%","%24 carat%","%sterling%","%platinum%")) THEN "eligible" ELSE "others" END AS METAL_PURITY
	,CASE WHEN LOWER(MAIN_STONE) like any ("%diamond%","no stone","%sapphire%","%emerald%","%ruby%","unspecified","unknown","%alexandrite%","%spinel%","%tourmaline%","%topaz%","%tanzanite%","%peridot%","%garnet%","%aquamarine%","%morganite%","%chrysoberyl%","%moissanite%","%mother of pearl/abalone%") THEN 'Approved main stones'
		WHEN MAIN_STONE IS NULL THEN "null"
		ELSE "others" END AS MAIN_STONE
	,CASE WHEN LOWER(MAIN_STONE) like any ("%diamond%","no stone","%sapphire%","%emerald%","%ruby%","unspecified","unknown","%alexandrite%","%spinel%","%tourmaline%","%topaz%","%tanzanite%","%peridot%","%garnet%","%aquamarine%","%morganite%","%chrysoberyl%","%moissanite%","%mother of pearl/abalone%") THEN LOWER(MAIN_STONE)
		WHEN MAIN_STONE IS NULL THEN "null"
		ELSE "others" END AS MAIN_STONE_LIST
	,CASE WHEN LOWER(SECONDARY_STONE) like any ("%diamond%","no stone","%sapphire%","%emerald%","%ruby%","unspecified","unknown","%alexandrite%","%spinel%","%tourmaline%","%topaz%","%tanzanite%","%peridot%","%garnet%","%aquamarine%","%morganite%","%chrysoberyl%","%moissanite%","%mother of pearl/abalone%") THEN 'eligible' WHEN SECONDARY_STONE IS NULL THEN "null"
	WHEN LOWER(SECONDARY_STONE) like any ("%pearl%","%turquoise%","%amethyst%","%opal%","%citrine%","%jade%","%jadeite%","%south sea pearl%","%quartz%","%tahitian pearl%","%amber%","%akoya pearl%","%smoky quartz%","%freshwater pearl%","%rose quartz%","%fire opal%","%jadeite jade%","%jade jadeite%","%pearls%","%mabe pearl%","%rutilated quartz%","%lemon quartz%","%nephrite%","%green amethyst/prasiolite%","%rock crystal%","%doublet opal%","%boulder opal%","%black opal%","%ametrine%","%freshwater cultured pearl%","%welo opal%","%rhinestone%","%tiger's eye%","%tiger eye%") THEN 'ineligible' else 'other eligible' END AS SECONDARY_STONE
	,CASE WHEN LOWER(SECONDARY_STONE) like any ("%diamond%","no stone","%sapphire%","%emerald%","%ruby%","unspecified","unknown","%alexandrite%","%spinel%","%tourmaline%","%topaz%","%tanzanite%","%peridot%","%garnet%","%aquamarine%","%morganite%","%chrysoberyl%","%moissanite%","%mother of pearl/abalone%") THEN LOWER(SECONDARY_STONE) WHEN SECONDARY_STONE IS NULL THEN "null"
	WHEN LOWER(SECONDARY_STONE) like any ("%pearl%","%turquoise%","%amethyst%","%opal%","%citrine%","%jade%","%jadeite%","%south sea pearl%","%quartz%","%tahitian pearl%","%amber%","%akoya pearl%","%smoky quartz%","%freshwater pearl%","%rose quartz%","%fire opal%","%jadeite jade%","%jade jadeite%","%pearls%","%mabe pearl%","%rutilated quartz%","%lemon quartz%","%nephrite%","%green amethyst/prasiolite%","%rock crystal%","%doublet opal%","%boulder opal%","%black opal%","%ametrine%","%freshwater cultured pearl%","%welo opal%","%rhinestone%","%tiger's eye%","%tiger eye%") THEN 'ineligible' else 'other eligible' END AS SECONDARY_STONE_LIST
			,CASE	WHEN BRAND_CLEAN IN ("TIFFANY & CO.","CARTIER",'CHANEL','VAN CLEEF',"BVLGARI","BULGARI",'CHOPARD') THEN "AUTHORISED BRANDS"
			WHEN BRAND_CLEAN IN ("PANDORA","LINK",'GEORGE JENSEN', 'PIAGET','VIVIENNE WESTWOOD', 'SWAROVSKI', 'CLOGAU','BOODLES','GRAFF','ASKEW') THEN "NOT ELIGIBLE BRANDS"
			WHEN BRAND_CLEAN IN ('unbranded') then 'unbranded'
			WHEN BRAND_CLEAN IN ('null') then 'null'
			ELSE "OTHERS" END AS BRAND
	,0 AS GMV_USD
	,0 AS SI
	,COUNT(DISTINCT(ITEM_ID)) AS LL
	FROM  P_ROBEVANS_T.JEWELRY_PSA_ASPECT_EXPLORATION_LL_Aug_ATTR a
	WHERE LSTG_SITE_UK_FLAG="UK"
	GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15
) a 
LEFT JOIN ACCESS_VIEWS.DW_USERS b on a.seller_id = b.user_id
GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16;
