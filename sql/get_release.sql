select
  package_id
, version
, retirement_reason
, retirement_message
, inserted_in_hex_at
, updated_in_hex_at
from
  releases
where
  id = $1
limit 1;
