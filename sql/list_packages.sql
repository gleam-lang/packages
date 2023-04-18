select
  packages.name
, description
, array_agg(latest_releases.version) as latest_releases
from
  packages,
  lateral (
    select version
    from releases
    where package_id = packages.id
    order by releases.inserted_in_hex_at desc
    limit 5
  ) as latest_releases
group by
  packages.id
order by
  packages.updated_in_hex_at desc
limit 500;
