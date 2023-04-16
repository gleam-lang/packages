select
  floor(extract('epoch' from timestamp))::bigint as timestamp
from most_recent_hex_timestamp
limit 1
