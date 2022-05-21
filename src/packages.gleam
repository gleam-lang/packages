import packages/web
import packages/hex
import gleam/erlang
import gleam/io
import gleam/pgo

pub fn main() {
  let db =
    pgo.connect(
      pgo.Config(
        ..pgo.default_config(),
        host: "localhost",
        database: "my_database",
        pool_size: 15,
      ),
    )

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
