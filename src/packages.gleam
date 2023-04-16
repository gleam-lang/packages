import gleam/dynamic as dyn
import gleam/result
import gleam/erlang
import gleam/pgo
import gleam/map
import gleam/list
import gleam/json
import gleam/hexpm
import packages/generated/sql
import packages/error.{Error}
import birl/time.{Time}
import packages/syncing

pub fn main() {
  let assert [key] = erlang.start_arguments()
  let assert Ok(limit) = time.from_iso8601("2022-11-21T10:23:29.806017Z")
  syncing.sync_new_gleam_releases(limit, key)
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
    pgo.nullable(pgo.text, package.html_url),
    pgo.nullable(pgo.text, package.docs_html_url),
    pgo.int(time.to_unix(package.inserted_at)),
    pgo.int(time.to_unix(package.updated_at)),
    pgo.nullable(pgo.text, package.meta.description),
  ]
  let decoder = dyn.element(0, dyn.int)
  use returned <- result.then(sql.upsert_package(db, parameters, decoder))
  let assert [id] = returned.rows
  Ok(id)
}
