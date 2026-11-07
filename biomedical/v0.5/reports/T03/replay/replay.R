# Strict offline code replay; no model requests. Use a new output directory.
a = commandArgs(TRUE)
script = sub("^--file=", "", grep("^--file=", commandArgs(), value = TRUE))
bundle = normalizePath(dirname(script))
input = normalizePath(a[1]); work = a[2]; trial = if (length(a) >= 3) a[3] else "A1-2"
dir.create(work, recursive = TRUE, showWarnings = FALSE)
work = normalizePath(work)
files = list.files(input, pattern = "[.]tsv$|^input-files[.]txt$", full.names = TRUE)
file.symlink(files, file.path(work, basename(files)))
file.copy(file.path(bundle, trial, "recorded.R"), file.path(work, "recorded.R"))
Sys.setenv(GPTR_REPLAY = "replay")
pkgload::load_all(Sys.getenv("GPTR_SOURCE"), quiet = TRUE, helpers = FALSE, attach_testthat = FALSE)
setwd(work)
gptr_source("recorded.R", replay = "replay", envir = new.env(parent = globalenv()))
# A1-1's final write tool is outside native R blocks; restore its recorded content.
calls = jsonlite::read_json(file.path(bundle, trial, "calls.json"))$calls
for (x in Filter(function(x) x$tool == "write", calls)) {
  writeChar(x$input$content, x$input$path, eos = NULL, useBytes = TRUE)
}
