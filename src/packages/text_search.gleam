import ethos.{type BagTable}
import gleam/dict
import gleam/int
import gleam/list
import gleam/option
import gleam/result
import gleam/string
import packages/error.{type Error}
import packages/storage
import porter_stemmer

pub opaque type TextSearchIndex {
  TextSearchIndex(table: BagTable(String, String))
}

pub fn new() -> TextSearchIndex {
  TextSearchIndex(ethos.new())
}

pub fn insert(
  index: TextSearchIndex,
  name name: String,
  description description: String,
) -> Result(Nil, Error) {
  case storage.is_ignored_package(name) {
    True -> Ok(Nil)
    False ->
      name
      |> string.append(" ")
      |> string.append(string.replace(name, "_", " "))
      |> string.append(" ")
      |> string.append(description)
      |> stem_words
      |> list.try_each(fn(word) { ethos.insert(index.table, word, name) })
      |> result.replace_error(error.EtsTableError)
  }
}

pub fn update(
  index: TextSearchIndex,
  name name: String,
  description description: String,
) -> Result(Nil, Error) {
  use _ <- result.try(remove(index, name))
  insert(index, name, description)
}

pub fn lookup(
  index: TextSearchIndex,
  phrase: String,
) -> Result(List(String), Error) {
  stem_words(phrase)
  |> list.flat_map(expand_search_term)
  |> list.try_map(ethos.get(index.table, _))
  |> result.map(fn(names) {
    names
    |> list.flatten
    |> list.fold(dict.new(), fn(counters, name) {
      dict.upsert(counters, name, fn(x) { option.unwrap(x, 0) + 1 })
    })
    |> dict.to_list
    |> list.sort(fn(a, b) { int.compare(b.1, a.1) })
    |> list.map(fn(pair) { pair.0 })
  })
  |> result.replace_error(error.EtsTableError)
}

/// Some words have common misspellings or associated words so we add those to
/// the search to get all appropriate results.
fn expand_search_term(term: String) -> List(String) {
  case term {
    "postgres" | "postgresql" -> ["postgres", "postgresql"]
    "regex" | "regexp" -> ["regex", "regexp"]
    term -> [term]
  }
}

fn remove(index: TextSearchIndex, name: String) -> Result(Nil, Error) {
  ethos.delete_value(index.table, name)
  |> result.replace_error(error.EtsTableError)
}

fn stem_words(phrase: String) -> List(String) {
  phrase
  |> string.replace(",", " ")
  |> string.replace(".", " ")
  |> string.replace("!", " ")
  |> string.replace("/", " ")
  |> string.replace("'", "")
  |> string.split(" ")
  |> list.filter(fn(word) { word != "" })
  |> list.map(porter_stemmer.stem)
  |> list.unique
}
