import gleam/bit_builder.{BitBuilder}
import gleam/list
import nakai
import nakai/html.{Node}
import nakai/html/attrs
import packages/store.{PackageSummary}

const stylesheet = "
:root {
  --color-charcoal: #2f2f2f;
  --color-black: #1e1e1e;
  --color-blacker: #151515;
  --color-white: #fefefc;
  --color-faff-pink: #ffaff3;
  --color-aged-plastic-yellow: #fffbe8;
  --color-unnamed-blue: #a6f0fc;
  --color-unexpected-aubergine: #584355;

  --max-width: 800px;
  --gap: 1rem;
  --gap-s: calc(var(--gap) * 0.5)
}

* {
  box-sizing: border-box;
}

body {
  padding: 0;
  margin: 0;
  background: var(--color-white);
}

.content {
  max-width: var(--max-width);
  padding: var(--gap);
}

.site-header {
  width: 100%;
  background-color: var(--color-faff-pink);
  padding: var(--gap);
}

.site-header a {
  color: black;
}

.site-header h1 {
  margin: 0;
}

.site-header nav {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.search-form {
  display: flex;
}

.search-form input[type=search] {
  height: 30px;
  border: none;
  padding: 0 var(--gap-s);
  border-radius: 3px;
  padding-left: var(--gap);
  border-radius: 100px 0 0 100px;
}

.search-form input[type=submit] {
  background: var(--color-white);
  border: none;
  border-radius: 0 100px 100px 0;
  height: 30px;
  padding: 0 var(--gap-s);
  margin-left: 1px;
}

.site-footer {
  width: 100%;
  padding: var(--gap);
  text-align: center;
}
"

pub fn packages_index(
  packages: List(PackageSummary),
  search_term: String,
) -> BitBuilder {
  html.main(
    [],
    [
      html.header(
        [attrs.class("site-header")],
        [
          html.nav(
            [],
            [
              html.a([attrs.href("/")], [html.h1_text([], "Gleam Packages")]),
              search_form(search_term),
            ],
          ),
        ],
      ),
      html.div([attrs.class("content")], [package_list(packages)]),
    ],
  )
  |> layout
  |> nakai.render
  |> bit_builder.from_string
}

fn search_form(search_term: String) -> Node(t) {
  html.form(
    [attrs.class("search-form"), attrs.Attr("method", "GET")],
    [
      html.input([
        attrs.name("search"),
        attrs.type_("search"),
        attrs.value(search_term),
      ]),
      html.input([attrs.type_("submit"), attrs.value("🔎")]),
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
      html.Element("style", [attrs.type_("text/css")], [html.Text(stylesheet)]),
    ]),
    content,
    html.footer(
      [attrs.class("site-footer")],
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
