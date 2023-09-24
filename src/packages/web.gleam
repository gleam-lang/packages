import mist
import gleam/uri
import gleam/option.{None}
import gleam/list
import gleam/result
import gleam/erlang_extra
import gleam/bit_builder
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
        |> response.map(mist.Bytes)
      }
    }
  }
}

pub fn handle_request(context: Context) -> Response(mist.ResponseData) {
  let path = request.path_segments(context.request)
  case path {
    [] -> search(context)
    ["packages.sqlite"] -> download_database()
    ["styles.css"] -> stylesheet()
    ["main.js"] -> javascript()
    _ -> redirect(to: "/")
  }
}

fn download_database() -> Response(mist.ResponseData) {
  let assert Ok(file) =
    mist.send_file(index.export_path, offset: 0, limit: None)
  response.new(200)
  |> response.set_header("content-type", "application/vnd.sqlite3")
  |> response.set_header(
    "content-disposition",
    "attachment; filename=packages.sqlite",
  )
  |> response.set_body(file)
}

fn stylesheet() -> Response(mist.ResponseData) {
  let assert Ok(priv) = erlang_extra.priv_directory("packages")
  let assert Ok(file) =
    mist.send_file(priv <> "/styles.css", offset: 0, limit: None)
  response.new(200)
  |> response.set_header("content-type", "text/css; charset=utf-8")
  |> response.set_body(file)
}

fn javascript() -> Response(mist.ResponseData) {
  let assert Ok(priv) = erlang_extra.priv_directory("packages")
  let assert Ok(file) =
    mist.send_file(priv <> "/main.js", offset: 0, limit: None)
  response.new(200)
  |> response.set_header(
    "content-type",
    "application/javascript; charset=utf-8",
  )
  |> response.set_body(file)
}

fn search(context: Context) -> Response(mist.ResponseData) {
  let search_term = get_search_parameter(context.request)
  let assert Ok(packages) = index.search_packages(context.db, search_term)
  let assert Ok(total_package_count) = index.get_total_package_count(context.db)

  let html = page.packages_list(packages, total_package_count, search_term)
  response.new(200)
  |> response.set_header("content-type", "text/html; charset=utf-8")
  |> response.set_body(mist.Bytes(html))
}

fn get_search_parameter(request: Request(_)) -> String {
  request.query
  |> option.to_result(Nil)
  |> result.then(uri.parse_query)
  |> result.then(list.key_find(_, "search"))
  |> result.unwrap("")
}

fn redirect(to destination: String) -> Response(mist.ResponseData) {
  response.redirect(destination)
  |> response.map(bit_builder.from_string)
  |> response.map(mist.Bytes)
}
