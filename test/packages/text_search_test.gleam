import gleeunit/should
import packages/text_search

pub fn lookup_empty_test() {
  let index = text_search.new()
  text_search.lookup(index, "wibble")
  |> should.be_ok
  |> should.equal([])
}

pub fn lookup_case_test() {
  let index = text_search.new()
  let assert Ok(_) =
    text_search.insert(index, "lustre", "HTML templates and stuff")
  let assert Ok(_) = text_search.insert(index, "squirrel", "SQL")

  text_search.lookup(index, "HTML")
  |> should.be_ok
  |> should.equal(["lustre"])
  text_search.lookup(index, "html")
  |> should.be_ok
  |> should.equal(["lustre"])
}

pub fn lookup_ing_test() {
  let index = text_search.new()
  let assert Ok(_) =
    text_search.insert(index, "lustre", "HTML templates and stuff")
  let assert Ok(_) = text_search.insert(index, "squirrel", "SQL")

  text_search.lookup(index, "templating")
  |> should.be_ok
  |> should.equal(["lustre"])
}

pub fn lookup_er_test() {
  let index = text_search.new()
  let assert Ok(_) =
    text_search.insert(index, "lustre", "HTML templates and stuff")
  let assert Ok(_) = text_search.insert(index, "squirrel", "SQL")

  text_search.lookup(index, "templater")
  |> should.be_ok
  |> should.equal(["lustre"])
}

pub fn lookup_spaces_test() {
  let index = text_search.new()
  let assert Ok(_) =
    text_search.insert(index, "lustre", "HTML templates and stuff")
  let assert Ok(_) = text_search.insert(index, "squirrel", "SQL")

  text_search.lookup(index, "  html   templater     ")
  |> should.be_ok
  |> should.equal(["lustre"])
}

pub fn lookup_more_matches_higher_rank_test() {
  let index = text_search.new()
  let assert Ok(_) = text_search.insert(index, "pog", "database client")
  let assert Ok(_) = text_search.insert(index, "httpc", "http client")

  text_search.lookup(index, "http client")
  |> should.be_ok
  |> should.equal(["httpc", "pog"])
}
