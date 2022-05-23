import gleam/dynamic.{Decoder} as d
import gleam/map.{Map}

/// Package from /api/packages
pub type HexPackage {
  HexPackage(
    name: String,
    updated_at: String,
    releases: List(HexPackageRelease),
    meta: HexPackageMeta,
  )
}

/// Meta for a hex package
pub type HexPackageMeta {
  HexPackageMeta(
    links: Map(String, String),
    licenses: List(String),
    description: String,
  )
}

/// Partial release embeded within a package from /api/packages
pub type HexPackageRelease {
  HexPackageRelease(version: String, url: String)
}

pub fn hex_package_decoder() -> Decoder(HexPackage) {
  d.decode4(
    HexPackage,
    d.field("name", d.string),
    d.field("updated_at", d.string),
    d.field(
      "releases",
      d.list(d.decode2(
        HexPackageRelease,
        d.field("version", d.string),
        d.field("url", d.string),
      )),
    ),
    d.field(
      "meta",
      d.decode3(
        HexPackageMeta,
        d.field("links", d.map(d.string, d.string)),
        d.field("licences", d.list(d.string)),
        d.field("description", d.string),
      ),
    ),
  )
}
