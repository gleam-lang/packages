import packages/web
import packages/hex
import gleam/erlang
import gleam/io

pub fn main() {
  case erlang.start_arguments() {
    ["serve"] -> web.start()
    ["query-hex"] -> {
      assert Ok(_) = hex.query()
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
