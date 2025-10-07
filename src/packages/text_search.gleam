import cell.{type Cell}
import edit_distance
import ethos.{type BagTable}
import gleam/bool
import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/option
import gleam/result
import gleam/set.{type Set}
import gleam/string
import packages/error.{type Error}
import packages/override
import porter_stemmer

pub opaque type TextSearchIndex {
  TextSearchIndex(
    table: BagTable(String, String),
    known_words: Cell(Set(String)),
  )
}

pub fn new() -> TextSearchIndex {
  let known_words = cell.new(cell.new_table())
  let assert Ok(_) = cell.write(known_words, set.new())
    as "cannot initialise cell"
  TextSearchIndex(table: ethos.new(), known_words:)
}

pub fn insert(
  index: TextSearchIndex,
  name name: String,
  description description: String,
) -> Result(Nil, Error) {
  case override.is_ignored_package(name) {
    True -> Ok(Nil)
    False -> {
      use _ <- result.try(insert_package(name, description, index))
      use _ <- result.try(update_known_words(name <> " " <> description, index))
      Ok(Nil)
    }
  }
}

fn insert_package(
  name: String,
  description: String,
  index: TextSearchIndex,
) -> Result(Nil, Error) {
  name
  |> string.append(" ")
  |> string.append(string.replace(name, "_", " "))
  |> string.append(" ")
  |> string.append(description)
  |> stem_words
  |> list.try_each(fn(word) { ethos.insert(index.table, word, name) })
  |> result.replace_error(error.EtsTableError)
}

fn update_known_words(
  text: String,
  index: TextSearchIndex,
) -> Result(Nil, Error) {
  cell.read(index.known_words)
  |> result.try(fn(known_words) {
    text
    |> string.lowercase
    |> string.split(on: " ")
    |> set.from_list
    |> set.union(known_words)
    |> cell.write(index.known_words, _)
  })
  |> result.replace_error(error.EtsTableError)
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
///
pub fn lookup(
  index: TextSearchIndex,
  phrase: String,
) -> Result(List(Found), Error) {
  let phrase = string.lowercase(phrase)
  stem_words(phrase)
  |> list.flat_map(override.expand_search_term)
  |> list.try_map(ethos.get(index.table, _))
  |> result.replace_error(error.EtsTableError)
  |> result.map(fn(names) {
    names
    |> list.flatten
    |> count_occurrences
    |> dict.to_list
    |> list.map(fn(pair) { Found(name: pair.0, match_count: pair.1) })
  })
}

fn count_occurrences(list: List(a)) -> Dict(a, Int) {
  list.fold(list, dict.new(), fn(counters, name) {
    dict.upsert(counters, name, fn(occurrences) {
      option.unwrap(occurrences, 0) + 1
    })
  })
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

pub fn did_you_mean(
  index: TextSearchIndex,
  phrase: String,
) -> Result(String, Nil) {
  use words <- result.try(
    cell.read(index.known_words)
    |> result.replace_error(Nil),
  )

  // We want to fix each word in the phrase individually and then join them back
  // together to give a suggestion.
  let suggestion =
    phrase
    |> string.lowercase
    |> string.split(on: " ")
    |> list.map(fn(word) {
      // If we find a fix we replace the word with the new suggestion, otherwise
      // we leave it unchanged.
      closest_word(word, from: words)
      |> result.unwrap(word)
    })
    |> string.join(with: " ")

  case suggestion == phrase {
    False -> Ok(suggestion)
    True -> Error(Nil)
  }
}

/// Finds the closest word amongst `words`. If none of the possible words is
/// close enough then this returns `Error(Nil)`.
///
fn closest_word(to word: String, from words: Set(String)) -> Result(String, Nil) {
  // We want to limit the maximum edit distance. Otherwise we could end up
  // suggesting fixes that are not related at all to the original query.
  let word_length = string.length(word)
  let limit = int.max(1, word_length / 3)

  set.fold(words, [], fn(acc, candidate) {
    let word_length = string.length(candidate)
    let minimum_distance = int.absolute_value(word_length - word_length)

    // If the minimum distance is greater than the allowed limit then we don't
    // even waste any time computing the edit distance of the two strings!
    use <- bool.guard(when: minimum_distance > limit, return: acc)
    let distance = edit_distance.levenshtein(word, candidate)
    case distance > limit {
      False -> [#(candidate, distance), ..acc]
      True -> acc
    }
  })
  // We only pick the word with the smallest possible edit distance that's below
  // the given threshold
  |> list.sort(fn(one, other) { int.compare(one.1, other.1) })
  |> list.first
  |> result.map(fn(suggestion) { suggestion.0 })
}
