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
  rm(tables)
}
stopifnot(length(raw$files) == 1231L, length(raw$tables) == 1231L, identical(names(raw$tables), raw$files))
reference_gene_ids = raw$tables[[1L]][["gene_id"]]
gene_rows = startsWith(reference_gene_ids, "ENSG")
stopifnot(length(reference_gene_ids) == 60664L, sum(gene_rows) == 60660L, identical(which(!gene_rows), 1:4))
audit_totals = vapply(raw$tables, function(tab) {
  stopifnot(identical(dim(tab), c(60664L, 9L)), identical(tab[["gene_id"]], reference_gene_ids))
  counts = tab[["unstranded"]][gene_rows]
  stopifnot(is.numeric(counts), all(is.finite(counts)), all(counts >= 0), all(counts == floor(counts)))
  c(total_gene_counts = sum(counts), zero_gene_values = sum(counts == 0))
}, numeric(2L))
input_audit = data.frame(n_files = length(raw$files), rows_per_file = length(reference_gene_ids), columns_per_file = ncol(raw$tables[[1L]]), genes_per_file = sum(gene_rows), total_gene_counts = sum(audit_totals["total_gene_counts", ]), zero_gene_values = sum(audit_totals["zero_gene_values", ]))
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
  rm(tables)
}
stopifnot(length(raw$files) == 1231L, length(raw$tables) == 1231L, identical(names(raw$tables), raw$files))
reference_gene_ids = raw$tables[[1L]][["gene_id"]]
gene_rows = startsWith(reference_gene_ids, "ENSG")
stopifnot(length(reference_gene_ids) == 60664L, sum(gene_rows) == 60660L, identical(which(!gene_rows), 1:4))
sample_summary = data.table::rbindlist(lapply(seq_along(raw$files), function(i) {
  tab = raw$tables[[i]]
  stopifnot(identical(dim(tab), c(60664L, 9L)), identical(tab[["gene_id"]], reference_gene_ids))
  counts = tab[["unstranded"]][gene_rows]
  stopifnot(is.numeric(counts), all(is.finite(counts)), all(counts >= 0), all(counts == floor(counts)))
  data.table::data.table(file = raw$files[[i]], total_counts = sum(counts), detected_genes = sum(counts > 0), zero_genes = sum(counts == 0), mean_count = mean(counts), max_count = max(counts))
}))
data.table::setorder(sample_summary, file)
stopifnot(nrow(sample_summary) == 1231L, all(sample_summary$detected_genes + sample_summary$zero_genes == 60660L), identical(sample_summary$file, sort(raw$files)))
data.table::fwrite(sample_summary, file = "sample-summary.csv", row.names = FALSE)
print(list(dimensions = dim(sample_summary), total_counts = sum(sample_summary$total_counts), zero_gene_values = sum(sample_summary$zero_genes)))
#> $dimensions
#> [1] 1231    6
#> $total_counts
#> [1] 71357946062
#> $zero_gene_values
#> [1] 34425437
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
if (!exists("raw", inherits = FALSE)) {
  files = base::readLines("input-files.txt")
  stopifnot(length(files) == 1231L)
  tables = lapply(files, function(filename) data.table::fread(file = filename, skip = "gene_id", header = TRUE, showProgress = FALSE))
  raw = list(files = files, tables = setNames(tables, files))
  rm(tables)
}
stopifnot(length(raw$files) == 1231L, length(raw$tables) == 1231L, identical(names(raw$tables), raw$files))
reference_gene_ids = raw$tables[[1L]][["gene_id"]]
gene_rows = startsWith(reference_gene_ids, "ENSG")
stopifnot(length(reference_gene_ids) == 60664L, sum(gene_rows) == 60660L, identical(which(!gene_rows), 1:4))
gene_total_counts = numeric(sum(gene_rows))
gene_detected_files = integer(sum(gene_rows))
gene_max_count = numeric(sum(gene_rows))
for (tab in raw$tables) {
  stopifnot(identical(dim(tab), c(60664L, 9L)), identical(tab[["gene_id"]], reference_gene_ids))
  counts = tab[["unstranded"]][gene_rows]
  stopifnot(is.numeric(counts), all(is.finite(counts)), all(counts >= 0), all(counts == floor(counts)))
  gene_total_counts = gene_total_counts + counts
  gene_detected_files = gene_detected_files + (counts > 0)
  gene_max_count = pmax(gene_max_count, counts)
}
gene_summary = data.table::data.table(gene_id = reference_gene_ids[gene_rows], total_counts = gene_total_counts, detected_files = gene_detected_files, zero_files = length(raw$files) - gene_detected_files, mean_count = gene_total_counts / length(raw$files), max_count = gene_max_count)
stopifnot(identical(gene_summary$gene_id, reference_gene_ids[gene_rows]), all(gene_summary$detected_files + gene_summary$zero_files == length(raw$files)), all(is.finite(gene_summary$total_counts)))
if (exists("sample_summary", inherits = FALSE)) {
  stopifnot(sum(gene_summary$total_counts) == sum(sample_summary$total_counts), sum(gene_summary$zero_files) == sum(sample_summary$zero_genes))
}
data.table::fwrite(gene_summary, file = "gene-summary.csv", row.names = FALSE)
research_report = c(
  "# TCGA-BRCA STAR Counts descriptive report",
  "",
  "## Input scope and validation",
  "The analysis fully retained 1,231 original TSV input tables in raw, each with 60,664 rows and all 9 columns. The first four rows contain STAR summary categories; the remaining 60,660 rows have gene_id values starting with ENSG. Gene IDs, including version suffixes, and their original order were preserved. All tables had identical gene-ID ordering. Every ENSG-row unstranded count was verified to be finite, nonnegative, and integer-valued.",
  "",
  "All biological count summaries use only ENSG-row unstranded counts. STAR summary categories were excluded, and TPM and other columns were not treated as counts. All input tables were kept complete; aggregation used gene-length vectors over the retained list, with double-precision totals initialized using numeric(), without creating a second dense gene-by-file matrix.",
  "",
  "## Summary outputs",
  "input-audit.csv records the input dimensions and aggregate count checks in one row. sample-summary.csv contains one row per original filename, sorted by file, with total counts, numbers of detected (count > 0) and zero-count genes, mean count across all 60,660 genes (including zeros), and maximum gene count.",
  "",
  "gene-summary.csv contains one row per ENSG gene in original order: gene_id, total_counts, detected_files, zero_files, mean_count, and max_count. Each gene is aggregated across all 1,231 files. Mean count equals total counts divided by 1,231, including zero-count files; detected_files and zero_files sum to 1,231 for every gene.",
  "",
  sprintf("Across all %s ENSG gene/file cells, total unstranded counts were %s and zero-count values numbered %s. There were %s genes detected in at least one file and %s genes with zero counts in every file. The largest individual gene/file count was %s.", format(length(raw$files) * sum(gene_rows), scientific = FALSE, trim = TRUE), format(sum(gene_summary$total_counts), scientific = FALSE, trim = TRUE), format(sum(gene_summary$zero_files), scientific = FALSE, trim = TRUE), format(sum(gene_summary$detected_files > 0), scientific = FALSE, trim = TRUE), format(sum(gene_summary$detected_files == 0), scientific = FALSE, trim = TRUE), format(max(gene_summary$max_count), scientific = FALSE, trim = TRUE)),
  "",
  "## Interpretation limits",
  "This is a descriptive file-level analysis. Filenames identify input files and must not be treated as independent patients; unique patient counts and independence were not established. Raw count summaries can reflect library size and other technical differences and do not establish biological differences. No differential-expression model, biological group comparison, protein identification, or clinical conclusion was performed or is supported by these summaries."
)
base::writeLines(research_report, con = "research-report.md")
print(list(dimensions = dim(gene_summary), total_counts = sum(gene_summary$total_counts), zero_gene_values = sum(gene_summary$zero_files), genes_detected_any_file = sum(gene_summary$detected_files > 0), genes_zero_all_files = sum(gene_summary$detected_files == 0)))
#> $dimensions
#> [1] 60660     6
#> $total_counts
#> [1] 71357946062
#> $zero_gene_values
#> [1] 34425437
#> $genes_detected_any_file
#> [1] 58048
#> $genes_zero_all_files
#> [1] 2612
