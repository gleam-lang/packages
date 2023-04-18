insert into releases
  ( package_id
  , version
  , retirement_reason
  , retirement_message
  , inserted_in_hex_at
  , updated_in_hex_at
  )
values
  ( $1
  , $2
  , $3
  , $4
  , $5
  , $6
  )
on conflict (package_id, version) do update
set
  version = excluded.version
, retirement_reason = excluded.retirement_reason
, retirement_message = excluded.retirement_message
, inserted_in_hex_at = excluded.inserted_in_hex_at
, updated_in_hex_at = excluded.updated_in_hex_at
returning
  id
