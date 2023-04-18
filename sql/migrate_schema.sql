do $$
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
, retirement_reason retirement_reason
, retirement_message text
, inserted_in_hex_at bigint not null
, updated_in_hex_at bigint not null
, unique(package_id, version)
);

create table if not exists hidden_packages
( name text primary key
);

-- These packages are placeholders or otherwise not useful.
insert into hidden_packages values
-- Test packages.
  ('bare_package1')
, ('bare_package_one')
, ('bare_package_two')
, ('first_gleam_publish_package')
, ('gleam_module_javascript_test')
-- Reserved official sounding names.
, ('gleam')
, ('gleam_deno')
, ('gleam_email')
, ('gleam_html')
, ('gleam_nodejs')
, ('gleam_tcp')
, ('gleam_test')
, ('gleam_toml')
, ('gleam_xml')
-- Reserved unreleased project names.
, ('glitter')
, ('sequin')
on conflict do nothing;

end
$$;
