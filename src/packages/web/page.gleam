import birl.{type Time}
import birl/duration
import gleam/dict
import gleam/int
import gleam/json
import gleam/list
import gleam/option
import gleam/order
import gleam/result
import gleam/string
import gleam/string_builder.{type StringBuilder}
import lustre/attribute.{attribute}
import lustre/element.{type Element}
import lustre/element/html
import packages/index.{type PackageSummary}
import packages/web/icons

pub fn packages_list(
  packages: List(PackageSummary),
  total_package_count: Int,
  search_term: String,
) -> StringBuilder {
  html.div([attribute.class("content")], [
    search_aware_package_list(packages, total_package_count, search_term),
  ])
  |> layout(search_term)
}

pub type Stats {
  Stats(
    package_counts: List(#(String, Int)),
    release_counts: List(#(String, Int)),
  )
}

pub fn internet_points(stats: Stats) -> StringBuilder {
  html.div([], [
    html.script([attribute.src("https://cdn.plot.ly/plotly-2.30.0.min.js")], ""),
    line_chart("Package count", stats.package_counts),
    line_chart("Release count", stats.release_counts),
  ])
  |> layout(search_term: "")
}

fn line_chart(name: String, data: List(#(String, Int))) -> Element(Nil) {
  let id = "chart-" <> name
  let json_x =
    json.array(data, fn(pair) { json.string(pair.0) })
    |> json.to_string
  let json_y =
    data
    |> list.scan(0, fn(total, new) { total + new.1 })
    |> json.array(fn(total) { json.int(total) })
    |> json.to_string

  let javascript = "
var trace = {
  x: " <> json_x <> ",
  y: " <> json_y <> ",
  type: 'scatter',
  line: { color: '#ffaff3', width: 2 }
};

Plotly.newPlot('" <> id <> "', [trace], {
  title: { text: '" <> name <> "' }
});
  "

  html.div([], [html.div([attribute.id(id)], []), html.script([], javascript)])
}

fn theme_picker() -> Element(Nil) {
  html.div([attribute.class("theme-picker")], [
    html.button(
      [
        attribute.type_("button"),
        attribute.class("theme-button -light"),
        attribute.attribute("data-light-theme-toggle", ""),
        attribute.alt("Switch to light mode"),
        attribute.attribute("title", "Switch to light mode"),
      ],
      [icons.icon_moon(), icons.icon_toggle_left()],
    ),
    html.button(
      [
        attribute.type_("button"),
        attribute.class("theme-button -dark"),
        attribute.attribute("data-dark-theme-toggle", ""),
        attribute.alt("Switch to dark mode"),
        attribute.attribute("title", "Switch to dark mode"),
      ],
      [icons.icon_sun(), icons.icon_toggle_right()],
    ),
  ])
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

  let latest_version_string = case package.latest_versions |> list.last {
    Ok(version) -> " @ v" <> version
    Error(_) -> ""
  }

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
    html.h2([attribute.class("package-name")], [
      external_link_text(url, package.name),
      html.small([], [element.text(latest_version_string)]),
    ]),
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
  let now = birl.now()
  let one_hour_ago = birl.subtract(now, duration.hours(1))
  case birl.compare(datetime, one_hour_ago) {
    order.Gt -> "Just now!"
    _ -> birl.legible_difference(now, datetime)
  }
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

fn layout(
  content: Element(Nil),
  search_term search_term: String,
) -> StringBuilder {
  html.html([attribute("lang", "en"), attribute.class("theme-light")], [
    html.head([], [
      html.meta([attribute("charset", "utf-8")]),
      html.meta([
        attribute.name("viewport"),
        attribute("content", "width=device-width, initial-scale=1"),
      ]),
      html.title([], "Gleam Packages"),
      html.link([
        attribute.rel("stylesheet"),
        attribute.href("/static/common.css"),
      ]),
      html.link([
        attribute.rel("stylesheet"),
        attribute.href("/static/styles.css"),
      ]),
      html.link([
        attribute.rel("icon"),
        attribute.href("https://gleam.run/images/lucy/lucy.svg"),
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
      html.script([attribute.type_("module")], theme_picker_js),
    ]),
    html.body([], [
      html.main([], [
        html.header([attribute.class("site-header")], [
          html.nav([attribute.class("content")], [
            html.a([attribute.href("/")], [
              html.img([
                attribute.class("logo"),
                attribute.src("https://gleam.run/images/lucy/lucy.svg"),
                attribute.alt("Lucy the star, Gleam's mascot"),
              ]),
              html.h1([], [element.text("Gleam Packages")]),
            ]),
            html.div([attribute.class("nav-right")], [
              theme_picker(),
              search_form(search_term),
            ]),
          ]),
        ]),
        content,
      ]),
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
  |> element.to_string_builder
  |> string_builder.prepend("<!DOCTYPE html>")
}

// This script is inlined in the response to avoid FOUC when applying the theme
const theme_picker_js = "
const mediaPrefersDarkTheme = window.matchMedia('(prefers-color-scheme: dark)')

function selectTheme(selectedTheme) {
  // Apply and remember the specified theme.
  applyTheme(selectedTheme)
  if ((selectedTheme === 'dark') === mediaPrefersDarkTheme.matches) {
    // Selected theme is the same as the device's preferred theme, so we can forget this setting.
    localStorage.removeItem('theme')
  } else {
    // Remember the selected theme to apply it on the next visit
    localStorage.setItem('theme', selectedTheme)
  }
}

function applyTheme(theme) {
  document.documentElement.classList.toggle('theme-dark', theme === 'dark')
  document.documentElement.classList.toggle('theme-light', theme !== 'dark')
}

// If user had selected a theme, load it. Otherwise, use device's preferred theme
const selectedTheme = localStorage.getItem('theme')
if (selectedTheme) {
  applyTheme(selectedTheme)
} else {
  applyTheme(mediaPrefersDarkTheme.matches ? 'dark' : 'light')
}

// Watch the device's preferred theme and update theme if user did not select a theme
mediaPrefersDarkTheme.addEventListener('change', () => {
  const selectedTheme = localStorage.getItem('theme')
  if (!selectedTheme) {
    applyTheme(mediaPrefersDarkTheme.matches ? 'dark' : 'light')
  }
})

// Add handlers for theme selection buttons.
document.querySelector('[data-light-theme-toggle]').addEventListener('click', () => {
  selectTheme('light')
})
document.querySelector('[data-dark-theme-toggle]').addEventListener('click', () => {
  selectTheme('dark')
})
"
