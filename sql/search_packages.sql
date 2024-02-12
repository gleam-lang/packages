select
  id
, name
, description
, docs_url
, links
, updated_in_hex_at
from
  non_retired_packages p
where
  (
    $1 = ''
    or id in (
      select rowid
      from packages_fts
      where packages_fts match $1
    )
  )
  and not exists (
    select 1
    from hidden_packages
    where hidden_packages.name = p.name
  )
group by
  p.id
order by
  p.updated_in_hex_at desc
limit 1000;
