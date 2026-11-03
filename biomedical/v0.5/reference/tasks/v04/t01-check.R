v04_check_t01 = function(workspace, raw) {
  failures = character()
  checks = list()
  check = function(name, value) {
    checks[[name]] <<- isTRUE(value)
    if (!isTRUE(value)) failures <<- c(failures, name)
  }
  tryCatch({
    read = function(name) utils::read.csv(file.path(workspace,name),stringsAsFactors=FALSE)
    qc = read('cell-qc.csv')
    comp = read('patient-composition.csv')
    tissue = read('tissue-comparison.csv')
    long = read('longitudinal.csv')
    audit = read('cohort-audit.csv')
    check('cell_alignment',identical(as.character(qc$barcode),raw$metadata$barcode))
    check('cell_qc_totals',isTRUE(all.equal(as.numeric(qc$n_count),as.numeric(Matrix::colSums(raw$counts)),tolerance=0)))
    check('detected_genes',identical(as.numeric(qc$n_feature),as.numeric(Matrix::colSums(raw$counts>0))))
    check('dimensions',audit$n_cells==ncol(raw$counts) && audit$n_genes==nrow(raw$counts))
    key = paste(comp$Patient,comp$Tissue,comp$Treatment,sep='|')
    check('immune_denominator',all(abs(tapply(comp$proportion,key,sum)-1)<1e-10))
    check('count_proportions',all(abs(comp$proportion-comp$n_cells/comp$denominator)<1e-10))
    keep = qc$n_count>=1000 & qc$n_feature>=500 & raw$metadata$MajorCellType %in% c('T','B','Mye','ILC')
    check('no_missing_immune_cells',sum(comp$n_cells)==sum(keep))
    source_keys = paste(raw$metadata$Patient, raw$metadata$Tissue,
                         raw$metadata$Treatment, raw$metadata$MajorCellType, sep = '|')
    observed_counts = table(source_keys[keep])
    output_keys = paste(comp$Patient, comp$Tissue, comp$Treatment, comp$lineage, sep = '|')
    expected_counts = as.numeric(observed_counts[output_keys])
    expected_counts[is.na(expected_counts)] = 0
    check('patient_lineage_counts', identical(as.numeric(comp$n_cells), expected_counts))
    compare_pairs = function(table, first, second, column, restrict) {
      d = comp[restrict, ]
      all(vapply(seq_len(nrow(table)), function(i) {
        x = d[d$lineage == table$lineage[i] & d[[column]] == first,
                c('Patient', 'proportion')]
        y = d[d$lineage == table$lineage[i] & d[[column]] == second,
                c('Patient', 'proportion')]
        paired = merge(x, y, by = 'Patient')
        delta = paired$proportion.y - paired$proportion.x
        expected = if (length(delta)) mean(delta) else NA_real_
        valid_effect = if (is.na(expected)) is.na(table$estimate[i]) else
          abs(table$estimate[i] - expected) < 1e-8
        valid_effect && table$n_pairs[i] == length(delta)
      }, logical(1)))
    }
    check('tissue_paired_effect', compare_pairs(tissue, 'Normal', 'Tumor', 'Tissue',
                                                comp$Treatment == 'I'))
    check('longitudinal_paired_effect', compare_pairs(long, 'I', 'IV', 'Treatment',
                                                      comp$Tissue == 'Tumor'))
    check('four_lineages',setequal(tissue$lineage,c('T','B','Mye','ILC')))
    check('fdr',isTRUE(all.equal(tissue$fdr,stats::p.adjust(tissue$p_value,'BH'),tolerance=1e-6)))
    check('patient_not_cell_units',all(tissue$n_pairs<=length(unique(raw$metadata$Patient))))
    check('valid_intervals',all(is.na(tissue$estimate) | tissue$ci_low<=tissue$ci_high))
    check('longitudinal_fdr',isTRUE(all.equal(long$fdr,stats::p.adjust(long$p_value,'BH'),tolerance=1e-6)))
    sensitivity = read('sensitivity.csv')
    check('both_sensitivities',setequal(sensitivity$setting,c('strict_qc','all_cell_denominator')))
    check('marker_evidence',setequal(read('marker-evidence.csv')$gene,c('CD3D','CD3E','MS4A1','LYZ','NKG7')))
    check('report_exists',file.info(file.path(workspace,'research-report.md'))$size>100)
  },error=function(e) failures <<- c(failures,conditionMessage(e)))
  list(ok=length(failures)==0L,checks=checks,failures=failures)
}
