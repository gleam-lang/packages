select
  name
, description
from
  packages
where
  id = $1
order by
  updated_in_hex_at
limit 500;
