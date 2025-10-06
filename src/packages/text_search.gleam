import ethos.{type BagTable}
import gleam/dict
import gleam/list
import gleam/option
import gleam/result
import gleam/string
import packages/error.{type Error}
import packages/override
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
  case override.is_ignored_package(name) {
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

/// Find all matches for the given search term. The list is not returned in any
/// order, but each found item is returned with a match count.
pub fn lookup(
  index: TextSearchIndex,
  phrase: String,
) -> Result(List(Found), Error) {
  let phrase = string.lowercase(phrase)
  stem_words(phrase)
  |> list.flat_map(override.expand_search_term)
  |> list.try_map(ethos.get(index.table, _))
  |> result.map(fn(names) {
    names
    |> list.flatten
    |> list.fold(dict.new(), fn(counters, name) {
      dict.upsert(counters, name, fn(x) { option.unwrap(x, 0) + 1 })
    })
    |> dict.to_list
    |> list.map(fn(pair) { Found(pair.0, pair.1) })
  })
  |> result.replace_error(error.EtsTableError)
}

pub type Found {
  Found(name: String, match_count: Int)
}

fn remove(index: TextSearchIndex, name: String) -> Result(Nil, Error) {
  ethos.delete_value(index.table, name)
  |> result.replace_error(error.EtsTableError)
}

fn stem_words(phrase: String) -> List(String) {
  phrase
  |> string.lowercase
  |> string.replace("-", " ")
  |> string.replace("_", " ")
  |> string.replace(",", " ")
  |> string.replace(".", " ")
  |> string.replace("!", " ")
  |> string.replace("/", " ")
  |> string.replace("'", "")
  |> string.split(" ")
  |> list.filter(fn(word) { word != "" })
  |> list.map(normalise_spelling)
  |> list.map(porter_stemmer.stem)
  |> list.unique
}

fn normalise_spelling(word: String) -> String {
  case word {
    "analyze" -> "analyse"
    "authorize" -> "authorise"
    "behavior" -> "behaviour"
    "categorize" -> "categorise"
    "color" -> "colour"
    "customization" -> "customisation"
    "customize" -> "customise"
    "honor" -> "honour"
    "initialize" -> "initialise"
    "labeled" -> "labelled"
    "labor" -> "labour"
    "license" -> "licence"
    "modeling" -> "modelling"
    "normalization" -> "normalisation"
    "normalize" -> "normalise"
    "optimization" -> "optimisation"
    "optimize" -> "optimise"
    "organize" -> "organise"
    "parameterize" -> "parameterise"
    "deserialization" -> "deserialisation"
    "deserialize" -> "deserialise"
    "serialization" -> "serialisation"
    "serialize" -> "serialise"
    "standardize" -> "standardise"
    "summarize" -> "summarise"
    "synchronize" -> "synchronise"
    "tokenize" -> "tokenise"
    _ -> word
  }
}
