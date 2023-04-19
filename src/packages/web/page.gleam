import gleam/bit_builder.{BitBuilder}
import gleam/list
import nakai
import nakai/html.{Node}
import nakai/html/attrs
import packages/store.{PackageSummary}

const stylesheet = "
@font-face {
  font-family: 'Lexend';
  font-display: swap;
  font-weight: 400;
  src: url('https://gleam.run/fonts/Lexend.woff2') format('woff2');
}

@font-face {
  font-family: 'Lexend';
  font-display: swap;
  font-weight: 700;
  src: url('https://gleam.run/fonts/Lexend-700.woff2') format('woff2');
}

@font-face {
  font-family: 'Outfit';
  font-display: swap;
  src: url('https://gleam.run/fonts/Outfit.woff') format('woff');
}

:root {
  --font-family-normal: 'Outfit', sans-serif;
  --font-family: 'Lexend', sans-serif;

  --color-charcoal: #2f2f2f;
  --color-black: #1e1e1e;
  --color-blacker: #151515;
  --color-white: #fefefc;
  --color-faff-pink: #ffaff3;
  --color-aged-plastic-yellow: #fffbe8;
  --color-unnamed-blue: #a6f0fc;
  --color-unexpected-aubergine: #584355;

  --font-size-normal: 18px;

  --content-width: 960px;
  --gap: 1rem;
  --gap-s: calc(var(--gap) * 0.5);
  --gap-l: calc(var(--gap) * 2);
}

* {
  box-sizing: border-box;
}

body {
  padding: 0;
  margin: 0;
  background: var(--color-white);
  font-family: var(--font-family-normal);
  background-color: var(--color-white);
  font-size: var(--font-size);
}

a,
a:visited {
  color: unset;
  text-decoration-color: var(--color-faff-pink);
}

h1, h2, h3, h4, h5, h6 {
  font-family: var(--font-family-title);
  font-weight: normal;
}

.content {
  max-width: var(--content-width);
  padding: var(--gap);
  margin: 0 auto;
}

.site-header {
  width: 100%;
  background-color: var(--color-faff-pink);
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

.package-list {
  padding: 0;
  margin: 0;
}

.package-list li {
  list-style: none;
  margin-top: var(--gap);
  margin-bottom: var(--gap-l);
}

.package-list h2 {
  margin: 0 var(--gap) var(--gap-s) 0;
}

.package-list p {
  margin: 0;
}
"

pub fn packages_search(
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
            [attrs.class("content")],
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
  html.ul([attrs.class("package-list")], list.map(packages, package_list_item))
}

fn package_list_item(package: PackageSummary) -> Node(t) {
  let url = "https://hex.pm/packages/" <> package.name
  html.li(
    [],
    [
      html.h2([], [external_link_text(url, package.name)]),
      html.p_text([], package.description),
    ],
  )
}

fn external_link_text(url: String, text: String) -> Node(t) {
  html.a_text(
    [attrs.href(url), attrs.rel("noopener noreferrer"), attrs.target("_blank")],
    text,
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
      html.Element(
        "script",
        [
          attrs.defer(),
          attrs.src("https://plausible.io/js/plausible.js"),
          attrs.Attr("data-domain", "packages.gleam.run"),
        ],
        [],
      ),
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
