pub fn is_ignored_package(name: String) -> Bool {
  case name {
    "bare_package1"
    | "bare_package_one"
    | "bare_package_two"
    | "first_gleam_publish_package"
    | "gleam_module_javascript_test"
    | // Reserved official sounding names.
      "gleam"
    | "gleam_deno"
    | "gleam_email"
    | "gleam_html"
    | "gleam_nodejs"
    | "gleam_tcp"
    | "gleam_test"
    | "gleam_toml"
    | "gleam_xml"
    | "gleam_mongo"
    | "gleam_bson"
    | "gleam_file"
    | "gleam_yaml"
    | // Unofficial packages impersonating the core team
      "gleam_dotenv"
    | "gleam_roman"
    | "gleam_sendgrid"
    | "gleam_bbmustache"
    | // Reserved unreleased project names.
      "glitter"
    | "sequin" -> True

    _ -> False
  }
}

/// Some words have common misspellings or associated words so we add those to
/// the search to get all appropriate results.
pub fn expand_search_term(term: String) -> List(String) {
  case term {
    "postgres" | "postgresql" -> ["postgres", "postgresql"]
    "mysql" | "mariadb" -> ["mysql", "mariadb"]
    "redis" | "valkey" -> ["redis", "valkey"]
    "regex" | "regexp" -> ["regex", "regexp"]
    "luster" -> ["luster", "lustre"]
    "mail" -> ["mail", "email"]
    term -> [term]
  }
}
