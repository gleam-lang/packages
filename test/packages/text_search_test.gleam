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

pub fn ignored_test() {
  let index = text_search.new()
  let assert Ok(_) = text_search.insert(index, "clean_bson", "wibble")
  // This one is ignored
  let assert Ok(_) = text_search.insert(index, "gleam_bson", "wibble")

  text_search.lookup(index, "gleam_bson")
  |> should.be_ok
  |> should.equal([])
  text_search.lookup(index, "wibble")
  |> should.be_ok
  |> should.equal(["clean_bson"])
}

pub fn word_in_title_test() {
  let index = text_search.new()
  let assert Ok(_) = text_search.insert(index, "gleam_regexp", "")

  text_search.lookup(index, "regexp")
  |> should.be_ok
  |> should.equal(["gleam_regexp"])
}

// regex also searches for regexp
pub fn extra_regex_test() {
  let index = text_search.new()
  let assert Ok(_) = text_search.insert(index, "gleam_regexp", "")
  let assert Ok(_) = text_search.insert(index, "third_party_regex", "")

  text_search.lookup(index, "regex")
  |> should.be_ok
  |> should.equal(["gleam_regexp", "third_party_regex"])
}

pub fn exact_title_match_goes_first_test() {
  let index = text_search.new()
  let assert Ok(_) = text_search.insert(index, "lustre_1", "stuff for lustre")
  let assert Ok(_) = text_search.insert(index, "lustre_2", "stuff for lustre")
  let assert Ok(_) = text_search.insert(index, "lustre", "html stuff")
  let assert Ok(_) = text_search.insert(index, "lustre_3", "stuff for lustre")
  let assert Ok(_) = text_search.insert(index, "lustre_4", "stuff for lustre")

  text_search.lookup(index, "lustre")
  |> should.be_ok
  |> should.equal(["lustre", "lustre_1", "lustre_2", "lustre_3", "lustre_4"])
}

pub fn translate_from_freedom_language_test() {
  let index = text_search.new()
  let assert Ok(_) =
    text_search.insert(
      index,
      "gleam_community_colour",
      "Colour types, conversions, and other utilities",
    )

  // Traditional
  text_search.lookup(index, "colour")
  |> should.be_ok
  |> should.equal(["gleam_community_colour"])

  // USA
  text_search.lookup(index, "color")
  |> should.be_ok
  |> should.equal(["gleam_community_colour"])

  // Irish
  text_search.lookup(index, "dath")
  |> should.be_ok
  |> should.equal([])
}
