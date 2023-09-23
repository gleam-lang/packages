import packages/index

pub fn with_database(f: fn(index.Connection) -> t) -> t {
  let db = index.connect(":memory:")
  let t = f(db)
  let Nil = index.disconnect(db)
  t
}
