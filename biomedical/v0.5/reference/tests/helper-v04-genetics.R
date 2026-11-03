v04_genetics_bench = normalizePath(file.path(".."))

v04_genetics_execute = function(id, raw) {
  module = new.env(parent = globalenv())
  source(file.path(v04_genetics_bench, "tasks", "v04", "registry.R"), local = module)
  task = module$v04_load(id, v04_genetics_bench, envir = module)
  if (!is.null(task$script)) {
    source(file.path(v04_genetics_bench, "tasks", "v04", paste0(tolower(id), "-check.R")), local = module)
  }
  output = tempfile(paste0(id, "-fixture-"))
  dir.create(output)
  withr::local_dir(output)
  state = new.env(parent = globalenv())
  state$raw = raw
  for (step in task$steps) eval(parse(text = step$code), state)
  checked = get(paste0("v04_check_", tolower(id)), module)(output, raw)
  list(task = task, checked = checked, output = output, module = module, state = state)
}

v04_fixture_t01 = function() {
  metadata = expand.grid(Patient = c("P1", "P2", "P3"),
                         Tissue = c("Normal", "Tumor"), Treatment = c("I", "II", "III", "IV"),
                         MajorCellType = c("T", "B", "Mye", "ILC"), stringsAsFactors = FALSE)
  metadata$barcode = paste0("cell", seq_len(nrow(metadata)))
  counts = Matrix::Matrix(matrix(3, 1005L, nrow(metadata)), sparse = TRUE)
  rownames(counts) = paste0("id", seq_len(nrow(counts)))
  colnames(counts) = metadata$barcode
  features = data.frame(gene_id = rownames(counts),
    gene_symbol = c("CD3D", "CD3E", "MS4A1", "LYZ", "NKG7", paste0("g", seq_len(1000))))
  list(counts = counts, metadata = metadata, features = features)
}

v04_fixture_t04 = function() {
  withr::local_seed(20261027)
  labels = rep(c("AFR", "EUR", "EAS"), each = 40L)
  frequency = seq(.15, .65, length.out = 120L)
  g = vapply(frequency, function(p) {
    stats::rbinom(120L, 2L, pmin(.95, p + rep(c(-.08, 0, .08), each = 40L)))
  }, integer(120L))
  g[1L, 1L] = NA_integer_
  samples = data.frame(sample = paste0("sample", seq_len(120)),
                       pop = rep(paste0("pop", seq_len(6)), each = 20L),
                       super_pop = labels, gender = rep(c("male", "female"), 60L))
  variants = data.frame(chr = "22", position = seq(100000L, by = 4000L, length.out = 120L),
                        id = paste0("rs", seq_len(120)), ref = "A", alt = "G")
  dimnames(g) = list(samples$sample, variants$id)
  list(genotypes = g, samples = samples, variants = variants)
}

v04_fixture_t10 = function() {
  withr::local_seed(20261027)
  positions = expand.grid(pixel_row = seq_len(8L) * 100L, pixel_col = seq_len(10L) * 100L)
  positions$barcode = paste0("spot", seq_len(nrow(positions)))
  positions$in_tissue = 1L
  positions$array_row = positions$pixel_row / 100L
  positions$array_col = positions$pixel_col / 100L
  m = matrix(stats::rpois(600L * nrow(positions), 6), 600L)
  m[seq_len(40L), positions$pixel_col > 500] =
    m[seq_len(40L), positions$pixel_col > 500] + 10L
  counts = Matrix::Matrix(m, sparse = TRUE)
  features = data.frame(gene_id = paste0("id", seq_len(600)),
                         gene = c("CD3D", "CD3E", "TRAC", "CD8A", paste0("g", seq_len(596))),
                         type = "Gene Expression")
  dimnames(counts) = list(features$gene_id, positions$barcode)
  list(counts = counts, features = features, positions = positions)
}

v04_fixture_t05 = function() {
  withr::local_seed(20261027)
  n = 300L
  position = seq(100000L, by = 20000L, length.out = n)
  p = stats::runif(n)
  p[c(10L, 11L, 60L, 120L)] = c(1e-10, 1e-12, 1e-9, 1e-11)
  association = data.frame(id = paste0("rs", seq_len(n)), chr = "1", position = position,
    effect_allele = "A", other_allele = "C", beta = stats::qnorm(1 - p / 2) * .05,
    se = .05, p = p)
  genes = data.frame(chr = "1", gene = paste0("gene", seq_len(100)),
                      tss = seq(100000L, by = 60000L, length.out = 100L))
  pathways = list(programA = paste0("gene", seq_len(20)),
                   programB = paste0("gene", 20:60), programC = paste0("gene", 60:100))
  list(associations = association, genes = genes, pathways = pathways,
         genome_build = "GRCh37", accession = "fixture-only")
}
