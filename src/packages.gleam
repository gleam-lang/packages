import gleam/dynamic
import gleam/hackney
import gleam/hexpm
import gleam/http/request
import gleam/io
import gleam/int
import gleam/json
import gleam/list
import gleam/bool
import gleam/uri
import gleam/erlang

pub fn main() {
  get_packages(1)
}

pub fn get_packages(page: Int) {
  let assert [key] = erlang.start_arguments()

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

  {
    use package <- list.each(packages)
    io.println(package.name)

    use release <- list.each(package.releases)
    get_release(release.url, key)
  }
  get_packages(page + 1)
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
