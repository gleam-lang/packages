with
  retired_package_ids as (
    select r.package_id from releases r where exists (
      select
        1
      from
        releases
      where
        r.package_id = package_id
        and retirement_message is not null
    )
  )
select
  count(1)
from
  packages
where
  id not in retired_package_ids;
