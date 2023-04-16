select
  name
, description
, hex_html_url
, docs_html_url
, extract('epoch' from inserted_in_hex_at)::bigint as inserted_in_hex_at
, extract('epoch' from inserted_in_hex_at)::bigint as inserted_in_hex_at
from
  packages
where
  id = $1
limit 1;
