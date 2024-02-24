import birl.{type Time}
import gleam/string
import gleam/dynamic.{type DecodeError, type Dynamic, DecodeError} as dyn
import gleam/hexpm
import gleam/json
import gleam/list
import gleam/dict.{type Dict}
import gleam/option.{type Option, None, Some}
import gleam/result.{try}
import packages/error.{type Error}
import packages/generated/sql
import simplifile
import sqlight
import gleam/erlang/os

pub const export_path = "/tmp/packages-export.sqlite"

const export_path_tmp = "/tmp/packages-export-new.sqlite"

pub opaque type Connection {
  Connection(inner: sqlight.Connection)
}

/// The application is considered to have write permissions if the
/// `DATABASE_LOCK_PATH` environment variable is not set, or if it is set and
/// no file exists at that path.
///
pub fn has_write_permission() -> Bool {
  case os.get_env("LITEFS_PRIMARY_FILE") {
    Ok(path) -> simplifile.verify_is_file(path) == Ok(False)
    Error(_) -> True
  }
}

/// Vacuum (export) the database to `export_path`
///
pub fn export(conn: Connection) -> Result(Nil, Error) {
  let params = [sqlight.text(export_path_tmp)]
  use _ <- result.try(
    sqlight.query("vacuum into ?", conn.inner, params, Ok)
    |> result.replace(Nil)
    |> result.map_error(error.DatabaseError),
  )
  simplifile.rename_file(at: export_path_tmp, to: export_path)
  |> result.map_error(error.FileError)
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

create view if not exists non_retired_packages as
  -- A package is retired if all its releases are retired
  select p.*
  from packages p
  where p.id in (
    select distinct r.package_id
    from releases r
    where r.id is null or r.retirement_reason is null
  );

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
  ('gleam_mongo'),
  ('gleam_bson'),
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
  time: Time,
) -> Result(Nil, Error) {
  let unix = birl.to_unix(time)
  sql.upsert_most_recent_hex_timestamp(db.inner, [sqlight.int(unix)], Ok)
  |> result.replace(Nil)
}

/// Get the most recent Hex timestamp from the database, returning the Unix
/// epoch if there is no previous timestamp in the database.
pub fn get_most_recent_hex_timestamp(db: Connection) -> Result(Time, Error) {
  let decoder = dyn.element(0, dyn.int)
  use returned <- result.map(sql.get_most_recent_hex_timestamp(
    db.inner,
    [],
    decoder,
  ))
  case returned {
    [unix] -> birl.from_unix(unix)
    _ -> birl.from_unix(0)
  }
}

// TODO: insert licences also
pub fn upsert_package(
  db: Connection,
  package: hexpm.Package,
) -> Result(Int, Error) {
  let links_json =
    package.meta.links
    |> dict.to_list
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
    sqlight.int(birl.to_unix(package.inserted_at)),
    sqlight.int(birl.to_unix(package.updated_at)),
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
    links: Dict(String, String),
    inserted_in_hex_at: Time,
    updated_in_hex_at: Time,
  )
}

pub fn decode_package(data: Dynamic) -> Result(Package, List(DecodeError)) {
  dyn.decode6(
    Package,
    dyn.element(0, dyn.string),
    dyn.element(1, dyn.optional(dyn.string)),
    dyn.element(2, dyn.optional(dyn.string)),
    dyn.element(3, decode_package_links),
    dyn.element(4, unix_timestamp),
    dyn.element(5, unix_timestamp),
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
    sqlight.int(birl.to_unix(release.inserted_at)),
    sqlight.int(birl.to_unix(release.updated_at)),
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
    inserted_in_hex_at: Time,
    updated_in_hex_at: Time,
  )
}

pub fn decode_release(data: Dynamic) -> Result(Release, List(DecodeError)) {
  dyn.decode6(
    Release,
    dyn.element(0, dyn.int),
    dyn.element(1, dyn.string),
    dyn.element(2, dyn.optional(hexpm.decode_retirement_reason)),
    dyn.element(3, dyn.optional(dyn.string)),
    dyn.element(4, unix_timestamp),
    dyn.element(5, unix_timestamp),
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
    id: Int,
    name: String,
    description: String,
    docs_url: Option(String),
    links: Dict(String, String),
    latest_versions: List(String),
    updated_in_hex_at: Time,
  )
}

fn decode_package_links(
  data: Dynamic,
) -> Result(Dict(String, String), List(DecodeError)) {
  use json_data <- try(dyn.string(data))

  json.decode(json_data, using: dyn.dict(of: dyn.string, to: dyn.string))
  |> result.map_error(fn(_) {
    [DecodeError(expected: "Map(String, String)", found: json_data, path: [])]
  })
}

fn decode_package_summary(
  data: Dynamic,
) -> Result(PackageSummary, List(DecodeError)) {
  dyn.decode7(
    PackageSummary,
    dyn.element(0, dyn.int),
    dyn.element(1, dyn.string),
    dyn.element(2, dyn.string),
    dyn.element(3, dyn.optional(dyn.string)),
    dyn.element(4, decode_package_links),
    fn(_) { Ok([]) },
    dyn.element(5, unix_timestamp),
  )(data)
}

pub fn search_packages(
  db: Connection,
  search_term: String,
) -> Result(List(PackageSummary), Error) {
  let db = db.inner
  let query = webquery_to_sqlite_fts_query(search_term)
  let params = [sqlight.text(query)]
  let result = sql.search_packages(db, params, decode_package_summary)
  use packages <- result.try(result)

  // Look up the latest versions for each package
  packages
  |> list.try_map(fn(package) {
    let params = [sqlight.int(package.id)]
    let decoder = dyn.element(0, dyn.string)
    let result = sql.get_most_recent_releases(db, params, decoder)
    use versions <- result.try(result)
    Ok(PackageSummary(..package, latest_versions: versions))
  })
}

// The search term here is used with SQLite's full-text-search feature, which
// expects query terms in a specific format.
// https://www.sqlite.org/fts5.html#full_text_query_syntax
//
// In future it would be good to build more sophisticated queries, but for now
// we just escape it to avoid syntax errors.
fn webquery_to_sqlite_fts_query(webquery: String) -> String {
  let webquery = string.trim(webquery)
  case webquery {
    "" -> ""
    _ -> "\"" <> string.replace(webquery, "\"", "\"\"") <> "\""
  }
}

fn unix_timestamp(data: Dynamic) -> Result(Time, List(DecodeError)) {
  use i <- result.map(dyn.int(data))
  birl.from_unix(i)
}
