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
  name
, description
, docs_url
, links
, inserted_in_hex_at
, updated_in_hex_at
from
  packages
where
  id = $1
  and id not in retired_package_ids
limit 1;
