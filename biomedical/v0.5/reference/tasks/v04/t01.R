v04_t01 = function() {
  list(id = "T01", script = "t01-analysis.R",
    artifacts = c(
      "cell-qc.csv", "cohort-audit.csv",
      "patient-audit.csv", "patient-composition.csv",
      "paired-patient-audit.csv", "tissue-comparison.csv",
      "statistical-audit.csv", "longitudinal.csv",
      "longitudinal-patient-values.csv", "sensitivity.csv",
      "marker-evidence.csv", "tissue-composition.png",
      "longitudinal-composition.png", "research-report.md"),
    steps = list(
      list(request = 1L, reads = c("raw"), writes = c("emit")),
      list(request = 1L, reads = c("raw", "emit"), writes = c("qc")),
      list(request = 1L, reads = c("raw", "qc", "emit"), writes = c("cohort_audit")),
      list(request = 1L, reads = c("raw", "qc"), writes = c("composition_fn")),
      list(request = 1L, reads = c("raw", "qc", "composition_fn"), writes = c("composition")),
      list(request = 1L, reads = c("composition", "emit"), writes = c("patient_audit")),
      list(request = 2L, reads = c("composition"), writes = c("tissue")),
      list(request = 2L, reads = c("tissue"), writes = c("pair_audit")),
      list(request = 2L, reads = c("tissue"), writes = c("paired_fn")),
      list(request = 2L, reads = c("tissue", "paired_fn"), writes = c("tissue_result")),
      list(request = 2L, reads = c("tissue_result"), writes = c("tissue_result")),
      list(request = 2L, reads = c("tissue_result", "pair_audit", "emit"), writes = character()),
      list(request = 2L, reads = c("tissue"), writes = character()),
      list(request = 2L, reads = c("tissue_result", "pair_audit", "emit"), writes = c("statistical_audit")),
      list(request = 3L, reads = c("composition", "paired_fn"), writes = c("longitudinal")),
      list(request = 3L, reads = c("longitudinal", "composition", "emit"), writes = character()),
      list(request = 3L, reads = c("raw", "qc", "composition_fn", "paired_fn"), writes = c("sensitivity")),
      list(request = 3L, reads = c("raw", "qc", "emit", "sensitivity"), writes = c("marker_evidence")),
      list(request = 3L, reads = c("composition"), writes = character()),
      list(request = 3L, reads = c("cohort_audit", "tissue_result", "longitudinal", "sensitivity"), writes = character())
    ))
}
