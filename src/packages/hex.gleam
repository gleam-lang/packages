import gleam/io
import gleam/json
import gleam/http
import gleam/result
import gleam/hackney
import gleam/list
import gleam/dynamic.{Decoder} as d
import time/parse.{parse_iso8601_to_epoch_timestamp}
import gleam/pgo
import gleam/string
import gleam/int

pub type Error {
  HackneyError(hackney.Error)
  JsonError(json.DecodeError)
  DatabaseError(pgo.QueryError)
  MiscError(String)
}

pub fn query(db: pgo.Connection) {
  try last_scanned = get_last_scanned(db)

  try packages = query_all_packages([], 1, last_scanned)

  assert Ok(_) = update_last_scanned(db)

  Ok(
    packages
    |> list.filter_map(sort_packages)
    |> io.debug,
  )
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
    [first, ..] -> Ok(parse.to_epoch_timetsamp(first.1))
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
  // 2. Get list of releases to check
  //    If in DB: only new releases
  //    If not: all releases
  // 3. Query list of releases and make a new list of valid ones
  // 4. If any valid insert into DB with a corresponding package row
  // 5. Update package in DB if out of date
  // 6. Return the new list of DB Package Type
  Ok(package)
}

fn query_all_packages(
  last_page: List(Package),
  next_page: Int,
  last_ran: Int,
) -> Result(List(Package), Error) {
  let req =
    http.default_req()
    |> http.set_method(http.Get)
    |> http.prepend_req_header(
      "User-Agent",
      "GleamPackages/0.0.1 (Gleam/0.21.0)",
    )
    |> http.set_host("hex.pm")
    |> http.set_path(
      "/api/packages?sort=updated_at&page="
      |> string.append(int.to_string(next_page)),
    )

  try response =
    hackney.send(req)
    |> result.map_error(HackneyError)

  try packages =
    json.decode(response.body, d.list(package_decoder()))
    |> result.map_error(JsonError)

  let new_packages =
    packages
    |> list.filter(fn(x) {
      parse_iso8601_to_epoch_timestamp(x.updated_at) > last_ran
    })

  case list.length(new_packages) >= list.length(packages) {
    True -> query_all_packages(new_packages, next_page + 1, last_ran)
    False ->
      Ok(list.append(
        last_page,
        packages
        |> list.filter(fn(x) {
          parse_iso8601_to_epoch_timestamp(x.updated_at) > last_ran
        }),
      ))
  }
}

pub type Package {
  Package(name: String, updated_at: String, releases: List(Release))
}

pub type Release {
  Release(version: String, url: String)
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
