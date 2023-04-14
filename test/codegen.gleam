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
  let module = string.join([module_header, ..functions], "\n\n") <> "\n"
  let assert Ok(_) = file.write(to: module_path, contents: module)
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
    "pub fn " <> name <> "() -> String {",
    "  \"" <> escaped <> "\"",
    "}",
  ]
  let function = string.join(lines, "\n")
  Ok(function)
}
