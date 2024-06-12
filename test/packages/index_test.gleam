import birl
import gleam/dict
import gleam/hexpm
import gleam/list
import gleam/option.{None, Some}
import gleeunit/should
import packages/index.{Package, Release}
import tests

pub fn most_recent_hex_timestamp_test() {
  use db <- tests.with_database

  let assert Ok(Nil) =
    index.upsert_most_recent_hex_timestamp(db, birl.from_unix(0))
  let assert Ok(time) = index.get_most_recent_hex_timestamp(db)
  let assert 0 = birl.to_unix(time)
  let assert "1970-01-01T00:00:00.000Z" = birl.to_iso8601(time)

  let assert Ok(Nil) =
    index.upsert_most_recent_hex_timestamp(db, birl.from_unix(2_284_352_323))
  let assert Ok(time) = index.get_most_recent_hex_timestamp(db)
  let assert "2042-05-22T06:18:43.000Z" = birl.to_iso8601(time)
  let assert 2_284_352_323 = birl.to_unix(time)
}

pub fn insert_package_test() {
  use db <- tests.with_database

  let assert Ok(id) =
    index.upsert_package(
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
        inserted_at: birl.from_unix(100),
        updated_at: birl.from_unix(2000),
      ),
    )

  let assert Ok(Some(package)) = index.get_package(db, id)
  package
  |> should.equal(Package(
    description: Some("Standard library for Gleam"),
    name: "gleam_stdlib",
    docs_url: Some("https://hexdocs.pm/gleam_stdlib/"),
    links: dict.from_list([
      #("Website", "https://gleam.run/"),
      #("Repository", "https://github.com/gleam-lang/stdlib"),
    ]),
    inserted_in_hex_at: birl.from_unix(100),
    updated_in_hex_at: birl.from_unix(2000),
  ))

  let assert Ok(None) = index.get_package(db, id + 1)
}

pub fn insert_release_test() {
  use db <- tests.with_database

  let assert Ok(package_id) =
    index.upsert_package(
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
        inserted_at: birl.from_unix(1_284_352_323),
        updated_at: birl.from_unix(1_284_352_322),
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
        updated_at: birl.from_unix(1000),
        inserted_at: birl.from_unix(2000),
      ),
    )

  let assert Ok(Some(release)) = index.get_release(db, id)
  release
  |> should.equal(Release(
    package_id: package_id,
    version: "0.0.3",
    retirement_reason: Some(hexpm.Security),
    retirement_message: Some("Retired due to security concerns"),
    updated_in_hex_at: birl.from_unix(1000),
    inserted_in_hex_at: birl.from_unix(2000),
  ))

  let assert Ok(None) = index.get_release(db, id + 1)
}

pub fn search_packages_empty_test() {
  use db <- tests.with_database

  let assert Ok(package_id) =
    index.upsert_package(
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
        inserted_at: birl.from_unix(100),
        updated_at: birl.from_unix(2000),
      ),
    )

  let assert Ok(_) =
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
        updated_at: birl.from_unix(1000),
        inserted_at: birl.from_unix(2000),
      ),
    )

  let assert Ok(_) =
    index.upsert_release(
      db,
      package_id,
      hexpm.Release(
        version: "0.0.4",
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
        updated_at: birl.from_unix(1001),
        inserted_at: birl.from_unix(2001),
      ),
    )

  let assert Ok(packages) = index.search_packages(db, "wibble")
  packages
  |> should.equal([])

  let assert Ok(packages) = index.search_packages(db, "library")
  packages
  |> should.equal([])
  // No results because all releases of gleam_stdlib are retired
  // TODO: include latest versions
}

pub fn search_packages_hide_retired_test() {
  use db <- tests.with_database

  // Prepare test data
  let assert Ok(package_id) =
    index.upsert_package(
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
        inserted_at: birl.from_unix(100),
        updated_at: birl.from_unix(2000),
      ),
    )

  let base_release =
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
      retirement: None,
      updated_at: birl.from_unix(1000),
      inserted_at: birl.from_unix(2000),
    )

  // A package's first release is published, it should be visible
  let assert Ok(_) = index.upsert_release(db, package_id, base_release)
  let assert Ok(packages) = index.search_packages(db, "gleam_stdlib")
  list.length(packages)
  |> should.equal(1)

  // The release is retired, the package should now be hidden
  let assert Ok(_) =
    index.upsert_release(
      db,
      package_id,
      hexpm.Release(
        ..base_release,
        retirement: Some(hexpm.ReleaseRetirement(
          reason: hexpm.Security,
          message: Some("Retired due to security concerns"),
        )),
        updated_at: birl.from_unix(1001),
        inserted_at: birl.from_unix(2001),
      ),
    )
  let assert Ok(packages) = index.search_packages(db, "gleam_stdlib")
  list.length(packages)
  |> should.equal(0)

  // A new release is published, the package should be visible again
  let assert Ok(_) =
    index.upsert_release(
      db,
      package_id,
      hexpm.Release(
        ..base_release,
        version: "0.0.4",
        updated_at: birl.from_unix(1002),
        inserted_at: birl.from_unix(2002),
      ),
    )
  let assert Ok(packages) = index.search_packages(db, "gleam_stdlib")
  list.length(packages)
  |> should.equal(1)
}

pub fn search_packages_query_escaping_test() {
  use db <- tests.with_database
  let assert Ok(package_id) =
    index.upsert_package(
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
        inserted_at: birl.from_unix(100),
        updated_at: birl.from_unix(2000),
      ),
    )

  let assert Ok(_) =
    index.upsert_release(
      db,
      package_id,
      hexpm.Release(
        version: "0.0.4",
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
        updated_at: birl.from_unix(1001),
        inserted_at: birl.from_unix(2001),
      ),
    )

  // This would be a syntax error if there was no escaping
  let assert Ok(packages) = index.search_packages(db, "gleam/io")
  packages
  |> should.equal([])
}

pub fn search_packages_substring_test() {
  use db <- tests.with_database

  let assert Ok(package_id) =
    index.upsert_package(
      db,
      hexpm.Package(
        downloads: dict.from_list([#("all", 5), #("recent", 2)]),
        docs_html_url: Some("https://hexdocs.pm/gleam_pgo/"),
        html_url: Some("https://hex.pm/packages/gleam_pgo"),
        meta: hexpm.PackageMeta(
          description: Some("Gleam bindings to the PGO PostgreSQL client"),
          licenses: ["Apache-2.0"],
          links: dict.from_list([
            #("Website", "https://gleam.run/"),
            #("Repository", "https://github.com/gleam-experiments/pgo"),
          ]),
        ),
        name: "gleam_pgo",
        owners: None,
        releases: [],
        inserted_at: birl.from_unix(100),
        updated_at: birl.from_unix(2000),
      ),
    )

  let assert Ok(_) =
    index.upsert_release(
      db,
      package_id,
      hexpm.Release(
        version: "0.6.1",
        checksum: "18a4940471ba798aa1fb85cd6e6d035a7403f66c4a2f19cdd471e0da450c3633",
        url: "https://hex.pm/apik/packages/gleam_pgo/releases/0.6.1",
        downloads: 0,
        meta: hexpm.ReleaseMeta(app: Some("gleam_pgo"), build_tools: ["gleam"]),
        publisher: Some(hexpm.PackageOwner(
          username: "lpil",
          email: None,
          url: "https://hex.pm/users/lpil",
        )),
        retirement: None,
        updated_at: birl.from_unix(1001),
        inserted_at: birl.from_unix(2001),
      ),
    )

  let assert Ok(packages) = index.search_packages(db, "sql")
  list.length(packages)
  |> should.equal(1)
}

pub fn search_packages_with_spaces_test() {
  use db <- tests.with_database

  let assert Ok(package_id) =
    index.upsert_package(
      db,
      hexpm.Package(
        downloads: dict.from_list([#("all", 5), #("recent", 2)]),
        docs_html_url: Some("https://hexdocs.pm/httpp/"),
        html_url: Some("https://hex.pm/packages/httpp"),
        meta: hexpm.PackageMeta(
          description: Some(
            "an http client for gleam which supports streaming, based on hackney",
          ),
          licenses: ["Apache-2.0"],
          links: dict.from_list([
            #("Website", "https://gleam.run/"),
            #("Repository", "https://github.com/VioletBuse/httpp"),
          ]),
        ),
        name: "httpp",
        owners: None,
        releases: [],
        inserted_at: birl.from_unix(100),
        updated_at: birl.from_unix(2000),
      ),
    )

  let assert Ok(_) =
    index.upsert_release(
      db,
      package_id,
      hexpm.Release(
        version: "1.0.1",
        checksum: "68f8fcdffd226e6065819b5c6d6c812c6b1c199e170a40b374aba79f6cacb528",
        url: "https://hex.pm/apik/packages/httpp/releases/1.0.1",
        downloads: 0,
        meta: hexpm.ReleaseMeta(app: Some("httpp"), build_tools: ["gleam"]),
        publisher: Some(hexpm.PackageOwner(
          username: "violetbuse",
          email: None,
          url: "https://hex.pm/users/violetbuse",
        )),
        retirement: None,
        updated_at: birl.from_unix(1001),
        inserted_at: birl.from_unix(2001),
      ),
    )

  let assert Ok(packages) = index.search_packages(db, "http")
  list.length(packages)
  |> should.equal(1)

  let assert Ok(packages) = index.search_packages(db, "    http")
  list.length(packages)
  |> should.equal(1)

  let assert Ok(packages) = index.search_packages(db, "http   ")
  list.length(packages)
  |> should.equal(1)

  let assert Ok(packages) = index.search_packages(db, "  http   ")
  list.length(packages)
  |> should.equal(1)

  let assert Ok(packages) = index.search_packages(db, "http client")
  list.length(packages)
  |> should.equal(1)

  let assert Ok(packages) = index.search_packages(db, "    http client")
  list.length(packages)
  |> should.equal(1)

  let assert Ok(packages) = index.search_packages(db, "http client    ")
  list.length(packages)
  |> should.equal(1)

  let assert Ok(packages) = index.search_packages(db, "http      client")
  list.length(packages)
  |> should.equal(1)

  let assert Ok(packages) =
    index.search_packages(db, "    http     client     ")
  list.length(packages)
  |> should.equal(1)
}
