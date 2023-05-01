import gleam/result
import gleam/dynamic.{DecodeError, Dynamic} as dyn
import birl/time.{DateTime}

pub fn unix_timestamp(data: Dynamic) -> Result(DateTime, List(DecodeError)) {
  use i <- result.map(dyn.int(data))
  time.from_unix(i)
}
