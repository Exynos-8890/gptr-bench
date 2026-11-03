source("biomedical/v0.5/tools/t01-capacity.R")
testthat::test_that("capacity selection retains real IDs, rare strata and deterministic quotas", {
  metadata = data.frame(Patient = c(rep("P1", 8), "P2", "P3"), Tissue = "Tumor",
    Treatment = "I", MajorCellType = c(rep("T", 9), NA),
    row.names = paste0("cell", seq_len(10)))
  result = t01_select(metadata, 6L)
  testthat::expect_length(result$selected, 6)
  testthat::expect_identical(result$selected, t01_select(metadata, 6L)$selected)
  testthat::expect_true(all(c(9L, 10L) %in% result$selected))
  testthat::expect_equal(sum(result$quotas$selected_cells), 6)
  testthat::expect_true(all(result$quotas$selected_cells <= result$quotas$source_cells))
  testthat::expect_identical(t01_select(metadata, 10L)$selected, seq_len(10))
  shuffled = metadata[rev(seq_len(10)), , drop = FALSE]
  chosen = rownames(metadata)[result$selected]
  testthat::expect_setequal(chosen, rownames(shuffled)[t01_select(shuffled, 6L)$selected])
})

testthat::test_that("large strata do not overflow integer quota products", {
  metadata = data.frame(Patient = c(rep("P1", 99998), "P2", "P3"),
    Tissue = "Tumor", Treatment = "I", MajorCellType = "T",
    row.names = paste0("cell", seq_len(100000)))
  result = t01_select(metadata, 50000L)
  testthat::expect_length(result$selected, 50000)
  testthat::expect_identical(result$quotas$selected_cells, c(49998L, 1L, 1L))
})
