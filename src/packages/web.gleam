import packages/storage
import packages/text_search

pub type Context {
  Context(
    db: storage.Database,
    git_sha: String,
    search_index: text_search.TextSearchIndex,
    static_directory: String,
  )
}
