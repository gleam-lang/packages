import birl.{type Time}
import birl/duration
import gleam/dynamic as dyn
import gleam/hackney
import gleam/hexpm
import gleam/option
import gleam/http/request
import gleam/int
import gleam/json
import gleam/list
import gleam/order
import gleam/result
import gleam/string
import gleam/uri
import packages/error.{type Error}
import packages/index
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
    limit: Time,
    newest: Time,
    hex_api_key: String,
    last_logged: Time,
    db: index.Connection,
  )
}

pub fn sync_new_gleam_releases(
  hex_api_key: String,
  db: index.Connection,
) -> Result(Nil, Error) {
  case index.has_write_permission() {
    True -> {
      wisp.log_info("Syncing new releases from Hex")
      use limit <- try(index.get_most_recent_hex_timestamp(db))
      use latest <- try(
        sync_packages(State(
          page: 1,
          limit: limit,
          newest: limit,
          hex_api_key: hex_api_key,
          last_logged: birl.now(),
          db: db,
        )),
      )
      let latest = index.upsert_most_recent_hex_timestamp(db, latest)
      wisp.log_info("\nUp to date!")
      latest
    }

    False -> {
      wisp.log_info("Node lacks write permission to DB, not syncing")
      Ok(Nil)
    }
  }
}

pub fn fetch_and_sync_package(
  db: index.Connection,
  package_name: String,
  secret hex_api_key: String,
) -> Result(Nil, Error) {
  use package <- try(get_api_package(package_name, secret: hex_api_key))
  wisp.log_info("Syncing package data from Hex")
  use _ <- try(sync_single_package(db, package, hex_api_key))
  wisp.log_info("\nDone")
  Ok(Nil)
}

fn sync_packages(state: State) -> Result(Time, Error) {
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
    _ if all_packages == []
    -> Ok(state.newest)
    False -> Ok(state.newest)

    // If all the releases were new then there may be more on the next page.
    True -> sync_packages(State(..state, page: state.page + 1))
  }
}

fn first_timestamp(packages: List(hexpm.Package), state: State) -> Time {
  case packages {
    [] -> state.newest
    [package, ..] -> {
      case birl.compare(package.updated_at, state.newest) {
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

fn get_api_package(
  package_name: String,
  secret hex_api_key: String,
) -> Result(hexpm.Package, Error) {
  use response <- result.try(
    request.new()
    |> request.set_host("hex.pm")
    |> request.set_path("/api/packages/" <> package_name)
    |> request.prepend_header("authorization", hex_api_key)
    |> hackney.send
    |> result.map_error(error.HttpClientError),
  )

  use package <- result.try(
    json.decode(response.body, using: hexpm.decode_package)
    |> result.map_error(error.JsonDecodeError),
  )
  Ok(package)
}

pub fn take_fresh_packages(
  packages: List(hexpm.Package),
  limit: Time,
) -> List(hexpm.Package) {
  use package <- list.take_while(packages)
  birl.compare(limit, package.updated_at) == order.Lt
}

pub fn with_only_fresh_releases(
  package: hexpm.Package,
  limit: Time,
) -> hexpm.Package {
  let releases =
    package.releases
    |> list.take_while(fn(release) {
      birl.compare(limit, release.inserted_at) == order.Lt
    })
  hexpm.Package(..package, releases: releases)
}

fn sync_package(state: State, package: hexpm.Package) -> Result(State, Error) {
  use releases <- try(lookup_gleam_releases(package, secret: state.hex_api_key))

  case releases {
    [] -> {
      use _ <- try(index.delete_package(state.db, package.name))
      let state = log_if_needed(state, package.updated_at)
      Ok(state)
    }
    _ -> {
      use _ <- try(insert_package_and_releases(package, releases, state.db))
      let state = State(..state, last_logged: birl.now())
      Ok(state)
    }
  }
}

fn sync_single_package(
  db: index.Connection,
  package: hexpm.Package,
  secret hex_api_key: String,
) -> Result(Nil, Error) {
  use releases <- try(lookup_gleam_releases(package, secret: hex_api_key))

  case releases {
    [] -> {
      use _ <- try(index.delete_package(db, package.name))
      Ok(Nil)
    }
    _ -> {
      use _ <- try(insert_package_and_releases(package, releases, db))
      Ok(Nil)
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
    // Select packages built with gleam, ignore retired releases
    list.contains(release.meta.build_tools, "gleam") && option.is_none(
      release.retirement,
    )
  })
  |> Ok
}

fn log_if_needed(state: State, time: Time) -> State {
  let interval = duration.new([#(5, duration.Second)])
  let print_deadline = birl.add(state.last_logged, interval)
  let not_logged_recently = birl.compare(print_deadline, birl.now()) == order.Lt
  case not_logged_recently {
    True -> {
      wisp.log_info("Still syncing, up to " <> birl.to_iso8601(time))
      State(..state, last_logged: birl.now())
    }
    False -> state
  }
}

fn insert_package_and_releases(
  package: hexpm.Package,
  releases: List(hexpm.Release),
  db: index.Connection,
) -> Result(Nil, Error) {
  let versions =
    releases
    |> list.map(fn(release) { release.version })
    |> string.join(", v")
  wisp.log_info("Saving " <> package.name <> " v" <> versions)

  use id <- try(index.upsert_package(db, package))

  releases
  |> list.try_each(fn(release) { index.upsert_release(db, id, release) })
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
    |> hackney.send
    |> result.map_error(error.HttpClientError),
  )

  json.decode(response.body, using: hexpm.decode_release)
  |> result.map_error(error.JsonDecodeError)
}
