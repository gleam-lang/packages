import gleam/dynamic as dyn
import gleam/hackney
import gleam/http/request
import gleam/int
import gleam/json
import gleam/bool
import gleam/uri
import gleam/order.{Eq, Gt, Lt}
import gleam/hexpm
import gleam/io
import packages/error.{Error}
import birl/time.{Time}

type State {
  State(page: Int, limit: Time, hex_api_key: String, log: fn(String) -> Nil)
}

type Next {
  Done
  Continue
}

pub fn sync_new_gleam_releases(
  most_recent_timestamp: Time,
  hex_api_key: String,
) -> Result(Nil, Error) {
  let state =
    State(
      page: 1,
      limit: most_recent_timestamp,
      hex_api_key: hex_api_key,
      log: io.println,
    )
  sync_packages(state)
  Ok(Nil)
}

fn sync_packages(state: State) {
  state.log("\nPage: " <> int.to_string(state.page))

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

  let assert Ok(packages) =
    json.decode(response.body, using: dyn.list(of: hexpm.decode_package))

  use <- bool.guard(when: packages == [], return: Nil)

  let next = iterate_over_packages(packages, state)

  // TODO: Only get the next page if all the packages are younger than the limit
  case next {
    Done -> state.log("Up to date!")
    Continue -> sync_packages(State(..state, page: state.page + 1))
  }
}

fn iterate_over_packages(packages: List(hexpm.Package), state: State) -> Next {
  case packages {
    [] -> Continue
    [package, ..packages] -> {
      let assert Ok(updated_at) = time.from_iso8601(package.updated_at)
      case time.compare(state.limit, updated_at) {
        Eq | Gt -> Done
        Lt -> {
          state.log("  " <> package.name)
          iterate_over_releases(package.releases, state)
          iterate_over_packages(packages, state)
        }
      }
    }
  }
}

fn iterate_over_releases(
  _releases: List(hexpm.PackageRelease),
  state: State,
) -> Nil {
  // TODO: Iterate over released until we find one that is older than the limit,
  // or we run out of releases.
  // get_release(release.url, key)
  Nil
}

fn get_release(url: String, state: State) {
  state.log("  " <> url)
  let assert Ok(url) = uri.parse(url)

  let assert Ok(response) =
    request.new()
    |> request.set_host("hex.pm")
    |> request.set_path(url.path)
    |> request.prepend_header("authorization", state.hex_api_key)
    |> hackney.send

  case json.decode(response.body, using: hexpm.decode_release) {
    Ok(_) -> Nil
    Error(e) -> {
      io.println(response.body)
      io.debug(e)
      panic
    }
  }
}
