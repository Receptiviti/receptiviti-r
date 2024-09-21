test_that("invalid inputs are caught", {
  expect_error(receptiviti_norming(key = ""), "specify your key")
  expect_error(receptiviti_norming(key = "123", secret = ""), "specify your secret")
  expect_error(receptiviti_norming(
    name = "INVALID", key = "123", secret = "123"
  ), "`name` can only include")
})

skip_if(Sys.getenv("RECEPTIVITI_KEY") == "", "no API key")

test_that("listing works", {
  custom_norms <- receptiviti_norming()
  expect_true("test" %in% custom_norms$name)
})

test_that("retrieving a status works", {
  expect_identical(receptiviti_norming("test")$name, "test")
})

test_that("updating works", {
  initial_status <- receptiviti_norming("short_text7", options = list(word_count_filter = 1))
  if (initial_status$status != "completed") {
    updated <- receptiviti_norming("short_text7", "new text to add")
  }
  final_status <- receptiviti_norming("short_text7")
  expect_true(final_status$status == "completed")
  base_request <- receptiviti("a new text to add", version = "v2")
  self_normed_request <- receptiviti(
    "a new text to add",
    version = "v2", api_args = list(custom_context = "short_text7")
  )
  expect_false(identical(base_request, self_normed_request))
})
