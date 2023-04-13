import gleam/dynamic.{DecodeError, Dynamic} as dyn
import gleam/map.{Map}
import gleam/option.{Option}

/// Package from /api/packages
pub type Package {
  Package(
    name: String,
    html_url: Option(String),
    docs_html_url: Option(String),
    meta: PackageMeta,
    downloads: PackageDownloads,
    owners: List(PackageOwner),
    releases: List(PackageRelease),
    inserted_at: String,
    updated_at: String,
  )
}

pub type PackageMeta {
  PackageMeta(
    links: Map(String, String),
    licenses: List(String),
    description: String,
  )
}

pub type PackageRelease {
  PackageRelease(version: String, url: String, inserted_at: String)
}

pub type PackageOwner {
  PackageOwner(username: String, email: String, url: String)
}

pub type PackageDownloads {
  PackageDownloads(all: Int, recent: Int)
}

pub fn decode_package(data: Dynamic) -> Result(Package, List(DecodeError)) {
  dyn.decode9(
    Package,
    dyn.field("name", dyn.string),
    dyn.field("html_url", dyn.optional(dyn.string)),
    dyn.field("docs_html_url", dyn.optional(dyn.string)),
    dyn.field(
      "meta",
      dyn.decode3(
        PackageMeta,
        dyn.field("links", dyn.map(dyn.string, dyn.string)),
        dyn.field("licenses", dyn.list(dyn.string)),
        dyn.field("description", dyn.string),
      ),
    ),
    dyn.field(
      "downloads",
      dyn.decode2(
        PackageDownloads,
        dyn.field("all", dyn.int),
        dyn.field("recent", dyn.int),
      ),
    ),
    dyn.field(
      "owners",
      dyn.list(dyn.decode3(
        PackageOwner,
        dyn.field("username", dyn.string),
        dyn.field("email", dyn.string),
        dyn.field("url", dyn.string),
      )),
    ),
    dyn.field(
      "releases",
      dyn.list(dyn.decode3(
        PackageRelease,
        dyn.field("version", dyn.string),
        dyn.field("url", dyn.string),
        dyn.field("inserted_at", dyn.string),
      )),
    ),
    dyn.field("inserted_at", dyn.string),
    dyn.field("updated_at", dyn.string),
  )(data)
}
// /// Meta for a hex release
// pub type HexReleaseMeta {
//   HexReleaseMeta(app: Option(String), build_tools: List(String))
// }

// /// Release from /api/packages/:package/releases/:release
// pub type HexRelease {
//   HexRelease(version: String, url: String, meta: HexReleaseMeta)
// }

// pub fn hex_release_decoder() -> Decoder(HexRelease) {
//   dyn.decode3(
//     HexRelease,
//     dyn.field("version", dyn.string),
//     dyn.field("url", dyn.string),
//     dyn.field(
//       "meta",
//       dyn.decode2(
//         HexReleaseMeta,
//         dyn.field("app", dyn.optional(dyn.string)),
//         dyn.field("build_tools", dyn.list(dyn.string)),
//       ),
//     ),
//   )
// }
