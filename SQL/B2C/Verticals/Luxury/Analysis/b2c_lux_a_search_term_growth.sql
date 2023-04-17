-- Author: 			Robbie Evans
-- Stakeholder: 	Emma Hamilton, Ines Morais, Alice Bridson
-- Purpose: 		Data for Comms Team on search term growth
-- Date Created: 	31/03/2023



select    
case when AGE_FOR_RTL_WEEK_ID between -4 and -1 then 'Latest Month'
	when AGE_FOR_RTL_WEEK_ID between -8 and -5 then 'Prev Month'
	 End as month_time_frame
, case when AGE_FOR_RTL_WEEK_ID between -52 and -1 then 'Latest Year'
	when AGE_FOR_RTL_WEEK_ID between -104 and -53 then 'Prev Year'
	End as year_timne_frame
,case when lower(src.keyword) like '%mulberry amberly satchel%' then 'mulberry amberly satchel'
	when lower(src.keyword) like '%demellier handbag%' then 'demellier handbag'
	when lower(src.keyword) like '%mayfair midi aspinal of london%' then 'mayfair midi aspinal of london'
	when lower(src.keyword) like '%chanel diana%' then 'chanel diana'
	when lower(src.keyword) like '%gucci bamboo tote%' then 'gucci bamboo tote'
	when lower(src.keyword) like '%launer london handbag%' then 'launer london handbag'
	when lower(src.keyword) like '%mulberry handbag%' then 'mulberry handbag'
	when lower(src.keyword) like '%aspinal of london handbag%' then 'aspinal of london handbag'
	when lower(src.keyword) like '%chanel handbag%' then 'chanel handbag'
	when lower(src.keyword) like '%gucci handbag%' then 'gucci handbag'
	when lower(src.keyword) like '%launer london%' then 'launer london'
	when lower(src.keyword) like '%mulberry%' then 'mulberry'
	when lower(src.keyword) like '%aspinal of london%' then 'aspinal of london'
	when lower(src.keyword) like '%chanel%' then 'chanel'
	when lower(src.keyword) like '%gucci%' then 'gucci'
	when lower(src.keyword) like '%Dior Lady Diana%' then 'Dior Lady Diana'
	when lower(src.keyword) like '%parmigiani fleurier toric chronograph%' then 'parmigiani fleurier toric chronograph'
	when lower(src.keyword) like '%cartier ballon bleu%' then 'cartier ballon bleu'
	when lower(src.keyword) like '%cartier tank francaise%' then 'cartier tank francaise'
	when lower(src.keyword) like '%omega seamaster%' then 'omega seamaster'
	when lower(src.keyword) like '%patek phillipe calatrava%' then 'patek phillipe calatrava'
	when lower(src.keyword) like '%rolex explorer%' then 'rolex explorer'
	when lower(src.keyword) like '%breitling aerospace%' then 'breitling aerospace'
	when lower(src.keyword) like '%cartier watch%' then 'cartier watch'
	when lower(src.keyword) like '%rolex%' then 'rolex'
	when lower(src.keyword) like '%omega%' then 'omega'
	when lower(src.keyword) like '%patek phillipe%' then 'patek phillipe'
	when lower(src.keyword) like '%brietling%' then 'brietling'
	when lower(src.keyword) like '%kiki mcdonough earrings%' then 'kiki mcdonough earrings'
	when lower(src.keyword) like '%kiki mcdonough jewellery%' then 'kiki mcdonough jewellery'
	when lower(src.keyword) like '%van cleef & arpels magic alhambra earrings%' then 'van cleef & arpels magic alhambra earrings'
	when lower(src.keyword) like '%cartier jewellery%' then 'cartier jewellery'
	when lower(src.keyword) like '%boucheron jewellery%' then 'boucheron jewellery'
	when lower(src.keyword) like '%pearl necklace%' then 'pearl necklace'
	when lower(src.keyword) like '%pearl earrings%' then 'pearl earrings'
	when lower(src.keyword) like '%annoushka ring%' then 'annoushka ring'
	when lower(src.keyword) like '%annoushka jewellery%' then 'annoushka jewellery'
	when lower(src.keyword) like '%cartier trinity necklace%' then 'cartier trinity necklace'
	when lower(src.keyword) like '%van cleef & arpels necklace%' then 'van cleef & arpels necklace'
	when lower(src.keyword) like '%van cleef & arpels jewellery%' then 'van cleef & arpels jewellery'
	when lower(src.keyword) like '%diamond earrings%' then 'diamond earrings'
	when lower(src.keyword) like '%diamond necklace%' then 'diamond necklace'
	when lower(src.keyword) like '%diamond bracelet%' then 'diamond bracelet'
	when lower(src.keyword) like '%tennis bracelet%' then 'tennis bracelet'
	when lower(src.keyword) like '%cartier%' then 'cartier'
	when lower(src.keyword) like '%boucheron%' then 'boucheron'
	when lower(src.keyword) like '%van cleef & arpels%' then 'van cleef & arpels'
	when lower(src.keyword) like '%annoushka%' then 'annoushka'
	 End as normalised_keyword
,case when lower(src.keyword) like any ('%mulberry amberly satchel%',
	'%demellier handbag%',
	'%mayfair midi aspinal of london%',
	'%chanel diana%',
	'%gucci bamboo tote%',
	'%launer london handbag%',
	'%mulberry handbag%',
	'%aspinal of london handbag%',
	'%chanel handbag%',
	'%gucci handbag%',
	'%launer london%',
	'%mulberry%',
	'%aspinal of london%',
	'%chanel%',
	'%gucci%',
	'%dior lady diana%')
		then 'Handbags'
	when lower(src.keyword) like any ('%parmigiani fleurier toric chronograph%',
	'%cartier ballon bleu%',
	'%cartier tank francaise%',
	'%omega seamaster%',
	'%patek phillipe calatrava%',
	'%rolex explorer%',
	'%breitling aerospace%',
	'%cartier watch%',
	'%rolex%',
	'%omega%',
	'%patek phillipe%',
	'%brietling%',
	'%breitling%')
		then 'Watches'
	when lower(src.keyword) like any ('%kiki mcdonough earrings%',
	'%kiki mcdonough jewellery%',
	'%van cleef & arpels magic alhambra earrings%',
	'%cartier jewellery%',
	'%boucheron jewellery%',
	'%pearl necklace%',
	'%pearl earrings%',
	'%annoushka ring%',
	'%annoushka jewellery%',
	'%cartier trinity necklace%',
	'%van cleef & arpels necklace%',
	'%van cleef & arpels jewellery%',
	'%diamond earrings%',
	'%diamond necklace%',
	'%diamond bracelet%',
	'%tennis bracelet%',
	'%cartier%',
	'%boucheron%',
	'%van cleef & arpels%',
	'%annoushka%')
		Then 'Jewellery'
	End as category
,count(*) as src_cnt 
,count(DISTINCT src.SESSION_SKEY) as visits

from  access_views.SRCH_KEYWORDS_EXT_FACT src 
inner join DW_CAL_DT cal
	on src.SESSION_START_DT = cal.CAL_DT
	and cal.AGE_FOR_RTL_WEEK_ID between -104 and -1

where src.site_id = 3 
and lower(src.KEYWORD) like any ( 
	'%mulberry amberly satchel%',
	'%demellier handbag%',
	'%mayfair midi aspinal of london%',
	'%chanel diana%',
	'%gucci bamboo tote%',
	'%launer london handbag%',
	'%mulberry handbag%',
	'%aspinal of london handbag%',
	'%chanel handbag%',
	'%gucci handbag%',
	'%launer london%',
	'%mulberry%',
	'%aspinal of london%',
	'%chanel%',
	'%gucci%',
	'%dior lady diana%',
	'%parmigiani fleurier toric chronograph%',
	'%cartier ballon bleu%',
	'%cartier tank francaise%',
	'%omega seamaster%',
	'%patek phillipe calatrava%',
	'%rolex explorer%',
	'%breitling aerospace%',
	'%cartier watch%',
	'%rolex%',
	'%omega%',
	'%patek phillipe%',
	'%brietling%',
	'%kiki mcdonough earrings%',
	'%kiki mcdonough jewellery%',
	'%van cleef & arpels magic alhambra earrings%',
	'%cartier jewellery%',
	'%boucheron jewellery%',
	'%pearl necklace%',
	'%pearl earrings%',
	'%annoushka ring%',
	'%annoushka jewellery%',
	'%cartier trinity necklace%',
	'%van cleef & arpels necklace%',
	'%van cleef & arpels jewellery%',
	'%diamond earrings%',
	'%diamond necklace%',
	'%diamond bracelet%',
	'%tennis bracelet%',
	'%cartier%',
	'%boucheron%',
	'%van cleef & arpels%',
	'%annoushka%'
)



group by 1,2,3,4

;



