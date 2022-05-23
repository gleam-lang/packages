import gleam/io
import gleam/json
import gleam/http
import gleam/result
import gleam/hackney
import gleam/list
import gleam/dynamic as d
import time/parse.{parse_iso8601_to_gregorian_seconds}
import gleam/pgo
import gleam/string
import gleam/int
import packages/models/hex/package.{HexPackage, hex_package_decoder}
import packages/models/hex/release.{hex_release_decoder}

pub type Error {
  HackneyError(hackney.Error)
  JsonError(json.DecodeError)
  DatabaseError(pgo.QueryError)
  ItemNotInListError(Nil)
}

pub fn query(db: pgo.Connection) {
  try last_scanned = get_last_scanned(db)

  try packages = query_all_packages([], 1, last_scanned)

  // Get the packages into order bassed on when they have
  // been updated with new data
  let packages =
    packages
    |> list.sort(fn(a, b) {
      int.compare(
        parse.parse_iso8601_to_gregorian_seconds(a.updated_at),
        parse.parse_iso8601_to_gregorian_seconds(b.updated_at),
      )
    })

  // Only update last scanned at if packages were actually
  // found that way we only ever use the time from
  // Hex's API, the list is revsersed so that the last package
  // is actually the first for easy with the case statement
  case packages
  |> list.reverse {
    [last, ..] -> {
      assert Ok(_) =
        update_last_scanned(db, parse.parse_iso8601(last.updated_at))
      Ok(Nil)
    }
    _ -> Ok(Nil)
  }

  packages
  |> list.filter_map(fliter_map_packages)
  // TODO (HarryET): Remove before merge of PR
  |> io.debug
  |> Ok
}

const last_scanned_query = "SELECT date_trunc('second', scanned_at) FROM previous_hex_api_scan LIMIT 1;"

fn get_last_scanned(db: pgo.Connection) -> Result(Int, Error) {
  let ints = d.tuple3(d.int, d.int, d.int)
  let datetime_decoder = d.tuple2(ints, ints)

  try response =
    pgo.execute(last_scanned_query, db, [], d.element(0, datetime_decoder))
    |> result.map_error(DatabaseError)

  case response.rows {
    [first, ..] -> Ok(parse.to_gregorian_seconds(first))
    _ -> Ok(0)
  }
}

fn update_last_scanned(
  db: pgo.Connection,
  date: parse.LocalDateTime,
) -> Result(pgo.Returned(d.Dynamic), Error) {
  // It is done this way as I could not figure out how to
  // inject a time as a string with the built in $1 system but
  // this is safe as the value is constructed from a known datatype
  pgo.execute(
    "UPDATE previous_hex_api_scan SET scanned_at = '"
    |> string.append(parse.to_pg_time(date))
    |> string.append("';"),
    db,
    [],
    d.dynamic,
  )
  |> result.map_error(DatabaseError)
}

fn fliter_map_packages(package: HexPackage) -> Result(HexPackage, Error) {
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
    |> result.map_error(ItemNotInListError)

  let req =
    http.default_req()
    |> http.set_method(http.Get)
    |> http.prepend_req_header("user-agent", "GleamPackages")
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
    json.decode(response.body, hex_release_decoder())
    |> result.map_error(JsonError)

  // Keep this package because the current version is made with gleam! ✨
  case list.contains(release.meta.build_tools, "gleam") {
    True -> Ok(package)
    False -> Error(ItemNotInListError(Nil))
  }
}

fn query_all_packages(
  last_page: List(HexPackage),
  next_page: Int,
  last_ran: Int,
) -> Result(List(HexPackage), Error) {
  let req =
    http.default_req()
    |> http.set_method(http.Get)
    |> http.prepend_req_header("user-agent", "GleamPackages")
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
    json.decode(response.body, d.list(hex_package_decoder()))
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
