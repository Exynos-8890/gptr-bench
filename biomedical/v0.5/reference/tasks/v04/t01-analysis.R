# T01参考分析：先加载raw，按顺序执行，结果写入当前目录。
# 花括号只划分20个执行步骤，不创建新环境。

# 1. 定义CSV写出函数（第1轮）
{
  emit = function(x, path) utils::write.csv(x, path, row.names = FALSE)
  environment(emit) = baseenv()
}

# 2. 计算细胞QC指标（第1轮）
{
  qc = data.frame(barcode = raw$metadata$barcode, n_count = Matrix::colSums(raw$counts), n_feature = Matrix::colSums(raw$counts >
    0))
  emit(qc, "cell-qc.csv")
}

# 3. 汇总队列规模（第1轮）
{
  cohort_audit = data.frame(n_cells = ncol(raw$counts), n_genes = nrow(raw$counts), patients = length(unique(raw$metadata$Patient)),
    total_umi = sum(qc$n_count), nonzero = length(raw$counts@x))
  emit(cohort_audit, "cohort-audit.csv")
}

# 4. 定义患者层面的细胞组成计算（第1轮）
{
  composition_fn = function(metadata, qc, umi, genes, immune_only = TRUE) {
    d = metadata[qc$n_count >= umi & qc$n_feature >= genes, c("Patient", "Tissue", "Treatment", "MajorCellType")]
    names(d)[4] = "lineage"
    if (immune_only)
      d = d[d$lineage %in% c("T", "B", "Mye", "ILC"), ]
    key = interaction(d$Patient, d$Tissue, d$Treatment, drop = TRUE)
    tab = as.data.frame(table(key, factor(d$lineage, levels = c("T", "B", "Mye", "ILC"))), stringsAsFactors = FALSE)
    first = match(levels(key), as.character(key))
    meta = d[first, c("Patient", "Tissue", "Treatment")]
    tab = cbind(meta[match(tab$key, levels(key)), , drop = FALSE], lineage = as.character(tab$Var2),
      n_cells = tab$Freq)
    denominator = if (immune_only)
      stats::ave(tab$n_cells, interaction(tab$Patient, tab$Tissue, tab$Treatment), FUN = sum)
    else {
      allmeta = metadata[qc$n_count >= umi & qc$n_feature >= genes, ]
      totals = table(paste(allmeta$Patient, allmeta$Tissue, allmeta$Treatment, sep = "|"))
      as.numeric(totals[paste(tab$Patient, tab$Tissue, tab$Treatment, sep = "|")])
    }
    tab$denominator = denominator
    tab$proportion = tab$n_cells/pmax(1, denominator)
    rownames(tab) = NULL
    tab
  }
  environment(composition_fn) = baseenv()
}

# 5. 计算免疫细胞比例（第1轮）
{
  composition = composition_fn(raw$metadata, qc, 1000, 500, TRUE)
}

# 6. 写出患者与组成表（第1轮）
{
  emit(composition, "patient-composition.csv")
  patient_audit = unique(composition[c("Patient", "Tissue", "Treatment")])
  emit(patient_audit, "patient-audit.csv")
}

# 7. 选取治疗前配对组织（第2轮）
{
  tissue = composition[composition$Treatment == "I" & composition$Tissue %in% c("Normal", "Tumor"),
    ]
}

# 8. 列出配对患者（第2轮）
{
  pair_audit = do.call(rbind, lapply(c("T", "B", "Mye", "ILC"), function(lineage) {
    d = tissue[tissue$lineage == lineage, ]
    pairs = intersect(d$Patient[d$Tissue == "Normal"], d$Patient[d$Tissue == "Tumor"])
    data.frame(lineage = lineage, n_pairs = length(pairs), patients = paste(sort(pairs), collapse = ";"))
  }))
}

# 9. 定义配对统计与患者bootstrap（第2轮）
{
  paired_fn = function(d, group_col, first, second, n_boot = 1000L) {
    do.call(rbind, lapply(c("T", "B", "Mye", "ILC"), function(lineage) {
      x = d[d$lineage == lineage & d[[group_col]] == first, c("Patient", "proportion")]
      y = d[d$lineage == lineage & d[[group_col]] == second, c("Patient", "proportion")]
      z = merge(x, y, by = "Patient", suffixes = c("_first", "_second"))
      delta = z$proportion_second - z$proportion_first
      p = if (length(delta) >= 2L && any(delta != 0))
        suppressWarnings(stats::wilcox.test(delta, exact = FALSE)$p.value)
      else 1
      boot = if (length(delta))
        replicate(n_boot, mean(sample(delta, length(delta), replace = TRUE)))
      else rep(NA_real_, n_boot)
      ci = if (length(delta))
        stats::quantile(boot, c(0.025, 0.975), names = FALSE)
      else c(NA_real_, NA_real_)
      data.frame(lineage = lineage, n_pairs = length(delta), estimate = if (length(delta))
        mean(delta)
      else NA_real_, ci_low = ci[1], ci_high = ci[2], p_value = p)
    }))
  }
  environment(paired_fn) = baseenv()
}

# 10. 估计组织间差异（第2轮）
{
  set.seed(20261027)
  tissue_result = paired_fn(tissue, "Tissue", "Normal", "Tumor")
}

# 11. 校正组织比较P值（第2轮）
{
  tissue_result$fdr = stats::p.adjust(tissue_result$p_value, "BH")
}

# 12. 写出组织比较结果（第2轮）
{
  emit(tissue_result, "tissue-comparison.csv")
  emit(pair_audit, "paired-patient-audit.csv")
}

# 13. 绘制组织组成图（第2轮）
{
  grDevices::png("tissue-composition.png", width = 1100, height = 650)
  graphics::boxplot(proportion ~ interaction(lineage, Tissue), data = tissue, las = 2, ylab = "Patient-level immune proportion")
  grDevices::dev.off()
}

# 14. 记录统计设计（第2轮）
{
  statistical_audit = data.frame(unit = "patient", contrast = "Tumor minus Normal at I", denominator = "T+B+Mye+ILC",
    ci = "patient bootstrap 1000", test = "paired Wilcoxon", multiplicity = "BH across four lineages")
  emit(statistical_audit, "statistical-audit.csv")
}

# 15. 估计纵向变化（第3轮）
{
  set.seed(20261027)
  longitudinal = paired_fn(composition[composition$Tissue == "Tumor", ], "Treatment", "I", "IV")
  longitudinal$fdr = stats::p.adjust(longitudinal$p_value, "BH")
}

# 16. 写出纵向结果（第3轮）
{
  emit(longitudinal, "longitudinal.csv")
  emit(composition[composition$Tissue == "Tumor" & composition$Treatment %in% c("I", "II", "III", "IV"),
    ], "longitudinal-patient-values.csv")
}

# 17. 计算两种敏感性分析（第3轮）
{
  set.seed(20261027)
  sensitivity = do.call(rbind, lapply(c("strict_qc", "all_cell_denominator"), function(setting) {
    d = if (setting == "strict_qc")
      composition_fn(raw$metadata, qc, 2000, 1000, TRUE)
    else composition_fn(raw$metadata, qc, 1000, 500, FALSE)
    result = paired_fn(d[d$Treatment == "I", ], "Tissue", "Normal", "Tumor")
    result$setting = setting
    result
  }))
  sensitivity$fdr = stats::p.adjust(sensitivity$p_value, "BH")
}

# 18. 汇总标记基因表达（第3轮）
{
  markers = c("CD3D", "CD3E", "MS4A1", "LYZ", "NKG7")
  idx = match(markers, raw$features$gene_symbol)
  marker_evidence = do.call(rbind, lapply(seq_along(idx), function(i) {
    values = as.numeric(raw$counts[idx[i], ]) * 1e+06/pmax(1, qc$n_count)
    d = data.frame(lineage = raw$metadata$MajorCellType, value = values)
    out = stats::aggregate(value ~ lineage, d, mean)
    out$gene = markers[i]
    out
  }))
  emit(marker_evidence, "marker-evidence.csv")
  emit(sensitivity, "sensitivity.csv")
}

# 19. 绘制纵向组成图（第3轮）
{
  grDevices::png("longitudinal-composition.png", width = 1100, height = 650)
  d = composition[composition$Tissue == "Tumor", ]
  graphics::boxplot(proportion ~ interaction(lineage, factor(Treatment, levels = c("I", "II", "III",
    "IV"))), data = d, las = 2, ylab = "Patient-level immune proportion")
  grDevices::dev.off()
}

# 20. 写出研究报告（第3轮）
{
  writeLines(c("# Patient-level immune composition study", paste("Observed cells:", cohort_audit$n_cells,
    "patients:", cohort_audit$patients), "The statistical unit is the patient. Immune denominator is T+B+Mye+ILC.",
    "Tissue comparison uses paired Normal/Tumor at I; longitudinal contrast uses paired Tumor I/IV.",
    "Effects, 1000 patient-bootstrap intervals, paired Wilcoxon P values and BH adjustments are in CSVs.",
    paste("Tissue contrasts with FDR below .05:", sum(tissue_result$fdr < 0.05)), paste("Longitudinal contrasts with FDR below .05:",
      sum(longitudinal$fdr < 0.05)), "Strict QC and all-cell denominator analyses test robustness; marker evidence is descriptive.",
    "Repeated cells are not independent biological replicates. Missing clinical response labels prevent response claims.",
    "This observational cohort does not establish treatment causality."), "research-report.md")
}

