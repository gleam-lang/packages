pub type LocalDateTime =
  #(#(Int, Int, Int), #(Int, Int, Int))

pub external fn parse_iso8601(datestring: String) -> LocalDateTime =
  "iso8601" "parse"

pub external fn to_gregorian_seconds(time: LocalDateTime) -> Int =
  "packages_ffi" "to_gregorian_seconds"

pub fn parse_iso8601_to_gregorian_seconds(datestring: String) -> Int {
  datestring
  |> parse_iso8601
  |> to_gregorian_seconds
}
