import gleam/pgo
import gleam/json
import gleam/hackney

pub type Error {
  DatabaseError(pgo.QueryError)
  HttpClientError(hackney.Error)
  JsonDecodeError(json.DecodeError)
}
