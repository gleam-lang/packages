-- TODO: insert links and licenses
insert into packages
  ( name
  , description
  , docs_url
  , links
  , inserted_in_hex_at
  , updated_in_hex_at
  , downloads_all
  , downloads_recent
  , downloads_week
  , downloads_day
  )
values
  ( $1
  , $2
  , $3
  , $4
  , $5
  , $6
  , $7
  , $8
  , $9
  , $10
  )
on conflict (name) do update
set
  updated_in_hex_at = excluded.updated_in_hex_at
, description = excluded.description
, docs_url = excluded.docs_url
, links = excluded.links
, downloads_all = excluded.downloads_all
, downloads_recent = excluded.downloads_recent
, downloads_week = excluded.downloads_week
, downloads_day = excluded.downloads_day
returning
  id
