import packages/index.{Package, Release}
import gleam/hexpm
import gleam/option.{None, Some}
import gleam/map
import gleeunit/should
import birl/time
import tests

pub fn most_recent_hex_timestamp_test() {
  use db <- tests.with_database
  tests.truncate_tables(db)

  let assert Ok(Nil) =
    index.upsert_most_recent_hex_timestamp(db, time.from_unix(0))
  let assert Ok(time) = index.get_most_recent_hex_timestamp(db)
  let assert 0 = time.to_unix(time)
  let assert "1970-01-01T00:00:00.000Z" = time.to_iso8601(time)

  let assert Ok(Nil) =
    index.upsert_most_recent_hex_timestamp(db, time.from_unix(2_284_352_323))
  let assert Ok(time) = index.get_most_recent_hex_timestamp(db)
  let assert "2042-05-22T06:18:43.000Z" = time.to_iso8601(time)
  let assert 2_284_352_323 = time.to_unix(time)
}

pub fn insert_package_test() {
  use db <- tests.with_database
  tests.truncate_tables(db)

  let assert Ok(id) =
    index.upsert_package(
      db,
      hexpm.Package(
        downloads: map.from_list([#("all", 5), #("recent", 2)]),
        docs_html_url: Some("https://hexdocs.pm/gleam_stdlib/"),
        html_url: Some("https://hex.pm/packages/gleam_stdlib"),
        meta: hexpm.PackageMeta(
          description: Some("Standard library for Gleam"),
          licenses: ["Apache-2.0"],
          links: map.from_list([
            #("Website", "https://gleam.run/"),
            #("Repository", "https://github.com/gleam-lang/stdlib"),
          ]),
        ),
        name: "gleam_stdlib",
        owners: None,
        releases: [],
        inserted_at: time.from_unix(100),
        updated_at: time.from_unix(2000),
      ),
    )

  let assert Ok(Some(package)) = index.get_package(db, id)
  package
  |> should.equal(Package(
    description: Some("Standard library for Gleam"),
    name: "gleam_stdlib",
    docs_url: Some("https://hexdocs.pm/gleam_stdlib/"),
    links: map.from_list([
      #("Website", "https://gleam.run/"),
      #("Repository", "https://github.com/gleam-lang/stdlib"),
    ]),
    inserted_in_hex_at: time.from_unix(100),
    updated_in_hex_at: time.from_unix(2000),
  ))

  let assert Ok(None) = index.get_package(db, id + 1)
}

pub fn insert_release_test() {
  use db <- tests.with_database
  tests.truncate_tables(db)

  let assert Ok(package_id) =
    index.upsert_package(
      db,
      hexpm.Package(
        downloads: map.from_list([#("all", 5), #("recent", 2)]),
        docs_html_url: Some("https://hexdocs.pm/gleam_stdlib/"),
        html_url: Some("https://hex.pm/packages/gleam_stdlib"),
        meta: hexpm.PackageMeta(
          description: Some("Standard library for Gleam"),
          licenses: ["Apache-2.0"],
          links: map.new(),
        ),
        name: "gleam_stdlib",
        owners: None,
        releases: [],
        inserted_at: time.from_unix(1_284_352_323),
        updated_at: time.from_unix(1_284_352_322),
      ),
    )

  let assert Ok(id) =
    index.upsert_release(
      db,
      package_id,
      hexpm.Release(
        version: "0.0.3",
        checksum: "a895b55c4c3749eb32328f02b15bbd3acc205dd874fabd135d7be5d12eda59a8",
        url: "https://hex.pm/api/packages/shimmer/releases/0.0.3",
        downloads: 0,
        meta: hexpm.ReleaseMeta(app: Some("shimmer"), build_tools: ["gleam"]),
        publisher: Some(hexpm.PackageOwner(
          username: "harryet",
          email: None,
          url: "https://hex.pm/api/users/harryet",
        )),
        retirement: Some(hexpm.ReleaseRetirement(
          reason: hexpm.Security,
          message: Some("Retired due to security concerns"),
        )),
        updated_at: time.from_unix(1000),
        inserted_at: time.from_unix(2000),
      ),
    )

  let assert Ok(Some(release)) = index.get_release(db, id)
  release
  |> should.equal(Release(
    package_id: package_id,
    version: "0.0.3",
    retirement_reason: Some(hexpm.Security),
    retirement_message: Some("Retired due to security concerns"),
    updated_in_hex_at: time.from_unix(1000),
    inserted_in_hex_at: time.from_unix(2000),
  ))

  let assert Ok(None) = index.get_release(db, id + 1)
}
