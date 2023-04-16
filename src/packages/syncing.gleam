import gleam/dynamic as dyn
import gleam/hackney
import gleam/http/request
import gleam/int
import gleam/list
import gleam/list_extra
import gleam/json
import gleam/uri
import gleam/order
import gleam/hexpm
import gleam/io
import gleam/result
import packages/error.{Error}
import birl/time.{Time}

pub fn try(a: Result(a, e), f: fn(a) -> Result(b, e)) -> Result(b, e) {
  case a {
    Ok(a) -> f(a)
    Error(e) -> Error(e)
  }
}

type State {
  State(page: Int, limit: Time, hex_api_key: String, log: fn(String) -> Nil)
}

pub fn sync_new_gleam_releases(
  most_recent_timestamp: Time,
  hex_api_key: String,
) -> Result(Nil, Error) {
  sync_packages(State(
    page: 1,
    limit: most_recent_timestamp,
    hex_api_key: hex_api_key,
    log: io.println,
  ))
}

fn sync_packages(state: State) -> Result(Nil, Error) {
  state.log("\nPage: " <> int.to_string(state.page))

  // Get the next page of packages from the API.
  use all_packages <- try(get_api_packages_page(state))

  // Take all the releases that we have not seen before.
  let new_packages =
    all_packages
    |> take_fresh_packages(state.limit)
  list.map(new_packages, with_only_fresh_releases(_, state.limit))

  // Insert the new releases into the database.
  use Nil <- try(list_extra.try_each(new_packages, sync_package(_, state)))

  case list.length(all_packages) == list.length(new_packages) {
    // If all the releases were new then there may be more on the next page.
    True -> sync_packages(State(..state, page: state.page + 1))

    // If some packages where not new then we have reached the end of the new
    // releases and can stop.
    False -> {
      state.log("Up to date!")
      Ok(Nil)
    }
  }
}

fn get_api_packages_page(state: State) -> Result(List(hexpm.Package), Error) {
  let assert Ok(response) =
    request.new()
    |> request.set_host("hex.pm")
    |> request.set_path("/api/packages")
    |> request.set_query([
      #("sort", "updated_at"),
      #("page", int.to_string(state.page)),
    ])
    |> request.prepend_header("authorization", state.hex_api_key)
    |> hackney.send

  let assert Ok(all_packages) =
    json.decode(response.body, using: dyn.list(of: hexpm.decode_package))
  Ok(all_packages)
}

pub fn take_fresh_packages(
  packages: List(hexpm.Package),
  limit: Time,
) -> List(hexpm.Package) {
  use package <- list.take_while(packages)
  let assert Ok(updated_at) = time.from_iso8601(package.updated_at)
  time.compare(limit, updated_at) == order.Lt
}

pub fn with_only_fresh_releases(
  package: hexpm.Package,
  limit: Time,
) -> hexpm.Package {
  let releases =
    package.releases
    |> list.take_while(fn(release) {
      let assert Ok(updated_at) = time.from_iso8601(release.inserted_at)
      time.compare(limit, updated_at) == order.Lt
    })
  hexpm.Package(..package, releases: releases)
}

fn sync_package(package: hexpm.Package, state: State) -> Result(Nil, Error) {
  // TODO: insert package
  list_extra.try_each(package.releases, sync_release(_, state))
}

fn sync_release(
  release: hexpm.PackageRelease,
  state: State,
) -> Result(Nil, Error) {
  let assert Ok(url) = uri.parse(release.url)

  use response <- try(
    request.new()
    |> request.set_host("hex.pm")
    |> request.set_path(url.path)
    |> request.prepend_header("authorization", state.hex_api_key)
    |> hackney.send
    |> result.map_error(error.HttpClientError),
  )

  use _release <- try(
    json.decode(response.body, using: hexpm.decode_release)
    |> result.map_error(error.JsonDecodeError),
  )

  Ok(Nil)
}
