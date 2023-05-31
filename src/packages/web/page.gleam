import birl/time.{DateTime}
import gleam/bit_builder.{BitBuilder}
import gleam/int
import gleam/list
import gleam/map
import gleam/option
import nakai
import nakai/html.{Node}
import nakai/html/attrs
import packages/index.{PackageSummary}
import gleam/string

pub fn packages_list(
  packages: List(PackageSummary),
  total_package_count: Int,
  search_term: String,
) -> BitBuilder {
  html.main(
    [],
    [
      html.header(
        [attrs.class("site-header")],
        [
          html.nav(
            [attrs.class("content")],
            [
              html.a([attrs.href("/")], [html.h1_text([], "Gleam Packages")]),
              search_form(search_term),
            ],
          ),
        ],
      ),
      html.div_text(
        [attrs.class("site-subheader")],
        [
          "There are",
          total_package_count
          |> int.to_string,
          pluralize_package(total_package_count),
          "available ✨",
        ]
        |> string.join(" "),
      ),
      html.div([attrs.class("content")], [package_list(packages, search_term)]),
    ],
  )
  |> layout
  |> nakai.to_string_builder
  |> bit_builder.from_string_builder
}

/// Pluralizes the word "package" based on the number we're referring to.
fn pluralize_package(amount: Int) -> String {
  case amount {
    1 -> "package"
    _ -> "packages"
  }
}

fn search_form(search_term: String) -> Node(t) {
  html.form(
    [attrs.class("search-form"), attrs.Attr("method", "GET")],
    [
      html.input([
        attrs.data("keybind-focus", "/"),
        attrs.name("search"),
        attrs.type_("search"),
        attrs.value(search_term),
        attrs.placeholder("Press / to focus"),
      ]),
      html.input([attrs.type_("submit"), attrs.value("🔎")]),
    ],
  )
}

fn package_list(packages: List(PackageSummary), search_term: String) -> Node(t) {
  case packages, string.is_empty(search_term) {
    [], False ->
      html.p_text(
        [],
        "I couldn't find any package matching your search: " <> search_term,
      )
    _, False -> {
      let package_count = list.length(packages)

      html.div(
        [],
        [
          html.p_text(
            [],
            [
              "I found",
              int.to_string(package_count),
              pluralize_package(package_count),
              "matching your search:",
              search_term,
            ]
            |> string.join(" "),
          ),
          html.ul(
            [attrs.class("package-list")],
            list.map(packages, package_list_item),
          ),
        ],
      )
    }
    _, _ ->
      html.ul(
        [attrs.class("package-list")],
        list.map(packages, package_list_item),
      )
  }
}

fn package_list_item(package: PackageSummary) -> Node(t) {
  let url = "https://hex.pm/packages/" <> package.name

  let repository_url =
    package.links
    |> map.get("Repository")
    |> option.from_result

  let links =
    [
      package.docs_url
      |> option.map(external_link_text(_, "Documentation")),
      repository_url
      |> option.map(external_link_text(_, "Repository")),
    ]
    |> list.filter_map(option.to_result(_, Nil))

  html.li(
    [],
    [
      html.div_text(
        [attrs.class("package-date-time")],
        format_date(package.updated_in_hex_at),
      ),
      html.h2([], [external_link_text(url, package.name)]),
      html.p_text([attrs.class("package-description")], package.description),
      case links {
        [] -> html.Nothing
        links ->
          html.nav(
            [attrs.class("package-links")],
            [
              html.ul(
                [],
                links
                |> list.map(fn(link) { html.li([], [link]) }),
              ),
            ],
          )
      },
    ],
  )
}

fn format_date(datetime: DateTime) -> String {
  time.legible_difference(time.now(), datetime)
}

fn external_link_text(url: String, text: String) -> Node(t) {
  html.a_text(
    [attrs.href(url), attrs.rel("noopener noreferrer"), attrs.target("_blank")],
    text,
  )
}

fn layout(content: Node(t)) -> Node(t) {
  html.Fragment([
    html.Head([
      html.meta([attrs.charset("utf-8")]),
      html.meta([
        attrs.name("viewport"),
        attrs.content("width=device-width, initial-scale=1"),
      ]),
      html.title("Gleam Packages"),
      html.link([attrs.rel("stylesheet"), attrs.href("/styles.css")]),
      html.link([
        attrs.rel("icon"),
        attrs.href("https://gleam.run/images/lucy-circle.svg"),
      ]),
      html.Element(
        "script",
        [
          attrs.defer(),
          attrs.src("https://plausible.io/js/plausible.js"),
          attrs.Attr("data-domain", "packages.gleam.run"),
        ],
        [],
      ),
      html.Element("script", [attrs.type_("module"), attrs.src("/main.js")], []),
    ]),
    content,
    html.footer(
      [attrs.class("site-footer")],
      [
        html.div(
          [],
          [
            html.Text("Special thanks to the "),
            external_link_text("https://hex.pm/", "Hex"),
            html.Text(" team."),
          ],
        ),
        html.div(
          [],
          [
            html.Text("Kindly hosted by "),
            external_link_text("https://fly.io/", "Fly"),
            html.Text("."),
          ],
        ),
        html.div(
          [],
          [
            external_link_text(
              "https://github.com/gleam-lang/packages",
              "Source code",
            ),
            html.Text("."),
          ],
        ),
      ],
    ),
  ])
}
