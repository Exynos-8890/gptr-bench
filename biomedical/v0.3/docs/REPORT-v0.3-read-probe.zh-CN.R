args = commandArgs(TRUE)
before = loadedNamespaces()
started = proc.time()
raw = readRDS(args[[1]])
elapsed = proc.time() - started
stopifnot(inherits(raw$counts, "dgCMatrix"), identical(dim(raw$counts), c(36027L, 100000L)))
jsonlite::write_json(list(read_seconds = unname(elapsed[["elapsed"]]),
                         user_seconds = unname(elapsed[["user.self"]]),
                         system_seconds = unname(elapsed[["sys.self"]]),
                         matrix_namespace_loaded_before_read = "Matrix" %in% before,
                         matrix_namespace_loaded_after_read = "Matrix" %in% loadedNamespaces(),
                         cells = ncol(raw$counts), genes = nrow(raw$counts)),
                     args[[2]], auto_unbox = TRUE, pretty = TRUE, digits = 16)
