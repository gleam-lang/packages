import packages/router

pub fn remove_extra_spaces_test() {
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
}
