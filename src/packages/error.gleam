import gleam/pgo

pub type Error {
  DatabaseError(pgo.QueryError)
}
