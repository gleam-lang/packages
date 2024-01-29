import simplifile
import gleam/result
import gleam/string
import gleam/list

pub fn main() {
  let Nil = generate_sql_queries_module()
}

const module_header = "// THIS FILE IS GENERATED. DO NOT EDIT.
// Regenerate with `gleam run -m codegen`"

fn generate_sql_queries_module() -> Nil {
  let module_path = "src/packages/generated/sql.gleam"
  let assert Ok(files) = simplifile.read_directory("sql")
  let assert Ok(functions) = list.try_map(files, generate_sql_function)

  let imports = [
    "import sqlight", "import gleam/result", "import gleam/dynamic",
    "import packages/error.{type Error}",
  ]
  let module =
    string.join(
      [
        module_header,
        string.join(imports, "\n"),
        "pub type QueryResult(t) =\n  Result(List(t), Error)",
        ..functions
      ],
      "\n\n",
    )
  let assert Ok(_) = simplifile.write(to: module_path, contents: module <> "\n")
  Nil
}

fn generate_sql_function(file: String) -> Result(String, _) {
  let name = string.replace(file, ".sql", "")
  use contents <- result.then(simplifile.read("sql/" <> file))
  let escaped =
    contents
    |> string.replace("\\", "\\\\")
    |> string.replace("\"", "\\\"")
  let lines = [
    "pub fn " <> name <> "(",
    "  db: sqlight.Connection,",
    "  arguments: List(sqlight.Value),",
    "  decoder: dynamic.Decoder(a),",
    ") -> QueryResult(a) {",
    "  let query =",
    "    \"" <> escaped <> "\"",
    "  sqlight.query(query, db, arguments, decoder)",
    "  |> result.map_error(error.DatabaseError)",
    "}",
  ]
  let function = string.join(lines, "\n")
  Ok(function)
}
