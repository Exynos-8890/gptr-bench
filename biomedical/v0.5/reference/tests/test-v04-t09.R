testthat::test_that("T09 preserves heldout labels and validates prediction metrics", {
  source(file.path("..", "tasks", "v04", "t09.R"), local = TRUE)
  withr::local_seed(101)
  x = matrix(stats::rlnorm(120 * 8), 120, 8)
  y = rep(0:1, each = 60)
  x[, 1] = x[, 1] + 2 * y
  x[seq(1, 120, 13), 3] = NA_real_
  colnames(x) = paste0("met", 1:8)
  raw = list(x = x, y = y, sample_id = paste0("sample", 1:120),
             metabolites = colnames(x))
  workspace = tempfile("t09-test-")
  dir.create(workspace)
  withr::local_dir(workspace)
  e = new.env(parent = baseenv())
  e$raw = raw
  task = v04_t09()
  testthat::expect_equal(length(task$steps), 24L)
  for (step in task$steps) eval(parse(text = step$code), e)
  checked = v04_check_t09(workspace, raw)
  testthat::expect_true(checked$ok, info = paste(checked$failures, collapse = "; "))
  m = utils::read.csv("heldout-metrics.csv")
  m$auc[[1L]] = 0
  utils::write.csv(m, "heldout-metrics.csv", row.names = FALSE)
  testthat::expect_false(v04_check_t09(workspace, raw)$ok)
})
