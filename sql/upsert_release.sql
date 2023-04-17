insert into packages
  ( package_id
  , version
  , hex_url
  , retirement_reason
  , retirement_message
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
  hex_html_url = excluded.hex_html_url
, docs_html_url = excluded.docs_html_url
, updated_in_hex_at = excluded.updated_in_hex_at
, description = excluded.description
returning
  id
