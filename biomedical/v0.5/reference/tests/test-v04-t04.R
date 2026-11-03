testthat::test_that("T04 tests within-population HWE, LD, PCA and Fst robustly", {
  raw = v04_fixture_t04()
  result = v04_genetics_execute("T04", raw)
  withr::defer(unlink(result$output, recursive = TRUE))
  testthat::expect_true(result$checked$ok, info = paste(result$checked$failures, collapse = ";"))
  testthat::expect_equal(length(result$task$steps), 22L)
  table = utils::read.csv(file.path(result$output, "pca.csv"))
  table$PC2 = table$PC1
  utils::write.csv(table, file.path(result$output, "pca.csv"), row.names = FALSE)
  testthat::expect_false(result$module$v04_check_t04(result$output, raw)$ok)
})
