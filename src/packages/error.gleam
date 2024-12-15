import gleam/hackney
import gleam/json
import simplifile
import storail

pub type Error {
  FileError(simplifile.FileError)
  HttpClientError(hackney.Error)
  JsonDecodeError(json.DecodeError)
  StorageError(storail.StorailError)
  EtsTableError
}
