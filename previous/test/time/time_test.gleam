import gleeunit/should
import time/parse

pub fn parse_iso8601_test() {
  parse.parse_iso8601("2006-08-19T05:00:00.000Z")
  |> should.equal(#(#(2006, 08, 19), #(5, 0, 0)))

  parse.parse_iso8601("2009-03-19T01:25:35.000Z")
  |> should.equal(#(#(2009, 03, 19), #(1, 25, 35)))

  parse.parse_iso8601("2022-05-16T09:30:00.000Z")
  |> should.equal(#(#(2022, 05, 16), #(9, 30, 0)))
}

pub fn to_gregorian_seconds_test() {
  parse.to_gregorian_seconds(#(#(2006, 08, 19), #(5, 0, 0)))
  |> should.equal(63323182800)

  parse.to_gregorian_seconds(#(#(2009, 03, 19), #(1, 25, 35)))
  |> should.equal(63404645135)

  parse.to_gregorian_seconds(#(#(2022, 05, 16), #(9, 30, 0)))
  |> should.equal(63819912600)
}

pub fn parse_iso8601_to_gregorian_seconds_test() {
  parse.parse_iso8601_to_gregorian_seconds("2006-08-19T05:00:00.000Z")
  |> should.equal(63323182800)

  parse.parse_iso8601_to_gregorian_seconds("2009-03-19T01:25:35.000Z")
  |> should.equal(63404645135)

  parse.parse_iso8601_to_gregorian_seconds("2022-05-16T09:30:00.000Z")
  |> should.equal(63819912600)
}
