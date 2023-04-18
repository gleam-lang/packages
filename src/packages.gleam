import gleam/erlang
import gleam/erlang/process
import gleam/int
import gleam/io
import gleam/list
import gleam/string
import mist
import packages/syncing
import packages/store
import packages/web

const usage = "Usage:
  gleam run list
  gleam run server
  gleam run sync <hex_api_key>
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
  let db = store.connect()
  let assert Ok(packages) = store.search_packages(db, "")
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

fn sync(key: String) -> Nil {
  let db = store.connect()
  let assert Ok(Nil) = syncing.sync_new_gleam_releases(key, db)
  Nil
}

fn server() {
  let db = store.connect()

  // Start the web server process
  let assert Ok(_) =
    mist.run_service(3000, web.make_service(db), max_body_limit: 4_000_000)
  io.println("Started listening on http://localhost:3000 ✨")

  // Put the main process to sleep while the web server does its thing
  process.sleep_forever()
}
