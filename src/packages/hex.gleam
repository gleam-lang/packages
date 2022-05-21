import gleam/io
import gleam/json
import gleam/http
import gleam/result
import gleam/hackney
import gleam/list
import gleam/dynamic.{Decoder} as d
import time/parse.{parse_iso8601_to_epoch_timestamp}
import gleam/pgo
import gleam/string
import gleam/int

pub type Error {
  HackneyError(hackney.Error)
  JsonError(json.DecodeError)
}

pub fn query(_db: pgo.Connection) {
  query_all_packages(
    [],
    1,
    parse_iso8601_to_epoch_timestamp("2022-05-21T07:47:42.555499Z"),
  )
  |> io.debug

  Ok(1)
}

fn query_all_packages(
  last_page: List(Package),
  next_page: Int,
  last_ran: Int,
) -> Result(List(Package), Error) {
  let req =
    http.default_req()
    |> http.set_method(http.Get)
    |> http.prepend_req_header(
      "User-Agent",
      "GleamPackages/0.0.1 (Gleam/0.21.0)",
    )
    |> http.set_host("hex.pm")
    |> http.set_path(
      "/api/packages?sort=updated_at&page="
      |> string.append(int.to_string(next_page)),
    )

  try response =
    hackney.send(req)
    |> result.map_error(HackneyError)

  try packages =
    json.decode(response.body, d.list(package_decoder()))
    |> result.map_error(JsonError)

  let new_packages =
    packages
    |> list.filter(fn(x) {
      parse_iso8601_to_epoch_timestamp(x.updated_at) > last_ran
    })

  case list.length(new_packages) >= list.length(packages) {
    True -> query_all_packages(new_packages, next_page + 1, last_ran)
    False ->
      Ok(list.append(
        last_page,
        packages
        |> list.filter(fn(x) {
          parse_iso8601_to_epoch_timestamp(x.updated_at) > last_ran
        }),
      ))
  }
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
