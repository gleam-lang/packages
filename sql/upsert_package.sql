-- TODO: insert links and licenses
insert into packages
  ( name
  , description
  , inserted_in_hex_at
  , updated_in_hex_at
  )
values
  ( $1
  , $2
  , $3
  , $4
  )
on conflict (name) do update
set
  updated_in_hex_at = excluded.updated_in_hex_at
, description = excluded.description
returning
  id
