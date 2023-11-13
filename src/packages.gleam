import gleam/erlang
import gleam/erlang/os
import gleam/erlang/process
import gleam/io
import gleam/otp/actor
import gleam/otp/supervisor
import gleam/result
import mist
import packages/error.{type Error}
import packages/index
import packages/periodic
import packages/syncing
import packages/router
import packages/web
import wisp

const usage = "Usage:
  gleam run server
  gleam run sync --name PACKAGE_NAME
"

pub fn main() {
  wisp.configure_logger()

  case erlang.start_arguments() {
    ["server"] -> server()
    ["sync", "--name", package_name] -> sync_one(package_name)
    _ -> io.println(usage)
  }
}

fn server() {
  let assert Ok(key) = os.get_env("HEX_API_KEY")
  let assert Ok(priv) = wisp.priv_directory("packages")
  let static_directory = priv <> "/static"
  let database_name = database_name()

  // We don't use any signing in this application so the secret key can be
  // generated anew each time
  let secret_key_base = wisp.random_string(64)

  // Initialisation that is run per-request
  let make_context = fn() {
    let db = index.connect(database_name)
    web.Context(db: db, static_directory: static_directory)
  }

  // Start the web server
  let assert Ok(_) =
    router.handle_request(_, make_context)
    |> wisp.mist_handler(secret_key_base)
    |> mist.new
    |> mist.port(3000)
    |> mist.start_http

  // Start syncing new releases periodically
  let assert Ok(_) = start_hex_syncer(database_name, key)

  // Start exporting the database periodically so that folks can download it if
  // they want to.
  let assert Ok(_) = start_database_exporter(database_name)

  // Put the main process to sleep while the web server handles traffic
  process.sleep_forever()
}

fn supervise(start: fn() -> _) -> Result(_, actor.StartError) {
  supervisor.start(fn(children) {
    children
    |> supervisor.add(supervisor.worker(fn(_) { start() }))
  })
}

fn export_database(name: String) -> Result(Nil, Error) {
  wisp.log_info("Exporting database to enable downloads")
  let db = index.connect(name)
  index.export(db)
}

fn database_name() {
  case os.get_env("DATABASE_PATH") {
    Ok(path) -> path
    Error(Nil) -> "./database.sqlite"
  }
}

fn start_hex_syncer(database_name: String, api_key: String) -> Result(_, _) {
  supervise(fn() {
    let sync = fn() {
      let db = index.connect(database_name)
      syncing.sync_new_gleam_releases(api_key, db)
    }
    periodic.periodically(do: sync, waiting: 60 * 1000)
  })
}

fn start_database_exporter(database_name: String) -> Result(_, _) {
  use _ <- result.try(
    export_database(database_name)
    |> result.nil_error,
  )
  supervise(fn() {
    periodic.periodically(
      do: fn() { export_database(database_name) },
      waiting: 60 * 60 * 1000,
    )
  })
  |> result.nil_error
}

fn sync_one(package_name: String) -> Nil {
  let db = index.connect(database_name())
  let assert Ok(key) = os.get_env("HEX_API_KEY")
  let assert Ok(Nil) =
    syncing.fetch_and_sync_package(db, package_name, secret: key)
  Nil
}
