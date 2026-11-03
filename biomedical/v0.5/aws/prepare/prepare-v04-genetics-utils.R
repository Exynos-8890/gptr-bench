v04_fetch = function(url, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  if (!file.exists(path)) {
    temporary = paste0(path, ".part")
    on.exit(unlink(temporary), add = TRUE)
    curl::curl_download(url, temporary, quiet = FALSE)
    stopifnot(file.info(temporary)$size > 0, file.rename(temporary, path))
  }
  normalizePath(path)
}

v04_source_record = function(path, url) {
  con = file(path, "rb")
  on.exit(close(con))
  list(file = basename(path), url = url, bytes = unname(file.info(path)$size),
       sha256 = unclass(as.character(openssl::sha256(con))))
}

v04_save_input = function(raw, output, accession, sources, extra = list()) {
  dir.create(output, recursive = TRUE, showWarnings = FALSE)
  path = file.path(output, "input.rds")
  saveRDS(raw, path, compress = FALSE)
  stream = file(path, "rb")
  on.exit(close(stream))
  checksum = unclass(as.character(openssl::sha256(stream)))
  info = c(list(input_sha256 = checksum, task_data_version = "0.4.0", accession = accession,
                prepared_at_utc = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
                synthetic = FALSE, rds_bytes = unname(file.info(path)$size),
                fully_resident = TRUE, sources = sources), extra)
  jsonlite::write_json(info, file.path(output, "dataset.json"), auto_unbox = TRUE,
                       pretty = TRUE, digits = 16, null = "null")
  invisible(path)
}

v04_gtf_genes = function(path) {
  con = gzfile(path, "rt")
  on.exit(close(con))
  genes = list()
  repeat {
    lines = readLines(con, 20000L, encoding = "UTF-8")
    if (!length(lines)) break
    lines = lines[!startsWith(lines, "#")]
    fields = strsplit(lines, "\t", fixed = TRUE)
    fields = Filter(function(x) length(x) == 9L && x[3L] == "gene", fields)
    if (!length(fields)) next
    m = do.call(rbind, fields)
    attribute = function(key) {
      pattern = paste0('.*', key, ' "([^";]+)".*')
      found = grepl(paste0(key, ' "'), m[, 9L], fixed = TRUE)
      result = rep(NA_character_, nrow(m))
      result[found] = sub(pattern, "\\1", m[found, 9L])
      result
    }
    genes[[length(genes) + 1L]] = data.frame(
      chr = sub("^chr", "", m[, 1L]), start = as.numeric(m[, 4L]),
      end = as.numeric(m[, 5L]), strand = m[, 7L], gene_id = attribute("gene_id"),
      gene = attribute("gene_name"), biotype = attribute("gene_type"))
  }
  do.call(rbind, genes)
}
