import sqlight
import gleam/json
import gleam/hackney

pub type Error {
  DatabaseError(sqlight.Error)
  HttpClientError(hackney.Error)
  JsonDecodeError(json.DecodeError)
}
