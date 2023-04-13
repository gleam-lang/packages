import gleam/json
import packages/models/hex/release.{HexRelease, HexReleaseMeta}
import gleeunit/should
import gleam/option.{Some}

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
  \"retirement\": null,
  \"updated_at\": \"2022-07-07T19:14:07.870166Z\",
  \"url\": \"https://hex.pm/api/packages/shimmer/releases/0.0.3\",
  \"version\": \"0.0.3\"
}"

  assert Ok(release) = json.decode(json_string, release.hex_release_decoder())

  release
  |> should.equal(HexRelease(
    version: "0.0.3",
    url: "https://hex.pm/api/packages/shimmer/releases/0.0.3",
    meta: HexReleaseMeta(app: Some("shimmer"), build_tools: ["gleam"]),
  ))
}
