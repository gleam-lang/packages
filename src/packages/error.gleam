import gleam/httpc
import gleam/json
import simplifile
import storail

pub type Error {
  FileError(simplifile.FileError)
  HttpClientError(httpc.HttpError)
  JsonDecodeError(json.DecodeError)
  StorageError(storail.StorailError)
  EtsTableError
}
