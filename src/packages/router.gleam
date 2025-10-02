import gleam/float
import gleam/http
import gleam/http/request
import gleam/json
import gleam/list
import gleam/option
import gleam/result
import gleam/string
import gleam/time/calendar
import gleam/time/timestamp
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
    ["api"] -> api(request, context)
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

fn api(request: Request, context: Context) -> Response {
  use <- wisp.require_method(request, http.Get)
  let time = fn(timestamp) {
    json.string(timestamp.to_rfc3339(timestamp, calendar.utc_offset))
  }
  let url = "https://github.com/gleam-lang/packages/commit/" <> context.git_sha
  json.object([
    #("version", json.string(context.git_sha)),
    #("code", json.string(url)),
    #("started-at", time(context.start_time)),
    #("built-at", time(context.build_time)),
  ])
  |> json.to_string()
  |> wisp.json_response(200)
}

fn api_packages(req: Request, ctx: Context) -> Response {
  use <- wisp.require_method(req, http.Get)
  let assert Ok(packages) = {
    use packages <- result.try(storage.list_packages(ctx.db))
    let packages = list.try_map(packages, storage.get_package(ctx.db, _))
    use packages <- result.try(packages)
    packages
    |> list.sort(fn(a, b) {
      timestamp.compare(b.inserted_in_hex_at, a.inserted_in_hex_at)
    })
    |> Ok
  }
  json.object([#("data", json.array(packages, package_to_json(_, option.None)))])
  |> json.to_string()
  |> wisp.json_response(200)
}

fn api_package(req: Request, ctx: Context, name: String) -> Response {
  use <- wisp.require_method(req, http.Get)

  let json = {
    use package <- result.try(storage.get_package(ctx.db, name))
    use releases <- result.try(storage.get_releases(ctx.db, name))
    let json = package_to_json(package, option.Some(releases))
    let json = json.object([#("data", json)])
    Ok(json)
  }

  case json {
    Ok(json) -> json |> json.to_string() |> wisp.json_response(200)
    Error(_) -> wisp.not_found()
  }
}

pub fn package_to_json(
  package: storage.Package,
  releases: option.Option(List(storage.Release)),
) -> json.Json {
  let fields = [
    #("name", json.string(package.name)),
    #("description", json.string(package.description)),
    #("latest-version", json.string(package.latest_version)),
    #("repository", json.nullable(package.repository_url, json.string)),
    #("updated-at", json_timestamp(package.updated_in_hex_at)),
    #("owners", json.array(package.owners, json.string)),
    #("total-downloads", json.int(package.downloads_all)),
    #("recent-downloads", json.int(package.downloads_recent)),
  ]

  let fields = case releases {
    option.None -> fields
    option.Some(releases) -> {
      let releases =
        releases
        |> list.sort(fn(a, b) {
          timestamp.compare(b.inserted_in_hex_at, a.inserted_in_hex_at)
        })
        |> json.array(fn(release) {
          json.object([
            #("version", json.string(release.version)),
            #("downloads", json.int(release.downloads)),
            #("updated-at", json_timestamp(release.updated_in_hex_at)),
          ])
        })
      list.append(fields, [#("releases", releases)])
    }
  }

  json.object(fields)
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
  let assert Ok(packages) =
    storage.ranked_package_summaries(context.db, packages, search_term)
  let packages = case search_term {
    "" ->
      list.sort(packages, fn(a, b) {
        timestamp.compare(b.updated_in_hex_at, a.updated_in_hex_at)
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
  |> result.try(uri.parse_query)
  |> result.try(list.key_find(_, "search"))
  |> result.unwrap("")
  |> string.trim
}

fn json_timestamp(timestamp: timestamp.Timestamp) -> json.Json {
  timestamp
  |> timestamp.to_unix_seconds
  |> float.round
  |> json.int
}
