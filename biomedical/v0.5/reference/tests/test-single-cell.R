single_cell_fixture = function() {
  genes = c("CD3D", "CD3E", "CD8A", "MS4A1", "LYZ", "NKG7", "EPCAM", "COL1A1",
             paste0("gene", seq_len(1000)))
  lengths = c(1008L, 700L, 400L, 1008L, 600L, 1008L)
  counts = Matrix::sparseMatrix(i = sequence(lengths),
                                j = rep(seq_along(lengths), lengths),
                                x = rep(c(3, 3, 3, 3, 3, 1), lengths),
                                dims = c(length(genes), 6L))
  colnames(counts) = paste0("cell", 1:6)
  rownames(counts) = paste0("id", seq_along(genes))
  list(counts = counts, metadata = data.frame(barcode = colnames(counts),
       Patient = rep(c("P1", "P2", "P3"), each = 2), Tissue = "Tumor", Treatment = "I"),
       features = data.frame(gene_id = rownames(counts), gene_symbol = genes))
}

testthat::test_that("single-cell outputs verify matrix-derived QC and threshold revision", {
  source(testthat::test_path("..", "tasks", "single-cell.R"), local = TRUE)
  source(testthat::test_path("..", "evaluate.R"), local = TRUE)
  raw = single_cell_fixture()
  workspace = withr::local_tempdir()
  withr::local_dir(workspace)
  home = new.env(parent = globalenv())
  home$raw = raw
  task = single_cell_task()
  testthat::expect_length(task$prompts, 3L)
  for (step in task$steps) eval(parse(text = step$code), envir = home)
  testthat::expect_true(check_artifacts(workspace, raw, task = task$id)$ok)
  baseline = utils::read.csv("baseline.csv")
  revised = utils::read.csv("revised.csv")
  testthat::expect_equal(baseline$n_cells[baseline$gene == "CD3D"], c(2, 1, 2))
  testthat::expect_equal(revised$n_cells[revised$gene == "CD3D"], c(1, 1, 0))
  testthat::expect_equal(revised$count[revised$gene == "CD3D"], c(3, 3, 0))
  testthat::expect_equal(revised$cpm[revised$gene == "CD3D"], c(3e6 / 3024, 3e6 / 3024, 0))
  utils::write.csv(baseline[rev(seq_len(nrow(baseline))), ], "baseline.csv", row.names = FALSE)
  testthat::expect_true(check_artifacts(workspace, raw, task = task$id)$ok)
  revised$count[1] = revised$count[1] + 1
  utils::write.csv(revised, "revised.csv", row.names = FALSE)
  testthat::expect_false(check_artifacts(workspace, raw, task = task$id)$ok)
  home$raw$counts@x = home$raw$counts@x * 1e6
  for (step in task$steps) eval(parse(text = step$code), envir = home)
  testthat::expect_true(check_artifacts(workspace, home$raw, task = task$id)$ok)
  qc = utils::read.csv("qc.csv")
  qc$total_umi = qc$total_umi + 1
  utils::write.csv(qc, "qc.csv", row.names = FALSE)
  testthat::expect_false(check_artifacts(workspace, home$raw, task = task$id)$ok)
})

testthat::test_that("source preparation keeps real identifiers and exact sparse counts", {
  source(testthat::test_path("..", "prepare-single-cell.R"), local = TRUE)
  raw = single_cell_fixture()
  root = withr::local_tempdir()
  input = file.path(root, "source")
  dir.create(input)
  write_gzip = function(lines, name) {
    con = gzfile(file.path(input, paste0("GSE236581_", name, ".gz")), "wt")
    on.exit(close(con))
    writeLines(lines, con)
  }
  triples = Matrix::summary(raw$counts)
  write_gzip(c("%%MatrixMarket matrix coordinate integer general", "% fixture",
               paste(nrow(raw$counts), ncol(raw$counts), nrow(triples)),
               paste(triples$i, triples$j, triples$x)), "counts.mtx")
  write_gzip(colnames(raw$counts), "barcodes.tsv")
  write_gzip(paste(raw$features$gene_id, raw$features$gene_symbol, "Gene Expression", sep = "\t"),
              "features.tsv")
  metadata = raw$metadata
  rownames(metadata) = metadata$barcode
  metadata$barcode = NULL
  con = gzfile(file.path(input, "GSE236581_CRC-ICB_metadata.txt.gz"), "wt")
  utils::write.table(metadata, con, quote = FALSE)
  close(con)
  standalone = system2(file.path(R.home("bin"), "Rscript"), c("--vanilla",
    shQuote(testthat::test_path("..", "prepare-single-cell.R")), shQuote(input),
    shQuote(file.path(root, "standalone")), "3"), stdout = TRUE, stderr = TRUE)
  testthat::expect_null(attr(standalone, "status"), info = paste(standalone, collapse = "\n"))
  output = file.path(root, "subset")
  prepare_single_cell(input, output, cells = 3L, chunk_entries = 100L)
  selected = readRDS(file.path(output, "input.rds"))
  testthat::expect_equal(selected$counts, raw$counts[, c(1, 4, 6)])
  testthat::expect_identical(selected$metadata$barcode, c("cell1", "cell4", "cell6"))
  manifest = jsonlite::read_json(file.path(output, "dataset.json"))
  testthat::expect_equal(manifest$source_cells, 6L)
  testthat::expect_equal(manifest$selected_cells, 3L)
  testthat::expect_length(manifest$sources, 4L)
  testthat::expect_true(all(vapply(manifest$sources, function(s) nchar(s$sha256) == 64, TRUE)))
  write_gzip(c("bad", colnames(raw$counts)[-1]), "barcodes.tsv")
  testthat::expect_error(prepare_single_cell(input, file.path(root, "invalid"), 3L),
                         "metadata|barcode")
})
