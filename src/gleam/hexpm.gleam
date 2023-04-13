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
    dyn.field("owners", dyn.list(decode_package_owner)),
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

/// Release from /api/packages/:package/releases/:release
pub type Release {
  Release(
    version: String,
    url: String,
    checksum: String,
    downloads: Int,
    publisher: PackageOwner,
    meta: ReleaseMeta,
    retirement: Option(ReleaseRetirement),
  )
}

/// Meta for a hex release
pub type ReleaseMeta {
  ReleaseMeta(app: Option(String), build_tools: List(String))
}

pub type ReleaseRetirement {
  ReleaseRetirement(reason: RetirementReason, message: Option(String))
}

pub type RetirementReason {
  OtherReason
  Invalid
  Security
  Deprecated
  Renamed
}

fn decode_retirement_reason(
  data: Dynamic,
) -> Result(RetirementReason, List(DecodeError)) {
  case dyn.string(data) {
    Error(e) -> Error(e)
    Ok("invalid") -> Ok(Invalid)
    Ok("security") -> Ok(Security)
    Ok("deprecated") -> Ok(Deprecated)
    Ok("renamed") -> Ok(Renamed)
    Ok(_) -> Ok(OtherReason)
  }
}

pub fn decode_release(data: Dynamic) -> Result(Release, List(DecodeError)) {
  dyn.decode7(
    Release,
    dyn.field("version", dyn.string),
    dyn.field("url", dyn.string),
    dyn.field("checksum", dyn.string),
    dyn.field("downloads", dyn.int),
    dyn.field("publisher", decode_package_owner),
    dyn.field(
      "meta",
      dyn.decode2(
        ReleaseMeta,
        dyn.field("app", dyn.optional(dyn.string)),
        dyn.field("build_tools", dyn.list(dyn.string)),
      ),
    ),
    dyn.field(
      "retirement",
      dyn.optional(dyn.decode2(
        ReleaseRetirement,
        dyn.field("reason", decode_retirement_reason),
        dyn.field("message", dyn.optional(dyn.string)),
      )),
    ),
  )(data)
}

fn decode_package_owner(
  data: Dynamic,
) -> Result(PackageOwner, List(DecodeError)) {
  dyn.decode3(
    PackageOwner,
    dyn.field("username", dyn.string),
    dyn.field("email", dyn.string),
    dyn.field("url", dyn.string),
  )(data)
}
