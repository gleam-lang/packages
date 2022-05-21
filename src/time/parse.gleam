pub type LocalDateTime =
  #(#(Int, Int, Int), #(Int, Int, Int))

pub external fn parse_iso8601(datestring: String) -> LocalDateTime =
  "iso8601" "parse"

pub external fn to_epoch_timetsamp(time: LocalDateTime) -> Int =
  "packages_ffi" "to_unix_timestamp"

pub fn parse_iso8601_to_epoch_timestamp(datestring: String) -> Int {
  datestring
  |> parse_iso8601
  |> to_epoch_timetsamp
}
