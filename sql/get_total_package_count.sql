select
  count(1)
from
  packages
where
  id not in retired_package_ids;
