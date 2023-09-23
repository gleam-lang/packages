select
  version
from
  releases
where
  package_id = $1
order by
  inserted_in_hex_at desc
limit 5;
