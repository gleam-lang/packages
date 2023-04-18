import gleam/bit_builder.{BitBuilder}
import gleam/list
import nakai
import nakai/html.{Node}
import nakai/html/attrs
import packages/store.{PackageSummary}

pub fn packages_index(
  packages: List(PackageSummary),
  search_term: String,
) -> BitBuilder {
  html.main(
    [],
    [
      html.a([attrs.href("/")], [html.h1_text([], "Gleam Packages")]),
      search_form(search_term),
      package_list(packages),
    ],
  )
  |> layout
  |> nakai.render
  |> bit_builder.from_string
}

fn search_form(search_term: String) -> Node(t) {
  html.form(
    [attrs.Attr("method", "GET")],
    [
      html.input([
        attrs.name("search"),
        attrs.type_("search"),
        attrs.value(search_term),
      ]),
      html.input([attrs.type_("submit"), attrs.value("Search")]),
    ],
  )
}

fn package_list(packages: List(PackageSummary)) -> Node(t) {
  html.ul([], list.map(packages, package_list_item))
}

fn package_list_item(package: PackageSummary) -> Node(t) {
  html.li(
    [],
    [
      html.a(
        [
          attrs.href("https://hex.pm/packages/" <> package.name),
          attrs.rel("noopener noreferrer"),
        ],
        [html.Text(package.name)],
      ),
      html.Text(" - "),
      html.Text(package.description),
    ],
  )
}

fn layout(content: Node(t)) -> Node(t) {
  html.Fragment([
    html.head([
      html.meta([attrs.charset("utf-8")]),
      html.meta([
        attrs.name("viewport"),
        attrs.content("width=device-width, initial-scale=1"),
      ]),
      html.title_text([], "Gleam Packages"),
    ]),
    content,
    html.footer(
      [],
      [
        html.div(
          [],
          [
            html.Text("© Louis Pilfold. Made with "),
            html.a([attrs.href("https://gleam.run/")], [html.Text("Gleam")]),
            html.Text("."),
          ],
        ),
      ],
    ),
  ])
}
