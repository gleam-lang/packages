select
  name
, description
, hex_html_url
, docs_html_url
, inserted_in_hex_at
, inserted_in_hex_at
from
  packages
where
  id = $1
limit 1;
