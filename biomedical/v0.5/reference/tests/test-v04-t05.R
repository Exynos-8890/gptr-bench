testthat::test_that("T05 audits GWAS and distinguishes association from causal mapping", {
  raw = v04_fixture_t05()
  result = v04_genetics_execute("T05", raw)
  withr::defer(unlink(result$output, recursive = TRUE))
  testthat::expect_true(result$checked$ok, info = paste(result$checked$failures, collapse = ";"))
  testthat::expect_equal(length(result$task$steps), 20L)
  regions = utils::read.csv(file.path(result$output, "lead-regions.csv"))
  testthat::expect_equal(nrow(regions), 3L)
  regions$lead_p[1L] = .5
  utils::write.csv(regions, file.path(result$output, "lead-regions.csv"), row.names = FALSE)
  testthat::expect_false(result$module$v04_check_t05(result$output, raw)$ok)
})

testthat::test_that("T05 reports a legitimate null GWAS without inventing candidate genes", {
  raw = v04_fixture_t05()
  raw$associations$p = pmax(.01, raw$associations$p)
  result = v04_genetics_execute("T05", raw)
  withr::defer(unlink(result$output, recursive = TRUE))
  testthat::expect_true(result$checked$ok, info = paste(result$checked$failures, collapse = ";"))
  testthat::expect_equal(nrow(utils::read.csv(file.path(result$output, "lead-regions.csv"))), 0L)
})

testthat::test_that("GENCODE preparation preserves actual gene attributes and coordinates", {
  scope = new.env(parent = globalenv())
  source(file.path(v04_genetics_bench, "prepare-v04-genetics-utils.R"), local = scope)
  path = tempfile(fileext = ".gtf.gz")
  withr::defer(unlink(path))
  con = gzfile(path, "wt")
  writeLines(paste("chr1", "ENSEMBL", "gene", "10", "25", ".", "-", ".",
    'gene_id "ENSG1"; gene_name "TP53"; gene_type "protein_coding";', sep = "\t"), con)
  close(con)
  genes = scope$v04_gtf_genes(path)
  testthat::expect_identical(genes$gene, "TP53")
  testthat::expect_identical(genes$biotype, "protein_coding")
  testthat::expect_equal(genes$start, 10)
})
