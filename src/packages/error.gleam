import simplifile
import sqlight
import gleam/json
import gleam/hackney

pub type Error {
  FileError(simplifile.FileError)
  DatabaseError(sqlight.Error)
  HttpClientError(hackney.Error)
  JsonDecodeError(json.DecodeError)
}
