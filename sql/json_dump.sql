select
  json_agg(row_to_json(packages))
from packages;
