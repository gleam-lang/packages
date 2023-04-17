import birl/time.{Time}
import gleam/dynamic.{DecodeError, Dynamic} as dyn
import gleam/dynamic_extra as dyn_extra
import gleam/erlang
import gleam/hexpm
import gleam/erlang/process
import gleam/http/response
import gleam/bit_builder
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{None, Option, Some}
import gleam/pgo
import gleam/result
import gleam/string
import mist
import packages/error.{Error}
import packages/generated/sql
import packages/syncing

const usage = "Usage:
  gleam run list
  gleam run server
  gleam run sync
"

pub fn main() {
  case erlang.start_arguments() {
    ["list"] -> list()
    ["server"] -> server()
    ["sync", key] -> sync(key)
    _ -> io.println(usage)
  }
}

fn list() -> Nil {
  let db = start_database_connection_pool()
  let assert Ok(packages) = list_packages(db)
  let packages =
    packages
    |> list.sort(fn(a, b) { string.compare(a.name, b.name) })

  packages
  |> list.each(fn(package) {
    let name = string.pad_right(package.name <> ":", 24, " ")
    let line = name <> " " <> package.description
    let line = case string.length(line) > 70 {
      True -> string.slice(line, 0, 67) <> "..."
      False -> line
    }
    io.println(line)
  })

  io.println("\n" <> int.to_string(list.length(packages)) <> " packages")
}

fn sync(key: String) -> Nil {
  let assert Ok(limit) = time.from_iso8601("2020-01-01T00:00:00.000000Z")
  let db = start_database_connection_pool()

  let assert Ok(_) =
    syncing.sync_new_gleam_releases(
      limit,
      key,
      upsert_package(db, _),
      fn(id, r) { upsert_release(db, id, r) },
    )

  Nil
}

fn server() {
  let service = fn(_) {
    response.new(200)
    |> response.set_body("Hello, world!")
    |> response.map(bit_builder.from_string)
  }
  // Start the web server process
  let assert Ok(_) = mist.run_service(3000, service, max_body_limit: 4_000_000)
  io.println("Started listening on http://localhost:3000 ✨")

  // Put the main process to sleep while the web server does its thing
  process.sleep_forever()
}

fn start_database_connection_pool() -> pgo.Connection {
  let db =
    pgo.connect(
      pgo.Config(
        ..pgo.default_config(),
        database: "gleam_packages",
        pool_size: 1,
      ),
    )
  let assert Ok(_) = sql.migrate_schema(db, [], Ok)
  db
}

/// Insert or replace the most recent Hex timestamp in the database.
pub fn upsert_most_recent_hex_timestamp(
  db: pgo.Connection,
  time: Time,
) -> Result(Nil, Error) {
  let unix = time.to_unix(time)
  sql.upsert_most_recent_hex_timestamp(db, [pgo.int(unix)], Ok)
  |> result.replace(Nil)
}

/// Get the most recent Hex timestamp from the database, returning the Unix
/// epoch if there is no previous timestamp in the database.
pub fn get_most_recent_hex_timestamp(db: pgo.Connection) -> Result(Time, Error) {
  let decoder = dyn.element(0, dyn.int)
  use returned <- result.map(sql.get_most_recent_hex_timestamp(db, [], decoder))
  case returned.rows {
    [unix] -> time.from_unix(unix)
    _ -> time.from_unix(0)
  }
}

// TODO: insert licences and links also
pub fn upsert_package(
  db: pgo.Connection,
  package: hexpm.Package,
) -> Result(Int, Error) {
  let parameters = [
    pgo.text(package.name),
    pgo.nullable(pgo.text, package.meta.description),
    pgo.nullable(pgo.text, package.html_url),
    pgo.nullable(pgo.text, package.docs_html_url),
    pgo.int(time.to_unix(package.inserted_at)),
    pgo.int(time.to_unix(package.updated_at)),
  ]
  let decoder = dyn.element(0, dyn.int)
  use returned <- result.then(sql.upsert_package(db, parameters, decoder))
  let assert [id] = returned.rows
  Ok(id)
}

pub type Package {
  Package(
    name: String,
    description: Option(String),
    html_url: Option(String),
    docs_html_url: Option(String),
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
    dyn.element(3, dyn.optional(dyn.string)),
    dyn.element(4, dyn_extra.unix_timestamp),
    dyn.element(5, dyn_extra.unix_timestamp),
  )(data)
}

pub fn get_package(
  db: pgo.Connection,
  id: Int,
) -> Result(Option(Package), Error) {
  let params = [pgo.int(id)]
  use returned <- result.then(sql.get_package(db, params, decode_package))
  case returned.rows {
    [package] -> Ok(Some(package))
    _ -> Ok(None)
  }
}

pub fn upsert_release(
  db: pgo.Connection,
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
    pgo.int(package_id),
    pgo.text(release.version),
    pgo.text(release.url),
    pgo.nullable(pgo.text, retirement_reason),
    pgo.nullable(pgo.text, retirement_message),
    pgo.int(time.to_unix(release.inserted_at)),
    pgo.int(time.to_unix(release.updated_at)),
  ]
  let decoder = dyn.element(0, dyn.int)
  use returned <- result.then(sql.upsert_release(db, parameters, decoder))
  let assert [id] = returned.rows
  Ok(id)
}

pub type Release {
  Release(
    package_id: Int,
    version: String,
    hex_url: String,
    retirement_reason: Option(hexpm.RetirementReason),
    retirement_message: Option(String),
    inserted_in_hex_at: Time,
    updated_in_hex_at: Time,
  )
}

pub fn decode_release(data: Dynamic) -> Result(Release, List(DecodeError)) {
  dyn.decode7(
    Release,
    dyn.element(0, dyn.int),
    dyn.element(1, dyn.string),
    dyn.element(2, dyn.string),
    dyn.element(3, dyn.optional(hexpm.decode_retirement_reason)),
    dyn.element(4, dyn.optional(dyn.string)),
    dyn.element(5, dyn_extra.unix_timestamp),
    dyn.element(6, dyn_extra.unix_timestamp),
  )(data)
}

pub fn get_release(
  db: pgo.Connection,
  id: Int,
) -> Result(Option(Release), Error) {
  let params = [pgo.int(id)]
  use returned <- result.then(sql.get_release(db, params, decode_release))
  case returned.rows {
    [package] -> Ok(Some(package))
    _ -> Ok(None)
  }
}

pub type PackageSummary {
  PackageSummary(name: String, description: String)
}

fn decode_package_summary(
  data: Dynamic,
) -> Result(PackageSummary, List(DecodeError)) {
  dyn.decode2(
    PackageSummary,
    dyn.element(0, dyn.string),
    dyn.element(1, dyn.string),
  )(data)
}

pub fn list_packages(db: pgo.Connection) -> Result(List(PackageSummary), Error) {
  use returned <- result.then(sql.list_packages(db, [], decode_package_summary))
  Ok(returned.rows)
}
