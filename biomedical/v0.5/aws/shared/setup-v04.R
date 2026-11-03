cran = c("jsonlite", "curl", "processx", "callr", "rlang", "cli", "yaml", "ps",
         "pkgload", "withr", "Matrix", "survival", "glmnet", "openssl", "readxl", "testthat")
bioc = c("limma", "edgeR")
if ("--install" %in% commandArgs(TRUE)) {
  needed = setdiff(cran, rownames(utils::installed.packages()))
  if (length(needed)) utils::install.packages(needed, repos = "https://cloud.r-project.org")
  needed = setdiff(bioc, rownames(utils::installed.packages()))
  if (length(needed)) {
    if (!requireNamespace("BiocManager", quietly = TRUE)) {
      utils::install.packages("BiocManager", repos = "https://cloud.r-project.org")
    }
    BiocManager::install(needed, ask = FALSE, update = FALSE)
  }
}
packages = c(cran, bioc)
invisible(lapply(packages, loadNamespace))
print(data.frame(package = packages,
  version = vapply(packages, function(p) as.character(utils::packageVersion(p)), "")))
cat(R.version.string, "\n")
