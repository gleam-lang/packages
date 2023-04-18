import gleam/pgo
import gleam/bit_builder.{BitBuilder}
import gleam/http/request.{Request}
import gleam/http/response.{Response}

pub type Context {
  Context(db: pgo.Connection, request: Request(BitString))
}

pub fn make_service(
  db: pgo.Connection,
) -> fn(Request(BitString)) -> Response(BitBuilder) {
  fn(request) {
    let context = Context(db: db, request: request)
    handle_request(context)
  }
}

pub fn handle_request(_context: Context) -> Response(BitBuilder) {
  response.new(200)
  |> response.set_header("content-type", "text/html; charset=utf-8")
  |> response.set_body("<h1>Hello, world!</h1>")
  |> response.map(bit_builder.from_string)
}
