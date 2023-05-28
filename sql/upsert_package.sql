-- TODO: insert links and licenses
insert into packages
  ( name
  , description
  , docs_url
  , inserted_in_hex_at
  , updated_in_hex_at
  )
values
  ( $1
  , $2
  , $3
  , $4
  , $5
  )
on conflict (name) do update
set
  updated_in_hex_at = excluded.updated_in_hex_at
, description = excluded.description
, docs_url = excluded.docs_url
returning
  id
