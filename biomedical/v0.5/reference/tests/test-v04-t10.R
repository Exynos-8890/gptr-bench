testthat::test_that("T10 estimates spatial structure and validates permutation probabilities", {
  raw = v04_fixture_t10()
  result = v04_genetics_execute("T10", raw)
  withr::defer(unlink(result$output, recursive = TRUE))
  testthat::expect_true(result$checked$ok, info = paste(result$checked$failures, collapse = ";"))
  testthat::expect_equal(length(result$task$steps), 24L)
  genes = utils::read.csv(file.path(result$output, "spatial-genes.csv"))
  permutation = utils::read.csv(file.path(result$output, "permutation.csv"))
  forged = genes
  forged$p_value = 1
  forged$fdr = 1
  permutation$exceed = 199L
  utils::write.csv(forged, file.path(result$output, "spatial-genes.csv"), row.names = FALSE)
  utils::write.csv(permutation, file.path(result$output, "permutation.csv"), row.names = FALSE)
  testthat::expect_false(result$module$v04_check_t10(result$output, raw)$ok)
  utils::write.csv(genes, file.path(result$output, "spatial-genes.csv"), row.names = FALSE)
  unlink(file.path(result$output, "qc-sensitivity.csv"))
  testthat::expect_false(result$module$v04_check_t10(result$output, raw)$ok)
  genes = utils::read.csv(file.path(result$output, "spatial-genes.csv"))
  genes$p_value[1L] = 0
  utils::write.csv(genes, file.path(result$output, "spatial-genes.csv"), row.names = FALSE)
  testthat::expect_false(result$module$v04_check_t10(result$output, raw)$ok)
})
