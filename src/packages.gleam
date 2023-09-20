import gleam/erlang
import gleam/erlang/os
import gleam/result
import gleam/erlang/process
import gleam/int
import gleam/io
import gleam/list
import gleam/otp/actor
import gleam/otp/supervisor
import gleam/string
import mist
import packages/index
import packages/periodic
import packages/syncing
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
    ["sync"] -> sync()
    _ -> io.println(usage)
  }
}

fn list() -> Nil {
  let db = index.connect()
  let assert Ok(packages) = index.search_packages(db, "")
  let packages =
    list.sort(packages, fn(a, b) { string.compare(a.name, b.name) })

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

fn sync() -> Nil {
  let db = index.connect()
  let assert Ok(key) = os.get_env("HEX_API_KEY")
  let assert Ok(Nil) = syncing.sync_new_gleam_releases(key, db)
  Nil
}

fn server() {
  let assert Ok(key) =
    os.get_env("HEX_API_KEY")
    |> result.map_error(fn(_) { "HEX_API_KEY environment variable is missing" })
  let db = index.connect()

  // Start the web server
  let service = web.make_service(db)
  let assert Ok(_) = mist.run_service(3000, service, max_body_limit: 4_000_000)
  io.println("Started listening on http://localhost:3000 ✨")

  // Start syncing new releases periodically
  let assert Ok(_) =
    supervise(fn() {
      let sync = fn() { syncing.sync_new_gleam_releases(key, db) }
      periodic.periodically(do: sync, waiting: 60 * 1000)
    })

  // Put the main process to sleep while the web server handles traffic
  process.sleep_forever()
}

fn supervise(start: fn() -> _) -> Result(_, actor.StartError) {
  supervisor.start(fn(children) {
    children
    |> supervisor.add(supervisor.worker(fn(_) { start() }))
  })
}
