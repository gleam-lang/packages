select
  name
, description
, docs_url
, inserted_in_hex_at
, updated_in_hex_at
from
  packages
where
  id = $1
limit 1;
