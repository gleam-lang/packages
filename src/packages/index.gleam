import birl/time.{DateTime}
import gleam/dynamic.{DecodeError, Dynamic} as dyn
import gleam/dynamic_extra as dyn_extra
import gleam/hexpm
import gleam/json
import gleam/list
import gleam/map.{Map}
import gleam/option.{None, Option, Some}
import gleam/result.{try}
import packages/error.{Error}
import packages/generated/sql
import sqlight

pub opaque type Connection {
  Connection(inner: sqlight.Connection)
}

const schema = "
pragma foreign_keys = on;
pragma journal_mode = wal;

create table if not exists most_recent_hex_timestamp (
  id integer primary key default 1
    -- we use a constraint to enforce that the id is always the value `1` so
    -- now this table can only hold one row.
    check (id == 1),
  
  unix_timestamp integer not null
) strict;

-- Use the timestamp of the first ever Gleam package as the initial timestamp.
insert into most_recent_hex_timestamp
  values (1, 1635092380)
  on conflict do nothing;

create table if not exists packages (
  id integer primary key autoincrement not null,
  name text not null unique,
  description text,
  inserted_in_hex_at integer not null,
  updated_in_hex_at integer not null,
  docs_url text,

  links text not null default '{}'
    check (json(links) not null)
) strict;

-- We want to be able to use full-text-search for packages.
create virtual table if not exists packages_fts using fts5(
  name,
  description,
  content=packages,
  content_rowid=id
);

-- Triggers to keep the full-text-search table up to date.
create trigger if not exists packages_text_insert
after insert on packages
begin
  insert into packages_fts (rowid, name, description)
    values (new.id, new.name, new.description);
end;

create trigger if not exists packages_packages_delete
after delete on packages
begin
  insert into packages_fts (packages_fts, rowid, name, description)
    values ('delete', old.id, old.name, old.description);
end;

create trigger if not exists packages_text_update
after update on packages
begin
  insert into packages_fts (packages_fts, rowid, name, description)
    values ('delete', old.id, old.name, old.description);
  insert into packages_fts (rowid, name, description)
    values (new.id, new.name, new.description);
end;

create table if not exists hex_user (
  id integer primary key autoincrement not null,
  username text not null unique,
  email text,
  hex_url text
) strict;

create table if not exists package_ownership (
  package_id integer references packages(id) on delete cascade,
  hex_user_id integer references hex_user(id) on delete cascade,
  primary key (package_id, hex_user_id)
) strict;

create table if not exists releases (
  id integer primary key autoincrement not null,
  package_id integer references packages(id) on delete cascade,
  version text not null,

  retirement_reason text
    check (retirement_reason in (
      'other', 'invalid', 'security', 'deprecated', 'renamed'
    )),

  retirement_message text,
  inserted_in_hex_at integer not null,
  updated_in_hex_at integer not null,

  unique(package_id, version)
) strict;

create table if not exists hidden_packages (
  name text primary key
) strict;

-- These packages are placeholders or otherwise not useful.
insert into hidden_packages values
  -- Test packages.
  ('bare_package1'),
  ('bare_package_one'),
  ('bare_package_two'),
  ('first_gleam_publish_package'),
  ('gleam_module_javascript_test'),
  -- Reserved official sounding names.
  ('gleam'),
  ('gleam_deno'),
  ('gleam_email'),
  ('gleam_html'),
  ('gleam_nodejs'),
  ('gleam_tcp'),
  ('gleam_test'),
  ('gleam_toml'),
  ('gleam_xml'),
  -- Reserved unreleased project names.
  ('glitter'),
  ('sequin')
on conflict do nothing;
"

pub fn connect(database: String) -> Connection {
  let assert Ok(db) = sqlight.open(database)
  let assert Ok(_) = sqlight.exec(schema, db)
  Connection(db)
}

pub fn disconnect(conn: Connection) -> Nil {
  let _ = conn
  Nil
}

pub fn exec(db: Connection, sql: String) -> Result(Nil, Error) {
  sqlight.exec(sql, db.inner)
  |> result.replace(Nil)
  |> result.map_error(error.DatabaseError)
}

/// Insert or replace the most recent Hex timestamp in the database.
pub fn upsert_most_recent_hex_timestamp(
  db: Connection,
  time: DateTime,
) -> Result(Nil, Error) {
  let unix = time.to_unix(time)
  sql.upsert_most_recent_hex_timestamp(db.inner, [sqlight.int(unix)], Ok)
  |> result.replace(Nil)
}

/// Get the most recent Hex timestamp from the database, returning the Unix
/// epoch if there is no previous timestamp in the database.
pub fn get_most_recent_hex_timestamp(db: Connection) -> Result(DateTime, Error) {
  let decoder = dyn.element(0, dyn.int)
  use returned <- result.map(sql.get_most_recent_hex_timestamp(
    db.inner,
    [],
    decoder,
  ))
  case returned {
    [unix] -> time.from_unix(unix)
    _ -> time.from_unix(0)
  }
}

// TODO: insert licences also
pub fn upsert_package(
  db: Connection,
  package: hexpm.Package,
) -> Result(Int, Error) {
  let links_json =
    package.meta.links
    |> map.to_list
    |> list.map(fn(pair) {
      let #(name, url) = pair
      #(name, json.string(url))
    })
    |> json.object
    |> json.to_string

  let parameters = [
    sqlight.text(package.name),
    sqlight.nullable(sqlight.text, package.meta.description),
    sqlight.nullable(sqlight.text, package.docs_html_url),
    sqlight.text(links_json),
    sqlight.int(time.to_unix(package.inserted_at)),
    sqlight.int(time.to_unix(package.updated_at)),
  ]
  let decoder = dyn.element(0, dyn.int)
  use returned <- result.then(sql.upsert_package(db.inner, parameters, decoder))
  let assert [id] = returned
  Ok(id)
}

pub type Package {
  Package(
    name: String,
    description: Option(String),
    docs_url: Option(String),
    links: Map(String, String),
    inserted_in_hex_at: DateTime,
    updated_in_hex_at: DateTime,
  )
}

pub fn decode_package(data: Dynamic) -> Result(Package, List(DecodeError)) {
  dyn.decode6(
    Package,
    dyn.element(0, dyn.string),
    dyn.element(1, dyn.optional(dyn.string)),
    dyn.element(2, dyn.optional(dyn.string)),
    dyn.element(3, decode_package_links),
    dyn.element(4, dyn_extra.unix_timestamp),
    dyn.element(5, dyn_extra.unix_timestamp),
  )(data)
}

pub fn get_package(db: Connection, id: Int) -> Result(Option(Package), Error) {
  let params = [sqlight.int(id)]
  use returned <- result.then(sql.get_package(db.inner, params, decode_package))
  case returned {
    [package] -> Ok(Some(package))
    _ -> Ok(None)
  }
}

pub fn get_total_package_count(db: Connection) -> Result(Int, Error) {
  use returned <- result.then(sql.get_total_package_count(
    db.inner,
    [],
    dyn.element(0, dyn.int),
  ))
  let assert [count] = returned
  Ok(count)
}

pub fn upsert_release(
  db: Connection,
  package_id: Int,
  release: hexpm.Release,
) -> Result(Int, Error) {
  let #(retirement_reason, retirement_message) = case release.retirement {
    Some(retirement) -> #(
      Some(hexpm.retirement_reason_to_string(retirement.reason)),
      retirement.message,
    )
    None -> #(None, None)
  }
  let parameters = [
    sqlight.int(package_id),
    sqlight.text(release.version),
    sqlight.nullable(sqlight.text, retirement_reason),
    sqlight.nullable(sqlight.text, retirement_message),
    sqlight.int(time.to_unix(release.inserted_at)),
    sqlight.int(time.to_unix(release.updated_at)),
  ]
  let decoder = dyn.element(0, dyn.int)
  use returned <- result.then(sql.upsert_release(db.inner, parameters, decoder))
  let assert [id] = returned
  Ok(id)
}

pub type Release {
  Release(
    package_id: Int,
    version: String,
    retirement_reason: Option(hexpm.RetirementReason),
    retirement_message: Option(String),
    inserted_in_hex_at: DateTime,
    updated_in_hex_at: DateTime,
  )
}

pub fn decode_release(data: Dynamic) -> Result(Release, List(DecodeError)) {
  dyn.decode6(
    Release,
    dyn.element(0, dyn.int),
    dyn.element(1, dyn.string),
    dyn.element(2, dyn.optional(hexpm.decode_retirement_reason)),
    dyn.element(3, dyn.optional(dyn.string)),
    dyn.element(4, dyn_extra.unix_timestamp),
    dyn.element(5, dyn_extra.unix_timestamp),
  )(data)
}

pub fn get_release(db: Connection, id: Int) -> Result(Option(Release), Error) {
  let params = [sqlight.int(id)]
  use returned <- result.then(sql.get_release(db.inner, params, decode_release))
  case returned {
    [package] -> Ok(Some(package))
    _ -> Ok(None)
  }
}

pub type PackageSummary {
  PackageSummary(
    name: String,
    description: String,
    docs_url: Option(String),
    links: Map(String, String),
    latest_versions: List(String),
    updated_in_hex_at: DateTime,
  )
}

fn decode_package_links(
  data: Dynamic,
) -> Result(Map(String, String), List(DecodeError)) {
  use json_data <- try(dyn.string(data))

  json.decode(json_data, using: dyn.map(of: dyn.string, to: dyn.string))
  |> result.map_error(fn(_) {
    [DecodeError(expected: "Map(String, String)", found: json_data, path: [])]
  })
}

fn decode_package_summary(
  data: Dynamic,
) -> Result(PackageSummary, List(DecodeError)) {
  dyn.decode6(
    PackageSummary,
    dyn.element(0, dyn.string),
    dyn.element(1, dyn.string),
    dyn.element(2, dyn.optional(dyn.string)),
    dyn.element(3, decode_package_links),
    fn(_) { Ok([]) },
    dyn.element(4, dyn_extra.unix_timestamp),
  )(data)
}

pub fn search_packages(
  db: Connection,
  search_term: String,
) -> Result(List(PackageSummary), Error) {
  let params = [sqlight.text(search_term)]
  sql.search_packages(db.inner, params, decode_package_summary)
}
