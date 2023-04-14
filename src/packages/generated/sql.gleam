// THIS FILE IS GENERATED. DO NOT EDIT. 
// Regenerate with `gleam run -m codegen`

import gleam/pgo
import gleam/dynamic.{Dynamic}

pub type QueryResult(t) =
  Result(pgo.Returned(t), pgo.QueryError)

pub fn schema(
  db: pgo.Connection,
  decoder: fn(Dynamic) -> Result(a, List(dynamic.DecodeError)),
  arguments: List(pgo.Value),
) -> QueryResult(a) {
  let query =
    "do $$
begin

create table if not exists packages
( id serial primary key
, name text not null unique
, hex_html_url text
, docs_html_url text
, inserted_in_hex_at timestamp with time zone
, updated_in_hex_at timestamp with time zone
, links jsonb not null default '{}'
, licenses text array not null default '{}'
, description text
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
);

end
$$;
"
  pgo.execute(query, db, arguments, decoder)
}
