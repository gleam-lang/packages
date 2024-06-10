import gleam/int
import gleam/list
import gleam/string
import packages/router

pub fn remove_extra_spaces_test() {
  let assert "" = router.remove_extra_spaces("")

  let assert "gleam" = router.remove_extra_spaces("gleam")

  let assert "gleam packages" = router.remove_extra_spaces("gleam packages")

  let assert "gleam packages" =
    router.remove_extra_spaces("        gleam packages")

  let assert "gleam packages" =
    router.remove_extra_spaces("gleam packages           ")

  let assert "gleam packages" =
    router.remove_extra_spaces("           gleam packages       ")

  let assert "gleam packages" =
    router.remove_extra_spaces("gleam        packages")

  let assert "gleam packages" =
    router.remove_extra_spaces("    gleam        packages      ")

  let assert "there should be no extra spaces" =
    router.remove_extra_spaces(
      "              there    should     be    no  extra    spaces      ",
    )

  let assert "there should be no extra spaces" =
    router.remove_extra_spaces(
      ["there", "should", "be", "no", "extra", "spaces"]
      |> list.map(fn(s) { string.pad_left(s, int.max(1, int.random(10)), " ") })
      |> string.join(" "),
    )
}
