import argv
import envoy
import gleam/erlang/process
import gleam/int
import gleam/io
import gleam/list
import gleam/otp/actor
import gleam/otp/static_supervisor as supervisor
import gleam/otp/supervision
import gleam/result
import gleam/time/duration
import gleam/time/timestamp
import mist
import packages/error.{type Error}
import packages/periodic
import packages/router
import packages/storage
import packages/syncing
import packages/text_search
import packages/web
import wisp
import wisp/wisp_mist

const usage = "Usage:
  gleam run server
  gleam run sync --name PACKAGE_NAME
"

pub fn main() {
  wisp.configure_logger()

  case argv.load().arguments {
    ["server"] -> server()
    ["sync"] -> sync_all()
    ["sync", "--name", package_name] -> sync_one(package_name)
    _ -> io.println(usage)
  }
}

fn server() {
  wisp.configure_logger()

  let start_time = timestamp.system_time()
  let build_time =
    envoy.get("BUILD_TIME")
    |> result.try(int.parse)
    |> result.map(timestamp.from_unix_seconds)
    |> result.unwrap(start_time)
  let git_sha = envoy.get("GIT_SHA") |> result.unwrap("HEAD")
  let assert Ok(key) = envoy.get("HEX_API_KEY") as "HEX_API_KEY not set"
  let assert Ok(priv) = wisp.priv_directory("packages")
  let static_directory = priv <> "/static"
  let database = storage.initialise(database_path())
  let index = text_search.new()
  let assert Ok(_) = seed_index(index, database)

  // We don't use any signing in this application so the secret key can be
  // generated anew each time
  let secret_key_base = wisp.random_string(64)

  // Initialisation that is run per-request
  let make_context = fn() {
    web.Context(
      db: database,
      git_sha:,
      start_time:,
      build_time:,
      search_index: index,
      static_directory: static_directory,
    )
  }

  // Start the web server
  let assert Ok(_) =
    router.handle_request(_, make_context)
    |> wisp_mist.handler(secret_key_base)
    |> mist.new
    |> mist.bind("0.0.0.0")
    |> mist.port(3000)
    |> mist.start

  // Start syncing new releases periodically
  let assert Ok(_) = start_hex_syncer(database, index, key)

  // Put the main process to sleep while the web server handles traffic
  process.sleep_forever()
}

fn seed_index(
  index: text_search.TextSearchIndex,
  database: storage.Database,
) -> Result(Nil, Error) {
  use _, package <- storage.try_fold_packages(database, Nil)
  text_search.insert(
    index,
    package.name,
    package.name <> " " <> package.description,
  )
}

fn supervise(start: fn() -> _) -> Result(_, actor.StartError) {
  supervisor.new(supervisor.OneForOne)
  |> supervisor.add(supervision.worker(start))
  |> supervisor.start()
}

fn database_path() {
  case envoy.get("DATABASE_PATH") {
    Ok(path) -> path
    Error(Nil) -> "./storage"
  }
}

fn start_hex_syncer(
  db: storage.Database,
  text_search: text_search.TextSearchIndex,
  api_key: String,
) -> Result(_, _) {
  supervise(fn() {
    let sync = fn() {
      syncing.sync_new_gleam_releases(api_key, db, text_search)
    }
    periodic.periodically(do: sync, waiting: 60 * 1000)
  })
}

fn sync_all() -> Nil {
  wisp.configure_logger()

  // Prepare
  let assert Ok(api_key) = envoy.get("HEX_API_KEY") as "HEX_API_KEY not set"
  let db = storage.initialise(database_path())
  let index = text_search.new()

  // Sync
  let start_time = timestamp.system_time()
  let assert Ok(_) = syncing.sync_new_gleam_releases(api_key, db, index)
  let end_time = timestamp.system_time()

  // Report
  let assert Ok(packages) = storage.list_packages(db)
  let assert Ok(releases_count) =
    packages
    |> list.try_map(fn(p) {
      storage.list_releases(db, p) |> result.map(list.length)
    })
    |> result.map(int.sum)
  let packages_count = list.length(packages)

  let time_taken = timestamp.difference(start_time, end_time)
  io.println(
    "Synced in "
    <> duration.to_iso8601_string(time_taken)
    <> ". There are now "
    <> int.to_string(packages_count)
    <> " packages and "
    <> int.to_string(releases_count)
    <> " releases.",
  )

  Nil
}

fn sync_one(package_name: String) -> Nil {
  let db = storage.initialise(database_path())
  let index = text_search.new()
  let assert Ok(key) = envoy.get("HEX_API_KEY")
  let assert Ok(Nil) =
    syncing.fetch_and_sync_package(db, index, package_name, secret: key)
  Nil
}
