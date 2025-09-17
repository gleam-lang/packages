import packages/text_search

pub fn lookup_empty_test() {
  let index = text_search.new()
  let assert Ok(value) = text_search.lookup(index, "wibble")
  assert value == []
}

pub fn lookup_case_test() {
  let index = text_search.new()
  let assert Ok(_) =
    text_search.insert(index, "lustre", "HTML templates and stuff")
  let assert Ok(_) = text_search.insert(index, "squirrel", "SQL")

  let assert Ok(value) = text_search.lookup(index, "HTML")
  assert value == ["lustre"]
  let assert Ok(value) = text_search.lookup(index, "html")
  assert value == ["lustre"]
}

pub fn lookup_different_case_exact_match_test() {
  let index = text_search.new()
  let assert Ok(_) = text_search.insert(index, "wibble", "blah")
  let assert Ok(_) = text_search.insert(index, "blah", "wibble wibble wibble")

  let assert Ok(value) = text_search.lookup(index, "wibble")
  assert value == ["wibble", "blah"]
  let assert Ok(value) = text_search.lookup(index, "WIBBLE")
  assert value == ["wibble", "blah"]
  let assert Ok(value) = text_search.lookup(index, "Wibble")
  assert value == ["wibble", "blah"]
}

pub fn lookup_ing_test() {
  let index = text_search.new()
  let assert Ok(_) =
    text_search.insert(index, "lustre", "HTML templates and stuff")
  let assert Ok(_) = text_search.insert(index, "squirrel", "SQL")

  let assert Ok(value) = text_search.lookup(index, "templating")
  assert value == ["lustre"]
}

pub fn lookup_er_test() {
  let index = text_search.new()
  let assert Ok(_) =
    text_search.insert(index, "lustre", "HTML templates and stuff")
  let assert Ok(_) = text_search.insert(index, "squirrel", "SQL")

  let assert Ok(value) = text_search.lookup(index, "templater")
  assert value == ["lustre"]
}

pub fn lookup_spaces_test() {
  let index = text_search.new()
  let assert Ok(_) =
    text_search.insert(index, "lustre", "HTML templates and stuff")
  let assert Ok(_) = text_search.insert(index, "squirrel", "SQL")

  let assert Ok(value) = text_search.lookup(index, "  html   templater     ")
  assert value == ["lustre"]
}

pub fn lookup_more_matches_higher_rank_test() {
  let index = text_search.new()
  let assert Ok(_) = text_search.insert(index, "pog", "database client")
  let assert Ok(_) = text_search.insert(index, "httpc", "http client")

  let assert Ok(value) = text_search.lookup(index, "http client")
  assert value == ["httpc", "pog"]
}

pub fn ignored_test() {
  let index = text_search.new()
  let assert Ok(_) = text_search.insert(index, "clean_bson", "wibble")
  // This one is ignored
  let assert Ok(_) = text_search.insert(index, "gleam_bson", "wibble")

  let assert Ok(value) = text_search.lookup(index, "gleam_bson")
  assert value == ["clean_bson"]
  let assert Ok(value) = text_search.lookup(index, "wibble")
  assert value == ["clean_bson"]
}

pub fn word_in_title_test() {
  let index = text_search.new()
  let assert Ok(_) = text_search.insert(index, "gleam_regexp", "")

  let assert Ok(value) = text_search.lookup(index, "regexp")
  assert value == ["gleam_regexp"]
}

// regex also searches for regexp
pub fn extra_regex_test() {
  let index = text_search.new()
  let assert Ok(_) = text_search.insert(index, "gleam_regexp", "")
  let assert Ok(_) = text_search.insert(index, "third_party_regex", "")

  let assert Ok(value) = text_search.lookup(index, "regex")
  assert value == ["gleam_regexp", "third_party_regex"]
}

pub fn case_insensitive_test() {
  let index = text_search.new()
  let assert Ok(_) =
    text_search.insert(
      index,
      "bucket",
      "Gleam S3 API client, suitable for AWS S3, Garage, Minio, Storj, Backblaze B2, Cloudflare R2, Ceph, Wasabi, and so on!",
    )

  let assert Ok(value) = text_search.lookup(index, "S3")
  assert value == ["bucket"]

  let assert Ok(value) = text_search.lookup(index, "s3")
  assert value == ["bucket"]

  let assert Ok(value) = text_search.lookup(index, "gArAgE")
  assert value == ["bucket"]
}

pub fn exact_title_match_goes_first_test() {
  let index = text_search.new()
  let assert Ok(_) = text_search.insert(index, "lustre_1", "stuff for lustre")
  let assert Ok(_) = text_search.insert(index, "lustre_2", "stuff for lustre")
  let assert Ok(_) = text_search.insert(index, "lustre", "html stuff")
  let assert Ok(_) = text_search.insert(index, "lustre_3", "stuff for lustre")
  let assert Ok(_) = text_search.insert(index, "lustre_4", "stuff for lustre")

  let assert Ok(value) = text_search.lookup(index, "lustre")
  assert value == ["lustre", "lustre_1", "lustre_2", "lustre_3", "lustre_4"]
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
  let assert Ok(value) = text_search.lookup(index, "colour")
  assert value == ["gleam_community_colour"]

  // USA
  let assert Ok(value) = text_search.lookup(index, "color")
  assert value == ["gleam_community_colour"]

  // Irish
  let assert Ok(value) = text_search.lookup(index, "dath")
  assert value == []
}

pub fn underscores_test() {
  let index = text_search.new()
  let assert Ok(_) = text_search.insert(index, "lustre_dev_tools", "")
  let assert Ok(_) = text_search.insert(index, "lustre", "")
  let assert Ok(_) = text_search.insert(index, "glam", "")

  let assert Ok(value) = text_search.lookup(index, "lustre_dev")
  assert value == ["lustre_dev_tools", "lustre"]
}
