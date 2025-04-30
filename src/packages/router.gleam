import birl
import gleam/http
import gleam/http/request
import gleam/int
import gleam/json
import gleam/list
import gleam/option
import gleam/result
import gleam/uri
import packages/storage
import packages/text_search
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
    ["internet-points"] -> internet_points(context)
    ["api", "packages"] -> api_packages(request, context)
    ["api", "packages", name] -> api_package(request, context, name)
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

fn api_packages(req: Request, ctx: Context) -> Response {
  use <- wisp.require_method(req, http.Get)
  let assert Ok(packages) = {
    use packages <- result.try(storage.list_packages(ctx.db))
    let packages = list.try_map(packages, storage.get_package(ctx.db, _))
    use packages <- result.try(packages)
    packages
    |> list.sort(fn(a, b) {
      int.compare(b.inserted_in_hex_at, a.inserted_in_hex_at)
    })
    |> Ok
  }
  json.object([#("data", json.array(packages, package_to_json))])
  |> json.to_string_tree()
  |> wisp.json_response(200)
}

fn api_package(req: Request, ctx: Context, name: String) -> Response {
  use <- wisp.require_method(req, http.Get)
  let assert Ok(package) = storage.get_package(ctx.db, name)
  json.object([#("data", package_to_json(package))])
  |> json.to_string_tree()
  |> wisp.json_response(200)
}

fn package_to_json(package: storage.Package) -> json.Json {
  json.object([
    #("name", json.string(package.name)),
    #("description", json.string(package.description)),
    #("latest-version", json.string(package.latest_version)),
    #("repository", json.nullable(package.repository_url, json.string)),
  ])
}

fn internet_points(context: Context) -> Response {
  let assert Ok(package_counts) = storage.new_package_count_per_day(context.db)
  let assert Ok(release_counts) = storage.new_release_count_per_day(context.db)
  let stats =
    page.Stats(package_counts: package_counts, release_counts: release_counts)
  page.internet_points(stats)
  |> wisp.html_response(200)
}

fn search(request: Request, context: Context) -> Response {
  let search_term = get_search_parameter(request)
  let assert Ok(packages) = case search_term {
    "" -> storage.list_packages(context.db)
    _ -> text_search.lookup(context.search_index, search_term)
  }
  let assert Ok(packages) = storage.package_summaries(context.db, packages)
  let packages = case search_term {
    "" ->
      list.sort(packages, fn(a, b) {
        birl.compare(b.updated_in_hex_at, a.updated_in_hex_at)
      })
    _ -> packages
  }
  let assert Ok(total_package_count) =
    storage.get_total_package_count(context.db)

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
