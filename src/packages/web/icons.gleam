import lustre/attribute.{attribute, class}
import lustre/element.{type Element}
import lustre/element/svg

pub fn git_tree() -> Element(Nil) {
  svg.svg(
    [
      attribute("viewBox", "0 0 448 512"),
      attribute("xmlns", "http://www.w3.org/2000/svg"),
    ],
    [
      svg.path([
        attribute(
          "d",
          "M80 112a32 32 0 1 0 0-64 32 32 0 1 0 0 64zm80-32c0 35.8-23.5 66.1-56 76.3l0 99.7c20.1-15.1 45-24 72-24l96 0c39.8 0 72-32.2 72-72l0-3.7c-32.5-10.2-56-40.5-56-76.3c0-44.2 35.8-80 80-80s80 35.8 80 80c0 35.8-23.5 66.1-56 76.3l0 3.7c0 66.3-53.7 120-120 120l-96 0c-39.8 0-72 32.2-72 72l0 3.7c32.5 10.2 56 40.5 56 76.3c0 44.2-35.8 80-80 80s-80-35.8-80-80c0-35.8 23.5-66.1 56-76.3l0-3.7 0-195.7C23.5 146.1 0 115.8 0 80C0 35.8 35.8 0 80 0s80 35.8 80 80zm240 0a32 32 0 1 0 -64 0 32 32 0 1 0 64 0zM80 464a32 32 0 1 0 0-64 32 32 0 1 0 0 64z",
        ),
      ]),
    ],
  )
}

pub fn search() -> Element(Nil) {
  svg.svg(
    [
      attribute("xmlns", "http://www.w3.org/2000/svg"),
      attribute("fill", "none"),
      attribute("viewBox", "0 0 24 24"),
      attribute("stroke", "currentColor"),
      class("search-icon"),
    ],
    [
      svg.path([
        attribute("stroke-linejoin", "round"),
        attribute("stroke-linecap", "round"),
        attribute("stroke-width", "2"),
        attribute(
          "d",
          "M11 19C15.4183 19 19 15.4183 19 11C19 6.58172 15.4183 3 11 3C6.58172 3 3 6.58172 3 11C3 15.4183 6.58172 19 11 19Z",
        ),
      ]),
      svg.path([
        attribute("stroke-linejoin", "round"),
        attribute("stroke-linecap", "round"),
        attribute("stroke-width", "2"),
        attribute("d", "M21 21L16.7 16.7"),
      ]),
    ],
  )
}
