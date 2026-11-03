single_cell_task = function() {
  aggregate_step = function(umi, genes, output) {
    list(reads = c("raw", "qc", "group"), writes = "aggregate_counts", code = paste(
      sprintf("keep = qc$n_count >= %d & qc$n_feature >= %d", umi, genes),
      "design = Matrix::sparseMatrix(i = which(keep), j = as.integer(group)[keep], x = 1,",
      "  dims = c(ncol(raw$counts), nlevels(group)))",
      "aggregate_counts = raw$counts %*% design",
      "markers = c('CD3D', 'CD3E', 'CD8A', 'MS4A1', 'LYZ', 'NKG7', 'EPCAM', 'COL1A1')",
      "marker_rows = match(markers, raw$features$gene_symbol)",
      "result = data.frame(group = rep(levels(group), each = length(markers)),",
      "  gene = rep(markers, nlevels(group)),",
      "  n_cells = rep(tabulate(as.integer(group)[keep], nbins = nlevels(group)),",
      "    each = length(markers)),",
      "  total_umi = rep(Matrix::colSums(aggregate_counts), each = length(markers)),",
      "  count = as.vector(as.matrix(aggregate_counts[marker_rows, , drop = FALSE])))",
      "result$cpm = result$count * 1e6 / pmax(1, result$total_umi)",
      sprintf("utils::write.csv(result, '%s', row.names = FALSE)", output), sep = "\n"))
  }
  list(id = "single-cell", instructions = paste(
    "Analyze the real GSE236581 single-cell cohort in R using Matrix and base R.",
    "Do not install packages or make dense copies of the full counts matrix.",
    "Use all provided cells and genes and reuse state across requests.",
    "raw is a list containing counts (genes by cells, sparse dgCMatrix), metadata",
    "(rows aligned to cells; barcode, Patient, Tissue, Treatment), and features",
    "(rows aligned to genes; gene_id, gene_symbol, feature_type).",
    "Write CSVs with headers, without row names, and without rounding numeric values.",
    "Group identifiers are Patient, Tissue, Treatment joined with '|', in sorted order.",
    "Markers in order: CD3D, CD3E, CD8A, MS4A1, LYZ, NKG7, EPCAM, COL1A1.",
    "Use the first matching feature row for each marker symbol.",
    "Each expression CSV has columns group, gene, n_cells, total_umi, count, cpm.",
    "Include every group from the original metadata and every marker even if no cells pass.",
    "count is the sum of marker UMI in passing cells; total_umi is all-gene UMI in that group.",
    "cpm = count * 1e6 / max(1, total_umi); empty groups have zeros.",
    "Aggregate ALL genes from the sparse matrix before extracting marker rows."
  ), prompts = list(
    paste("Verify identifiers and dimensions between counts, metadata and features.",
          "Compute per-cell total UMI and number of genes with positive counts from counts.",
          "Write cell-qc.csv with barcode, n_count, n_feature in input cell order.",
          "Write qc.csv with one row: n_cells, n_genes, nonzero, total_umi.",
          "Retain QC and group assignments for later requests."),
    paste("Keep cells with n_count >= 1000 and n_feature >= 500.",
          "Sum expression for all genes by patient/tissue/treatment group, then extract",
          "the markers and write baseline.csv with the required expression columns."),
    paste("Change thresholds to n_count >= 2000 and n_feature >= 1000.",
          "Reuse the input and QC, recompute all-gene expression by the same groups,",
          "then extract the markers and write revised.csv. Keep previous output files.")
  ), steps = list(
    list(reads = "raw", writes = c("qc", "group"), code = paste(
      "stopifnot(identical(colnames(raw$counts), raw$metadata$barcode),",
      "  identical(rownames(raw$counts), raw$features$gene_id))",
      "qc = data.frame(barcode = raw$metadata$barcode,",
      "  n_count = Matrix::colSums(raw$counts),",
      "  n_feature = Matrix::colSums(raw$counts > 0), row.names = NULL)",
      "group = factor(paste(raw$metadata$Patient, raw$metadata$Tissue,",
      "  raw$metadata$Treatment, sep = '|'))",
      "utils::write.csv(qc, 'cell-qc.csv', row.names = FALSE)",
      "utils::write.csv(data.frame(n_cells = ncol(raw$counts), n_genes = nrow(raw$counts),",
      "  nonzero = length(raw$counts@x), total_umi = sum(qc$n_count)),",
      "  'qc.csv', row.names = FALSE)", sep = "\n")),
    aggregate_step(1000, 500, "baseline.csv"), aggregate_step(2000, 1000, "revised.csv")
  ))
}
