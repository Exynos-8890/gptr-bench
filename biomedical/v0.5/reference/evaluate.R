# Reference calculations run outside the timed agent workspace.
clinical_reference = function(raw) {
  d = raw[stats::complete.cases(raw[c("time", "status", "trt", "age", "karno")]), ]
  d = d[d$time > 0 & d$status %in% 0:1, ]
  d$trt = factor(d$trt, levels = 1:2)
  curves = survival::survfit(survival::Surv(time, status == 1) ~ trt, data = d)
  baseline = survival::coxph(survival::Surv(time, status == 1) ~ trt + age, data = d)
  adjusted = survival::coxph(survival::Surv(time, status == 1) ~ trt + age + karno, data = d)
  table = function(model) {
    s = summary(model)$coefficients
    data.frame(term = rownames(s), estimate = s[, "coef"], se = s[, "se(coef)"],
               row.names = NULL)
  }
  list(
    qc.csv = data.frame(n_input = nrow(raw), n = nrow(d), events = sum(d$status == 1)),
    km.csv = data.frame(time = curves$time, surv = curves$surv,
                        stratum = rep(names(curves$strata), curves$strata)),
    cox.csv = table(baseline), revised.csv = table(adjusted)
  )
}

check_artifacts = function(workspace, raw, tolerance = 1e-6, task = "clinical") {
  expected = if (identical(task, "single-cell")) {
    single_cell_reference(raw)
  } else {
    clinical_reference(raw)
  }
  errors = character()
  for (name in names(expected)) {
    path = file.path(workspace, name)
    if (!file.exists(path)) {
      errors = c(errors, paste(name, "missing"))
      next
    }
    actual = utils::read.csv(path, stringsAsFactors = FALSE)
    wanted = expected[[name]]
    if (!identical(names(actual), names(wanted))) {
      errors = c(errors, paste(name, "column names do not match"))
      next
    }
    if ("term" %in% names(actual)) actual = actual[order(actual$term), , drop = FALSE]
    if ("term" %in% names(wanted)) wanted = wanted[order(wanted$term), , drop = FALSE]
    if (identical(name, "km.csv")) {
      actual = actual[order(actual$stratum, actual$time), , drop = FALSE]
      wanted = wanted[order(wanted$stratum, wanted$time), , drop = FALSE]
    }
    keys = intersect(c("barcode", "group", "gene"), names(wanted))
    if (length(keys)) {
      actual = actual[do.call(order, actual[keys]), , drop = FALSE]
      wanted = wanted[do.call(order, wanted[keys]), , drop = FALSE]
    }
    rownames(actual) = NULL
    rownames(wanted) = NULL
    for (column in names(wanted)) {
      tol = if (identical(task, "single-cell") && column != "cpm") 0 else tolerance
      equal = all.equal(actual[[column]], wanted[[column]], tolerance = tol,
                        check.attributes = FALSE)
      if (!isTRUE(equal)) errors = c(errors, paste(name, column, paste(equal, collapse = "; ")))
    }
  }
  list(ok = !length(errors), errors = errors)
}

# Reference sums only marker rows and cell totals, independently of all-gene sparse multiplication.
single_cell_reference = function(raw) {
  counts = Matrix::colSums(raw$counts)
  features = diff(raw$counts@p)
  labels = paste(raw$metadata$Patient, raw$metadata$Tissue, raw$metadata$Treatment, sep = "|")
  groups = sort(unique(labels))
  markers = c("CD3D", "CD3E", "CD8A", "MS4A1", "LYZ", "NKG7", "EPCAM", "COL1A1")
  values = as.matrix(raw$counts[match(markers, raw$features$gene_symbol), , drop = FALSE])
  aggregate = function(umi, genes) {
    keep = counts >= umi & features >= genes
    do.call(rbind, lapply(groups, function(label) {
      indices = which(keep & labels == label)
      total = sum(counts[indices])
      sums = rowSums(values[, indices, drop = FALSE])
      data.frame(group = label, gene = markers, n_cells = length(indices),
                 total_umi = total, count = sums, cpm = sums * 1e6 / max(1, total),
                 row.names = NULL)
    }))
  }
  list(qc.csv = data.frame(n_cells = ncol(raw$counts), n_genes = nrow(raw$counts),
                           nonzero = length(raw$counts@x), total_umi = sum(counts)),
       "cell-qc.csv" = data.frame(barcode = raw$metadata$barcode, n_count = counts,
                                   n_feature = features, row.names = NULL),
       baseline.csv = aggregate(1000, 500), revised.csv = aggregate(2000, 1000))
}
