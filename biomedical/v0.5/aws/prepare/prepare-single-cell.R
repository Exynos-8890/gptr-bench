# Stream public Matrix Market counts; retain original cells, genes and integer values.
prepare_single_cell = function(input, output, cells = 100000L, chunk_entries = 1000000L) {
  stopifnot(requireNamespace("Matrix", quietly = TRUE),
            requireNamespace("openssl", quietly = TRUE),
            requireNamespace("jsonlite", quietly = TRUE))
  dir.create(output, recursive = TRUE, showWarnings = FALSE)
  paths = file.path(input, paste0("GSE236581_", c("counts.mtx", "barcodes.tsv",
                                                "features.tsv", "CRC-ICB_metadata.txt"), ".gz"))
  stopifnot(all(file.exists(paths)), cells >= 1L)
  barcodes = readLines(gzfile(paths[2L]), encoding = "UTF-8")
  features = utils::read.delim(gzfile(paths[3L]), header = FALSE, stringsAsFactors = FALSE,
                               col.names = c("gene_id", "gene_symbol", "feature_type"))
  metadata = utils::read.table(gzfile(paths[4L]), header = TRUE, stringsAsFactors = FALSE,
                               check.names = FALSE)
  if (anyDuplicated(barcodes) || !setequal(barcodes, rownames(metadata))) {
    stop("Source barcode and metadata identifiers do not match")
  }
  metadata = metadata[barcodes, , drop = FALSE]
  metadata$barcode = barcodes
  con = gzfile(paths[1L], "rt")
  on.exit(close(con), add = TRUE)
  stopifnot(identical(readLines(con, 1L), "%%MatrixMarket matrix coordinate integer general"))
  line = readLines(con, 1L)
  while (startsWith(line, "%")) line = readLines(con, 1L)
  dimensions = scan(text = line, what = integer(), quiet = TRUE)
  stopifnot(dimensions[1L] == nrow(features), dimensions[2L] == length(barcodes))
  selected = unique(as.integer(round(seq(1L, dimensions[2L], length.out = min(cells,
                                                                            dimensions[2L])))))
  lookup = integer(dimensions[2L])
  lookup[selected] = seq_along(selected)
  binaries = file.path(output, c("i.bin", "x.bin"))
  streams = lapply(binaries, file, open = "wb")
  on.exit({
    for (stream in streams) try(close(stream), silent = TRUE)
    unlink(binaries)
  }, add = TRUE)
  pointers = integer(length(selected))
  seen = 0
  previous_column = 0L
  previous_row = 0L
  repeat {
    values = scan(con, what = integer(), nmax = 3L * chunk_entries, quiet = TRUE)
    if (!length(values)) break
    stopifnot(length(values) %% 3L == 0L)
    i = values[seq.int(1L, length(values), 3L)]
    j = values[seq.int(2L, length(values), 3L)]
    x = values[seq.int(3L, length(values), 3L)]
    stopifnot(all(i >= 1L & i <= dimensions[1L]), all(j >= 1L & j <= dimensions[2L]),
              all(x > 0L), !is.unsorted(j), j[1L] >= previous_column)
    same = c(j[1L] == previous_column, diff(j) == 0L)
    delta = c(i[1L] - previous_row, diff(i))
    stopifnot(all(delta[same] > 0L))
    previous_column = tail(j, 1L)
    previous_row = tail(i, 1L)
    mapped = lookup[j]
    keep = mapped > 0L
    writeBin(i[keep] - 1L, streams[[1L]], endian = "little")
    writeBin(x[keep], streams[[2L]], endian = "little")
    pointers = pointers + tabulate(mapped[keep], nbins = length(selected))
    seen = seen + length(j)
    if (seen %% (100 * chunk_entries) == 0) message("Source entries scanned: ", seen)
  }
  stopifnot(seen == dimensions[3L])
  for (stream in streams) close(stream)
  size = sum(pointers)
  counts = methods::new("dgCMatrix", i = readBin(binaries[1L], "integer", n = size,
                                                endian = "little"),
                        p = c(0L, as.integer(cumsum(pointers))),
                        x = as.double(readBin(binaries[2L], "integer", n = size,
                                              endian = "little")),
                        Dim = c(dimensions[1L], length(selected)),
                        Dimnames = list(features$gene_id, barcodes[selected]))
  methods::validObject(counts)
  raw = list(counts = counts, metadata = metadata[selected, , drop = FALSE], features = features)
  saveRDS(raw, file.path(output, "input.rds"), compress = FALSE)
  writeLines(barcodes[selected], file.path(output, "barcodes.tsv"), useBytes = TRUE)
  sources = lapply(paths, function(path) {
    stream = file(path, "rb")
    on.exit(close(stream))
    list(file = basename(path), sha256 = unclass(as.character(openssl::sha256(stream))),
         bytes = unname(file.info(path)$size),
         retrieved_at = format(file.info(path)$mtime, "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"))
  })
  jsonlite::write_json(list(accession = "GSE236581", source_updated = "2024-07-29",
    source_url = "https://ftp.ncbi.nlm.nih.gov/geo/series/GSE236nnn/GSE236581/suppl/",
    source_cells = dimensions[2L], source_genes = dimensions[1L], source_nonzero = dimensions[3L],
    selected_cells = length(selected), selected_nonzero = size,
    selection = "unique(round(seq(1, source_cells, length.out = min(cells, source_cells))))",
    representation = "fully resident dgCMatrix; all genes; original nonzero counts",
    sources = sources, prepared_at = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")),
    file.path(output, "dataset.json"), auto_unbox = TRUE, pretty = TRUE)
  invisible(raw)
}

if (sys.nframe() == 0L) {
  args = commandArgs(TRUE)
  prepare_single_cell(args[[1L]], args[[2L]], as.integer(args[[3L]]))
}
