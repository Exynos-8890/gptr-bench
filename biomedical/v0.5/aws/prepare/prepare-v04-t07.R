# ProteinGym v1.3; only GB1 is extracted from the official archive.
source("biomedical/prepare-v04-mlclinical-utils.R", local = TRUE)

v04_prepare_t07 = function(source_dir, output_dir, offline = FALSE) {
  reference_url = paste0("https://raw.githubusercontent.com/OATML-Markslab/ProteinGym/main/",
    "reference_files/DMS_substitutions.csv")
  archive_url = paste0("https://marks.hms.harvard.edu/proteingym/ProteinGym_v1.3/",
    "DMS_ProteinGym_substitutions.zip")
  reference = v04_source_file(source_dir, "DMS_substitutions.csv", reference_url, offline)
  ref = utils::read.csv(reference, check.names = FALSE, stringsAsFactors = FALSE)
  assay = ref[ref$DMS_id == "SPG1_STRSG_Wu_2016", , drop = FALSE]
  stopifnot(nrow(assay) == 1L)
  filename = assay$DMS_filename[[1L]]
  csv = file.path(source_dir, filename)
  archive = NULL
  if (!file.exists(csv)) {
    archive = v04_source_file(source_dir, "DMS_ProteinGym_substitutions.zip", archive_url, offline)
    members = utils::unzip(archive, list = TRUE)$Name
    member = members[basename(members) == filename]
    if (length(member) != 1L) stop("GB1 member missing or ambiguous in official ProteinGym archive")
    dir = tempfile("proteingym-gb1-")
    dir.create(dir)
    on.exit(unlink(dir, recursive = TRUE), add = TRUE)
    utils::unzip(archive, files = member, exdir = dir)
    if (!file.copy(file.path(dir, member), csv)) stop("Could not retain GB1 source CSV")
  }
  d = utils::read.csv(csv, stringsAsFactors = FALSE, check.names = FALSE)
  stopifnot(all(c("mutant", "mutated_sequence", "DMS_score") %in% names(d)),
    nrow(d) == as.integer(assay$DMS_total_number_mutants[[1L]]), nrow(d) == 149360L)
  positions = sort(unique(as.integer(unlist(regmatches(d$mutant,
    gregexpr("[0-9]+", d$mutant))))))
  stopifnot(length(positions) == 4L, all(positions >= 1L),
    all(positions <= nchar(assay$target_seq[[1L]])))
  raw = list(variants = d[c("mutant", "mutated_sequence", "DMS_score")],
    wild_type = assay$target_seq[[1L]], sites = positions,
    assay = "SPG1_STRSG_Wu_2016", score_direction = "Higher measured binding fitness is better")
  sources = list(v04_source_record(reference, reference_url),
    v04_source_record(csv, paste0(archive_url, "#", filename)))
  if (!is.null(archive)) sources = c(sources, list(v04_source_record(archive, archive_url)))
  v04_save_prepared(raw, output_dir, "T07", "ProteinGym v1.3 GB1 SPG1_STRSG_Wu_2016", sources,
    list(variants = nrow(d), variable_sites = positions,
      reference_sequence_length = nchar(raw$wild_type)),
    "Official processed experimental DMS scores. Feature construction and splitting remain timed.")
}

if (sys.nframe() == 0L) {
  args = commandArgs(TRUE)
  if (length(args) < 2L) stop("Usage: prepare-v04-t07.R SOURCE_DIR OUTPUT_DIR [--offline]")
  v04_prepare_t07(args[[1]], args[[2]], "--offline" %in% args)
}
