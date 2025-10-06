import packages/text_search.{Found}

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
  assert value == [Found("lustre", 1)]
  let assert Ok(value) = text_search.lookup(index, "html")
  assert value == [Found("lustre", 1)]
}

pub fn lookup_different_case_exact_match_test() {
  let index = text_search.new()
  let assert Ok(_) = text_search.insert(index, "wibble", "blah")
  let assert Ok(_) = text_search.insert(index, "blah", "wibble wibble wibble")

  let assert Ok(value) = text_search.lookup(index, "wibble")
  assert value == [Found("blah", 1), Found("wibble", 1)]
  let assert Ok(value) = text_search.lookup(index, "WIBBLE")
  assert value == [Found("blah", 1), Found("wibble", 1)]
  let assert Ok(value) = text_search.lookup(index, "Wibble")
  assert value == [Found("blah", 1), Found("wibble", 1)]
}

pub fn lookup_ing_test() {
  let index = text_search.new()
  let assert Ok(_) =
    text_search.insert(index, "text", "HTML templates and stuff")
  let assert Ok(_) = text_search.insert(index, "squirrel", "SQL")

  let assert Ok(value) = text_search.lookup(index, "templating")
  assert value == [Found("text", 1)]
}

pub fn lookup_er_test() {
  let index = text_search.new()
  let assert Ok(_) =
    text_search.insert(index, "text", "HTML templates and stuff")
  let assert Ok(_) = text_search.insert(index, "squirrel", "SQL")

  let assert Ok(value) = text_search.lookup(index, "templater")
  assert value == [Found("text", 1)]
}

pub fn lookup_spaces_test() {
  let index = text_search.new()
  let assert Ok(_) =
    text_search.insert(index, "text", "HTML templates and stuff")
  let assert Ok(_) = text_search.insert(index, "squirrel", "SQL")

  let assert Ok(value) = text_search.lookup(index, "  html   templater     ")
  assert value == [Found("text", 2)]
}

pub fn lookup_more_matches_higher_rank_test() {
  let index = text_search.new()
  let assert Ok(_) = text_search.insert(index, "pog", "database client")
  let assert Ok(_) = text_search.insert(index, "httpc", "http client")

  let assert Ok(value) = text_search.lookup(index, "http client")
  assert value == [Found("httpc", 2), Found("pog", 1)]
}

pub fn ignored_test() {
  let index = text_search.new()
  let assert Ok(_) = text_search.insert(index, "clean_bson", "wibble")
  // This one is ignored
  let assert Ok(_) = text_search.insert(index, "gleam_bson", "wibble")

  let assert Ok(value) = text_search.lookup(index, "gleam_bson")
  assert value == [Found("clean_bson", 1)]
  let assert Ok(value) = text_search.lookup(index, "wibble")
  assert value == [Found("clean_bson", 1)]
}

pub fn word_in_title_test() {
  let index = text_search.new()
  let assert Ok(_) = text_search.insert(index, "gleam_regexp", "")

  let assert Ok(value) = text_search.lookup(index, "regexp")
  assert value == [Found("gleam_regexp", 1)]
}

// regex also searches for regexp
pub fn extra_regex_test() {
  let index = text_search.new()
  let assert Ok(_) = text_search.insert(index, "gleam_regexp", "")
  let assert Ok(_) = text_search.insert(index, "third_party_regex", "")

  let assert Ok(value) = text_search.lookup(index, "regex")
  assert value == [Found("gleam_regexp", 1), Found("third_party_regex", 1)]
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
  assert value == [Found("bucket", 1)]

  let assert Ok(value) = text_search.lookup(index, "s3")
  assert value == [Found("bucket", 1)]

  let assert Ok(value) = text_search.lookup(index, "gArAgE")
  assert value == [Found("bucket", 1)]
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
  assert value == [Found("gleam_community_colour", 1)]

  // USA
  let assert Ok(value) = text_search.lookup(index, "color")
  assert value == [Found("gleam_community_colour", 1)]

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
  assert value == [Found("lustre", 1), Found("lustre_dev_tools", 2)]
}
