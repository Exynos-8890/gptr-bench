# Exported recorded R and ordinary source; not executed or validated.
# Earlier console input and unrecorded tool effects are not recovered.
# Review code, external inputs and package versions before running.

# s = peter("Use R for a complete native RNA read-and-reuse task on TCGA-BRCA STAR Counts. This is a descriptive file-level performance task, not differential expression, clinical inference, or patient-level comparison. There are three sequential requests. Complete ONLY the current request: do not infer or compute later requests early. In EVERY request use the same complete original tables in memory. If raw already exists in the current R session (exists(\"raw\", inherits=FALSE)), reuse it without rereading. Otherwise read input-files.txt with base::readLines and fully load each of its 1231 TSV files with data.table::fread(file=filename, skip=\"gene_id\", header=TRUE, showProgress=FALSE), setDTthreads(1), retaining ALL 60664 rows and ALL 9 columns of every file. Store raw=list(files=files,tables=setNames(tables,files)). No input.rds exists. No streaming substitute, lazy/on-disk object, row/column selection, or downsampling. The first four rows are STAR summary categories; gene rows have gene_id starting ENSG (60660 per file). Keep original gene IDs and order, including version suffixes. Biological summaries use unstranded counts for ENSG rows only; do not reinterpret TPM or other columns as counts. Each filename identifies an input file, not necessarily a unique patient. Files have matching gene-ID order. Work column-by-column/table-by-table in the retained list; do not concatenate or duplicate the full dataset into a second dense matrix. Use R assignment =. No package installation; data.table and base R suffice. Use the session r tool whenever available; otherwise use ./instrumentation/bench-rscript --vanilla FILE.R (or -e CODE) for finite native Rscript. Do not launch shell R when an r tool exists. Do not alter instrumentation, GPTR_BENCH_IO_EVENTS, library paths, or runtime settings. Combine related loading, computation, output and necessary checks into coherent calls; do not add calls merely to reprint known state. Diagnose errors or inconsistencies when needed. Keep tool returns concise: dimensions and aggregate checks, never full tables. Write only this request's explicitly named scientific outputs in the unchanged working directory, exact requested columns, unrounded numbers, no row names. No scientific RDS/RData or other state caches. Requested summary files cannot replace the required complete input tables. Use only supplied files and instructions, not references or other runs.\n\nArtifact policy shared by both arms: write only the scientific result files explicitly requested by this task. Do not write additional intermediate datasets, cleaned-cohort tables, object caches, checkpoints, state snapshots, or files intended solely to restore analysis state in a later execution. Do not hide such state in extra columns, sheets, metadata, or renamed files. R script source files needed to execute the analysis and required benchmark instrumentation are allowed; they must not embed datasets or serialized state as a cache. Requested result files may be read again for their stated scientific purpose. Reuse existing in-memory objects when available.\n\nRequest 1: Fully load the tables as specified. Verify file count, dimensions, identical gene_id ordering across all files, and finite nonnegative integer unstranded counts on every ENSG row. Write input-audit.csv with exactly one row and columns n_files,rows_per_file,columns_per_file,genes_per_file,total_gene_counts,zero_gene_values. The final two quantities sum across all ENSG gene/file cells. Keep all complete tables in raw. Do not write other scientific files in this request.", model = "trace-replay/trace-replay-1", mode = "auto", tools = "minimal")
# Recorded prompt: "Use R for a complete native RNA read-and-reuse task on
#  TCGA-BRCA STAR Counts. This is a descriptive file-level performance task,
#  not differential expression, clinical inference, or patient-level
#  comparison. There are three sequential requests. Complete ONLY the current
#  request: do not infer or compute later requests early. In EVERY request use
#  the same complete original tables in memory. If raw already exists in the
#  current R session (exists(\"raw\", inherits=FALSE)), reuse it without
#  rereading. Otherwise read input-files.txt with base::readLines and fully
#  load each of its 1231 TSV files with data.table::fread(file=filename,
#  skip=\"gene_id\", header=TRUE, showProgress=FALSE), setDTthreads(1),
#  retaining ALL 60664 rows and ALL 9 columns of every file. Store
#  raw=list(files=files,tables=setNames(tables,files)). No input.rds exists. No
#  streaming substitute, lazy/on-disk object, row/column selection, or
#  downsampling. The first four rows are STAR summary categories; gene rows
#  have gene_id starting ENSG (60660 per file). Keep original gene IDs and
#  order, including version suffixes. Biological summaries use unstranded
#  counts for ENSG rows only; do not reinterpret TPM or other columns as
#  counts. Each filename identifies an input file, not necessarily a unique
#  patient. Files have matching gene-ID order. Work
#  column-by-column/table-by-table in the retained list; do not concatenate or
#  duplicate the full dataset into a second dense matrix. Use R assignment =.
#  No package installation; data.table and base R suffice. Use the session r
#  tool whenever available; otherwise use ./instrumentation/bench-rscript
#  --vanilla FILE.R (or -e CODE) for finite native Rscript. Do not launch shell
#  R when an r tool exists. Do not alter instrumentation, GPTR_BENCH_IO_EVENTS,
#  library paths, or runtime settings. Combine related loading, computation,
#  output and necessary checks into coherent calls; do not add calls merely to
#  reprint known state. Diagnose errors or inconsistencies when needed. Keep
#  tool returns concise: dimensions and aggregate checks, never full tables.
#  Write only this request's explicitly named scientific outputs in the
#  unchanged working directory, exact requested columns, unrounded numbers, no
#  row names. No scientific RDS/RData or other state caches. Requested summary
#  files cannot replace the required complete input tables. Use only supplied
#  files and instructions, not references or other runs.\n\nArtifact policy
#  shared by both arms: write only the scientific result files explicitly
#  requested by this task. Do not write additional intermediate datasets,
#  cleaned-cohort tables, object caches, checkpoints, state snapshots, or files
#  intended solely to restore analysis state in a later execution. Do not hide
#  such state in extra columns, sheets, metadata, or renamed files. R script
#  source files needed to execute the analysis and required benchmark
#  instrumentation are allowed; they must not embed datasets or serialized
#  state as a cache. Requested result files may be read again for their stated
#  scientific purpose. Reuse existing in-memory objects when
#  available.\n\nRequest 1: Fully load the tables as specified. Verify file
#  count, dimensions, identical gene_id ordering across all files, and finite
#  nonnegative integer unstranded counts on every ENSG row. Write
#  input-audit.csv with exactly one row and columns
#  n_files,rows_per_file,columns_per_file,genes_per_file,total_gene_counts,zero_
# gene_values. The final two quantities sum across all ENSG gene/file cells.
#  Keep all complete tables in raw. Do not write other scientific files in this
#  request."
data.table::setDTthreads(1)
if (!exists("raw", inherits = FALSE)) {
  files = base::readLines("input-files.txt")
  stopifnot(length(files) == 1231L)
  tables = lapply(files, function(filename) data.table::fread(file = filename, skip = "gene_id", header = TRUE, showProgress = FALSE))
  raw = list(files = files, tables = setNames(tables, files))
}
stopifnot(length(raw$files) == 1231L, length(raw$tables) == 1231L, identical(names(raw$tables), raw$files))
audit_gene_ids = raw$tables[[1L]]$gene_id
audit_gene_rows = startsWith(audit_gene_ids, "ENSG")
stopifnot(length(audit_gene_ids) == 60664L, sum(audit_gene_rows) == 60660L, identical(which(!audit_gene_rows), 1:4))
audit_totals = c(total_gene_counts = 0, zero_gene_values = 0)
for (audit_i in seq_along(raw$tables)) {
  audit_table = raw$tables[[audit_i]]
  stopifnot(identical(dim(audit_table), c(60664L, 9L)), identical(audit_table$gene_id, audit_gene_ids), "unstranded" %in% names(audit_table))
  audit_counts = audit_table$unstranded[audit_gene_rows]
  stopifnot(is.numeric(audit_counts), all(is.finite(audit_counts)), all(audit_counts >= 0), all(audit_counts == floor(audit_counts)))
  audit_totals = audit_totals + c(sum(audit_counts), sum(audit_counts == 0))
}
input_audit = data.frame(n_files = length(raw$files), rows_per_file = length(audit_gene_ids), columns_per_file = ncol(raw$tables[[1L]]), genes_per_file = sum(audit_gene_rows), total_gene_counts = unname(audit_totals[1L]), zero_gene_values = unname(audit_totals[2L]))
data.table::fwrite(input_audit, file = "input-audit.csv", row.names = FALSE)
print(input_audit)
#>   n_files rows_per_file columns_per_file genes_per_file total_gene_counts...
#> 1    1231         60664                9          60660       71357946062...
# s |> peter("Request 2: Reuse or fully reload the same complete raw tables under Request 1 rules. From each file's ENSG-row unstranded counts compute total counts, number of genes with count>0, number with count=0, mean and maximum count. Write sample-summary.csv with columns file,total_counts,detected_genes,zero_genes,mean_count,max_count, one row per original filename, sorted by file. Do not write other scientific files or compute the next request early.")
# Recorded prompt: "Request 2: Reuse or fully reload the same complete raw
#  tables under Request 1 rules. From each file's ENSG-row unstranded counts
#  compute total counts, number of genes with count>0, number with count=0,
#  mean and maximum count. Write sample-summary.csv with columns
#  file,total_counts,detected_genes,zero_genes,mean_count,max_count, one row
#  per original filename, sorted by file. Do not write other scientific files
#  or compute the next request early."
data.table::setDTthreads(1)
if (!exists("raw", inherits = FALSE)) {
  files = base::readLines("input-files.txt")
  stopifnot(length(files) == 1231L)
  tables = lapply(files, function(filename) data.table::fread(file = filename, skip = "gene_id", header = TRUE, showProgress = FALSE))
  raw = list(files = files, tables = setNames(tables, files))
}
stopifnot(length(raw$files) == 1231L, length(raw$tables) == 1231L, identical(names(raw$tables), raw$files))
summary_gene_ids = raw$tables[[1L]]$gene_id
summary_gene_rows = startsWith(summary_gene_ids, "ENSG")
stopifnot(length(summary_gene_ids) == 60664L, sum(summary_gene_rows) == 60660L)
sample_summary = lapply(seq_along(raw$tables), function(i) {
  tab = raw$tables[[i]]
  stopifnot(identical(dim(tab), c(60664L, 9L)), identical(tab$gene_id, summary_gene_ids))
  counts = tab$unstranded[summary_gene_rows]
  stopifnot(is.numeric(counts), all(is.finite(counts)), all(counts >= 0), all(counts == floor(counts)))
  data.frame(file = raw$files[i], total_counts = sum(counts), detected_genes = sum(counts > 0), zero_genes = sum(counts == 0), mean_count = mean(counts), max_count = max(counts))
}) |> data.table::rbindlist()
sample_summary = sample_summary[order(file)]
stopifnot(nrow(sample_summary) == 1231L, all(sample_summary$detected_genes + sample_summary$zero_genes == 60660L))
data.table::fwrite(sample_summary, file = "sample-summary.csv", row.names = FALSE)
print(list(dim = dim(sample_summary), total_counts = sum(sample_summary$total_counts), zero_genes = sum(sample_summary$zero_genes), sorted_by_file = identical(order(sample_summary$file), seq_len(nrow(sample_summary)))))
#> $dim
#> [1] 1231    6
#> $total_counts
#> [1] 71357946062
#> $zero_genes
#> [1] 34425437
#> $sorted_by_file
#> [1] TRUE
# s |> peter("Request 3: Reuse or fully reload the same complete raw tables under Request 1 rules. For every ENSG gene, aggregate its unstranded counts over ALL files: total counts, files with count>0, files with count=0, mean and maximum count. Write gene-summary.csv with columns gene_id,total_counts,detected_files,zero_files,mean_count,max_count, in original gene order. Accumulate gene-length vectors over the existing list, initializing totals with numeric() to avoid integer overflow; avoid a second dense matrix. Write research-report.md describing the input scope and summaries, with these limits: files are not independent patients; no differential-expression model, biological group comparison, protein identification, or clinical conclusion. No other scientific outputs.")
# Recorded prompt: "Request 3: Reuse or fully reload the same complete raw
#  tables under Request 1 rules. For every ENSG gene, aggregate its unstranded
#  counts over ALL files: total counts, files with count>0, files with count=0,
#  mean and maximum count. Write gene-summary.csv with columns
#  gene_id,total_counts,detected_files,zero_files,mean_count,max_count, in
#  original gene order. Accumulate gene-length vectors over the existing list,
#  initializing totals with numeric() to avoid integer overflow; avoid a second
#  dense matrix. Write research-report.md describing the input scope and
#  summaries, with these limits: files are not independent patients; no
#  differential-expression model, biological group comparison, protein
#  identification, or clinical conclusion. No other scientific outputs."
data.table::setDTthreads(1)
gene_raw_reused = exists("raw", inherits = FALSE)
if (!gene_raw_reused) {
  files = base::readLines("input-files.txt")
  stopifnot(length(files) == 1231L)
  tables = lapply(files, function(filename) data.table::fread(file = filename, skip = "gene_id", header = TRUE, showProgress = FALSE))
  raw = list(files = files, tables = setNames(tables, files))
}
stopifnot(length(raw$files) == 1231L, length(raw$tables) == 1231L, identical(names(raw$tables), raw$files))
gene_ids_all = raw$tables[[1L]]$gene_id
gene_rows = startsWith(gene_ids_all, "ENSG")
stopifnot(length(gene_ids_all) == 60664L, sum(gene_rows) == 60660L, identical(which(!gene_rows), 1:4))
gene_totals = numeric(sum(gene_rows))
gene_detected = integer(sum(gene_rows))
gene_maximum = numeric(sum(gene_rows))
for (gene_i in seq_along(raw$tables)) {
  gene_tab = raw$tables[[gene_i]]
  stopifnot(identical(dim(gene_tab), c(60664L, 9L)), identical(gene_tab$gene_id, gene_ids_all))
  gene_counts = gene_tab$unstranded[gene_rows]
  stopifnot(is.numeric(gene_counts), all(is.finite(gene_counts)), all(gene_counts >= 0), all(gene_counts == floor(gene_counts)))
  gene_totals = gene_totals + gene_counts
  gene_detected = gene_detected + (gene_counts > 0)
  gene_maximum = pmax(gene_maximum, gene_counts)
}
gene_summary = data.table::data.table(gene_id = gene_ids_all[gene_rows], total_counts = gene_totals, detected_files = gene_detected, zero_files = length(raw$files) - gene_detected, mean_count = gene_totals / length(raw$files), max_count = gene_maximum)
stopifnot(identical(gene_summary$gene_id, gene_ids_all[gene_rows]), all(gene_summary$detected_files + gene_summary$zero_files == length(raw$files)))
if (exists("sample_summary", inherits = FALSE)) {
  stopifnot(sum(gene_summary$total_counts) == sum(sample_summary$total_counts), sum(gene_summary$zero_files) == sum(sample_summary$zero_genes))
}
data.table::fwrite(gene_summary, file = "gene-summary.csv", row.names = FALSE)
gene_report_stats = list(raw_reused = gene_raw_reused, dimensions = dim(gene_summary), n_files = length(raw$files), gene_file_cells = as.double(nrow(gene_summary)) * length(raw$files), total_counts = sum(gene_summary$total_counts), zero_values = sum(gene_summary$zero_files), detected_values = sum(gene_summary$detected_files), genes_detected_any = sum(gene_summary$detected_files > 0), genes_detected_all = sum(gene_summary$detected_files == length(raw$files)), genes_zero_all = sum(gene_summary$detected_files == 0))
print(gene_report_stats)
#> $raw_reused
#> [1] TRUE
#> $dimensions
#> [1] 60660     6
#> $n_files
#> [1] 1231
#> $gene_file_cells
#> [1] 74672460
#> $total_counts
#> [1] 71357946062
#> $zero_values
#> ... (further captured output omitted)
