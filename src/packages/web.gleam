import mist
import gleam/uri
import gleam/option
import gleam/list
import gleam/result
import gleam/erlang/file
import gleam/erlang_extra
import gleam/bit_builder.{BitBuilder}
import gleam/http/request.{Request}
import gleam/http/response.{Response}
import packages/index
import packages/web/page

pub type Context {
  Context(db: index.Connection, request: Request(BitString))
}

pub fn make_service(
  db_connect: fn() -> index.Connection,
) -> fn(Request(mist.Connection)) -> Response(mist.ResponseData) {
  fn(request) {
    case mist.read_body(request, 1024 * 1024 * 10) {
      Ok(request) -> {
        let db = db_connect()
        let context = Context(db: db, request: request)
        handle_request(context)
      }
      Error(_) -> {
        response.new(400)
        |> response.set_body(bit_builder.new())
      }
    }
    |> response.map(mist.Bytes)
  }
}

pub fn handle_request(context: Context) -> Response(BitBuilder) {
  let path = request.path_segments(context.request)
  case path {
    [] -> search(context)
    ["styles.css"] -> stylesheet()
    ["main.js"] -> javascript()
    _ -> redirect(to: "/")
  }
}

fn stylesheet() -> Response(BitBuilder) {
  let assert Ok(priv) = erlang_extra.priv_directory("packages")
  let assert Ok(css) = file.read_bits(priv <> "/styles.css")
  response.new(200)
  |> response.set_header("content-type", "text/css; charset=utf-8")
  |> response.set_body(bit_builder.from_bit_string(css))
}

fn javascript() -> Response(BitBuilder) {
  let assert Ok(priv) = erlang_extra.priv_directory("packages")
  let assert Ok(js) = file.read_bits(priv <> "/main.js")
  response.new(200)
  |> response.set_header(
    "content-type",
    "application/javascript; charset=utf-8",
  )
  |> response.set_body(bit_builder.from_bit_string(js))
}

fn search(context: Context) -> Response(BitBuilder) {
  let search_term = get_search_parameter(context.request)
  let assert Ok(packages) = index.search_packages(context.db, search_term)
  let assert Ok(total_package_count) = index.get_total_package_count(context.db)

  let html = page.packages_list(packages, total_package_count, search_term)
  response.new(200)
  |> response.set_header("content-type", "text/html; charset=utf-8")
  |> response.set_body(html)
}

fn get_search_parameter(request: Request(_)) -> String {
  request.query
  |> option.to_result(Nil)
  |> result.then(uri.parse_query)
  |> result.then(list.key_find(_, "search"))
  |> result.unwrap("")
}

fn redirect(to destination: String) -> Response(BitBuilder) {
  response.redirect(destination)
  |> response.map(bit_builder.from_string)
}
