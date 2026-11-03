testthat::test_that("T07 evaluates unseen variants and obeys sequence design constraints", {
  source(file.path("..", "tasks", "v04", "t07.R"), local = TRUE)
  withr::local_seed(102)
  aa = strsplit("ACDEFGHIKLMNPQRSTVWY", "")[[1]]
  codes = sample.int(20^4, 600) - 1L
  positions = vapply(0:3, function(k) aa[(codes %/% (20^k)) %% 20 + 1L], character(600))
  sequences = apply(positions, 1, paste0, collapse = "")
  wild = strsplit("VDGV", "")[[1]]
  mutants = vapply(seq_len(nrow(positions)), function(i) {
    j = which(positions[i, ] != wild)
    if (!length(j)) "WT" else paste0(wild[j], j, positions[i, j], collapse = ":")
  }, "")
  variants = data.frame(mutant = mutants, mutated_sequence = sequences,
    DMS_score = (positions[, 1] == "A") + .8 * (positions[, 2] == "G") +
      (positions[, 1] == positions[, 3]) + stats::rnorm(600, sd = .1))
  raw = list(variants = variants, wild_type = "VDGV", sites = 1:4)
  workspace = tempfile("t07-test-")
  dir.create(workspace)
  withr::local_dir(workspace)
  e = new.env(parent = baseenv())
  e$raw = raw
  task = v04_t07()
  testthat::expect_equal(length(task$steps), 24L)
  for (step in task$steps) eval(parse(text = step$code), e)
  checked = v04_check_t07(workspace, raw)
  testthat::expect_true(checked$ok, info = paste(checked$failures, collapse = "; "))
  p = utils::read.csv("heldout-predictions.csv")
  p$observed[[1L]] = p$observed[[1L]] + 1
  utils::write.csv(p, "heldout-predictions.csv", row.names = FALSE)
  testthat::expect_false(v04_check_t07(workspace, raw)$ok)
})
