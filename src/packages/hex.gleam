import gleam/io
import gleam/json
import gleam/http
import gleam/result
import gleam/hackney
import gleam/list
import gleam/dynamic.{Decoder} as d
import time/parse.{parse_iso8601_to_epoch_timestamp}

pub type Error {
  HackneyError(hackney.Error)
  JsonError(json.DecodeError)
}

pub fn query() {
  let req =
    http.default_req()
    |> http.set_method(http.Get)
    |> http.prepend_req_header(
      "User-Agent",
      "GleamPackages/0.0.1 (Gleam/0.21.0)",
    )
    |> http.set_host("hex.pm")
    |> http.set_path("/api/packages?sort=updated_at&page=1")

  try response =
    hackney.send(req)
    |> result.map_error(HackneyError)

  try packages =
    json.decode(response.body, d.list(package_decoder()))
    |> result.map_error(JsonError)

  let last_ran = parse_iso8601_to_epoch_timestamp("2022-05-21T07:47:42.555499Z")

  packages
  |> list.reverse
  |> list.filter(fn(x) {
    parse_iso8601_to_epoch_timestamp(x.updated_at) > last_ran
  })
  |> io.debug

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
