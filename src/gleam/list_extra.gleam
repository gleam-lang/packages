pub fn try_each(xs: List(a), f: fn(a) -> Result(b, e)) -> Result(Nil, e) {
  case xs {
    [] -> Ok(Nil)
    [x, ..xs] -> {
      case f(x) {
        Ok(_) -> try_each(xs, f)
        Error(e) -> Error(e)
      }
    }
  }
}
