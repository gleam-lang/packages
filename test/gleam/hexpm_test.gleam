import gleam/json
import gleam/map
import gleam/option.{None, Some}
import gleam/hexpm.{
  Package, PackageMeta, PackageOwner, PackageRelease, Release, ReleaseMeta,
  ReleaseRetirement, Security,
}
import birl/time.{Time}
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
      description: Some("A Gleam library for interacting with the Discord API"),
      links: map.from_list([
        #("Repository", "https://github.com/HarryET/shimmer"),
        #("Website", "https://gleampkg.com/packages/shimmer"),
      ]),
      licenses: ["Apache-2.0"],
    ),
    downloads: map.from_list([#("all", 17), #("recent", 1)]),
    owners: Some([
      PackageOwner(
        username: "harryet",
        email: Some("h.bairstow22@gmail.com"),
        url: "https://hex.pm/api/users/harryet",
      ),
    ]),
    releases: [
      PackageRelease(
        version: "0.0.3",
        url: "https://hex.pm/api/packages/shimmer/releases/0.0.3",
        inserted_at: timestamp("2022-07-07T19:14:04.497803Z"),
      ),
      PackageRelease(
        version: "0.0.1",
        url: "https://hex.pm/api/packages/shimmer/releases/0.0.1",
        inserted_at: timestamp("2022-01-11T16:33:25.536567Z"),
      ),
    ],
    inserted_at: timestamp("2022-01-11T16:33:25.508966Z"),
    updated_at: timestamp("2022-07-07T19:14:07.871112Z"),
  ))
}

fn timestamp(string: String) -> Time {
  let assert Ok(t) = time.from_iso8601(string)
  t
}

pub fn hex_packages_decoder_test() {
  let json_string =
    "{
  \"configs\": {
    \"erlang.mk\": \"dep_activity_pub = hex 0.1.0\",
    \"mix.exs\": \"{:activity_pub, \\\"~> 0.1.0\\\"}\",
    \"rebar.config\": \"{activity_pub, \\\"0.1.0\\\"}\"
  },
  \"docs_html_url\": \"https://hexdocs.pm/activity_pub/\",
  \"downloads\": {
    \"all\": 2438,
    \"recent\": 12
  },
  \"html_url\": \"https://hex.pm/packages/activity_pub\",
  \"inserted_at\": \"2018-01-24T18:51:53.327128Z\",
  \"latest_stable_version\": \"0.1.0\",
  \"latest_version\": \"0.1.0\",
  \"meta\": {
    \"description\": null,
    \"licenses\": [
      \"MIT\"
    ],
    \"links\": {
      \"GitHub\": \"https://github.com/coryodaniel/activity_pub\",
      \"W3C\": \"https://www.w3.org/TR/activitypub/\"
    },
    \"maintainers\": [
      \"Cory O'Daniel\"
    ]
  },
  \"name\": \"activity_pub\",
  \"releases\": [
    {
      \"has_docs\": true,
      \"inserted_at\": \"2018-01-24T18:51:53.334078Z\",
      \"url\": \"https://hex.pm/api/packages/activity_pub/releases/0.1.0\",
      \"version\": \"0.1.0\"
    }
  ],
  \"repository\": \"hexpm\",
  \"retirements\": {},
  \"updated_at\": \"2018-01-24T18:51:58.585612Z\",
  \"url\": \"https://hex.pm/api/packages/activity_pub\"
}"

  let assert Ok(package) = json.decode(json_string, hexpm.decode_package)

  package
  |> should.equal(Package(
    name: "activity_pub",
    html_url: Some("https://hex.pm/packages/activity_pub"),
    docs_html_url: Some("https://hexdocs.pm/activity_pub/"),
    meta: PackageMeta(
      description: None,
      links: map.from_list([
        #("GitHub", "https://github.com/coryodaniel/activity_pub"),
        #("W3C", "https://www.w3.org/TR/activitypub/"),
      ]),
      licenses: ["MIT"],
    ),
    downloads: map.from_list([#("all", 2438), #("recent", 12)]),
    owners: None,
    releases: [
      PackageRelease(
        version: "0.1.0",
        url: "https://hex.pm/api/packages/activity_pub/releases/0.1.0",
        inserted_at: timestamp("2018-01-24T18:51:53.334078Z"),
      ),
    ],
    inserted_at: timestamp("2018-01-24T18:51:53.327128Z"),
    updated_at: timestamp("2018-01-24T18:51:58.585612Z"),
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
    publisher: Some(PackageOwner(
      username: "harryet",
      email: Some("h.bairstow22@gmail.com"),
      url: "https://hex.pm/api/users/harryet",
    )),
    retirement: Some(ReleaseRetirement(
      reason: Security,
      message: Some("Retired due to security concerns"),
    )),
    updated_at: timestamp("2022-07-07T19:14:07.870166Z"),
    inserted_at: timestamp("2022-07-07T19:14:04.497803Z"),
  ))
}

pub fn hex_release_decoder_with_empty_list_downloads_test() {
  // For some unknown reason, the downloads field can be an empty list instead
  // of an int.

  let json_string =
    "{
  \"checksum\": \"a895b55c4c3749eb32328f02b15bbd3acc205dd874fabd135d7be5d12eda59a8\",
  \"configs\": {
    \"erlang.mk\": \"dep_shimmer = hex 0.0.3\",
    \"mix.exs\": \"{:shimmer, \\\"~> 0.0.3\\\"}\",
    \"rebar.config\": \"{shimmer, \\\"0.0.3\\\"}\"
  },
  \"docs_html_url\": \"https://hexdocs.pm/shimmer/0.0.3/\",
  \"downloads\": [],
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
    \"url\": \"https://hex.pm/api/users/harryet\",
    \"username\": \"harryet\"
  },
  \"requirements\": {},
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
    downloads: 0,
    meta: ReleaseMeta(app: Some("shimmer"), build_tools: ["gleam"]),
    publisher: Some(PackageOwner(
      username: "harryet",
      email: None,
      url: "https://hex.pm/api/users/harryet",
    )),
    retirement: Some(ReleaseRetirement(
      reason: Security,
      message: Some("Retired due to security concerns"),
    )),
    updated_at: timestamp("2022-07-07T19:14:07.870166Z"),
    inserted_at: timestamp("2022-07-07T19:14:04.497803Z"),
  ))
}
