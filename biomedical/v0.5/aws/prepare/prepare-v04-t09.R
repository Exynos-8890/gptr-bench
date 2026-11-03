# Author-provided tidy representation of the real MTBLS90 study.
source("biomedical/prepare-v04-mlclinical-utils.R", local = TRUE)

v04_prepare_t09 = function(source_dir, output_dir, offline = FALSE) {
  url = paste0("https://raw.githubusercontent.com/CIMCB/MetabComparisonBinaryML/master/",
    "notebooks/data/MTBLS90.xlsx")
  path = v04_source_file(source_dir, "MTBLS90.xlsx", url, offline)
  if (!requireNamespace("readxl", quietly = TRUE)) stop("Preparation requires installed readxl")
  data = as.data.frame(readxl::read_excel(path, sheet = "Data"))
  peak = as.data.frame(readxl::read_excel(path, sheet = "Peak"))
  stopifnot(all(c("SampleID", "Class") %in% names(data)), "Name" %in% names(peak))
  features = as.character(peak$Name)
  stopifnot(length(features) == 189L, nrow(data) == 968L,
    all(features %in% names(data)), !anyDuplicated(features), !anyDuplicated(data$SampleID))
  x = as.matrix(data[features])
  storage.mode(x) = "double"
  y = as.integer(data$Class)
  stopifnot(all(y %in% 0:1), sum(y == 1L) == 485L, sum(y == 0L) == 483L)
  raw = list(x = x, y = y, sample_id = as.character(data$SampleID), metabolites = features,
    annotation = peak, outcome = "Male=1; Female=0")
  v04_save_prepared(raw, output_dir, "T09", "MetaboLights MTBLS90; CIMCB tidy processed release",
    list(v04_source_record(path, url)),
    list(samples = nrow(x), metabolites = ncol(x), male = sum(y), female = sum(y == 0)),
    paste("Public author-formatted measured metabolite matrix; sex classification at age70.",
      "No imputation/scaling, model fit or dataset split performed during preparation."))
}

if (sys.nframe() == 0L) {
  args = commandArgs(TRUE)
  if (length(args) < 2L) stop("Usage: prepare-v04-t09.R SOURCE_DIR OUTPUT_DIR [--offline]")
  v04_prepare_t09(args[[1]], args[[2]], "--offline" %in% args)
}
