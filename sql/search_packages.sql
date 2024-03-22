select
  id
, name
, description
, docs_url
, links
, updated_in_hex_at
from
  visible_packages p
where
  (
    $1 = ''
    or instr(lower(name), $2) > 0
    or instr(lower(description), $2) > 0
    or id in (
      select rowid
      from packages_fts
      where packages_fts match $1
    )
  )
group by
  p.id
order by
  p.updated_in_hex_at desc
limit 1000;
