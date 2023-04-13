import gleam/json
import gleam/map
import gleam/option.{Some}
import gleam/hexpm.{
  Package, PackageDownloads, PackageMeta, PackageOwner, PackageRelease, Release,
  ReleaseMeta, ReleaseRetirement, Security,
}
import gleeunit/should

pub fn hex_package_decoder_test() {
  let json_string =
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

  let assert Ok(package) = json.decode(json_string, hexpm.decode_package)

  package
  |> should.equal(Package(
    name: "shimmer",
    html_url: Some("https://hex.pm/packages/shimmer"),
    docs_html_url: Some("https://hexdocs.pm/shimmer/"),
    meta: PackageMeta(
      description: "A Gleam library for interacting with the Discord API",
      links: map.from_list([
        #("Repository", "https://github.com/HarryET/shimmer"),
        #("Website", "https://gleampkg.com/packages/shimmer"),
      ]),
      licenses: ["Apache-2.0"],
    ),
    downloads: PackageDownloads(all: 17, recent: 1),
    owners: [
      PackageOwner(
        username: "harryet",
        email: "h.bairstow22@gmail.com",
        url: "https://hex.pm/api/users/harryet",
      ),
    ],
    releases: [
      PackageRelease(
        version: "0.0.3",
        url: "https://hex.pm/api/packages/shimmer/releases/0.0.3",
        inserted_at: "2022-07-07T19:14:04.497803Z",
      ),
      PackageRelease(
        version: "0.0.1",
        url: "https://hex.pm/api/packages/shimmer/releases/0.0.1",
        inserted_at: "2022-01-11T16:33:25.536567Z",
      ),
    ],
    inserted_at: "2022-01-11T16:33:25.508966Z",
    updated_at: "2022-07-07T19:14:07.871112Z",
  ))
}

pub fn hex_release_decoder_test() {
  let json_string =
    "{
  \"checksum\": \"a895b55c4c3749eb32328f02b15bbd3acc205dd874fabd135d7be5d12eda59a8\",
  \"configs\": {
    \"erlang.mk\": \"dep_shimmer = hex 0.0.3\",
    \"mix.exs\": \"{:shimmer, \\\"~> 0.0.3\\\"}\",
    \"rebar.config\": \"{shimmer, \\\"0.0.3\\\"}\"
  },
  \"docs_html_url\": \"https://hexdocs.pm/shimmer/0.0.3/\",
  \"downloads\": 5,
  \"has_docs\": true,
  \"html_url\": \"https://hex.pm/packages/shimmer/0.0.3\",
  \"inserted_at\": \"2022-07-07T19:14:04.497803Z\",
  \"meta\": {
    \"app\": \"shimmer\",
    \"build_tools\": [
      \"gleam\"
    ],
    \"elixir\": null
  },
  \"package_url\": \"https://hex.pm/api/packages/shimmer\",
  \"publisher\": {
    \"email\": \"h.bairstow22@gmail.com\",
    \"url\": \"https://hex.pm/api/users/harryet\",
    \"username\": \"harryet\"
  },
  \"requirements\": {
    \"certifi\": {
      \"app\": \"certifi\",
      \"optional\": false,
      \"requirement\": \"~> 2.9\"
    },
    \"gleam_erlang\": {
      \"app\": \"gleam_erlang\",
      \"optional\": false,
      \"requirement\": \"~> 0.9\"
    },
    \"gleam_hackney\": {
      \"app\": \"gleam_hackney\",
      \"optional\": false,
      \"requirement\": \"~> 0.2\"
    },
    \"gleam_http\": {
      \"app\": \"gleam_http\",
      \"optional\": false,
      \"requirement\": \"~> 3.0\"
    },
    \"gleam_json\": {
      \"app\": \"gleam_json\",
      \"optional\": false,
      \"requirement\": \"~> 0.3\"
    },
    \"gleam_otp\": {
      \"app\": \"gleam_otp\",
      \"optional\": false,
      \"requirement\": \"~> 0.4\"
    },
    \"gleam_stdlib\": {
      \"app\": \"gleam_stdlib\",
      \"optional\": false,
      \"requirement\": \"~> 0.22\"
    },
    \"gun\": {
      \"app\": \"gun\",
      \"optional\": false,
      \"requirement\": \"> 1.3.0 and < 3.0.0\"
    }
  },
  \"retirement\": {
    \"reason\": \"security\",
    \"message\": \"Retired due to security concerns\"
  },
  \"updated_at\": \"2022-07-07T19:14:07.870166Z\",
  \"url\": \"https://hex.pm/api/packages/shimmer/releases/0.0.3\",
  \"version\": \"0.0.3\"
}"

  let assert Ok(release) = json.decode(json_string, hexpm.decode_release)

  release
  |> should.equal(Release(
    version: "0.0.3",
    checksum: "a895b55c4c3749eb32328f02b15bbd3acc205dd874fabd135d7be5d12eda59a8",
    url: "https://hex.pm/api/packages/shimmer/releases/0.0.3",
    downloads: 5,
    meta: ReleaseMeta(app: Some("shimmer"), build_tools: ["gleam"]),
    publisher: PackageOwner(
      username: "harryet",
      email: "h.bairstow22@gmail.com",
      url: "https://hex.pm/api/users/harryet",
    ),
    retirement: Some(ReleaseRetirement(
      reason: Security,
      message: Some("Retired due to security concerns"),
    )),
  ))
}
