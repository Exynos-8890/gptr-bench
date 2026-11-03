# Shared preparation helpers for the clinical and two ML tasks; never used in timed analysis.
v04_source_file = function(source_dir, filename, url, offline = FALSE) {
  dir.create(source_dir, recursive = TRUE, showWarnings = FALSE)
  target = file.path(source_dir, filename)
  if (!file.exists(target)) {
    if (offline) stop("Missing source file in offline mode: ", target)
    partial = paste0(target, ".partial")
    on.exit(unlink(partial), add = TRUE)
    curl::curl_download(url, partial, quiet = FALSE)
    if (!file.rename(partial, target)) stop("Could not finalize downloaded source")
  }
  target
}

v04_source_record = function(path, url) {
  con = file(path, "rb")
  on.exit(close(con), add = TRUE)
  list(filename = basename(path), url = url, bytes = unname(file.info(path)$size),
       sha256 = unclass(as.character(openssl::sha256(con))))
}

v04_save_prepared = function(raw, output_dir, task, study, sources, scale, notice) {
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  path = file.path(output_dir, "input.rds")
  if (file.exists(path)) stop("Refusing to overwrite prepared input: ", path)
  partial = paste0(path, ".partial")
  on.exit(unlink(partial), add = TRUE)
  saveRDS(raw, partial, compress = FALSE, version = 3)
  if (!file.rename(partial, path)) stop("Could not finalize prepared input")
  con = file(path, "rb")
  checksum = unclass(as.character(openssl::sha256(con)))
  close(con)
  manifest = list(schema_version = 1L, task = task, study = study,
    prepared_at_utc = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
    status = "prepared_real_public", synthetic = FALSE, fully_resident = TRUE, sources = sources, scale = scale,
    input_bytes = unname(file.info(path)$size), input_sha256 = checksum,
    rds_compressed = FALSE, selection = "All source observations; no simulated/duplicated data",
    analysis_preprocessing = "QC, splits, features, transforms and fitting remain timed",
    notice = notice)
  jsonlite::write_json(manifest, file.path(output_dir, "dataset.json"),
    auto_unbox = TRUE, pretty = TRUE, null = "null", digits = 16)
  invisible(manifest)
}
