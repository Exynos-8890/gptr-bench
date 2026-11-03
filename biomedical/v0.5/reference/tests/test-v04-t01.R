testthat::test_that("T01 performs patient-level scientific workflow and rejects corruption", {
  raw = v04_fixture_t01()
  result = v04_genetics_execute("T01", raw)
  withr::defer(unlink(result$output, recursive = TRUE))
  testthat::expect_true(result$checked$ok, info = paste(result$checked$failures, collapse = ";"))
  testthat::expect_equal(as.integer(table(vapply(result$task$steps, function(x) x$request, 1L))),
                         c(6L, 8L, 6L))
  table = utils::read.csv(file.path(result$output, "patient-composition.csv"))
  table$n_cells[1L] = table$n_cells[1L] + 1L
  utils::write.csv(table, file.path(result$output, "patient-composition.csv"), row.names = FALSE)
  testthat::expect_false(result$module$v04_check_t01(result$output, raw)$ok)
})

testthat::test_that("T01 full-tier preparation never silently uses the diagnostic subset", {
  scope = new.env(parent = globalenv())
  source(file.path(v04_genetics_bench, "prepare-v04-t01.R"), local = scope)
  withr::local_dir(normalizePath(file.path(v04_genetics_bench, "..", "..", "..")))
  testthat::expect_error(scope$prepare_v04_t01(tempdir(), tempfile(), available_gb = 8),
                         "Full tier not prepared")
})

testthat::test_that("T01 analysis is directly sourceable as an ordinary R script", {
  raw = v04_fixture_t01()
  output = withr::local_tempdir()
  withr::local_dir(output)
  state = new.env(parent = globalenv())
  state$raw = raw
  source(file.path(v04_genetics_bench, "tasks/v04/t01-analysis.R"), local = state)
  source(file.path(v04_genetics_bench, "tasks/v04/t01-check.R"), local = state)
  testthat::expect_true(state$v04_check_t01(output, raw)$ok)
})
