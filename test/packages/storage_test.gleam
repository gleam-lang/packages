import birl
import gleam/dict
import gleam/hexpm
import gleam/option.{None, Some}
import gleeunit/should
import packages/error
import packages/storage.{Package, Release}
import storail
import tests

pub fn most_recent_hex_timestamp_test() {
  use db <- tests.with_database

  let assert Ok(Nil) =
    storage.upsert_most_recent_hex_timestamp(db, birl.from_unix(0))
  let assert Ok(time) = storage.get_most_recent_hex_timestamp(db)
  let assert 0 = birl.to_unix(time)
  let assert "1970-01-01T00:00:00.000Z" = birl.to_iso8601(time)

  let assert Ok(Nil) =
    storage.upsert_most_recent_hex_timestamp(db, birl.from_unix(2_284_352_323))
  let assert Ok(time) = storage.get_most_recent_hex_timestamp(db)
  let assert "2042-05-22T06:18:43.000Z" = birl.to_iso8601(time)
  let assert 2_284_352_323 = birl.to_unix(time)
}

pub fn insert_package_test() {
  use db <- tests.with_database

  let assert Ok(_) =
    storage.upsert_package_from_hex(
      db,
      hexpm.Package(
        downloads: dict.from_list([#("all", 5), #("recent", 2)]),
        docs_html_url: Some("https://hexdocs.pm/gleam_stdlib/"),
        html_url: Some("https://hex.pm/packages/gleam_stdlib"),
        meta: hexpm.PackageMeta(
          description: Some("Standard library for Gleam"),
          licenses: ["Apache-2.0"],
          links: dict.from_list([
            #("Website", "https://gleam.run/"),
            #("Repository", "https://github.com/gleam-lang/stdlib"),
          ]),
        ),
        name: "gleam_stdlib",
        owners: None,
        releases: [],
        inserted_at: birl.to_iso8601(birl.from_unix(100)),
        updated_at: birl.to_iso8601(birl.from_unix(2000)),
      ),
      "1.0.0",
    )

  let assert Ok(package) = storage.get_package(db, "gleam_stdlib")
  package
  |> should.equal(Package(
    description: "Standard library for Gleam",
    name: "gleam_stdlib",
    inserted_in_hex_at: 100,
    updated_in_hex_at: 2000,
    downloads_all: 5,
    downloads_recent: 2,
    downloads_day: 0,
    downloads_week: 0,
    latest_version: "1.0.0",
    repository_url: Some("https://github.com/gleam-lang/stdlib"),
  ))
}

pub fn insert_ignored_package_test() {
  use db <- tests.with_database

  let assert Ok(_) =
    storage.upsert_package_from_hex(
      db,
      hexpm.Package(
        downloads: dict.from_list([#("all", 5), #("recent", 2)]),
        docs_html_url: Some("https://hexdocs.pm/gleam_file/"),
        html_url: Some("https://hex.pm/packages/gleam_file"),
        meta: hexpm.PackageMeta(
          description: Some("Standard library for Gleam"),
          licenses: ["Apache-2.0"],
          links: dict.from_list([
            #("Website", "https://gleam.run/"),
            #("Repository", "https://github.com/gleam-lang/stdlib"),
          ]),
        ),
        name: "gleam_file",
        owners: None,
        releases: [],
        inserted_at: birl.to_iso8601(birl.from_unix(100)),
        updated_at: birl.to_iso8601(birl.from_unix(2000)),
      ),
      "1.0.0",
    )

  let package = storage.get_package(db, "gleam_file")
  package
  |> should.equal(
    Error(error.StorageError(storail.ObjectNotFound([], "gleam_file"))),
  )
}

pub fn insert_release_test() {
  use db <- tests.with_database

  let assert Ok(_) =
    storage.upsert_package_from_hex(
      db,
      hexpm.Package(
        downloads: dict.from_list([#("all", 5), #("recent", 2)]),
        docs_html_url: Some("https://hexdocs.pm/gleam_stdlib/"),
        html_url: Some("https://hex.pm/packages/gleam_stdlib"),
        meta: hexpm.PackageMeta(
          description: Some("Standard library for Gleam"),
          licenses: ["Apache-2.0"],
          links: dict.new(),
        ),
        name: "gleam_stdlib",
        owners: None,
        releases: [],
        inserted_at: birl.to_iso8601(birl.from_unix(1_284_352_323)),
        updated_at: birl.to_iso8601(birl.from_unix(1_284_352_322)),
      ),
      "2.0.2",
    )

  let assert Ok(_) =
    storage.upsert_release(
      db,
      "gleam_stdlib",
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
        inserted_at: birl.to_iso8601(birl.from_unix(1000)),
        updated_at: birl.to_iso8601(birl.from_unix(2000)),
      ),
    )

  let assert Ok(release) = storage.get_release(db, "gleam_stdlib", "0.0.3")
  release
  |> should.equal(Release(
    version: "0.0.3",
    retirement_reason: Some("security"),
    retirement_message: Some("Retired due to security concerns"),
    updated_in_hex_at: 1000,
    inserted_in_hex_at: 2000,
  ))
}
