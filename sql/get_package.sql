with
  retired_package_ids as (
    -- A package is retired if its latest release is retired
    select package_id from (
      select
        package_id
        , retirement_reason
      from
        releases
      group by
        package_id
      having
        max(inserted_in_hex_at)
    )
    where
      retirement_reason is not null
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
