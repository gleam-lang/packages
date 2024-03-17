import gleam/hackney
import gleam/json
import simplifile
import sqlight

pub type Error {
  FileError(simplifile.FileError)
  DatabaseError(sqlight.Error)
  HttpClientError(hackney.Error)
  JsonDecodeError(json.DecodeError)
}
