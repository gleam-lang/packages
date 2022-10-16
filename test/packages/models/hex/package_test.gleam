import gleam/json
import gleam/map
import packages/models/hex/package.{
  HexPackage, HexPackageMeta, HexPackageRelease,
}
import gleeunit/should

pub fn hex_package_decoder_test() {
  let shimmer =
    "{
  \"configs\": {
    \"erlang.mk\": \"dep_shimmer = hex 0.0.3\",
    \"mix.exs\": \"{:shimmer, \\\"~> 0.0.3\\\"}\",
    \"rebar.config\": \"{shimmer, \\\"0.0.3\\\"}\"
  },
  \"docs_html_url\": \"https://hexdocs.pm/shimmer/\",
  \"downloads\": {
    \"all\": 17,
    \"recent\": 1
  },
  \"html_url\": \"https://hex.pm/packages/shimmer\",
  \"inserted_at\": \"2022-01-11T16:33:25.508966Z\",
  \"latest_stable_version\": \"0.0.3\",
  \"latest_version\": \"0.0.3\",
  \"meta\": {
    \"description\": \"A Gleam library for interacting with the Discord API\",
    \"licenses\": [
      \"Apache-2.0\"
    ],
    \"links\": {
      \"Repository\": \"https://github.com/HarryET/shimmer\",
      \"Website\": \"https://gleampkg.com/packages/shimmer\"
    },
    \"maintainers\": [

    ]
  },
  \"name\": \"shimmer\",
  \"owners\": [
    {
      \"email\": \"h.bairstow22@gmail.com\",
      \"url\": \"https://hex.pm/api/users/harryet\",
      \"username\": \"harryet\"
    }
  ],
  \"releases\": [
    {
      \"has_docs\": true,
      \"inserted_at\": \"2022-07-07T19:14:04.497803Z\",
      \"url\": \"https://hex.pm/api/packages/shimmer/releases/0.0.3\",
      \"version\": \"0.0.3\"
    },
    {
      \"has_docs\": true,
      \"inserted_at\": \"2022-01-11T16:33:25.536567Z\",
      \"url\": \"https://hex.pm/api/packages/shimmer/releases/0.0.1\",
      \"version\": \"0.0.1\"
    }
  ],
  \"repository\": \"hexpm\",
  \"retirements\": {

  },
  \"updated_at\": \"2022-07-07T19:14:07.871112Z\",
  \"url\": \"https://hex.pm/api/packages/shimmer\"
}"

  assert Ok(package) = json.decode(shimmer, package.hex_package_decoder())

  package
  |> should.equal(HexPackage(
    name: "shimmer",
    meta: HexPackageMeta(
      description: "A Gleam library for interacting with the Discord API",
      links: map.new()
      |> map.insert("Repository", "https://github.com/HarryET/shimmer")
      |> map.insert("Website", "https://gleampkg.com/packages/shimmer"),
      licenses: ["Apache-2.0"],
    ),
    releases: [
      HexPackageRelease(
        version: "0.0.3",
        url: "https://hex.pm/api/packages/shimmer/releases/0.0.3",
      ),
      HexPackageRelease(
        version: "0.0.1",
        url: "https://hex.pm/api/packages/shimmer/releases/0.0.1",
      ),
    ],
    updated_at: "2022-07-07T19:14:07.871112Z",
  ))
}
