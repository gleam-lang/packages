import gleam/io
import gleam/json
import gleam/http
import gleam/result
import gleam/hackney
import gleam/dynamic.{Decoder}

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
    json.decode(response.body, dynamic.list(package_decoder()))
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
  dynamic.decode3(
    Package,
    dynamic.field("name", dynamic.string),
    dynamic.field("updated_at", dynamic.string),
    dynamic.field(
      "releases",
      dynamic.list(dynamic.decode2(
        Release,
        dynamic.field("version", dynamic.string),
        dynamic.field("url", dynamic.string),
      )),
    ),
  )
}
