import packages/web
import packages/hex
import gleam/erlang
import gleam/erlang/os
import gleam/io
import gleam/pgo

pub fn main() {
  assert Ok(pg_url) = os.get_env("DATABASE_URL")
  assert Ok(pgo_config) = pgo.url_config(pg_url)

  let db = pgo.connect(pgo.Config(..pgo_config, pool_size: 15))

  case erlang.start_arguments() {
    ["serve"] -> web.start()
    ["query-hex"] -> {
      assert Ok(_) = hex.query(db)
      Nil
    }
    _ -> print_help()
  }
}

fn print_help() {
  io.print("USAGE:
  gleam run serve
  gleam run query-hex
")
  exit(1)
}

external fn exit(Int) -> whatever =
  "erlang" "halt"
