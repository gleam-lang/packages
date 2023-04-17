import gleam/dynamic.{DecodeError, Dynamic} as dyn
import gleam/dynamic_extra as dyn_extra
import gleam/result
import gleam/erlang
import gleam/pgo
import gleam/option.{None, Option, Some}
import gleam/hexpm
import packages/generated/sql
import packages/error.{Error}
import birl/time.{Time}
import packages/syncing

pub fn main() {
  let assert [key] = erlang.start_arguments()
  let assert Ok(limit) = time.from_iso8601("2020-01-01T00:00:00.000000Z")

  let db =
    pgo.connect(
      pgo.Config(
        ..pgo.default_config(),
        database: "gleam_packages",
        pool_size: 1,
      ),
    )
  let assert Ok(_) = sql.migrate_schema(db, [], Ok)

  let assert Ok(_) =
    syncing.sync_new_gleam_releases(
      limit,
      key,
      upsert_package(db, _),
      fn(id, r) { upsert_release(db, id, r) },
    )
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
