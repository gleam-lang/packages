import gleam/dynamic.{Decoder} as d
import gleam/option.{Option}

/// Meta for a hex release
pub type HexReleaseMeta {
  HexReleaseMeta(app: Option(String), build_tools: List(String))
}

/// Release from /api/packages/:package/releases/:release
pub type HexRelease {
  HexRelease(version: String, url: String, meta: HexReleaseMeta)
}

pub fn hex_release_decoder() -> Decoder(HexRelease) {
  d.decode3(
    HexRelease,
    d.field("version", d.string),
    d.field("url", d.string),
    d.field(
      "meta",
      d.decode2(
        HexReleaseMeta,
        d.field("app", d.optional(d.string)),
        d.field("build_tools", d.list(d.string)),
      ),
    ),
  )
}
