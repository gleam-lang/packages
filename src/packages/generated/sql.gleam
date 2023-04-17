// THIS FILE IS GENERATED. DO NOT EDIT. 
// Regenerate with `gleam run -m codegen`

import gleam/pgo
import gleam/result
import gleam/dynamic
import packages/error.{Error}

pub type QueryResult(t) =
  Result(pgo.Returned(t), Error)

pub fn upsert_release(
  db: pgo.Connection,
  arguments: List(pgo.Value),
  decoder: dynamic.Decoder(a),
) -> QueryResult(a) {
  let query =
    "insert into releases
  ( package_id
  , version
  , hex_url
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
  , $7
  )
on conflict (package_id, version) do update
set
  version = excluded.version
, hex_url = excluded.hex_url
, retirement_reason = excluded.retirement_reason
, retirement_message = excluded.retirement_message
, inserted_in_hex_at = excluded.inserted_in_hex_at
, updated_in_hex_at = excluded.updated_in_hex_at
returning
  id
"
  pgo.execute(query, db, arguments, decoder)
  |> result.map_error(error.DatabaseError)
}

pub fn upsert_most_recent_hex_timestamp(
  db: pgo.Connection,
  arguments: List(pgo.Value),
  decoder: dynamic.Decoder(a),
) -> QueryResult(a) {
  let query =
    "insert into most_recent_hex_timestamp
  (id, unix_timestamp)
values
  (true, $1)
on conflict (id) do update
set
  unix_timestamp = $1;
"
  pgo.execute(query, db, arguments, decoder)
  |> result.map_error(error.DatabaseError)
}

pub fn upsert_hex_user(
  db: pgo.Connection,
  arguments: List(pgo.Value),
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
  pgo.execute(query, db, arguments, decoder)
  |> result.map_error(error.DatabaseError)
}

pub fn get_package(
  db: pgo.Connection,
  arguments: List(pgo.Value),
  decoder: dynamic.Decoder(a),
) -> QueryResult(a) {
  let query =
    "select
  name
, description
, hex_html_url
, docs_html_url
, inserted_in_hex_at
, updated_in_hex_at
from
  packages
where
  id = $1
limit 1;
"
  pgo.execute(query, db, arguments, decoder)
  |> result.map_error(error.DatabaseError)
}

pub fn list_packages(
  db: pgo.Connection,
  arguments: List(pgo.Value),
  decoder: dynamic.Decoder(a),
) -> QueryResult(a) {
  let query =
    "select
  name
, description
from
  packages
where
  id = $1
order by
  updated_in_hex_at
limit 500;
"
  pgo.execute(query, db, arguments, decoder)
  |> result.map_error(error.DatabaseError)
}

pub fn get_most_recent_hex_timestamp(
  db: pgo.Connection,
  arguments: List(pgo.Value),
  decoder: dynamic.Decoder(a),
) -> QueryResult(a) {
  let query =
    "select
  unix_timestamp
from most_recent_hex_timestamp
limit 1
"
  pgo.execute(query, db, arguments, decoder)
  |> result.map_error(error.DatabaseError)
}

pub fn get_release(
  db: pgo.Connection,
  arguments: List(pgo.Value),
  decoder: dynamic.Decoder(a),
) -> QueryResult(a) {
  let query =
    "select
  package_id
, version
, hex_url
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
  pgo.execute(query, db, arguments, decoder)
  |> result.map_error(error.DatabaseError)
}

pub fn migrate_schema(
  db: pgo.Connection,
  arguments: List(pgo.Value),
  decoder: dynamic.Decoder(a),
) -> QueryResult(a) {
  let query =
    "do $$
begin

create table if not exists most_recent_hex_timestamp (
  id boolean primary key default true
, unix_timestamp bigint not null
  -- we use a constraint to enforce that the id is always the value `true` so
  -- now this table can only hold one row.
, constraint most_recent_hex_timestamp_singleton check (id)
);

create table if not exists packages
( id serial primary key
, name text not null unique
, description text
, hex_html_url text
, docs_html_url text
, inserted_in_hex_at bigint not null
, updated_in_hex_at bigint not null
, links jsonb not null default '{}'
, licenses text array not null default '{}'
);

create table if not exists hex_user
( id serial primary key
, username text not null unique
, email text
, hex_url text
);

create table if not exists package_ownership
( package_id integer references packages(id) on delete cascade
, hex_user_id integer references hex_user(id) on delete cascade
, primary key (package_id, hex_user_id)
);

if to_regtype('retirement_reason') is null then
  create type retirement_reason as enum
  ( 'other'
  , 'invalid'
  , 'security'
  , 'deprecated'
  , 'renamed'
  );
end if;

create table if not exists releases
( id serial primary key
, package_id integer references packages(id) on delete cascade
, version text not null
, hex_url text not null
, retirement_reason retirement_reason
, retirement_message text
, inserted_in_hex_at bigint not null
, updated_in_hex_at bigint not null
, unique(package_id, version)
);

end
$$;
"
  pgo.execute(query, db, arguments, decoder)
  |> result.map_error(error.DatabaseError)
}

pub fn upsert_package(
  db: pgo.Connection,
  arguments: List(pgo.Value),
  decoder: dynamic.Decoder(a),
) -> QueryResult(a) {
  let query =
    "-- TODO: insert links and licenses
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
  , $5
  , $6
  )
on conflict (name) do update
set
  hex_html_url = excluded.hex_html_url
, docs_html_url = excluded.docs_html_url
, updated_in_hex_at = excluded.updated_in_hex_at
, description = excluded.description
returning
  id
"
  pgo.execute(query, db, arguments, decoder)
  |> result.map_error(error.DatabaseError)
}
