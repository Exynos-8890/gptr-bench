prepare_v04_t04 = function(source_dir, output_dir) {
  source("biomedical/prepare-v04-genetics-utils.R", local = TRUE)
  base = "https://ftp.1000genomes.ebi.ac.uk/vol1/ftp/release/20130502/"
  name = "ALL.chr22.phase3_shapeit2_mvncall_integrated_v5b.20130502.genotypes.vcf.gz"
  panel_name = "integrated_call_samples_v3.20130502.ALL.panel"
  paths = mapply(v04_fetch, paste0(base, c(name, panel_name)),
                  file.path(source_dir, c(name, panel_name)), USE.NAMES = FALSE)
  panel = utils::read.delim(paths[2L], stringsAsFactors = FALSE)
  con = gzfile(paths[1L], "rt")
  on.exit(close(con))
  genotypes = list()
  variants = list()
  bins = integer()
  samples = NULL
  scanned = 0L
  repeat {
    lines = readLines(con, 1000L, encoding = "UTF-8")
    if (!length(lines)) break
    for (line in lines) {
      if (startsWith(line, "##")) next
      f = strsplit(line, "\t", fixed = TRUE)[[1L]]
      if (startsWith(line, "#CHROM")) {
        samples = f[-seq_len(9L)]
        next
      }
      scanned = scanned + 1L
      if (length(f) != length(samples) + 9L || nchar(f[4L]) != 1L ||
          nchar(f[5L]) != 1L || !f[7L] %in% c("PASS", ".")) next
      bin = as.integer(as.numeric(f[2L]) %/% 4000)
      if (bin %in% bins) next
      bins = c(bins, bin)
      gt = sub(":.*", "", f[-seq_len(9L)])
      dosage = rep(NA_integer_, length(gt))
      dosage[gt %in% c("0|0", "0/0")] = 0L
      dosage[gt %in% c("1|0", "0|1", "1/0", "0/1")] = 1L
      dosage[gt %in% c("1|1", "1/1")] = 2L
      genotypes[[length(genotypes) + 1L]] = dosage
      variants[[length(variants) + 1L]] = data.frame(chr = "22", position = as.numeric(f[2L]),
        id = f[3L], ref = f[4L], alt = f[5L])
    }
  }
  stopifnot(length(samples) == 2504L, length(genotypes) >= 5000L,
            length(genotypes) <= 10000L, !anyDuplicated(samples))
  matrix = do.call(cbind, genotypes)
  variant_table = do.call(rbind, variants)
  dimnames(matrix) = list(samples, variant_table$id)
  panel = panel[match(samples, panel$sample), c("sample", "pop", "super_pop", "gender")]
  stopifnot(!anyNA(panel$sample))
  raw = list(genotypes = matrix, variants = variant_table, samples = panel)
  v04_save_input(raw, output_dir, "1000G Phase3 chr22 GRCh37",
                 Map(v04_source_record, paths, paste0(base, c(name, panel_name))),
                 list(individuals = nrow(matrix), variants = ncol(matrix),
                      selection = "First eligible PASS biallelic SNP per 4000bp bin; full chr22 scanned",
                      scanned_variants = scanned, genome_build = "GRCh37"))
}

if (sys.nframe() == 0L) {
  args = commandArgs(TRUE)
  prepare_v04_t04(args[[1L]], args[[2L]])
}
