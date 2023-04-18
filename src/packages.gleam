import birl/time
import gleam/erlang
import gleam/erlang/process
import gleam/int
import gleam/io
import gleam/list
import gleam/pgo
import gleam/string
import mist
import packages/generated/sql
import packages/syncing
import packages/store
import packages/web

const usage = "Usage:
  gleam run list
  gleam run server
  gleam run sync
"

pub fn main() {
  case erlang.start_arguments() {
    ["list"] -> list()
    ["server"] -> server()
    ["sync", key] -> sync(key)
    _ -> io.println(usage)
  }
}

fn list() -> Nil {
  let db = start_database_connection_pool()
  let assert Ok(packages) = store.list_packages(db)
  let packages =
    packages
    |> list.sort(fn(a, b) { string.compare(a.name, b.name) })

  packages
  |> list.each(fn(package) {
    let name = string.pad_right(package.name <> ":", 24, " ")
    let line = name <> " " <> package.description
    let line = case string.length(line) > 70 {
      True -> string.slice(line, 0, 67) <> "..."
      False -> line
    }
    io.println(line)
  })

  io.println("\n" <> int.to_string(list.length(packages)) <> " packages")
}

fn sync(key: String) -> Nil {
  let assert Ok(limit) = time.from_iso8601("2020-01-01T00:00:00.000000Z")
  let db = start_database_connection_pool()

  let assert Ok(_) =
    syncing.sync_new_gleam_releases(
      limit,
      key,
      store.upsert_package(db, _),
      fn(id, r) { store.upsert_release(db, id, r) },
    )

  Nil
}

fn server() {
  let db = start_database_connection_pool()

  // Start the web server process
  let assert Ok(_) =
    mist.run_service(3000, web.make_service(db), max_body_limit: 4_000_000)
  io.println("Started listening on http://localhost:3000 ✨")

  // Put the main process to sleep while the web server does its thing
  process.sleep_forever()
}

fn start_database_connection_pool() -> pgo.Connection {
  let db =
    pgo.connect(
      pgo.Config(
        ..pgo.default_config(),
        database: "gleam_packages",
        pool_size: 1,
      ),
    )
  let assert Ok(_) = sql.migrate_schema(db, [], Ok)
  db
}
