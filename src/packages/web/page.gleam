import birl.{type Time}
import gleam/string_builder.{type StringBuilder}
import gleam/int
import gleam/list
import gleam/dict
import gleam/option
import lustre/attribute.{attribute}
import lustre/element.{type Element}
import lustre/element/html
import packages/index.{type PackageSummary}
import gleam/string

pub fn packages_list(
  packages: List(PackageSummary),
  total_package_count: Int,
  search_term: String,
) -> StringBuilder {
  html.main([], [
    html.header([attribute.class("site-header")], [
      html.nav([attribute.class("content")], [
        html.a([attribute.href("/")], [
          html.h1([], [element.text("Gleam Packages")]),
        ]),
        search_form(search_term),
      ]),
    ]),
    html.div([attribute.class("content")], [
      search_aware_package_list(packages, total_package_count, search_term),
    ]),
  ])
  |> layout
  |> element.to_string_builder
  |> string_builder.prepend("<!DOCTYPE html>")
}

fn search_form(search_term: String) -> Element(Nil) {
  html.form([attribute.class("search-form"), attribute("method", "GET")], [
    html.input([
      attribute("data-keybind-focus", "/"),
      attribute("value", search_term),
      attribute.name("search"),
      attribute.type_("search"),
      attribute.placeholder("Press / to focus"),
    ]),
    html.input([
      attribute.type_("submit"),
      attribute("value", "🔎"),
      attribute("aria-label", "search packages"),
    ]),
  ])
}

/// Pluralizes the word "package" based on the number we're referring to.
fn pluralize_package(amount: Int) -> String {
  case amount {
    1 -> "package"
    _ -> "packages"
  }
}

fn search_aware_package_list(
  packages: List(PackageSummary),
  total_package_count: Int,
  search_term: String,
) -> Element(Nil) {
  case packages, string.is_empty(search_term) {
    [], False ->
      html.p([attribute.class("package-list-message")], [
        element.text("I couldn't find any package matching your search."),
      ])
    _, False -> {
      let package_count = list.length(packages)

      html.div([], [
        html.p([attribute.class("package-list-message")], [
          element.text(
            [
              "I found",
              int.to_string(package_count),
              pluralize_package(package_count),
              "matching your search.",
            ]
            |> string.join(" "),
          ),
        ]),
        package_list(packages),
      ])
    }
    _, _ ->
      html.div([], [
        html.p([attribute.class("package-list-message")], [
          element.text(
            [
              "There are",
              int.to_string(total_package_count),
              pluralize_package(total_package_count),
              "available",
            ]
            |> string.join(" "),
          ),
          html.span([attribute("aria-hidden", "true")], [element.text(" ✨")]),
        ]),
        package_list(packages),
      ])
  }
}

fn package_list(packages: List(PackageSummary)) -> Element(Nil) {
  html.ul(
    [attribute.class("package-list")],
    list.map(packages, package_list_item),
  )
}

fn package_list_item(package: PackageSummary) -> Element(Nil) {
  let url = "https://hex.pm/packages/" <> package.name

  let repository_url =
    package.links
    |> dict.get("Repository")
    |> option.from_result

  let links =
    [
      package.docs_url
      |> option.map(external_link_text(_, "Documentation")),
      repository_url
      |> option.map(external_link_text(_, "Repository")),
    ]
    |> list.filter_map(option.to_result(_, Nil))

  html.li([], [
    html.div([attribute.class("package-date-time")], [
      element.text(format_date(package.updated_in_hex_at)),
    ]),
    html.h2([], [external_link_text(url, package.name)]),
    html.p([attribute.class("package-description")], [
      element.text(package.description),
    ]),
    case links {
      [] -> element.text("")
      links ->
        html.nav([attribute.class("package-links")], [
          html.ul(
            [],
            links
            |> list.map(fn(link) { html.li([], [link]) }),
          ),
        ])
    },
  ])
}

fn format_date(datetime: Time) -> String {
  birl.legible_difference(birl.now(), datetime)
}

fn external_link_text(url: String, text: String) -> Element(Nil) {
  html.a(
    [
      attribute.href(url),
      attribute.rel("noopener noreferrer"),
      attribute.target("_blank"),
    ],
    [element.text(text)],
  )
}

fn layout(content: Element(Nil)) -> Element(Nil) {
  html.html([attribute("lang", "en")], [
    html.head([], [
      html.meta([attribute("charset", "utf-8")]),
      html.meta([
        attribute.name("viewport"),
        attribute("content", "width=device-width, initial-scale=1"),
      ]),
      html.title([], "Gleam Packages"),
      html.link([
        attribute.rel("stylesheet"),
        attribute.href("/static/styles.css"),
      ]),
      html.link([
        attribute.rel("icon"),
        attribute.href("https://gleam.run/images/lucy-circle.svg"),
      ]),
      html.script(
        [
          attribute.property("defer", True),
          attribute.src("https://plausible.io/js/plausible.js"),
          attribute("data-domain", "packages.gleam.run"),
        ],
        "",
      ),
      html.script(
        [attribute.type_("module"), attribute.src("/static/main.js")],
        "",
      ),
    ]),
    html.body([], [
      content,
      html.footer([attribute.class("site-footer")], [
        html.div([], [
          element.text("Special thanks to the "),
          external_link_text("https://hex.pm/", "Hex"),
          element.text(" team."),
        ]),
        html.div([], [
          element.text("Kindly hosted by "),
          external_link_text("https://fly.io/", "Fly"),
          element.text("."),
        ]),
        html.div([], [
          external_link_text(
            "https://github.com/gleam-lang/packages",
            "Source code",
          ),
          element.text("."),
        ]),
      ]),
    ]),
  ])
}
