select
  name
, description
, inserted_in_hex_at
, updated_in_hex_at
from
  packages
where
  id = $1
limit 1;
