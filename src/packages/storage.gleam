import birl.{type Time}
import decode/zero
import gleam/dict.{type Dict}
import gleam/hexpm
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option}
import gleam/result
import packages/error.{type Error}
import storail.{type Collection}

// text search index thing
//   name, description

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
      decoder: zero.int,
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
      name: "packages",
      to_json: release_to_json,
      decoder: release_decoder(),
      config:,
    )

  Database(most_recent_hex_timestamp:, packages:, releases:)
}

pub const hidden_packages = [
  "bare_package1", "bare_package_one", "bare_package_two",
  "first_gleam_publish_package", "gleam_module_javascript_test",
  // Reserved official sounding names.
  "gleam", "gleam_deno", "gleam_email", "gleam_html", "gleam_nodejs",
  "gleam_tcp", "gleam_test", "gleam_toml", "gleam_xml", "gleam_mongo",
  "gleam_bson",
  // Reserved unreleased project names.
  "glitter", "sequin",
]

const gleam_package_epoch = 1_635_092_380

pub type Package {
  Package(
    name: String,
    description: String,
    inserted_in_hex_at: Int,
    updated_in_hex_at: Int,
    docs_url: String,
    downloads_all: Int,
    downloads_recent: Int,
    downloads_week: Int,
    downloads_day: Int,
    links: Dict(String, String),
  )
}

fn package_to_json(package: Package) -> Json {
  let links =
    json.object(
      package.links
      |> dict.to_list
      |> list.map(fn(pair) { #(pair.0, json.string(pair.1)) }),
    )
  json.object([
    #("name", json.string(package.name)),
    #("description", json.string(package.description)),
    #("inserted_in_hex_at", json.int(package.inserted_in_hex_at)),
    #("updated_in_hex_at", json.int(package.updated_in_hex_at)),
    #("docs_url", json.string(package.docs_url)),
    #("downloads_all", json.int(package.downloads_all)),
    #("downloads_recent", json.int(package.downloads_recent)),
    #("downloads_week", json.int(package.downloads_week)),
    #("downloads_day", json.int(package.downloads_day)),
    #("links", links),
  ])
}

fn package_decoder() -> zero.Decoder(Package) {
  use name <- zero.field("name", zero.string)
  use description <- zero.field("description", zero.string)
  use inserted_in_hex_at <- zero.field("inserted_in_hex_at", zero.int)
  use updated_in_hex_at <- zero.field("updated_in_hex_at", zero.int)
  use docs_url <- zero.field("docs_url", zero.string)
  use downloads_all <- zero.field("downloads_all", zero.int)
  use downloads_recent <- zero.field("downloads_recent", zero.int)
  use downloads_week <- zero.field("downloads_week", zero.int)
  use downloads_day <- zero.field("downloads_day", zero.int)
  use links <- zero.field("links", zero.dict(zero.string, zero.string))
  zero.success(Package(
    name:,
    description:,
    inserted_in_hex_at:,
    updated_in_hex_at:,
    docs_url:,
    downloads_all:,
    downloads_recent:,
    downloads_week:,
    downloads_day:,
    links:,
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

fn release_decoder() -> zero.Decoder(Release) {
  use version <- zero.field("version", zero.string)
  use retirement_reason <- zero.field(
    "retirement_reason",
    zero.optional(zero.string),
  )
  use retirement_message <- zero.field(
    "retirement_message",
    zero.optional(zero.string),
  )
  use inserted_in_hex_at <- zero.field("inserted_in_hex_at", zero.int)
  use updated_in_hex_at <- zero.field("updated_in_hex_at", zero.int)
  zero.success(Release(
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

fn hex_package_to_storage_package(package: hexpm.Package) -> Package {
  let downloads_count = fn(period) {
    package.downloads |> dict.get(period) |> result.unwrap(0)
  }
  Package(
    name: package.name,
    description: package.meta.description |> option.unwrap(""),
    inserted_in_hex_at: birl.to_unix(package.inserted_at),
    updated_in_hex_at: birl.to_unix(package.updated_at),
    docs_url: package.docs_html_url |> option.unwrap(""),
    downloads_all: downloads_count("all"),
    downloads_recent: downloads_count("recent"),
    downloads_week: downloads_count("week"),
    downloads_day: downloads_count("day"),
    links: package.meta.links,
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
  Release(
    version: release.version,
    retirement_reason:,
    retirement_message:,
    inserted_in_hex_at: birl.to_unix(release.inserted_at),
    updated_in_hex_at: birl.to_unix(release.updated_at),
  )
}

pub fn upsert_package_from_hex(
  database: Database,
  package: hexpm.Package,
) -> Result(Nil, Error) {
  database.packages
  |> storail.key(package.name)
  |> storail.write(hex_package_to_storage_package(package))
  |> result.map_error(error.StorageError)
}

pub fn get_package(
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
) -> Result(Option(Release), Error) {
  database.releases
  |> storail.namespaced_key([package], version)
  |> storail.optional_read
  |> result.map_error(error.StorageError)
}
//
// pub type PackageSummary {
//   PackageSummary(
//     id: Int,
//     name: String,
//     description: String,
//     docs_url: Option(String),
//     links: Dict(String, String),
//     latest_versions: List(String),
//     updated_in_hex_at: Time,
//   )
// }
//
// fn decode_package_links(
//   data: Dynamic,
// ) -> Result(Dict(String, String), List(DecodeError)) {
//   use json_data <- try(dyn.string(data))
//
//   json.decode(json_data, using: dyn.dict(of: dyn.string, to: dyn.string))
//   |> result.map_error(fn(_) {
//     [DecodeError(expected: "Map(String, String)", found: json_data, path: [])]
//   })
// }
//
// fn decode_package_summary(
//   data: Dynamic,
// ) -> Result(PackageSummary, List(DecodeError)) {
//   dyn.decode7(
//     PackageSummary,
//     dyn.element(0, dyn.int),
//     dyn.element(1, dyn.string),
//     dyn.element(2, dyn.string),
//     dyn.element(3, dyn.optional(dyn.string)),
//     dyn.element(4, decode_package_links),
//     fn(_) { Ok([]) },
//     dyn.element(5, unix_timestamp),
//   )(data)
// }
//
// fn remove_extra_spaces(input: String) -> String {
//   input
//   |> string.trim
//   |> string.split(" ")
//   |> list.filter(fn(part) { !string.is_empty(part) })
//   |> string.join(" ")
// }
//
// pub fn search_packages(
//   db: Connection,
//   search_term: String,
// ) -> Result(List(PackageSummary), Error) {
//   let db = db.inner
//
//   let trimmed_search_term = remove_extra_spaces(search_term)
//
//   let query = webquery_to_sqlite_fts_query(trimmed_search_term)
//   let params = [sqlight.text(query), sqlight.text(trimmed_search_term)]
//   let result = sql.search_packages(db, params, decode_package_summary)
//   use packages <- result.try(result)
//
//   // Look up the latest versions for each package
//   packages
//   |> list.try_map(fn(package) {
//     let params = [sqlight.int(package.id)]
//     let decoder = dyn.element(0, dyn.string)
//     let result = sql.get_most_recent_releases(db, params, decoder)
//     use versions <- result.try(result)
//     Ok(PackageSummary(..package, latest_versions: versions))
//   })
// }
//
// // The search term here is used with SQLite's full-text-search feature, which
// // expects query terms in a specific format.
// // https://www.sqlite.org/fts5.html#full_text_query_syntax
// //
// // In future it would be good to build more sophisticated queries, but for now
// // we just escape it to avoid syntax errors.
// fn webquery_to_sqlite_fts_query(webquery: String) -> String {
//   let webquery = string.trim(webquery)
//   case webquery {
//     "" -> ""
//     _ -> "\"" <> string.replace(webquery, "\"", "\"\"") <> "\""
//   }
// }
//
// fn unix_timestamp(data: Dynamic) -> Result(Time, List(DecodeError)) {
//   use i <- result.map(dyn.int(data))
//   birl.from_unix(i)
// }
//
// pub fn new_package_count_per_day(
//   db: Connection,
// ) -> Result(List(#(String, Int)), Error) {
//   let decoder = dyn.tuple2(dyn.string, dyn.int)
//   sql.new_package_count_per_day(db.inner, [], decoder)
// }
//
// pub fn new_release_count_per_day(
//   db: Connection,
// ) -> Result(List(#(String, Int)), Error) {
//   let decoder = dyn.tuple2(dyn.string, dyn.int)
//   sql.new_release_count_per_day(db.inner, [], decoder)
// }
