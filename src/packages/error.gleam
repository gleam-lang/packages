import gleam/hackney
import gleam/json
import simplifile
import sqlight
import storail

pub type Error {
  FileError(simplifile.FileError)
  DatabaseError(sqlight.Error)
  HttpClientError(hackney.Error)
  JsonDecodeError(json.DecodeError)
  StorageError(storail.StorailError)
  EtsTableError
}
