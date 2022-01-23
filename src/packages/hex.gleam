import gleam/io
import gleam/json
import gleam/http
import gleam/result
import gleam/hackney
import gleam/dynamic.{Decoder} as d

pub type Error {
  HackneyError(hackney.Error)
  JsonError(json.DecodeError)
}

pub fn query() {
  let req =
    http.default_req()
    |> http.set_method(http.Get)
    |> http.set_host("hex.pm")
    |> http.set_path("/api/packages?sort=updated_at&page=1")

  try response =
    hackney.send(req)
    |> result.map_error(HackneyError)

  try packages =
    json.decode(response.body, d.list(package_decoder()))
    |> result.map_error(JsonError)

  io.debug(packages)

  Ok(1)
}

type Package {
  Package(name: String, updated_at: String, releases: List(Release))
}

type Release {
  Release(version: String, url: String)
}

fn package_decoder() -> Decoder(Package) {
  d.decode3(
    Package,
    d.field("name", d.string),
    d.field("updated_at", d.string),
    d.field(
      "releases",
      d.list(d.decode2(
        Release,
        d.field("version", d.string),
        d.field("url", d.string),
      )),
    ),
  )
}
