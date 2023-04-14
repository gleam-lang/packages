import gleam/erlang/file
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
  let assert Ok(files) = file.list_directory("sql")
  let assert Ok(functions) = list.try_map(files, generate_sql_function)

  let imports = ["import gleam/pgo", "import gleam/dynamic"]
  let module =
    string.join(
      [
        module_header,
        string.join(imports, "\n"),
        "pub type QueryResult(t) =\n  Result(pgo.Returned(t), pgo.QueryError)",
        ..functions
      ],
      "\n\n",
    )
  let assert Ok(_) = file.write(to: module_path, contents: module <> "\n")
  Nil
}

fn generate_sql_function(file: String) -> Result(String, _) {
  let name = string.replace(file, ".sql", "")
  use contents <- result.then(file.read("sql/" <> file))
  let escaped =
    contents
    |> string.replace("\\", "\\\\")
    |> string.replace("\"", "\\\"")
  let lines = [
    "pub fn " <> name <> "(",
    "  db: pgo.Connection,",
    "  decoder: dynamic.Decoder(a),",
    "  arguments: List(pgo.Value),",
    ") -> QueryResult(a) {",
    "  let query =",
    "    \"" <> escaped <> "\"",
    "  pgo.execute(query, db, arguments, decoder)",
    "}",
  ]
  let function = string.join(lines, "\n")
  Ok(function)
}
