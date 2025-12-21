import gleam/dict
import gleam/hexpm
import gleam/option.{None, Some}
import gleam/time/calendar
import gleam/time/timestamp
import packages/error
import packages/storage.{FullSync, Package, PartialSync, Release}
import storail
import tests

pub fn partial_sync_time_test() {
  use db <- tests.with_database

  let timestamp = timestamp.from_unix_seconds(0)
  let assert Ok(Nil) = storage.upsert_hex_sync_time(db, PartialSync, timestamp)
  let assert Ok(time) = storage.get_hex_sync_time(db, PartialSync)
  let assert #(0, 0) = timestamp.to_unix_seconds_and_nanoseconds(time)
  let assert "1970-01-01T00:00:00Z" =
    timestamp.to_rfc3339(time, calendar.utc_offset)

  let timestamp = timestamp.from_unix_seconds(2_284_352_323)
  let assert Ok(Nil) = storage.upsert_hex_sync_time(db, PartialSync, timestamp)
  let assert Ok(time) = storage.get_hex_sync_time(db, PartialSync)
  let assert "2042-05-22T06:18:43Z" =
    timestamp.to_rfc3339(time, calendar.utc_offset)
  let assert #(2_284_352_323, 0) =
    timestamp.to_unix_seconds_and_nanoseconds(time)
}

pub fn full_sync_time_test() {
  use db <- tests.with_database

  let timestamp = timestamp.from_unix_seconds(0)
  let assert Ok(Nil) = storage.upsert_hex_sync_time(db, FullSync, timestamp)
  let assert Ok(time) = storage.get_hex_sync_time(db, FullSync)
  let assert #(0, 0) = timestamp.to_unix_seconds_and_nanoseconds(time)
  let assert "1970-01-01T00:00:00Z" =
    timestamp.to_rfc3339(time, calendar.utc_offset)

  let timestamp = timestamp.from_unix_seconds(2_284_352_323)
  let assert Ok(Nil) = storage.upsert_hex_sync_time(db, FullSync, timestamp)
  let assert Ok(time) = storage.get_hex_sync_time(db, FullSync)
  let assert "2042-05-22T06:18:43Z" =
    timestamp.to_rfc3339(time, calendar.utc_offset)
  let assert #(2_284_352_323, 0) =
    timestamp.to_unix_seconds_and_nanoseconds(time)
}

pub fn insert_package_test() {
  use db <- tests.with_database
  let now = timestamp.from_unix_seconds(3000)

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
        inserted_at: timestamp.from_unix_seconds(100),
        updated_at: timestamp.from_unix_seconds(2000),
      ),
      now,
      "1.0.0",
    )

  let assert Ok(package) = storage.get_package(db, "gleam_stdlib")
  assert package
    == Package(
      description: "Standard library for Gleam",
      name: "gleam_stdlib",
      inserted_in_hex_at: timestamp.from_unix_seconds(100),
      updated_in_hex_at: timestamp.from_unix_seconds(2000),
      downloads_all: 5,
      downloads_recent: 2,
      downloads_day: 0,
      downloads_week: 0,
      latest_version: "1.0.0",
      repository_url: Some("https://github.com/gleam-lang/stdlib"),
      owners: [],
    )

  assert storage.get_latest_sample(db, "gleam_stdlib")
    == Ok(
      Some(storage.DownloadsSample(calendar.Date(1970, calendar.January, 1), 5)),
    )
}

pub fn insert_package_with_owners_test() {
  use db <- tests.with_database
  let now = timestamp.from_unix_seconds(3000)

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
        owners: Some([
          hexpm.PackageOwner(
            username: "user1",
            email: Some("u1@example.com"),
            url: "https://hex.pm/api/users/user1",
          ),
          hexpm.PackageOwner(
            username: "user2",
            email: None,
            url: "https://hex.pm/api/users/user2",
          ),
        ]),
        releases: [],
        inserted_at: timestamp.from_unix_seconds(100),
        updated_at: timestamp.from_unix_seconds(2000),
      ),
      now,
      "1.0.0",
    )

  let assert Ok(package) = storage.get_package(db, "gleam_stdlib")
  assert package
    == Package(
      description: "Standard library for Gleam",
      name: "gleam_stdlib",
      inserted_in_hex_at: timestamp.from_unix_seconds(100),
      updated_in_hex_at: timestamp.from_unix_seconds(2000),
      downloads_all: 5,
      downloads_recent: 2,
      downloads_day: 0,
      downloads_week: 0,
      latest_version: "1.0.0",
      repository_url: Some("https://github.com/gleam-lang/stdlib"),
      owners: ["user1", "user2"],
    )
}

pub fn insert_ignored_package_test() {
  use db <- tests.with_database
  let now = timestamp.from_unix_seconds(3000)

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
        inserted_at: timestamp.from_unix_seconds(100),
        updated_at: timestamp.from_unix_seconds(2000),
      ),
      now,
      "1.0.0",
    )

  let package = storage.get_package(db, "gleam_file")
  assert package
    == Error(error.StorageError(storail.ObjectNotFound([], "gleam_file")))
}

pub fn insert_release_test() {
  use db <- tests.with_database
  let now = timestamp.from_unix_seconds(3000)

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
        inserted_at: timestamp.from_unix_seconds(1_284_352_323),
        updated_at: timestamp.from_unix_seconds(1_284_352_322),
      ),
      now,
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
        downloads: 12_345,
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
        inserted_at: timestamp.from_unix_seconds(2000),
        updated_at: timestamp.from_unix_seconds(1000),
      ),
      timestamp.from_unix_seconds(5000),
    )

  let assert Ok(release) = storage.get_release(db, "gleam_stdlib", "0.0.3")
  assert release
    == Release(
      version: "0.0.3",
      downloads: 12_345,
      retirement_reason: Some("security"),
      retirement_message: Some("Retired due to security concerns"),
      updated_in_hex_at: timestamp.from_unix_seconds(1000),
      inserted_in_hex_at: timestamp.from_unix_seconds(2000),
      last_scanned_at: timestamp.from_unix_seconds(5000),
    )
}
