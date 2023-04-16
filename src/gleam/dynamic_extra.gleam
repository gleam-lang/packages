import gleam/result
import gleam/dynamic.{DecodeError, Dynamic} as dyn
import birl/time.{Time}

pub fn iso_timestamp(data: Dynamic) -> Result(Time, List(DecodeError)) {
  use s <- result.then(dyn.string(data))
  case time.from_iso8601(s) {
    Ok(t) -> Ok(t)
    Error(_) -> Error([DecodeError("Timestamp", dyn.classify(data), [])])
  }
}

pub fn unix_timestamp(data: Dynamic) -> Result(Time, List(DecodeError)) {
  use i <- result.map(dyn.int(data))
  time.from_unix(i)
}
