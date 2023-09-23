import birl/time.{DateTime}
import birl/duration
import gleam/dynamic as dyn
import gleam/hackney
import gleam/hexpm
import gleam/http/request
import gleam/int
import gleam/io
import gleam/json
import gleam/list
import gleam/list_extra
import gleam/order
import gleam/result
import gleam/string
import gleam/uri
import packages/error.{Error}
import packages/index

pub fn try(a: Result(a, e), f: fn(a) -> Result(b, e)) -> Result(b, e) {
  case a {
    Ok(a) -> f(a)
    Error(e) -> Error(e)
  }
}

type State {
  State(
    page: Int,
    limit: DateTime,
    newest: DateTime,
    hex_api_key: String,
    last_logged: DateTime,
    db: index.Connection,
  )
}

pub fn sync_new_gleam_releases(
  hex_api_key: String,
  db: index.Connection,
) -> Result(Nil, Error) {
  case index.has_write_permission() {
    True -> {
      io.println("Syncing new releases from Hex")
      use limit <- try(index.get_most_recent_hex_timestamp(db))
      use latest <- try(sync_packages(State(
        page: 1,
        limit: limit,
        newest: limit,
        hex_api_key: hex_api_key,
        last_logged: time.now(),
        db: db,
      )))
      let latest = index.upsert_most_recent_hex_timestamp(db, latest)
      io.println("\nUp to date!")
      latest
    }

    False -> {
      io.println("Node lacks write permission to DB, not syncing")
      Ok(Nil)
    }
  }
}

fn sync_packages(state: State) -> Result(DateTime, Error) {
  // Get the next page of packages from the API.
  use all_packages <- try(get_api_packages_page(state))

  // The timestamp of the first package on the page is the newest. index this so
  // we can record it in the database to use as the limit for the next sync.
  let state = State(..state, newest: first_timestamp(all_packages, state))

  // Take all the releases that we have not seen before.
  let new_packages =
    all_packages
    |> take_fresh_packages(state.limit)
  list.map(new_packages, with_only_fresh_releases(_, state.limit))

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

fn first_timestamp(packages: List(hexpm.Package), state: State) -> DateTime {
  case packages {
    [] -> state.newest
    [package, ..] -> {
      case time.compare(package.updated_at, state.newest) {
        order.Gt -> package.updated_at
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
      #("sort", "updated_at"),
      #("page", int.to_string(state.page)),
    ])
    |> request.prepend_header("authorization", state.hex_api_key)
    |> hackney.send
    |> result.map_error(error.HttpClientError),
  )

  use all_packages <- result.try(
    json.decode(response.body, using: dyn.list(of: hexpm.decode_package))
    |> result.map_error(error.JsonDecodeError),
  )
  Ok(all_packages)
}

pub fn take_fresh_packages(
  packages: List(hexpm.Package),
  limit: DateTime,
) -> List(hexpm.Package) {
  use package <- list.take_while(packages)
  time.compare(limit, package.updated_at) == order.Lt
}

pub fn with_only_fresh_releases(
  package: hexpm.Package,
  limit: DateTime,
) -> hexpm.Package {
  let releases =
    package.releases
    |> list.take_while(fn(release) {
      time.compare(limit, release.inserted_at) == order.Lt
    })
  hexpm.Package(..package, releases: releases)
}

fn sync_package(state: State, package: hexpm.Package) -> Result(State, Error) {
  use releases <- try(list.try_map(package.releases, lookup_release(_, state)))
  let releases =
    releases
    |> list.filter(fn(release) {
      list.contains(release.meta.build_tools, "gleam")
    })

  case releases {
    [] -> {
      let state = log_if_needed(state, package.updated_at)
      Ok(state)
    }
    _ -> {
      use _ <- try(insert_package_and_releases(package, releases, state))
      let state = State(..state, last_logged: time.now())
      Ok(state)
    }
  }
}

fn log_if_needed(state: State, time: DateTime) -> State {
  let interval = duration.new([#(5, duration.Second)])
  let print_deadline = time.add(state.last_logged, interval)
  let not_logged_recently = time.compare(print_deadline, time.now()) == order.Lt
  case not_logged_recently {
    True -> {
      io.println("Still syncing, up to " <> time.to_iso8601(time))
      State(..state, last_logged: time.now())
    }
    False -> state
  }
}

fn insert_package_and_releases(
  package: hexpm.Package,
  releases: List(hexpm.Release),
  state: State,
) -> Result(Nil, Error) {
  let versions =
    releases
    |> list.map(fn(release) { release.version })
    |> string.join(", v")
  io.println("Saving " <> package.name <> " v" <> versions)

  use id <- try(index.upsert_package(state.db, package))

  releases
  |> list_extra.try_each(fn(release) {
    index.upsert_release(state.db, id, release)
  })
}

fn lookup_release(
  release: hexpm.PackageRelease,
  state: State,
) -> Result(hexpm.Release, Error) {
  let assert Ok(url) = uri.parse(release.url)

  use response <- try(
    request.new()
    |> request.set_host("hex.pm")
    |> request.set_path(url.path)
    |> request.prepend_header("authorization", state.hex_api_key)
    |> hackney.send
    |> result.map_error(error.HttpClientError),
  )

  json.decode(response.body, using: hexpm.decode_release)
  |> result.map_error(error.JsonDecodeError)
}
