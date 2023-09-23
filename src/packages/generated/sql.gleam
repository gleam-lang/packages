// THIS FILE IS GENERATED. DO NOT EDIT. 
// Regenerate with `gleam run -m codegen`

import sqlight
import gleam/result
import gleam/dynamic
import packages/error.{Error}

pub type QueryResult(t) =
  Result(List(t), Error)

pub fn upsert_release(
  db: sqlight.Connection,
  arguments: List(sqlight.Value),
  decoder: dynamic.Decoder(a),
) -> QueryResult(a) {
  let query =
    "insert into releases
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
"
  sqlight.query(query, db, arguments, decoder)
  |> result.map_error(error.DatabaseError)
}

pub fn upsert_most_recent_hex_timestamp(
  db: sqlight.Connection,
  arguments: List(sqlight.Value),
  decoder: dynamic.Decoder(a),
) -> QueryResult(a) {
  let query =
    "insert into most_recent_hex_timestamp
  (id, unix_timestamp)
values
  (1, $1)
on conflict (id) do update
set
  unix_timestamp = $1;
"
  sqlight.query(query, db, arguments, decoder)
  |> result.map_error(error.DatabaseError)
}

pub fn upsert_hex_user(
  db: sqlight.Connection,
  arguments: List(sqlight.Value),
  decoder: dynamic.Decoder(a),
) -> QueryResult(a) {
  let query =
    "-- Insert or update a hex_user record.
-- If the username is already in use, update the email and hex_url.
insert into hex_user
  (username, email, hex_url)
values
  ($1, $2, $3)
on conflict (username) do update
set
  email = excluded.email
, hex_url = excluded.hex_url
returning
  id
"
  sqlight.query(query, db, arguments, decoder)
  |> result.map_error(error.DatabaseError)
}

pub fn get_package(
  db: sqlight.Connection,
  arguments: List(sqlight.Value),
  decoder: dynamic.Decoder(a),
) -> QueryResult(a) {
  let query =
    "select
  name
, description
, docs_url
, links
, inserted_in_hex_at
, updated_in_hex_at
from
  packages
where
  id = $1
limit 1;
"
  sqlight.query(query, db, arguments, decoder)
  |> result.map_error(error.DatabaseError)
}

pub fn get_most_recent_hex_timestamp(
  db: sqlight.Connection,
  arguments: List(sqlight.Value),
  decoder: dynamic.Decoder(a),
) -> QueryResult(a) {
  let query =
    "select
  unix_timestamp
from most_recent_hex_timestamp
limit 1
"
  sqlight.query(query, db, arguments, decoder)
  |> result.map_error(error.DatabaseError)
}

pub fn get_total_package_count(
  db: sqlight.Connection,
  arguments: List(sqlight.Value),
  decoder: dynamic.Decoder(a),
) -> QueryResult(a) {
  let query =
    "select
  count(1)
from
  packages;
"
  sqlight.query(query, db, arguments, decoder)
  |> result.map_error(error.DatabaseError)
}

pub fn search_packages(
  db: sqlight.Connection,
  arguments: List(sqlight.Value),
  decoder: dynamic.Decoder(a),
) -> QueryResult(a) {
  let query =
    "select
  name
, description
, docs_url
, links
, updated_in_hex_at
from
  packages
where
  (
    $1 = ''
    or rowid in (
      select rowid
      from packages_fts
      where packages_fts match $1
    )
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
"
  sqlight.query(query, db, arguments, decoder)
  |> result.map_error(error.DatabaseError)
}

pub fn get_release(
  db: sqlight.Connection,
  arguments: List(sqlight.Value),
  decoder: dynamic.Decoder(a),
) -> QueryResult(a) {
  let query =
    "select
  package_id
, version
, retirement_reason
, retirement_message
, inserted_in_hex_at
, updated_in_hex_at
from
  releases
where
  id = $1
limit 1;
"
  sqlight.query(query, db, arguments, decoder)
  |> result.map_error(error.DatabaseError)
}

pub fn json_dump(
  db: sqlight.Connection,
  arguments: List(sqlight.Value),
  decoder: dynamic.Decoder(a),
) -> QueryResult(a) {
  let query =
    "select
  json_agg(row_to_json(packages))
from packages;
"
  sqlight.query(query, db, arguments, decoder)
  |> result.map_error(error.DatabaseError)
}

pub fn upsert_package(
  db: sqlight.Connection,
  arguments: List(sqlight.Value),
  decoder: dynamic.Decoder(a),
) -> QueryResult(a) {
  let query =
    "-- TODO: insert links and licenses
insert into packages
  ( name
  , description
  , docs_url
  , links
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
on conflict (name) do update
set
  updated_in_hex_at = excluded.updated_in_hex_at
, description = excluded.description
, docs_url = excluded.docs_url
, links = excluded.links
returning
  id
"
  sqlight.query(query, db, arguments, decoder)
  |> result.map_error(error.DatabaseError)
}
