import gleam/int
import gleam/json
import gleam/list
import gleam/option
import gleam/string
import gleam/time/duration
import gleam/time/timestamp.{type Timestamp}
import lustre/attribute.{attribute, class}
import lustre/element.{type Element, text}
import lustre/element/html
import packages/storage.{type Package}
import packages/web/icons

pub fn packages_list(
  packages: List(Package),
  total_package_count: Int,
  search_term: String,
) -> String {
  html.div(
    [attribute.class("content")],
    search_aware_package_list(packages, total_package_count, search_term),
  )
  |> layout
}

pub type Stats {
  Stats(
    package_counts: List(#(String, Int)),
    release_counts: List(#(String, Int)),
  )
}

pub fn internet_points(stats: Stats) -> String {
  html.div([], [
    html.script([attribute.src("https://cdn.plot.ly/plotly-2.30.0.min.js")], ""),
    line_chart("Package count", stats.package_counts),
    line_chart("Release count", stats.release_counts),
  ])
  |> layout
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

fn search_form(search_term: String) -> Element(Nil) {
  html.form([class("search-bar")], [
    html.input([
      attribute.data("keybind-focus", "/"),
      attribute.placeholder("Press / to focus"),
      attribute("aria-label", "Package name, to search"),
      attribute.name("search"),
      attribute.value(search_term),
    ]),
    icons.search(),
  ])
}

fn search_aware_package_list(
  packages: List(Package),
  total_package_count: Int,
  search_term: String,
) -> List(Element(Nil)) {
  let header_phrase = case search_term, packages {
    "", [] -> "No packages have been added yet"
    "", [_] -> "1 package is available!"
    "", _ -> int.to_string(total_package_count) <> " packages are available!"

    _, [] -> "No packages match your query"
    _, [_] -> "1 package matches your query!"
    _, _ ->
      int.to_string(list.length(packages)) <> " packages match your search"
  }

  [
    html.header([class("page-header")], [text(header_phrase)]),
    search_form(search_term),
    case packages, string.is_empty(search_term) {
      [], False ->
        html.p([attribute.class("package-list-message")], [
          element.text("I couldn't find any package matching your search."),
        ])
      _, _ -> package_list(packages)
    },
  ]
}

fn package_list(packages: List(Package)) -> Element(Nil) {
  html.div(
    [attribute.class("package-list")],
    list.map(packages, package_list_item),
  )
}

fn package_list_item(package: Package) {
  html.div([class("package-item")], [
    html.main([], [
      html.h2([class("package-name")], [
        text(package.name),
        html.span([class("release-version")], [
          text("@" <> package.latest_version),
        ]),
      ]),
      html.p([class("package-description")], [text(package.description)]),
      html.nav([class("package-buttons")], [
        package_button(
          "/static/docs.svg",
          "https://hexdocs.pm/" <> package.name,
          "Docs",
        ),
        case package.repository_url {
          option.Some(url) -> package_button("/static/repo.svg", url, "Repo")
          _ -> element.none()
        },
        package_button(
          "/static/hex.svg",
          "https://hex.pm/packages/" <> package.name,
          "Hex",
        ),
      ]),
    ]),
    html.aside([], [
      html.p([class("package-update-time")], [
        element.text("Updated "),
        html.span([], [element.text(format_date(package.updated_in_hex_at))]),
      ]),
    ]),
  ])
}

fn package_button(icon_location: String, destination: String, label: String) {
  html.a([class("package-button"), attribute.href(destination)], [
    html.img([
      attribute.src(icon_location),
      attribute.alt(label <> " Button Icon"),
    ]),
    text(label),
  ])
}

fn format_date(datetime: Timestamp) -> String {
  let now = timestamp.system_time()
  let #(i, unit) = duration.approximate(timestamp.difference(datetime, now))
  let print = fn(unit) {
    case i {
      1 -> "1 " <> unit <> " ago"
      _ -> int.to_string(i) <> " " <> unit <> "s ago"
    }
  }
  case unit {
    _ if i < 0 -> "just now"
    duration.Microsecond
    | duration.Millisecond
    | duration.Minute
    | duration.Nanosecond
    | duration.Second -> "just now"
    duration.Day -> print("day")
    duration.Hour -> print("hour")
    duration.Week -> print("week")
    duration.Month -> print("month")
    duration.Year -> print("year")
  }
}

const meta_title = "Gleam Package Index"

const meta_description = "List and search through all the packages available for the Gleam programming language!"

fn layout(content: Element(Nil)) -> String {
  let social_meta_tags = [
    html.title([], meta_title),
    html.meta([
      attribute("content", meta_title),
      attribute.name("title"),
    ]),
    html.meta([
      attribute("content", meta_description),
      attribute.name("description"),
    ]),
    html.meta([
      attribute("content", "website"),
      attribute("property", "og:type"),
    ]),
    html.meta([
      attribute("content", "https://packages.gleam.run/"),
      attribute("property", "og:url"),
    ]),
    html.meta([
      attribute("content", meta_title),
      attribute("property", "og:title"),
    ]),
    html.meta([
      attribute("content", meta_description),
      attribute("property", "og:description"),
    ]),
    // html.meta([
    //   attribute("content", "https://packages.gleam.run/preview.png"),
    //   attribute("property", "og:image"),
    // ]),
    // html.meta([
    //   attribute("content", "summary_large_image"),
    //   attribute("property", "twitter:card"),
    // ]),
    html.meta([
      attribute("content", "https://packages.gleam.run/"),
      attribute("property", "twitter:url"),
    ]),
    html.meta([
      attribute("content", meta_title),
      attribute("property", "twitter:title"),
    ]),
    // html.meta([
    //   attribute("content", "https://packages.gleam.run/preview.png"),
    //   attribute("property", "twitter:image"),
    // ]),
    html.meta([
      attribute("content", meta_description),
      attribute("property", "twitter:description"),
    ]),
  ]

  html.html([attribute("lang", "en")], [
    html.head([], [
      html.meta([attribute("charset", "utf-8")]),
      html.meta([
        attribute.name("viewport"),
        attribute("content", "width=device-width, initial-scale=1"),
      ]),

      element.fragment(social_meta_tags),

      html.link([
        attribute.rel("preload"),
        attribute.href("/fonts/Lexend.woff2"),
        attribute.type_("font/woff2"),
        attribute("crossorigin", "true"),
        attribute("as", "font"),
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
          attribute.property("defer", json.bool(True)),
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
      navbar(),
      html.main([class("page-content container")], [content]),
      footer(),
    ]),
  ])
  |> element.to_document_string
}

fn navbar() {
  html.nav([class("page-nav")], [
    html.div([class("container")], [
      html.a([attribute.href("/"), class("nav-brand")], [
        html.img([
          attribute.width(55),
          attribute.height(60),
          attribute.src("/static/packages-icon.svg"),
          attribute.alt("The Gleam Packages icon, Lucy popping out of a box!"),
        ]),
        text("Gleam Packages"),
      ]),
      darkmode_toggle(),
    ]),
  ])
}

fn darkmode_toggle() {
  html.button([class("darkmode-toggle"), attribute.data("theme-toggle", "")], [
    html.img([
      class("toggle-icon toggle-dark"),
      attribute.src("/static/mode-switch-dark.svg"),
      attribute.alt("Dark mode switch icon"),
    ]),
    html.img([
      class("toggle-icon toggle-light"),
      attribute.src("/static/mode-switch-light.svg"),
      attribute.alt("Light mode switch icon"),
    ]),
    html.script([], theme_picker_js),
  ])
}

fn footer() {
  html.footer([class("page-footer container")], [
    html.p([], [
      // The spaces before and after the text elements are important for correct display.
      element.text("Special thanks to the "),
      html.a([attribute.href("https://hex.pm")], [element.text("Hex")]),
      element.text(" team."),
    ]),
    html.a(
      [
        attribute.href("https://github.com/gleam-lang/packages"),
        class("source-button"),
      ],
      [icons.git_tree(), element.text("Source Code")],
    ),
  ])
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
  document.body.classList.toggle('theme-dark', theme === 'dark')
  document.body.classList.toggle('theme-light', theme !== 'dark')
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
document.addEventListener('DOMContentLoaded', function () {
  document.querySelector('[data-theme-toggle]').addEventListener('click', () => {
    const theme = document.body.classList.contains('theme-dark') ? 'light' : 'dark'
    selectTheme(theme)
  })
});
"
