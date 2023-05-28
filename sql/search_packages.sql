select
  packages.name
, description
, docs_url
, array_agg(latest_releases.version) as latest_releases
, packages.updated_in_hex_at
from
  packages,
  lateral (
    select version
    from releases
    where package_id = packages.id
    order by releases.inserted_in_hex_at desc
    limit 5
  ) as latest_releases
where
  (
    $1 = ''
    or to_tsvector(packages.name || ' ' || packages.description) @@ websearch_to_tsquery($1)
  )
  and not exists (
    select 1
    from hidden_packages
    where hidden_packages.name = packages.name
  )
group by
  packages.id
order by
  packages.updated_in_hex_at desc
limit 1000;
