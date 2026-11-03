# Version-specific real input preparation. No changes to frozen v0.4 source or data.
prepare_v05_t01 = function(source_dir, output_dir, cells = 150000L,
                           chunk_entries = 1000000L,
                           source_hashes = jsonlite::read_json(
                             "biomedical/v0.5/aws/source-hashes.json")$T01) {
  loadNamespace("Matrix")
  source("biomedical/v0.5/tools/t01-capacity.R", local = TRUE)
  source("biomedical/prepare-v04-genetics-utils.R", local = TRUE)
  paths = file.path(source_dir, paste0("GSE236581_", c("counts.mtx", "barcodes.tsv",
    "features.tsv", "CRC-ICB_metadata.txt"), ".gz"))
  urls = paste0("https://ftp.ncbi.nlm.nih.gov/geo/series/GSE236nnn/GSE236581/suppl/",
                basename(paths))
  sources = Map(v04_source_record, paths, urls)
  for (record in sources) {
    if (record$sha256 != source_hashes[[record$file]]) stop("Source SHA256 differs: ", record$file)
  }
  metadata = utils::read.table(gzfile(paths[4L]), header = TRUE,
                              stringsAsFactors = FALSE, check.names = FALSE)
  barcodes = readLines(gzfile(paths[2L]))
  metadata = metadata[barcodes, , drop = FALSE]
  selection = t01_select(metadata, cells)
  selected = selection$selected
  subset = metadata[selected, , drop = FALSE]
  subset$barcode = barcodes[selected]
  expected_nnz = sum(subset$nFeature_RNA)
  features = utils::read.delim(gzfile(paths[3L]), header = FALSE,
    stringsAsFactors = FALSE, col.names = c("gene_id", "gene_symbol", "feature_type"))
  stream = gzfile(paths[1L], "rt")
  on.exit(close(stream), add = TRUE)
  readLines(stream, 1L) # Matrix Market header
  line = readLines(stream, 1L)
  while (startsWith(line, "%")) line = readLines(stream, 1L)
  dimensions = scan(text = line, what = integer(), quiet = TRUE)
  lookup = integer(dimensions[2L])
  lookup[selected] = seq_along(selected)
  # Allocate the selected arrays once; never allocate the full source matrix.
  indices = integer(expected_nnz)
  values = numeric(expected_nnz)
  pointers = integer(length(selected))
  scanned = 0
  offset = 0
  repeat {
    triples = scan(stream, what = integer(), nmax = 3L * chunk_entries, quiet = TRUE)
    if (!length(triples)) break
    i = triples[seq.int(1L, length(triples), 3L)]
    j = triples[seq.int(2L, length(triples), 3L)]
    x = triples[seq.int(3L, length(triples), 3L)]
    mapped = lookup[j]
    keep = mapped > 0L
    n = sum(keep)
    if (n) {
      at = offset + seq_len(n)
      indices[at] = i[keep] - 1L
      values[at] = x[keep]
      pointers = pointers + tabulate(mapped[keep], nbins = length(selected))
      offset = offset + n
    }
    scanned = scanned + length(j)
    if (scanned %% (100 * chunk_entries) == 0) message("Source entries scanned: ", scanned)
  }
  counts = methods::new("dgCMatrix", i = indices, p = c(0L, as.integer(cumsum(pointers))),
    x = values, Dim = c(dimensions[1L], length(selected)),
    Dimnames = list(features$gene_id, barcodes[selected]))
  raw = list(counts = counts, metadata = subset, features = features)
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  writeLines(barcodes[selected], file.path(output_dir, "barcodes.tsv"))
  utils::write.csv(selection$quotas, file.path(output_dir, "strata.csv"), row.names = FALSE)
  v04_save_input(raw, output_dir, "GSE236581 real stratified cells",
    sources, list(task = "T01", profile = paste0("cells-", cells),
      source_cells = dimensions[2L], source_genes = dimensions[1L],
      source_nonzero = dimensions[3L], selected_cells = length(selected),
      selected_nonzero = offset, selection_seed = 20261031L,
      selection = paste("Patient/Tissue/Treatment/MajorCellType strata; one per stratum,",
        "largest-remainder quota on remaining capacity; SHA256(seed|barcode) rank; source order")))
  invisible(raw)
}

v05_read_gwas = function(path, chromosomes = NULL, chunk_rows = 100000L) {
  stream = gzfile(path, "rt")
  on.exit(close(stream))
  header = strsplit(trimws(readLines(stream, 1L)), "[[:space:]]+")[[1L]]
  required = c("SNP", "CHR", "POS", "Tested_Allele", "Other_Allele", "BETA", "SE", "P")
  specification = lapply(header, function(name) if (name %in% required) "" else NULL)
  chunks = list()
  source_rows = 0
  selected_rows = 0
  repeat {
    fields = scan(stream, what = specification, nlines = chunk_rows, quiet = TRUE,
                  comment.char = "", quote = "", na.strings = "NA")
    names(fields) = header
    fields = fields[required]
    n = length(fields[[1L]])
    if (!n) break
    source_rows = source_rows + n
    keep = if (is.null(chromosomes)) rep(TRUE, n) else fields$CHR %in% chromosomes
    if (any(keep)) {
      fields = lapply(fields, `[`, keep)
      chunks[[length(chunks) + 1L]] = data.frame(id = fields$SNP, chr = fields$CHR,
        position = suppressWarnings(as.numeric(fields$POS)),
        effect_allele = toupper(fields$Tested_Allele), other_allele = toupper(fields$Other_Allele),
        beta = suppressWarnings(as.numeric(fields$BETA)),
        se = suppressWarnings(as.numeric(fields$SE)), p = suppressWarnings(as.numeric(fields$P)),
        stringsAsFactors = FALSE)
      selected_rows = selected_rows + sum(keep)
    }
    if (source_rows %% (10 * chunk_rows) == 0) message("GWAS source rows scanned: ", source_rows)
  }
  list(associations = do.call(rbind, chunks), source_rows = source_rows,
       excluded_by_scope = source_rows - selected_rows)
}

prepare_v05_t05 = function(source_dir, output_dir, chromosomes = NULL) {
  source("biomedical/prepare-v04-genetics-utils.R", local = TRUE)
  base = paste0("https://ftp.ebi.ac.uk/pub/databases/gwas/summary_statistics/",
                "GCST006001-GCST007000/GCST006900/")
  filename = "Meta-analysis_Locke_et_al+UKBiobank_2018_UPDATED.txt.gz"
  urls = c(paste0(base, filename),
    paste0(base, "README_summary_statistics_Yengo_et_al_2018.txt"),
    paste0("https://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_19/",
           "gencode.v19.annotation.gtf.gz"),
    "https://maayanlab.cloud/Enrichr/geneSetLibrary?mode=text&libraryName=Reactome_2022")
  names = c(filename, "README_summary_statistics_Yengo_et_al_2018.txt",
            "gencode.v19.annotation.gtf.gz", "Reactome_2022.gmt")
  paths = mapply(v04_fetch, urls, file.path(source_dir, names), USE.NAMES = FALSE)
  read = v05_read_gwas(paths[1L], chromosomes)
  genes = v04_gtf_genes(paths[3L])
  genes$tss = ifelse(genes$strand == "-", genes$end, genes$start)
  fields = strsplit(readLines(paths[4L], encoding = "UTF-8"), "\t", fixed = TRUE)
  pathways = stats::setNames(lapply(fields, function(x) unique(x[-c(1L, 2L)])),
                              vapply(fields, `[`, "", 1L))
  raw = list(associations = read$associations, genes = genes, pathways = pathways,
             genome_build = "GRCh37", accession = "GCST006900")
  v04_save_input(raw, output_dir, "GCST006900 BMI Yengo2018",
    Map(v04_source_record, paths, urls), list(task = "T05",
      profile = if (is.null(chromosomes)) "full-source" else paste0("chr", paste(chromosomes,
        collapse = "-")), source_rows = read$source_rows, variants = nrow(read$associations),
      excluded_by_scope = read$excluded_by_scope, prepare_time_scientific_qc = FALSE,
      all_source_rows_retained = is.null(chromosomes), genome_build = "GRCh37"))
}

if (sys.nframe() == 0L) {
  args = commandArgs(TRUE)
  if (args[[1L]] == "T01") {
    prepare_v05_t01(args[[2L]], args[[3L]], as.integer(args[[4L]]))
  } else if (args[[1L]] == "T05") {
    chromosomes = if (length(args) < 4L || args[[4L]] == "full") NULL else
      strsplit(args[[4L]], ",", fixed = TRUE)[[1L]]
    prepare_v05_t05(args[[2L]], args[[3L]], chromosomes)
  } else stop("Only version-specific T01 and T05 preparation is supported")
}
