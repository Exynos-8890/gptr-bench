# Small offline fixtures ONLY. Never consumed by the formal preparation commands.
destination = commandArgs(TRUE)[[1L]]
bench = normalizePath("..")
source("helper-v04-genetics.R", local = TRUE)
fixtures = list(T01 = v04_fixture_t01(), T04 = v04_fixture_t04(),
                T05 = v04_fixture_t05(), T10 = v04_fixture_t10())
set.seed(100)
d = survival::lung
fixtures$T02 = data.frame(id = paste0("p", seq_len(nrow(d))), time = d$time / 30.4375,
  event = d$status - 1L, age = d$age, er = ifelse(d$sex == 1, "Negative", "Positive"),
  nodes = d$ph.ecog, chemo = rep(c("YES", "NO"), length.out = nrow(d)))
samples = data.frame(sample = paste0("S", 1:16), patient = rep(paste0("P", 1:8), 2),
  group = rep(c("Normal", "Tumor"), each = 8), batch = rep(c("A", "B"), 8))
counts = matrix(stats::rnbinom(160 * 16, mu = 60, size = 4), 160, 16,
  dimnames = list(paste0("G", 1:160), samples$sample))
counts[1:30, 9:16] = counts[1:30, 9:16] * 4L
fixtures$T03 = list(counts = counts, samples = samples,
  pathways = list(set1 = paste0("G", 1:40), set2 = paste0("G", 40:120)))
p = data.frame(chr = rep(c("chr1", "chr2"), each = 12),
  start = rep(seq(1000, 23000, 2000), 2), end = rep(seq(1000, 23000, 2000), 2) + 200,
  score = seq_len(24))
fixtures$T06 = list(peaks = list(p, p), genes = data.frame(
  chr = rep(c("chr1", "chr2"), each = 12), tss = rep(seq(1100, 23100, 2000), 2),
  gene = paste0("G", seq_len(24))), chromosomes = data.frame(
    chr = c("chr1", "chr2"), length = c(100000, 100000)))
aa = strsplit("ACDEFGHIKLMNPQRSTVWY", "")[[1L]]
codes = sample.int(20^4, 600) - 1L
positions = vapply(0:3, function(k) aa[(codes %/% (20^k)) %% 20 + 1L], character(600))
wild = strsplit("VDGV", "")[[1L]]
mutants = vapply(seq_len(nrow(positions)), function(i) {
  j = which(positions[i, ] != wild)
  if (!length(j)) "WT" else paste0(wild[j], j, positions[i, j], collapse = ":")
}, "")
fixtures$T07 = list(variants = data.frame(mutant = mutants,
  mutated_sequence = apply(positions, 1, paste0, collapse = ""),
  DMS_score = (positions[, 1] == "A") + .8 * (positions[, 2] == "G") +
    (positions[, 1] == positions[, 3]) + stats::rnorm(600, sd = .1)),
  wild_type = "VDGV", sites = 1:4)
samples = data.frame(sample = paste0("S", 1:32), patient = paste0("P", 1:32),
  subtype = rep(c("LumA", "Basal", "Her2", "LumB"), each = 8),
  batch = rep(c("A", "B"), 16), channel = rep(c("itraq_114", "itraq_115"), 16),
  is_reference = FALSE)
x = matrix(stats::rnorm(120 * 32), 120, 32,
  dimnames = list(paste0("G", 1:120), samples$sample))
x[1:20, samples$subtype == "Basal"] = x[1:20, samples$subtype == "Basal"] + 2
x[90:110, 1:2] = NA_real_
fixtures$T08 = list(abundance = x, samples = samples, scale = "log2_ratio_to_reference",
  pathways = list(set1 = paste0("G", 1:30), set2 = paste0("G", 60:100)))
x = matrix(stats::rlnorm(120 * 8), 120, 8)
y = rep(0:1, each = 60)
x[, 1] = x[, 1] + 2 * y
x[seq(1, 120, 13), 3] = NA_real_
colnames(x) = paste0("met", 1:8)
fixtures$T09 = list(x = x, y = y, sample_id = paste0("sample", 1:120), metabolites = colnames(x))
source(file.path(bench, "tasks/v04/registry.R"), local = TRUE)
for (id in names(fixtures)) {
  directory = file.path(destination, id)
  dir.create(directory, recursive = TRUE, showWarnings = FALSE)
  saveRDS(fixtures[[id]], file.path(directory, "input.rds"), compress = FALSE)
  task = v04_load(id, bench)
  jsonlite::write_json(task, file.path(directory, "task.json"), auto_unbox = TRUE, pretty = TRUE)
}
