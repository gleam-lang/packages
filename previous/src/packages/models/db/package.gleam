import time/parse.{LocalDateTime}
import gleam/map.{Map}

pub type Package {
  Package(
    name: String,
    updated_at: LocalDateTime,
    links: Map(String, String),
    licenses: List(String),
    description: String,
  )
}
