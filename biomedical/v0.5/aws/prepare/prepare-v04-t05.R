# The original candidate lacks coordinates. Freeze a verified same-phenotype public replacement.
prepare_v04_t05 = function(source_dir, output_dir) {
  source("biomedical/prepare-v04-genetics-utils.R", local = TRUE)
  base = paste0("https://ftp.ebi.ac.uk/pub/databases/gwas/summary_statistics/",
                "GCST006001-GCST007000/GCST006900/")
  filename = "Meta-analysis_Locke_et_al+UKBiobank_2018_UPDATED.txt.gz"
  urls = c(paste0(base, filename),
           paste0(base, "README_summary_statistics_Yengo_et_al_2018.txt"),
           "https://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_19/gencode.v19.annotation.gtf.gz",
           "https://maayanlab.cloud/Enrichr/geneSetLibrary?mode=text&libraryName=Reactome_2022")
  names = c(filename, "README_summary_statistics_Yengo_et_al_2018.txt",
             "gencode.v19.annotation.gtf.gz", "Reactome_2022.gmt")
  paths = mapply(v04_fetch, urls, file.path(source_dir, names), USE.NAMES = FALSE)
  readme = paste(readLines(paths[2L], encoding = "UTF-8"), collapse = "\n")
  stopifnot(grepl("hg19", readme, fixed = TRUE))
  data = utils::read.table(gzfile(paths[1L]), header = TRUE, stringsAsFactors = FALSE,
                            check.names = FALSE, comment.char = "", quote = "")
  required = c("SNP", "CHR", "POS", "Tested_Allele", "Other_Allele", "BETA", "SE", "P")
  if (!all(required %in% names(data))) stop("Unexpected GCST006900 columns; inspect frozen README")
  association = data.frame(id = data$SNP, chr = as.character(data$CHR),
    position = data$POS, effect_allele = toupper(data$Tested_Allele),
    other_allele = toupper(data$Other_Allele), beta = data$BETA, se = data$SE, p = data$P)
  genes = v04_gtf_genes(paths[3L])
  genes$tss = ifelse(genes$strand == "-", genes$end, genes$start)
  fields = strsplit(readLines(paths[4L], encoding = "UTF-8"), "\t", fixed = TRUE)
  pathways = stats::setNames(lapply(fields, function(x) unique(x[-c(1L, 2L)])),
                              vapply(fields, `[`, "", 1L))
  stopifnot(length(pathways) >= 100L, nrow(genes) >= 10000L, nrow(association) >= 100000L)
  raw = list(associations = association, genes = genes, pathways = pathways,
               genome_build = "GRCh37", accession = "GCST006900")
  v04_save_input(raw, output_dir, "GCST006900 BMI Yengo2018",
    Map(v04_source_record, paths, urls),
    list(variants = nrow(association), genes = nrow(genes), pathways = length(pathways),
      genome_build = "GRCh37", planned_candidate = "GCST009004",
      replacement_reason = paste("GCST009004 original table lacks CHR/POS; harmonised directory",
        "returned404. GCST006900 is a real same-phenotype BMI meta-analysis with official hg19",
        "coordinate columns, verified before data preparation.")))
}

if (sys.nframe() == 0L) {
  args = commandArgs(TRUE)
  prepare_v04_t05(args[[1L]], args[[2L]])
}
