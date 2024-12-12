import packages/storage
import packages/text_search

pub type Context {
  Context(
    db: storage.Database,
    search_index: text_search.TextSearchIndex,
    static_directory: String,
  )
}
