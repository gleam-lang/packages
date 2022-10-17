import packages/models/hex/package.{
  HexPackage, HexPackageMeta, HexPackageRelease,
}
import gleam/map
import gleam/string
import gleam/list
import packages/hex.{is_gleam_package}
import gleeunit/should

pub fn packages_list_fliter_test() {
  let example_packages = [
    new_test_package("shimmer", "0.0.3"),
    new_test_package("phoenix", "1.6.14"),
    new_test_package("plug", "1.13.6"),
    new_test_package("gleam_stdlib", "0.23.0"),
  ]

  let flitered_packages =
    example_packages
    |> list.filter_map(is_gleam_package)

  flitered_packages
  |> list.length
  |> should.equal(2)
}

pub fn is_gleam_package_reject_invalid_test() {
  let example_package = new_test_package("phoenix", "1.6.14")

  assert Error(_) = is_gleam_package(example_package)
}

pub fn is_gleam_package_accept_valid_test() {
  let example_package = new_test_package("gleam_stdlib", "0.23.0")

  assert Ok(_) = is_gleam_package(example_package)
}

fn new_test_package(name: String, release: String) -> HexPackage {
  HexPackage(
    name: name,
    meta: HexPackageMeta(description: "", links: map.new(), licenses: []),
    releases: [
      HexPackageRelease(
        version: release,
        url: "https://hex.pm/api/packages/"
        |> string.append(name)
        |> string.append("/releases/")
        |> string.append(release),
      ),
    ],
    updated_at: "",
  )
}
