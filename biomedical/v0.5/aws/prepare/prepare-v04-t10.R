prepare_v04_t10 = function(source_dir, output_dir) {
  source("biomedical/prepare-v04-genetics-utils.R", local = TRUE)
  stem = "V1_Breast_Cancer_Block_A_Section_1"
  base = paste0("https://cf.10xgenomics.com/samples/spatial-exp/1.0.0/", stem, "/", stem)
  files = paste0(stem, c("_filtered_feature_bc_matrix.tar.gz", "_spatial.tar.gz"))
  urls = paste0(base, c("_filtered_feature_bc_matrix.tar.gz", "_spatial.tar.gz"))
  paths = mapply(v04_fetch, urls, file.path(source_dir, files), USE.NAMES = FALSE)
  unpacked = file.path(source_dir, "unpacked")
  dir.create(unpacked, recursive = TRUE, showWarnings = FALSE)
  for (p in paths) utils::untar(p, exdir = unpacked)
  locate = function(pattern) {
    found = list.files(unpacked, pattern = pattern, recursive = TRUE, full.names = TRUE)
    stopifnot(length(found) == 1L)
    found
  }
  counts = methods::as(Matrix::readMM(gzfile(locate("^matrix[.]mtx[.]gz$"))), "CsparseMatrix")
  barcodes = readLines(gzfile(locate("^barcodes[.]tsv[.]gz$")), encoding = "UTF-8")
  features = utils::read.delim(gzfile(locate("^features[.]tsv[.]gz$")), header = FALSE,
                              col.names = c("gene_id", "gene", "type"))
  position = utils::read.csv(locate("^tissue_positions_list[.]csv$"), header = FALSE,
                            col.names = c("barcode", "in_tissue", "array_row", "array_col",
                                          "pixel_row", "pixel_col"))
  position = position[match(barcodes, position$barcode), ]
  stopifnot(ncol(counts) == 3813L, all(position$in_tissue == 1L),
            !anyNA(position$barcode), nrow(counts) == nrow(features))
  dimnames(counts) = list(features$gene_id, barcodes)
  raw = list(counts = counts, features = features, positions = position)
  v04_save_input(raw, output_dir, stem,
                 Map(v04_source_record, paths, urls),
                 list(spots = ncol(counts), genes = nrow(counts), nonzero = length(counts@x),
                      release = "Space Ranger 1.0.0", license = "CC-BY-4.0"))
}

if (sys.nframe() == 0L) {
  args = commandArgs(TRUE)
  prepare_v04_t10(args[[1L]], args[[2L]])
}
