import gleam/dynamic
import gleam/hackney
import gleam/hexpm
import gleam/http/request
import gleam/io
import gleam/int
import gleam/json
import gleam/bool
import gleam/uri
import gleam/erlang
import gleam/string
import gleam/order.{Eq, Gt, Lt}

pub fn main() {
  let assert [key] = erlang.start_arguments()
  let limit = "2023-04-14T10:23:29.806017Z"
  get_packages(1, limit, key)
}

pub fn get_packages(page: Int, limit: String, key: String) {
  io.println("\nPage: " <> int.to_string(page))

  let assert Ok(response) =
    request.new()
    |> request.set_host("hex.pm")
    |> request.set_path("/api/packages")
    |> request.set_query([
      #("sort", "updated_at"),
      #("page", int.to_string(page)),
    ])
    |> request.prepend_header("authorization", key)
    |> hackney.send

  let assert Ok(packages) =
    json.decode(response.body, using: dynamic.list(of: hexpm.decode_package))

  use <- bool.guard(when: packages == [], return: Nil)

  let next = iterate_over_packages(packages, limit, key)

  // TODO: Only get the next page if all the packages are younger than the limit
  case next {
    Done -> io.println("Up to date!")
    Continue -> get_packages(page + 1, limit, key)
  }
}

type Next {
  Done
  Continue
}

fn iterate_over_packages(
  packages: List(hexpm.Package),
  limit: String,
  key: String,
) -> Next {
  case packages {
    [] -> Done
    [package, ..packages] -> {
      case string.compare(limit, package.updated_at) {
        Eq | Gt -> Done
        Lt -> {
          io.println(package.name)
          iterate_over_releases(package.releases, limit, key)
          iterate_over_packages(packages, limit, key)
        }
      }
    }
  }
}

fn iterate_over_releases(
  releases: List(hexpm.PackageRelease),
  limit: String,
  key: String,
) -> Nil {
  // TODO: Iterate over released until we find one that is older than the limit,
  // or we run out of releases.
  // get_release(release.url, key)
  io.println("Pretending to get releases")
}

pub fn get_release(url: String, key) {
  io.println(url)
  let assert Ok(url) = uri.parse(url)

  let assert Ok(response) =
    request.new()
    |> request.set_host("hex.pm")
    |> request.set_path(url.path)
    |> request.prepend_header("authorization", key)
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
