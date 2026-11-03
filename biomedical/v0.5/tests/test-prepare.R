source("biomedical/v0.5/tools/prepare-inputs.R")

testthat::test_that("T01 writes selected sparse counts after source hash verification", {
  root = withr::local_tempdir()
  input = file.path(root, "source")
  dir.create(input)
  write_gzip = function(lines, suffix) {
    con = gzfile(file.path(input, paste0("GSE236581_", suffix, ".gz")), "wt")
    on.exit(close(con))
    writeLines(lines, con)
  }
  counts = Matrix::Matrix(matrix(c(2L, 0L, 4L, 1L, 5L, 1L, 0L, 2L,
    3L, 3L, 1L, 0L, 0L, 5L, 2L, 1L, 1L, 3L, 1L, 2L, 4L, 1L, 1L, 1L), 4), sparse = TRUE)
  dimnames(counts) = list(paste0("gene", 1:4), paste0("cell", 1:6))
  metadata = data.frame(Patient = c("P1", "P1", "P1", "P2", "P2", "P2"),
    Tissue = c("Normal", "Tumor", "Tumor", "Normal", "Tumor", "Tumor"),
    Treatment = "I", MajorCellType = "T", nCount_RNA = Matrix::colSums(counts),
    nFeature_RNA = diff(counts@p), row.names = colnames(counts))
  con = gzfile(file.path(input, "GSE236581_CRC-ICB_metadata.txt.gz"), "wt")
  utils::write.table(metadata, con, quote = FALSE)
  close(con)
  write_gzip(colnames(counts), "barcodes.tsv")
  write_gzip(paste(rownames(counts), rownames(counts), "Gene Expression", sep = "\t"),
              "features.tsv")
  triples = Matrix::summary(counts)
  write_gzip(c("%%MatrixMarket matrix coordinate integer general", "% fixture",
    paste(nrow(counts), ncol(counts), nrow(triples)),
    paste(triples$i, triples$j, triples$x)), "counts.mtx")
  paths = list.files(input, full.names = TRUE)
  hashes = stats::setNames(lapply(paths, function(path) {
    stream = file(path, "rb")
    on.exit(close(stream))
    as.character(openssl::sha256(stream))
  }), basename(paths))
  testthat::expect_true(callr::r(function(input, output, repo, hashes) {
    setwd(repo)
    stopifnot(!"Matrix" %in% loadedNamespaces())
    source("biomedical/v0.5/tools/prepare-inputs.R")
    prepare_v05_t01(input, output, cells = 4L, chunk_entries = 2L, source_hashes = hashes)
    file.exists(file.path(output, "input.rds"))
  }, list(input, file.path(root, "cold-selected"), normalizePath("."), hashes),
  libpath = .libPaths()))
  output = file.path(root, "selected")
  prepare_v05_t01(input, output, cells = 4L, chunk_entries = 2L, source_hashes = hashes)
  raw = readRDS(file.path(output, "input.rds"))
  testthat::expect_equal(raw$counts, counts[, raw$metadata$barcode])
  testthat::expect_identical(colnames(raw$counts), raw$metadata$barcode)
  info = jsonlite::read_json(file.path(output, "dataset.json"))
  testthat::expect_false(info$synthetic)
  stream = file(file.path(output, "input.rds"), "rb")
  testthat::expect_identical(info$input_sha256, unclass(as.character(openssl::sha256(stream))))
  close(stream)
  testthat::expect_equal(info$selected_cells, 4)
  testthat::expect_equal(info$source_cells, 6)
  hashes[[1L]] = "incorrect"
  testthat::expect_error(prepare_v05_t01(input, output, cells = 4L, source_hashes = hashes), "SHA256")
})

testthat::test_that("T05 streaming retains invalid QC rows, source order and exact scope counts", {
  root = withr::local_tempdir()
  path = file.path(root, "gwas.txt.gz")
  con = gzfile(path, "wt")
  writeLines(c("SNP CHR POS Tested_Allele Other_Allele BETA SE P Ignored",
    "rs1 1 100 a c 0.1 0.05 0.4 foo",
    "rs2 2 200 g a 0.2 0 0.9 bar",
    "rs3 3 300 t g NA 0.1 NA baz",
    "rs4 4 -1 c c 0.3 0.1 0.001 x",
    ". 1 500 a t -0.1 0.2 0.8 y"), con)
  close(con)
  full = v05_read_gwas(path, chunk_rows = 2L)
  testthat::expect_equal(full$source_rows, 5)
  testthat::expect_identical(full$associations$id, c(paste0("rs", 1:4), "."))
  testthat::expect_identical(full$associations$effect_allele, c("A", "G", "T", "C", "A"))
  testthat::expect_equal(full$associations$se[2], 0)
  testthat::expect_true(is.na(full$associations$p[3]))
  testthat::expect_equal(full$associations$position[4], -1)
  subset = v05_read_gwas(path, chromosomes = c("1", "2", "3"), chunk_rows = 2L)
  testthat::expect_identical(subset$associations$id, c("rs1", "rs2", "rs3", "."))
  testthat::expect_equal(subset$excluded_by_scope, 1)
  testthat::expect_identical(names(full$associations),
    c("id", "chr", "position", "effect_allele", "other_allele", "beta", "se", "p"))
})
