# Full-cohort preparation deliberately refuses to substitute the diagnostic subset.
prepare_v04_t01 = function(source_dir, output_dir, available_gb = NULL) {
  source("biomedical/prepare-single-cell.R", local = TRUE)
  if (is.null(available_gb)) {
    available = processx::run("python3", c("-c", paste(
      "import psutil; print(psutil.virtual_memory().available / 1e9)")),
      error_on_status = TRUE)$stdout
    available_gb = as.numeric(trimws(available))
  }
  if (!is.finite(available_gb) || available_gb < 40.057) {
    stop(sprintf(paste("T01 full cohort requires at least 40.057 GB available RAM;",
                       "only %.3f GB available. Full tier not prepared."), available_gb))
  }
  source("biomedical/prepare-v04-genetics-utils.R", local = TRUE)
  files = c("GSE236581_counts.mtx.gz", "GSE236581_barcodes.tsv.gz",
            "GSE236581_features.tsv.gz", "GSE236581_CRC-ICB_metadata.txt.gz")
  base = "https://ftp.ncbi.nlm.nih.gov/geo/series/GSE236nnn/GSE236581/suppl/"
  for (name in files) v04_fetch(paste0(base, name), file.path(source_dir, name))
  prepare_single_cell(source_dir, output_dir, cells = 975275L)
  info_path = file.path(output_dir, "dataset.json")
  info = jsonlite::read_json(info_path)
  stopifnot(info$selected_cells == 975275L, info$source_genes == 36027L)
  info$benchmark_version = "0.4.0"
  info$tier = "full-cohort-formal"
  info$fully_resident = TRUE
  info$synthetic = FALSE
  jsonlite::write_json(info, info_path, auto_unbox = TRUE, pretty = TRUE)
}

if (sys.nframe() == 0L) {
  args = commandArgs(TRUE)
  prepare_v04_t01(args[[1L]], args[[2L]])
}
