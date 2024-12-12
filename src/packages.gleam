import argv
import envoy
import gleam/erlang/process
import gleam/io
import gleam/otp/actor
import gleam/otp/supervisor
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
    ["sync", "--name", package_name] -> sync_one(package_name)
    _ -> io.println(usage)
  }
}

fn server() {
  wisp.configure_logger()

  let assert Ok(key) = envoy.get("HEX_API_KEY")
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
      search_index: index,
      static_directory: static_directory,
    )
  }

  // Start the web server
  let assert Ok(_) =
    router.handle_request(_, make_context)
    |> wisp_mist.handler(secret_key_base)
    |> mist.new
    |> mist.port(3000)
    |> mist.start_http

  // Start syncing new releases periodically
  let assert Ok(_) = start_hex_syncer(database, key)

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
  supervisor.start(fn(children) {
    children
    |> supervisor.add(supervisor.worker(fn(_) { start() }))
  })
}

fn database_path() {
  case envoy.get("DATABASE_PATH") {
    Ok(path) -> path
    Error(Nil) -> "./storage"
  }
}

fn start_hex_syncer(db: storage.Database, api_key: String) -> Result(_, _) {
  supervise(fn() {
    let sync = fn() { syncing.sync_new_gleam_releases(api_key, db) }
    periodic.periodically(do: sync, waiting: 60 * 1000)
  })
}

fn sync_one(package_name: String) -> Nil {
  let db = storage.initialise(database_path())
  let assert Ok(key) = envoy.get("HEX_API_KEY")
  let assert Ok(Nil) =
    syncing.fetch_and_sync_package(db, package_name, secret: key)
  Nil
}
