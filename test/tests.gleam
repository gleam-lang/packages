import packages/storage
import simplifile

pub fn with_database(f: fn(storage.Database) -> t) -> t {
  let path = "test/storage"
  let assert Ok(_) = simplifile.delete_all(["test/storage"])
  let db = storage.initialise(path)
  let t = f(db)
  let assert Ok(_) = simplifile.delete_all(["test/storage"])
  t
}
