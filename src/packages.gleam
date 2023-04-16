import gleam/dynamic as dyn
import gleam/result
import gleam/erlang
import gleam/pgo
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
