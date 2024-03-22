select
  strftime('%Y-%m-%d', datetime(inserted_in_hex_at, 'unixepoch')) as creation_date
, count(*) as count
from
  releases
group by
  creation_date
order by 
  inserted_in_hex_at asc;
