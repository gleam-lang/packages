import gleam/http/request.{Request}
import gleam/http/response.{Response}
import gleam/http/elli
import gleam/bit_builder.{BitBuilder}
import gleam/erlang/process
import gleam/string
import gleam/int
import gleam/io

fn service(_req: Request(BitString)) -> Response(BitBuilder) {
  let body = bit_builder.from_string("Hello, Joe!")

  response.new(200)
  |> response.prepend_header("made-with", "Gleam")
  |> response.set_body(body)
}

pub fn start() -> Nil {
  let port = 3000

  io.println(string.concat([
    "Started listening on localhost:",
    int.to_string(port),
    " ✨",
  ]))

  // Start the web server process
  assert Ok(_) = elli.become(service, on_port: port)

  // Put the main process to sleep while the web server does its thing
  process.sleep_forever()
}
