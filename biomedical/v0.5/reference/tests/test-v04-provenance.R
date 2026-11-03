testthat::test_that("preparation hashes remain plain JSON strings", {
  for (helper in c("prepare-v04-mlclinical-utils.R", "prepare-v04-genetics-utils.R")) {
    e = new.env(parent = baseenv())
    source(file.path("..", helper), local = e)
    directory = withr::local_tempdir()
    source_file = file.path(directory, "fixture.txt")
    writeLines("offline preparation fixture", source_file)
    record = e$v04_source_record(source_file, "https://example.org/offline-fixture")
    testthat::expect_identical(class(record$sha256), "character")
    testthat::expect_match(record$sha256, "^[0-9a-f]{64}$")
    testthat::expect_silent(jsonlite::toJSON(record, auto_unbox = TRUE))
  }
})

testthat::test_that("METABRIC preparation records the source ER spelling correction", {
  repo = normalizePath(file.path("..", "..", "..", ".."))
  withr::local_dir(repo)
  e = new.env(parent = baseenv())
  source("dev/bench/biomedical/prepare-v04-t02.R", local = e)
  directory = withr::local_tempdir()
  source_dir = file.path(directory, "source")
  dir.create(source_dir)
  source_data = data.frame(PATIENT_ID = paste0("fixture", 1:2509), OS_MONTHS = 12,
    OS_STATUS = "0:LIVING", AGE_AT_DIAGNOSIS = 60,
    ER_IHC = c(rep("Positve", 1817), rep("Negative", 609), rep(NA, 83)),
    LYMPH_NODES_EXAMINED_POSITIVE = 0, CHEMOTHERAPY = "NO")
  utils::write.table(source_data, file.path(source_dir, "data_clinical_patient.txt"),
                    sep = "\t", row.names = FALSE, quote = FALSE)
  output = file.path(directory, "prepared")
  e$v04_prepare_t02(source_dir, output, offline = TRUE)
  raw = readRDS(file.path(output, "input.rds"))
  manifest = jsonlite::read_json(file.path(output, "dataset.json"))
  testthat::expect_equal(sum(raw$er == "Positive", na.rm = TRUE), 1817)
  testthat::expect_equal(sum(raw$er == "Negative", na.rm = TRUE), 609)
  testthat::expect_equal(sum(is.na(raw$er)), 83)
  testthat::expect_equal(manifest$scale$corrected_er_labels, 1817)
})
