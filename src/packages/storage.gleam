import gleam/dict
import gleam/dynamic/decode.{type Decoder}
import gleam/float
import gleam/hexpm
import gleam/int
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option}
import gleam/order
import gleam/result
import gleam/string
import gleam/time/calendar
import gleam/time/timestamp.{type Timestamp}
import packages/error.{type Error}
import packages/override
import packages/text_search
import storail.{type Collection}

pub opaque type Database {
  Database(
    hex_sync_times: Collection(Timestamp),
    packages: Collection(Package),
    releases: Collection(Release),
  )
}

pub fn initialise(storage_path: String) -> Database {
  let config = storail.Config(storage_path:)

  let hex_sync_times =
    storail.Collection(
      name: "hex_sync_times",
      to_json: json_timestamp,
      decoder: decode.int |> decode.map(timestamp.from_unix_seconds),
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

  Database(hex_sync_times:, packages:, releases:)
}

fn gleam_package_epoch() -> Timestamp {
  timestamp.from_unix_seconds(1_635_092_380)
}

pub type Package {
  Package(
    name: String,
    description: String,
    inserted_in_hex_at: Timestamp,
    updated_in_hex_at: Timestamp,
    downloads_all: Int,
    downloads_recent: Int,
    downloads_week: Int,
    downloads_day: Int,
    repository_url: Option(String),
    latest_version: String,
    owners: List(String),
  )
}

fn package_to_json(package: Package) -> Json {
  let Package(
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
    owners:,
  ) = package
  json.object([
    #("name", json.string(name)),
    #("description", json.string(description)),
    #("inserted_in_hex_at", json_timestamp(inserted_in_hex_at)),
    #("updated_in_hex_at", json_timestamp(updated_in_hex_at)),
    #("latest_version", json.string(latest_version)),
    #("downloads_all", json.int(downloads_all)),
    #("downloads_recent", json.int(downloads_recent)),
    #("downloads_week", json.int(downloads_week)),
    #("downloads_day", json.int(downloads_day)),
    #("repository_url", json.nullable(repository_url, json.string)),
    #("owners", json.array(owners, json.string)),
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
  use owners <- decode.optional_field("owners", [], decode.list(decode.string))
  decode.success(Package(
    name:,
    description:,
    inserted_in_hex_at: timestamp.from_unix_seconds(inserted_in_hex_at),
    updated_in_hex_at: timestamp.from_unix_seconds(updated_in_hex_at),
    downloads_all:,
    downloads_recent:,
    downloads_week:,
    downloads_day:,
    repository_url:,
    latest_version:,
    owners:,
  ))
}

pub type Release {
  Release(
    version: String,
    downloads: Int,
    retirement_reason: Option(String),
    retirement_message: Option(String),
    inserted_in_hex_at: Timestamp,
    updated_in_hex_at: Timestamp,
    last_scanned_at: Timestamp,
  )
}

fn json_timestamp(timestamp: timestamp.Timestamp) -> json.Json {
  timestamp
  |> timestamp.to_unix_seconds
  |> float.round
  |> json.int
}

fn release_to_json(release: Release) -> Json {
  let Release(
    version:,
    downloads:,
    retirement_reason:,
    retirement_message:,
    inserted_in_hex_at:,
    updated_in_hex_at:,
    last_scanned_at:,
  ) = release
  json.object([
    #("version", json.string(version)),
    #("downloads", json.int(downloads)),
    #("retirement_reason", json.nullable(retirement_reason, json.string)),
    #("retirement_message", json.nullable(retirement_message, json.string)),
    #("inserted_in_hex_at", json_timestamp(inserted_in_hex_at)),
    #("updated_in_hex_at", json_timestamp(updated_in_hex_at)),
    #("last_scanned_at", json_timestamp(last_scanned_at)),
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
  use downloads <- decode.field("downloads", decode.int)
  use inserted_in_hex_at <- decode.field("inserted_in_hex_at", decode.int)
  use updated_in_hex_at <- decode.field("updated_in_hex_at", decode.int)
  use last_scanned_at <- decode.field("last_scanned_at", decode.int)
  decode.success(Release(
    version:,
    downloads:,
    retirement_reason:,
    retirement_message:,
    inserted_in_hex_at: timestamp.from_unix_seconds(inserted_in_hex_at),
    updated_in_hex_at: timestamp.from_unix_seconds(updated_in_hex_at),
    last_scanned_at: timestamp.from_unix_seconds(last_scanned_at),
  ))
}

pub type WhichHexSyncTime {
  PartialSync
  FullSync
}

fn which_hex_sync_time_key(which: WhichHexSyncTime) -> String {
  case which {
    PartialSync -> "most-recent-partial-sync"
    FullSync -> "most-recent-full-sync"
  }
}

/// Insert or replace the a Hex timestamp in the database.
pub fn upsert_hex_sync_time(
  database: Database,
  which: WhichHexSyncTime,
  time: Timestamp,
) -> Result(Nil, Error) {
  database.hex_sync_times
  |> storail.key(which_hex_sync_time_key(which))
  |> storail.write(time)
  |> result.map_error(error.StorageError)
}

/// Get a Hex timestamp from the database, returning a time
/// before the first package publication if there is no previous timestamp in
/// the database.
pub fn get_hex_sync_time(
  database: Database,
  which: WhichHexSyncTime,
) -> Result(Timestamp, Error) {
  database.hex_sync_times
  |> storail.key(which_hex_sync_time_key(which))
  |> storail.optional_read
  |> result.map(option.unwrap(_, gleam_package_epoch()))
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
  let owners =
    package.owners
    |> option.unwrap([])
    |> list.map(fn(owner) { owner.username })

  Package(
    name: package.name,
    description: package.meta.description |> option.unwrap(""),
    inserted_in_hex_at: package.inserted_at,
    updated_in_hex_at: package.updated_at,
    downloads_all: downloads_count("all"),
    downloads_recent: downloads_count("recent"),
    downloads_week: downloads_count("week"),
    downloads_day: downloads_count("day"),
    repository_url:,
    latest_version:,
    owners:,
  )
}

fn hexpm_release_to_storage_release(
  release: hexpm.Release,
  last_scanned_at: Timestamp,
) -> Release {
  let #(retirement_reason, retirement_message) = case release.retirement {
    option.Some(retirement) -> #(
      option.Some(hexpm.retirement_reason_to_string(retirement.reason)),
      retirement.message,
    )
    option.None -> #(option.None, option.None)
  }

  Release(
    version: release.version,
    downloads: release.downloads,
    retirement_reason:,
    retirement_message:,
    inserted_in_hex_at: release.inserted_at,
    updated_in_hex_at: release.updated_at,
    last_scanned_at:,
  )
}

pub fn upsert_package_from_hex(
  database: Database,
  package: hexpm.Package,
  latest_version latest_version: String,
) -> Result(Nil, Error) {
  case override.is_ignored_package(package.name) {
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

pub fn upsert_release(
  database: Database,
  package: String,
  release: hexpm.Release,
  now now: Timestamp,
) -> Result(Nil, Error) {
  let release = hexpm_release_to_storage_release(release, now)
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

pub fn get_releases(
  database: Database,
  package package: String,
) -> Result(List(Release), Error) {
  use releases <- result.try(list_releases(database, package))
  use release <- list.try_map(releases)
  get_release(database, package, release)
}

pub fn list_releases(
  database: Database,
  package package: String,
) -> Result(List(String), Error) {
  storail.list(database.releases, [package])
  |> result.map_error(error.StorageError)
}

pub fn list_packages(database: Database) -> Result(List(String), Error) {
  case storail.list(database.packages, []) {
    Ok(packages) ->
      Ok(list.filter(packages, fn(p) { !override.is_ignored_package(p) }))
    Error(e) -> Error(error.StorageError(e))
  }
}

pub type SearchOutcome {
  Packages(packages: List(Package))
  DidYouMean(suggestion: String)
}

pub fn search_packages(
  db: Database,
  search: text_search.TextSearchIndex,
  search_term: String,
) -> Result(SearchOutcome, Error) {
  use found <- result.try(text_search.lookup(search, search_term))

  case found {
    [_, ..] ->
      rank_found_results(found, db, search_term)
      |> result.map(Packages)

    // If no results are found we try and suggest a fix for the search term.
    [] ->
      case text_search.did_you_mean(search, search_term) {
        Ok(suggestion) -> Ok(DidYouMean(suggestion:))
        Error(_) -> Ok(Packages(packages: []))
      }
  }
}

/// Given a list of `text_search` results, this returns a list of the matching
/// packages, ranked from most relevant to least relevant.
///
fn rank_found_results(
  found: List(text_search.Found),
  db: Database,
  search_term: String,
) -> Result(List(Package), Error) {
  use packages <- result.map(
    list.try_map(found, fn(found) {
      use package <- result.map(get_package(db, found.name))
      let ordering_key = package_ordering_key(search_term, package, found)
      #(ordering_key, package)
    }),
  )

  packages
  |> list.sort(fn(a, b) { list_compare(b.0, a.0, int.compare) })
  |> list.map(fn(pair) { pair.1 })
}

/// This is the value we use to determine what order packages should be shown
/// by.
///
fn package_ordering_key(
  search_term: String,
  package: Package,
  found: text_search.Found,
) -> List(Int) {
  let bool = fn(bool) {
    case bool {
      True -> 1
      False -> 0
    }
  }

  let exact_package_name_match = bool(search_term == package.name)
  let is_not_v0 = bool(!string.starts_with(package.latest_version, "0."))
  let is_core_package = bool(override.is_core_package(package.name))
  let updated_at =
    float.round(timestamp.to_unix_seconds(package.updated_in_hex_at))

  // Later list values only take effect if the earlier ones are equal.
  [
    exact_package_name_match,
    is_not_v0,
    found.match_count,
    is_core_package,
    package.downloads_recent,
    updated_at,
  ]
}

fn list_compare(
  a: List(t),
  b: List(t),
  compare: fn(t, t) -> order.Order,
) -> order.Order {
  case a, b {
    [], [] -> order.Eq
    [], _ -> order.Lt
    _, [] -> order.Gt
    [a1, ..a], [b1, ..b] ->
      case compare(a1, b1) {
        order.Eq -> list_compare(a, b, compare)
        order.Gt as order | order.Lt as order -> order
      }
  }
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
  package: String,
  initial: acc,
  folder: fn(acc, Release) -> Result(acc, Error),
) -> Result(acc, Error) {
  use releases <- result.try(list_releases(database, package))
  list.try_fold(releases, initial, fn(acc, version) {
    use release <- result.try(get_release(database, package, version))
    folder(acc, release)
  })
}

pub type InternetPoints {
  InternetPoints(
    total_downloads: Int,
    package_counts: List(#(String, Int)),
    release_counts: List(#(String, Int)),
    package_download_counts: List(#(String, Int)),
    owner_download_counts: List(#(String, Int)),
    owner_package_counts: List(#(String, Int)),
  )
}

type InternetPointsAcc {
  InternetPointsAcc(
    total_downloads: Int,
    package_counts: dict.Dict(String, Int),
    release_counts: dict.Dict(String, Int),
    package_download_counts: dict.Dict(String, Int),
    owner_download_counts: dict.Dict(String, Int),
    owner_package_counts: dict.Dict(String, Int),
  )
}

pub fn internet_points(database: Database) -> Result(InternetPoints, Error) {
  let d = dict.new()
  let acc = InternetPointsAcc(0, d, d, d, d, d)

  use acc <- result.try(
    try_fold_packages(database, acc, fn(acc, package) {
      let count_for_owners = fn(counts, amount) {
        list.fold(package.owners, counts, fn(counts, owner) {
          dict.upsert(counts, owner, fn(c) { option.unwrap(c, 0) + amount })
        })
      }
      let count_for_dates = fn(counts, date) {
        date
        |> date_string
        |> dict.upsert(counts, _, fn(c) { option.unwrap(c, 0) + 1 })
      }

      let package_download_counts =
        dict.upsert(acc.package_download_counts, package.name, fn(c) {
          option.unwrap(c, 0) + package.downloads_all
        })
      let owner_package_counts = count_for_owners(acc.owner_package_counts, 1)
      let owner_download_counts =
        count_for_owners(acc.owner_download_counts, package.downloads_all)
      let package_counts =
        count_for_dates(acc.package_counts, package.inserted_in_hex_at)

      use release_counts <- result.try(
        try_fold_releases(
          database,
          package.name,
          acc.release_counts,
          fn(counts, release) {
            release.inserted_in_hex_at
            |> date_string
            |> dict.upsert(counts, _, fn(c) { option.unwrap(c, 0) + 1 })
            |> Ok
          },
        ),
      )

      let acc =
        InternetPointsAcc(
          total_downloads: acc.total_downloads + package.downloads_all,
          release_counts:,
          package_counts:,
          package_download_counts:,
          owner_download_counts:,
          owner_package_counts:,
        )
      Ok(acc)
    }),
  )

  Ok(InternetPoints(
    total_downloads: acc.total_downloads,
    package_counts: acc.package_counts
      |> dict.to_list
      |> list.sort(fn(a, b) { string.compare(a.0, b.0) }),
    release_counts: acc.release_counts
      |> dict.to_list
      |> list.sort(fn(a, b) { string.compare(a.0, b.0) }),
    package_download_counts: acc.package_download_counts
      |> dict.to_list
      |> list.sort(fn(a, b) { int.compare(b.1, a.1) }),
    owner_download_counts: acc.owner_download_counts
      |> dict.to_list
      |> list.sort(fn(a, b) { int.compare(b.1, a.1) }),
    owner_package_counts: acc.owner_package_counts
      |> dict.to_list
      |> list.sort(fn(a, b) { int.compare(b.1, a.1) }),
  ))
}

fn date_string(timestamp: Timestamp) -> String {
  timestamp
  |> timestamp.to_rfc3339(calendar.utc_offset)
  |> string.slice(0, 10)
}

pub fn packages_most_recent_first(db: Database) -> Result(List(Package), Error) {
  use packages <- result.try(list_packages(db))
  use packages <- result.map(list.try_map(packages, get_package(db, _)))
  list.sort(packages, fn(a, b) {
    timestamp.compare(b.updated_in_hex_at, a.updated_in_hex_at)
  })
}
