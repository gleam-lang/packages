import gleam/io
import gleam/json
import gleam/http
import gleam/result
import gleam/hackney
import gleam/list
import gleam/dynamic.{Decoder} as d
import time/parse.{parse_iso8601_to_gregorian_seconds}
import gleam/pgo
import gleam/string
import gleam/int
import gleam/option.{Option}

pub type Error {
  HackneyError(hackney.Error)
  JsonError(json.DecodeError)
  DatabaseError(pgo.QueryError)
  MiscError(String)
  NilError(Nil)
}

pub fn query(db: pgo.Connection) {
  try last_scanned = get_last_scanned(db)

  try packages = query_all_packages([], 1, last_scanned)

  assert Ok(_) = update_last_scanned(db)

  packages
  |> list.filter_map(sort_packages)
  |> io.debug
  |> Ok
}

const last_scanned_query = "SELECT id, date_trunc('second', scanned_at) FROM previous_hex_api_scan LIMIT 1;"

fn get_last_scanned(db: pgo.Connection) -> Result(Int, Error) {
  try response =
    pgo.execute(
      last_scanned_query,
      db,
      [],
      d.tuple2(
        d.bool,
        d.tuple2(d.tuple3(d.int, d.int, d.int), d.tuple3(d.int, d.int, d.int)),
      ),
    )
    |> result.map_error(DatabaseError)

  case response.rows {
    [first, ..] -> Ok(parse.to_gregorian_seconds(first.1))
    _ -> Ok(0)
  }
}

const update_last_scanned_query = "UPDATE previous_hex_api_scan SET scanned_at = now();"

fn update_last_scanned(
  db: pgo.Connection,
) -> Result(pgo.Returned(d.Dynamic), Error) {
  pgo.execute(update_last_scanned_query, db, [], d.dynamic)
  |> result.map_error(DatabaseError)
}

fn sort_packages(package: Package) -> Result(Package, Error) {
  // TODO Sort Gleam Packages
  // 1. Check if already in DB
  // 2. Check latest release
  //    If is gleam: keep, else: remove
  // 3. Save new release in DB
  // 4. Update package in DB if out of date
  // 5. Return the new list of DB Package Type
  try latest_release =
    package.releases
    |> list.at(0)
    |> result.map_error(NilError)

  let req =
    http.default_req()
    |> http.set_method(http.Get)
    |> http.prepend_req_header("User-Agent", "GleamPackages")
    |> http.set_host("hex.pm")
    |> http.set_path(
      "/api/packages/"
      |> string.append(package.name)
      |> string.append("/releases/")
      |> string.append(latest_release.version),
    )

  try response =
    hackney.send(req)
    |> result.map_error(HackneyError)

  try release =
    json.decode(response.body, full_release_decoder())
    |> result.map_error(JsonError)

  // Keep this package because the current version is made with gleam! ✨
  case list.contains(release.meta.build_tools, "gleam") {
    True -> Ok(package)
    False -> Error(NilError(Nil))
  }
}

fn query_all_packages(
  last_page: List(Package),
  next_page: Int,
  last_ran: Int,
) -> Result(List(Package), Error) {
  let req =
    http.default_req()
    |> http.set_method(http.Get)
    |> http.prepend_req_header("User-Agent", "GleamPackages")
    |> http.set_host("hex.pm")
    |> http.set_path(
      "/api/packages?sort=updated_at&page="
      |> string.append(int.to_string(next_page)),
    )

  try response =
    hackney.send(req)
    |> result.map_error(HackneyError)

  // The packages just fetched from the page
  try packages =
    json.decode(response.body, d.list(package_decoder()))
    |> result.map_error(JsonError)

  // The packages that have been updated since we last scanned and indexed the
  // hex api.
  let new_packages =
    packages
    |> list.filter(fn(x) {
      parse_iso8601_to_gregorian_seconds(x.updated_at) > last_ran
    })

  let all_packages = list.append(last_page, new_packages)

  // Checks if the new_packages are the same length (or greater - even though 
  // imposible in theory) than the packages fetched from hex. If it is that
  // means that more packages need to be fetched as the entire page is new
  // from the last scan, if not then we know we have got all the new packages
  // and anything elase can be ignored as it should in theory have already been
  // indexed.
  case list.length(new_packages) >= list.length(packages) {
    True -> query_all_packages(all_packages, next_page + 1, last_ran)
    False -> Ok(all_packages)
  }
}

pub type Package {
  Package(name: String, updated_at: String, releases: List(Release))
}

pub type Release {
  Release(version: String, url: String)
}

pub type ReleaseMeta {
  ReleaseMeta(app: Option(String), build_tools: List(String))
}

pub type FullRelease {
  FullRelease(version: String, url: String, meta: ReleaseMeta)
}

fn full_release_decoder() -> Decoder(FullRelease) {
  d.decode3(
    FullRelease,
    d.field("version", d.string),
    d.field("url", d.string),
    d.field(
      "meta",
      d.decode2(
        ReleaseMeta,
        d.field("app", d.optional(d.string)),
        d.field("build_tools", d.list(d.string)),
      ),
    ),
  )
}

fn package_decoder() -> Decoder(Package) {
  d.decode3(
    Package,
    d.field("name", d.string),
    d.field("updated_at", d.string),
    d.field(
      "releases",
      d.list(d.decode2(
        Release,
        d.field("version", d.string),
        d.field("url", d.string),
      )),
    ),
  )
}
