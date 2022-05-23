import gleam/int
import gleam/string

pub type LocalDateTime =
  #(#(Int, Int, Int), #(Int, Int, Int))

pub external fn parse_iso8601(datestring: String) -> LocalDateTime =
  "iso8601" "parse"

pub external fn to_gregorian_seconds(time: LocalDateTime) -> Int =
  "calendar" "datetime_to_gregorian_seconds"

pub fn parse_iso8601_to_gregorian_seconds(datestring: String) -> Int {
  datestring
  |> parse_iso8601
  |> to_gregorian_seconds
}

pub fn to_pg_time(datetime: LocalDateTime) -> String {
  let date = datetime.0
  let time = datetime.1
  int.to_string(date.0)
  |> string.append("-")
  |> string.append(int.to_string(date.1))
  |> string.append("-")
  |> string.append(int.to_string(date.2))
  |> string.append(" ")
  |> string.append(int.to_string(time.0))
  |> string.append(":")
  |> string.append(int.to_string(time.1))
  |> string.append(":")
  |> string.append(int.to_string(time.2))
  |> string.append(".000000")
}
