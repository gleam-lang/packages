-- TODO: insert links and licenses
insert into packages
  ( name
  , description
  , hex_html_url
  , docs_html_url
  , inserted_in_hex_at
  , updated_in_hex_at
  )
values
  ( $1
  , $2
  , $3
  , $4
  , to_timestamp($5)
  , to_timestamp($6)
  )
on conflict (name) do update
set
  hex_html_url = excluded.hex_html_url
, docs_html_url = excluded.docs_html_url
, updated_in_hex_at = excluded.updated_in_hex_at
, description = excluded.description
returning
  id
