import ethos.{type BagTable}
import gleam/dict
import gleam/int
import gleam/list
import gleam/option
import gleam/result
import gleam/string
import packages/error.{type Error}
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
  name
  |> string.append(" ")
  |> string.append(description)
  |> stem_words
  |> list.try_each(fn(word) { insert(index, word, name) })
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
) -> Result(List(String), Nil) {
  let words = stem_words(phrase)
  use names <- result.map(list.try_map(words, ethos.get(index.table, _)))
  names
  |> list.flatten
  |> list.fold(dict.new(), fn(counters, name) {
    dict.upsert(counters, name, fn(x) { option.unwrap(x, 0) + 1 })
  })
  |> dict.to_list
  |> list.sort(fn(a, b) { int.compare(a.1, b.1) })
  |> list.map(fn(pair) { pair.0 })
}

fn remove(index: TextSearchIndex, name: String) -> Result(Nil, Error) {
  ethos.delete_value(index.table, name)
  |> result.replace_error(error.EtsTableError)
}

fn stem_words(phrase: String) -> List(String) {
  phrase
  |> string.split(" ")
  |> list.filter(fn(word) { word != "" })
  |> list.map(porter_stemmer.stem)
  |> list.unique
}
