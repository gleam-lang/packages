import gleam/http/request
import gleam/list
import gleam/option
import gleam/result
import gleam/uri
import packages/index
import packages/web.{type Context}
import packages/web/page
import wisp.{type Request, type Response}

pub fn handle_request(
  request: Request,
  make_context: fn() -> Context,
) -> Response {
  let context = make_context()
  use request <- middleware(request, context)

  case request.path_segments(request) {
    [] -> search(request, context)
    ["packages.sqlite"] -> download_database()
    _ -> wisp.redirect(to: "/")
  }
}

pub fn middleware(
  req: Request,
  ctx: Context,
  handle_request: fn(Request) -> Response,
) -> Response {
  let req = wisp.method_override(req)
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use <- wisp.serve_static(req, under: "/static", from: ctx.static_directory)

  handle_request(req)
}

fn download_database() -> Response {
  wisp.ok()
  |> wisp.set_header("content-type", "application/vnd.sqlite3")
  |> wisp.set_header(
    "content-disposition",
    "attachment; filename=packages.sqlite",
  )
  |> wisp.set_body(wisp.File(index.export_path))
}

fn search(request: Request, context: Context) -> Response {
  let search_term = get_search_parameter(request)
  let assert Ok(packages) = index.search_packages(context.db, search_term)
  let assert Ok(total_package_count) = index.get_total_package_count(context.db)

  page.packages_list(packages, total_package_count, search_term)
  |> wisp.html_response(200)
}

fn get_search_parameter(request: Request) -> String {
  request.query
  |> option.to_result(Nil)
  |> result.then(uri.parse_query)
  |> result.then(list.key_find(_, "search"))
  |> result.unwrap("")
}
