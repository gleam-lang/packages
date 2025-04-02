import birl.{type Time}
import gleam/dict
import gleam/dynamic/decode.{type Decoder}
import gleam/hexpm
import gleam/int
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option}
import gleam/result
import packages/error.{type Error}
import storail.{type Collection}

pub opaque type Database {
  Database(
    most_recent_hex_timestamp: Collection(Int),
    packages: Collection(Package),
    releases: Collection(Release),
  )
}

pub fn initialise(storage_path: String) -> Database {
  let config = storail.Config(storage_path:)

  let most_recent_hex_timestamp =
    storail.Collection(
      name: "most_recent_hex_timestamp",
      to_json: json.int,
      decoder: decode.int,
      config:,
    )

  let packages =
    storail.Collection(
      name: "packages",
      to_json: package_to_json,
      decoder: package_decoder(),
      config:,
    )

  let releases =
    storail.Collection(
      name: "releases",
      to_json: release_to_json,
      decoder: release_decoder(),
      config:,
    )

  Database(most_recent_hex_timestamp:, packages:, releases:)
}

const ignored_packages = [
  "bare_package1", "bare_package_one", "bare_package_two",
  "first_gleam_publish_package", "gleam_module_javascript_test",
  // Reserved official sounding names.
  "gleam", "gleam_deno", "gleam_email", "gleam_html", "gleam_nodejs",
  "gleam_tcp", "gleam_test", "gleam_toml", "gleam_xml", "gleam_mongo",
  "gleam_bson", "gleam_file", "gleam_yaml",
  // Reserved unreleased project names.
  "glitter", "sequin",
]

const gleam_package_epoch = 1_635_092_380

pub type PackageSummary {
  PackageSummary(
    name: String,
    description: String,
    repository_url: Option(String),
    latest_version: String,
    updated_in_hex_at: Time,
  )
}

pub type Package {
  Package(
    name: String,
    description: String,
    inserted_in_hex_at: Int,
    updated_in_hex_at: Int,
    downloads_all: Int,
    downloads_recent: Int,
    downloads_week: Int,
    downloads_day: Int,
    repository_url: Option(String),
    latest_version: String,
  )
}

fn package_to_json(package: Package) -> Json {
  json.object([
    #("name", json.string(package.name)),
    #("description", json.string(package.description)),
    #("inserted_in_hex_at", json.int(package.inserted_in_hex_at)),
    #("updated_in_hex_at", json.int(package.updated_in_hex_at)),
    #("latest_version", json.string(package.latest_version)),
    #("downloads_all", json.int(package.downloads_all)),
    #("downloads_recent", json.int(package.downloads_recent)),
    #("downloads_week", json.int(package.downloads_week)),
    #("downloads_day", json.int(package.downloads_day)),
    #("repository_url", json.nullable(package.repository_url, json.string)),
  ])
}

fn package_decoder() -> Decoder(Package) {
  use name <- decode.field("name", decode.string)
  use description <- decode.field("description", decode.string)
  use inserted_in_hex_at <- decode.field("inserted_in_hex_at", decode.int)
  use updated_in_hex_at <- decode.field("updated_in_hex_at", decode.int)
  use downloads_all <- decode.field("downloads_all", decode.int)
  use downloads_recent <- decode.field("downloads_recent", decode.int)
  use downloads_week <- decode.field("downloads_week", decode.int)
  use downloads_day <- decode.field("downloads_day", decode.int)
  use repository_url <- decode.field(
    "repository_url",
    decode.optional(decode.string),
  )
  use latest_version <- decode.field("latest_version", decode.string)
  decode.success(Package(
    name:,
    description:,
    inserted_in_hex_at:,
    updated_in_hex_at:,
    downloads_all:,
    downloads_recent:,
    downloads_week:,
    downloads_day:,
    repository_url:,
    latest_version:,
  ))
}

pub type Release {
  Release(
    version: String,
    retirement_reason: Option(String),
    retirement_message: Option(String),
    inserted_in_hex_at: Int,
    updated_in_hex_at: Int,
  )
}

fn release_to_json(release: Release) -> Json {
  json.object([
    #("version", json.string(release.version)),
    #(
      "retirement_reason",
      json.nullable(release.retirement_reason, json.string),
    ),
    #(
      "retirement_message",
      json.nullable(release.retirement_message, json.string),
    ),
    #("inserted_in_hex_at", json.int(release.inserted_in_hex_at)),
    #("updated_in_hex_at", json.int(release.updated_in_hex_at)),
  ])
}

fn release_decoder() -> Decoder(Release) {
  use version <- decode.field("version", decode.string)
  use retirement_reason <- decode.field(
    "retirement_reason",
    decode.optional(decode.string),
  )
  use retirement_message <- decode.field(
    "retirement_message",
    decode.optional(decode.string),
  )
  use inserted_in_hex_at <- decode.field("inserted_in_hex_at", decode.int)
  use updated_in_hex_at <- decode.field("updated_in_hex_at", decode.int)
  decode.success(Release(
    version:,
    retirement_reason:,
    retirement_message:,
    inserted_in_hex_at:,
    updated_in_hex_at:,
  ))
}

/// Insert or replace the most recent Hex timestamp in the database.
pub fn upsert_most_recent_hex_timestamp(
  database: Database,
  time: Time,
) -> Result(Nil, Error) {
  database.most_recent_hex_timestamp
  |> storail.key("latest")
  |> storail.write(birl.to_unix(time))
  |> result.map_error(error.StorageError)
}

/// Get the most recent Hex timestamp from the database, returning the Unix
/// epoch if there is no previous timestamp in the database.
pub fn get_most_recent_hex_timestamp(database: Database) -> Result(Time, Error) {
  database.most_recent_hex_timestamp
  |> storail.key("latest")
  |> storail.optional_read
  |> result.map(option.unwrap(_, gleam_package_epoch))
  |> result.map(birl.from_unix)
  |> result.map_error(error.StorageError)
}

fn hex_package_to_storage_package(
  package: hexpm.Package,
  latest_version latest_version: String,
) -> Package {
  let downloads_count = fn(period) {
    package.downloads |> dict.get(period) |> result.unwrap(0)
  }
  let repository_url =
    dict.get(package.meta.links, "Repository") |> option.from_result

  let assert Ok(inserted_in_hex_at) = birl.parse(package.inserted_at)
  let assert Ok(updated_in_hex_at) = birl.parse(package.updated_at)

  Package(
    name: package.name,
    description: package.meta.description |> option.unwrap(""),
    inserted_in_hex_at: birl.to_unix(inserted_in_hex_at),
    updated_in_hex_at: birl.to_unix(updated_in_hex_at),
    downloads_all: downloads_count("all"),
    downloads_recent: downloads_count("recent"),
    downloads_week: downloads_count("week"),
    downloads_day: downloads_count("day"),
    repository_url:,
    latest_version:,
  )
}

fn hexpm_release_to_storage_release(release: hexpm.Release) -> Release {
  let #(retirement_reason, retirement_message) = case release.retirement {
    option.Some(retirement) -> #(
      option.Some(hexpm.retirement_reason_to_string(retirement.reason)),
      retirement.message,
    )
    option.None -> #(option.None, option.None)
  }

  let assert Ok(inserted_at) = birl.parse(release.inserted_at)
  let assert Ok(updated_at) = birl.parse(release.updated_at)

  Release(
    version: release.version,
    retirement_reason:,
    retirement_message:,
    inserted_in_hex_at: birl.to_unix(inserted_at),
    updated_in_hex_at: birl.to_unix(updated_at),
  )
}

pub fn upsert_package_from_hex(
  database: Database,
  package: hexpm.Package,
  latest_version latest_version: String,
) -> Result(Nil, Error) {
  case list.contains(ignored_packages, package.name) {
    True -> Ok(Nil)
    False -> {
      database.packages
      |> storail.key(package.name)
      |> storail.write(hex_package_to_storage_package(package, latest_version))
      |> result.map_error(error.StorageError)
    }
  }
}

pub fn get_package(database: Database, name: String) -> Result(Package, Error) {
  database.packages
  |> storail.key(name)
  |> storail.read
  |> result.map_error(error.StorageError)
}

pub fn get_optional_package(
  database: Database,
  name: String,
) -> Result(Option(Package), Error) {
  database.packages
  |> storail.key(name)
  |> storail.optional_read
  |> result.map_error(error.StorageError)
}

pub fn get_total_package_count(database: Database) -> Result(Int, Error) {
  database.packages
  |> storail.list([])
  |> result.map(list.length)
  |> result.map_error(error.StorageError)
}

pub fn upsert_release(
  database: Database,
  package: String,
  release: hexpm.Release,
) -> Result(Nil, Error) {
  let release = hexpm_release_to_storage_release(release)
  database.releases
  |> storail.namespaced_key([package], release.version)
  |> storail.write(release)
  |> result.map_error(error.StorageError)
}

pub fn get_release(
  database: Database,
  package: String,
  version: String,
) -> Result(Release, Error) {
  database.releases
  |> storail.namespaced_key([package], version)
  |> storail.read
  |> result.map_error(error.StorageError)
}

pub fn list_releases(
  database: Database,
  package: String,
) -> Result(List(String), Error) {
  storail.list(database.releases, [package])
  |> result.map_error(error.StorageError)
}

pub fn list_packages(database: Database) -> Result(List(String), Error) {
  storail.list(database.packages, [])
  |> result.map_error(error.StorageError)
}

pub fn package_summaries(
  database: Database,
  packages: List(String),
) -> Result(List(PackageSummary), Error) {
  use name <- list.try_map(packages)
  use package <- result.try(get_package(database, name))
  Ok(PackageSummary(
    name:,
    description: package.description,
    repository_url: package.repository_url,
    latest_version: package.latest_version,
    updated_in_hex_at: birl.from_unix(package.updated_in_hex_at),
  ))
}

pub fn try_fold_packages(
  database: Database,
  initial: acc,
  folder: fn(acc, Package) -> Result(acc, Error),
) -> Result(acc, Error) {
  use packages <- result.try(list_packages(database))
  list.try_fold(packages, initial, fn(acc, name) {
    use package <- result.try(get_package(database, name))
    folder(acc, package)
  })
}

fn try_fold_releases(
  database: Database,
  initial: acc,
  folder: fn(acc, Release) -> Result(acc, Error),
) -> Result(acc, Error) {
  try_fold_packages(database, initial, fn(acc, package) {
    use releases <- result.try(list_releases(database, package.name))
    list.try_fold(releases, acc, fn(acc, version) {
      use release <- result.try(get_release(database, package.name, version))
      folder(acc, release)
    })
  })
}

pub fn new_package_count_per_day(
  database: Database,
) -> Result(List(#(String, Int)), Error) {
  use packages <- result.try(
    try_fold_packages(database, dict.new(), fn(counts, package) {
      birl.from_unix(package.inserted_in_hex_at)
      |> birl.to_date_string
      |> dict.upsert(counts, _, fn(c) { option.unwrap(c, 0) + 1 })
      |> Ok
    }),
  )
  packages
  |> dict.to_list
  |> list.sort(fn(a, b) { int.compare(a.1, b.1) })
  |> Ok
}

pub fn new_release_count_per_day(
  database: Database,
) -> Result(List(#(String, Int)), Error) {
  use releases <- result.try(
    try_fold_releases(database, dict.new(), fn(counts, release) {
      birl.from_unix(release.inserted_in_hex_at)
      |> birl.to_date_string
      |> dict.upsert(counts, _, fn(c) { option.unwrap(c, 0) + 1 })
      |> Ok
    }),
  )
  releases
  |> dict.to_list
  |> list.sort(fn(a, b) { int.compare(a.1, b.1) })
  |> Ok
}
