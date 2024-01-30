select
  id
, name
, description
, docs_url
, links
, updated_in_hex_at
from
  packages
where
  (
    $1 = ''
    or rowid in (
      select rowid
      from packages_fts
      where packages_fts match $1
    )
  )
  and not exists (
    select 1
    from hidden_packages
    where hidden_packages.name = packages.name
  )
  and id not in retired_package_ids
group by
  packages.id
order by
  packages.updated_in_hex_at desc
limit 1000;
