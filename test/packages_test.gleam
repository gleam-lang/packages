import gleeunit
import packages
import birl/time
import tests

pub fn main() {
  gleeunit.main()
}

pub fn most_recent_hex_timestamp_test() {
  use db <- tests.with_database
  tests.truncate_tables(db)

  let assert Ok(Nil) =
    packages.upsert_most_recent_hex_timestamp(db, time.from_unix(1_284_352_323))
  let assert Ok(time) = packages.get_most_recent_hex_timestamp(db)
  let assert "2010-09-13T04:32:03.000Z" = time.to_iso8601(time)
  let assert 1_284_352_323 = time.to_unix(time)

  let assert Ok(Nil) =
    packages.upsert_most_recent_hex_timestamp(db, time.from_unix(2_284_352_323))
  let assert Ok(time) = packages.get_most_recent_hex_timestamp(db)
  let assert "2042-05-22T06:18:43.000Z" = time.to_iso8601(time)
  let assert 2_284_352_323 = time.to_unix(time)
}
