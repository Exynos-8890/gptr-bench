testthat::test_that("T02 performs and independently validates a complete survival workflow", {
  source(file.path("..", "tasks", "v04", "t02.R"), local = TRUE)
  withr::local_seed(100)
  d = survival::lung
  raw = data.frame(id = paste0("p", seq_len(nrow(d))), time = d$time / 30.4375,
                   event = d$status - 1L, age = d$age,
                   er = ifelse(d$sex == 1, "Negative", "Positive"),
                   nodes = d$ph.ecog, chemo = ifelse(d$sex == 1, "YES", "NO"))
  raw$chemo = rep(c("YES", "NO"), length.out = nrow(raw))
  workspace = tempfile("t02-test-")
  dir.create(workspace)
  withr::local_dir(workspace)
  e = new.env(parent = baseenv())
  e$raw = raw
  task = v04_t02()
  testthat::expect_equal(length(task$steps), 18L)
  for (step in task$steps) eval(parse(text = step$code), e)
  checked = v04_check_t02(workspace, raw)
  testthat::expect_true(checked$ok, info = paste(checked$failures, collapse = "; "))
  risk = utils::read.csv("risk-table.csv")
  risk$stratum = paste0("er=", risk$stratum)
  utils::write.csv(risk[10:1, ], "risk-table.csv", row.names = FALSE)
  testthat::expect_true(v04_check_t02(workspace, raw)$ok)
  bytes_before = length(serialize(e$state, NULL))
  e$unrelated_payload = numeric(1000000)
  testthat::expect_equal(length(serialize(e$state, NULL)), bytes_before)
  testthat::expect_identical(attr(e$state$full$terms, ".Environment"), baseenv())
  coef = utils::read.csv("cox-models.csv")
  coef$estimate[[1L]] = coef$estimate[[1L]] + 1
  utils::write.csv(coef, "cox-models.csv", row.names = FALSE)
  testthat::expect_false(v04_check_t02(workspace, raw)$ok)
})

testthat::test_that("clinical and ML preparers fail offline without source files", {
  repo = normalizePath(file.path("..", "..", "..", ".."))
  withr::local_dir(repo)
  for (id in c("02", "07", "09")) {
    e = new.env(parent = baseenv())
    source(file.path("dev", "bench", "biomedical", paste0("prepare-v04-t", id, ".R")),
      local = e)
    prepare = get(paste0("v04_prepare_t", id), e)
    src = tempfile(paste0("t", id, "-sources-"))
    out = tempfile(paste0("t", id, "-prepared-"))
    testthat::expect_error(prepare(src, out, offline = TRUE), "Missing source file")
    testthat::expect_false(file.exists(file.path(out, "input.rds")))
  }
})
