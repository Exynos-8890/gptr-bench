# Run from repo root: Rscript --vanilla .../prepare-v04-t02.R SOURCE_DIR OUTPUT_DIR [--offline]
source("biomedical/prepare-v04-mlclinical-utils.R", local = TRUE)

v04_prepare_t02 = function(source_dir, output_dir, offline = FALSE) {
  url = paste0("https://media.githubusercontent.com/media/cBioPortal/datahub/master/",
    "public/brca_metabric/data_clinical_patient.txt")
  path = v04_source_file(source_dir, "data_clinical_patient.txt", url, offline)
  d = utils::read.delim(path, comment.char = "#", check.names = FALSE,
    stringsAsFactors = FALSE, na.strings = c("", "NA", "[Not Available]", "[Not Applicable]"))
  fields = c("PATIENT_ID", "OS_MONTHS", "OS_STATUS", "AGE_AT_DIAGNOSIS", "ER_IHC",
             "LYMPH_NODES_EXAMINED_POSITIVE", "CHEMOTHERAPY")
  stopifnot(all(fields %in% names(d)), nrow(d) == 2509L, !anyDuplicated(d$PATIENT_ID))
  status = trimws(as.character(d$OS_STATUS))
  event = rep(NA_integer_, nrow(d))
  event[status %in% c("0:LIVING", "0:Living", "LIVING", "0")] = 0L
  event[status %in% c("1:DECEASED", "1:Deceased", "DECEASED", "1")] = 1L
  unrecognized = !is.na(status) & !status %in% c("", "NA") & is.na(event)
  if (any(unrecognized)) stop("Unknown METABRIC overall-survival status encoding")
  er = trimws(as.character(d$ER_IHC))
  corrected = sum(er == "Positve", na.rm = TRUE)
  er[!is.na(er) & er == "Positve"] = "Positive"
  raw = data.frame(id = d$PATIENT_ID, time = as.numeric(d$OS_MONTHS), event = event,
    age = as.numeric(d$AGE_AT_DIAGNOSIS), er = er,
    nodes = as.numeric(d$LYMPH_NODES_EXAMINED_POSITIVE),
    chemo = toupper(as.character(d$CHEMOTHERAPY)), stringsAsFactors = FALSE)
  v04_save_prepared(raw, output_dir, "T02", "METABRIC brca_metabric",
    list(v04_source_record(path, url)), list(patients = nrow(raw), variables = ncol(raw),
      er_label_normalization = "ER_IHC Positve -> Positive", corrected_er_labels = corrected),
    "Public clinical table; events follow OS_STATUS prefixes. No causal claim.")
}

if (sys.nframe() == 0L) {
  args = commandArgs(TRUE)
  if (length(args) < 2L) stop("Usage: prepare-v04-t02.R SOURCE_DIR OUTPUT_DIR [--offline]")
  v04_prepare_t02(args[[1]], args[[2]], "--offline" %in% args)
}
