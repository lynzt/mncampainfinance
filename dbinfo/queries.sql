select city, zip, count(*) as zip_count from companies 
group by zip
order by zip_count desc
;