import gleam/dynamic/decode
import gleam/hexpm
import gleam/http/request
import gleam/httpc
import gleam/int
import gleam/json
import gleam/list
import gleam/option
import gleam/order
import gleam/result
import gleam/string
import gleam/time/calendar
import gleam/time/duration
import gleam/time/timestamp.{type Timestamp}
import gleam/uri
import packages/error.{type Error}
import packages/storage.{type Database}
import packages/text_search
import wisp

pub fn try(a: Result(a, e), f: fn(a) -> Result(b, e)) -> Result(b, e) {
  case a {
    Ok(a) -> f(a)
    Error(e) -> Error(e)
  }
}

type State {
  State(
    page: Int,
    limit: Timestamp,
    newest: Timestamp,
    hex_api_key: String,
    last_logged: Timestamp,
    db: storage.Database,
    text_search: text_search.TextSearchIndex,
  )
}

pub fn sync_new_gleam_releases(
  hex_api_key: String,
  db: Database,
  text_search: text_search.TextSearchIndex,
) -> Result(Nil, Error) {
  wisp.log_info("Syncing new releases from Hex")
  use limit <- try(storage.get_most_recent_hex_timestamp(db))
  use latest <- try(
    sync_packages(State(
      page: 1,
      limit:,
      newest: limit,
      hex_api_key:,
      last_logged: timestamp.system_time(),
      db:,
      text_search:,
    )),
  )
  let latest = storage.upsert_most_recent_hex_timestamp(db, latest)
  wisp.log_info("Up to date!")
  latest
}

pub fn fetch_and_sync_package(
  db: storage.Database,
  text_search: text_search.TextSearchIndex,
  package_name: String,
  secret hex_api_key: String,
) -> Result(Nil, Error) {
  let state =
    State(
      page: 0,
      limit: timestamp.system_time(),
      newest: timestamp.system_time(),
      last_logged: timestamp.system_time(),
      hex_api_key:,
      db:,
      text_search:,
    )
  wisp.log_info("Syncing package data from Hex")
  use _ <- try(sync_package(state, package_name))
  wisp.log_info("Done")
  Ok(Nil)
}

fn sync_packages(state: State) -> Result(Timestamp, Error) {
  // Get the next page of packages from the API.
  use all_packages <- try(get_api_packages_page(state))

  // The timestamp of the first package on the page is the newest. index this so
  // we can record it in the database to use as the limit for the next sync.
  let state = State(..state, newest: first_timestamp(all_packages, state))

  // Take all the releases that we have not seen before.
  let new_packages =
    all_packages
    |> take_fresh_packages(state.limit)
    |> list.map(with_only_fresh_releases(_, state.limit))
    |> list.map(fn(package) { package.name })

  // Insert the new releases into the database.
  use state <- try(list.try_fold(new_packages, state, sync_package))

  case list.length(all_packages) == list.length(new_packages) {
    // If there were no packages or some packages where not new then we have
    // reached the end of the new releases and can stop.
    _ if all_packages == [] -> Ok(state.newest)
    False -> Ok(state.newest)

    // If all the releases were new then there may be more on the next page.
    True -> sync_packages(State(..state, page: state.page + 1))
  }
}

fn first_timestamp(packages: List(hexpm.Package), state: State) -> Timestamp {
  case packages {
    [] -> state.newest
    [package, ..] -> {
      let updated_at = package.updated_at
      case timestamp.compare(updated_at, state.newest) {
        order.Gt -> updated_at
        _ -> state.newest
      }
    }
  }
}

fn get_api_packages_page(state: State) -> Result(List(hexpm.Package), Error) {
  use response <- result.try(
    request.new()
    |> request.set_host("hex.pm")
    |> request.set_path("/api/packages")
    |> request.set_query([
      #("search", "build_tool:gleam"),
      #("sort", "updated_at"),
      #("page", int.to_string(state.page)),
    ])
    |> request.prepend_header("authorization", state.hex_api_key)
    |> httpc.send
    |> result.map_error(error.HttpClientError),
  )

  use all_packages <- result.try(
    json.parse(response.body, using: decode.list(of: hexpm.package_decoder()))
    |> result.map_error(error.JsonDecodeError),
  )
  Ok(all_packages)
}

fn get_api_package(
  package_name: String,
  secret hex_api_key: String,
) -> Result(hexpm.Package, Error) {
  use response <- result.try(
    request.new()
    |> request.set_host("hex.pm")
    |> request.set_path("/api/packages/" <> package_name)
    |> request.prepend_header("authorization", hex_api_key)
    |> httpc.send
    |> result.map_error(error.HttpClientError),
  )

  use package <- result.try(
    json.parse(response.body, using: hexpm.package_decoder())
    |> result.map_error(error.JsonDecodeError),
  )
  Ok(package)
}

pub fn take_fresh_packages(
  packages: List(hexpm.Package),
  limit: Timestamp,
) -> List(hexpm.Package) {
  use package <- list.take_while(packages)
  let updated_at = package.updated_at
  timestamp.compare(limit, updated_at) == order.Lt
}

pub fn with_only_fresh_releases(
  package: hexpm.Package,
  limit: Timestamp,
) -> hexpm.Package {
  let releases =
    package.releases
    |> list.take_while(fn(release) {
      timestamp.compare(limit, release.inserted_at) == order.Lt
    })
  hexpm.Package(..package, releases: releases)
}

fn sync_package(state: State, package_name: String) -> Result(State, Error) {
  // We want all the information about the package, so we fetch the package
  // again from the package endpoint, as the package list endpoint doesn't have
  // all the data.
  use package <- try(get_api_package(package_name, secret: state.hex_api_key))

  use releases <- try(lookup_gleam_releases(package, secret: state.hex_api_key))

  case releases {
    [] -> {
      let state = log_if_needed(state, package.updated_at)
      Ok(state)
    }
    _ -> {
      use _ <- try(insert_package_and_releases(package, releases, state))
      let state = State(..state, last_logged: timestamp.system_time())
      Ok(state)
    }
  }
}

fn lookup_gleam_releases(
  package: hexpm.Package,
  secret hex_api_key: String,
) -> Result(List(hexpm.Release), Error) {
  use releases <- try(
    list.try_map(package.releases, lookup_release(_, hex_api_key)),
  )
  releases
  |> list.filter(fn(release) {
    list.contains(release.meta.build_tools, "gleam")
  })
  |> Ok
}

fn log_if_needed(state: State, time: Timestamp) -> State {
  let interval = duration.seconds(5)
  let print_deadline = timestamp.add(state.last_logged, interval)
  let not_logged_recently =
    timestamp.compare(print_deadline, timestamp.system_time()) == order.Lt
  case not_logged_recently {
    True -> {
      let date = timestamp.to_rfc3339(time, calendar.local_offset())
      wisp.log_info("Still syncing, up to " <> date)
      State(..state, last_logged: timestamp.system_time())
    }
    False -> state
  }
}

fn insert_package_and_releases(
  package: hexpm.Package,
  releases: List(hexpm.Release),
  state: State,
) -> Result(Nil, Error) {
  let assert Ok(latest) =
    releases
    |> list.sort(fn(a, b) { timestamp.compare(b.inserted_at, a.inserted_at) })
    |> list.first
  let versions =
    releases
    |> list.map(fn(release) { release.version })
    |> string.join(", v")
  wisp.log_info("Saving " <> package.name <> " v" <> versions)

  use _ <- try(text_search.update(
    state.text_search,
    package.name,
    package.meta.description |> option.unwrap(""),
  ))

  use _ <- try(storage.upsert_package_from_hex(
    state.db,
    package,
    latest.version,
  ))

  let now = timestamp.system_time()
  releases
  |> list.try_each(storage.upsert_release(state.db, package.name, _, now))
}

fn lookup_release(
  release: hexpm.PackageRelease,
  secret hex_api_key: String,
) -> Result(hexpm.Release, Error) {
  let assert Ok(url) = uri.parse(release.url)

  use response <- try(
    request.new()
    |> request.set_host("hex.pm")
    |> request.set_path(url.path)
    |> request.prepend_header("authorization", hex_api_key)
    |> httpc.send
    |> result.map_error(error.HttpClientError),
  )

  json.parse(from: response.body, using: hexpm.release_decoder())
  |> result.map_error(error.JsonDecodeError)
}
