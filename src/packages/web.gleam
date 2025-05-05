import gleam/time/timestamp
import packages/storage
import packages/text_search

pub type Context {
  Context(
    db: storage.Database,
    git_sha: String,
    start_time: timestamp.Timestamp,
    build_time: timestamp.Timestamp,
    search_index: text_search.TextSearchIndex,
    static_directory: String,
  )
}
