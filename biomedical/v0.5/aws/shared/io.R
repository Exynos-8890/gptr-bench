# Instrumentation for isolated benchmark children, including base::readRDS calls.
bench_io_start = function(path, arm, request = 0L) {
  stopifnot(requireNamespace("jsonlite", quietly = TRUE))
  state = new.env(parent = baseenv())
  state$path = normalizePath(path, mustWork = FALSE)
  state$arm = arm
  state$request = request
  state$finish = function(operation, file, started, started_unix, success = TRUE) {
    filename = if (is.character(file) && length(file) == 1L) file else "<connection>"
    if (!startsWith(filename, "<")) filename = normalizePath(filename, mustWork = FALSE)
    bytes = if (file.exists(filename)) unname(file.info(filename)$size) else NULL
    event = list(operation = operation, arm = state$arm, request = state$request,
                 pid = Sys.getpid(), file = filename, bytes = bytes,
                 started_unix = started_unix, finished_unix = as.numeric(Sys.time()),
                 success = success,
                 duration_ms = 1000 * (proc.time()[["elapsed"]] - started),
                 scope = "serialization_or_deserialization_not_pure_disk_io")
    cat(jsonlite::toJSON(event, auto_unbox = TRUE, null = "null"), "\n",
        file = state$path, append = TRUE, sep = "")
  }
  # readRDS itself replaces on.exit(), so trace(exit=) silently loses its timer.
  # These wrappers exist only in the disposable child and restore the base bindings.
  originals = lapply(c("readRDS", "saveRDS"), get, envir = baseenv())
  names(originals) = c("readRDS", "saveRDS")
  wrap = function(operation) {
    original = originals[[operation]]
    replacement = if (identical(operation, "readRDS")) {
      function(file, refhook = NULL) {
        started = proc.time()[["elapsed"]]
        started_unix = as.numeric(Sys.time())
        success = FALSE
        on.exit(state$finish("readRDS", file, started, started_unix, success), add = TRUE)
        value = original(file, refhook = refhook)
        success = TRUE
        value
      }
    } else {
      function(object, file = "", ascii = FALSE, version = NULL,
               compress = TRUE, refhook = NULL) {
        started = proc.time()[["elapsed"]]
        started_unix = as.numeric(Sys.time())
        success = FALSE
        on.exit(state$finish("saveRDS", file, started, started_unix, success), add = TRUE)
        value = original(object, file, ascii = ascii, version = version,
                         compress = compress, refhook = refhook)
        success = TRUE
        invisible(value)
      }
    }
    stopifnot(identical(names(formals(replacement)), names(formals(original))))
    unlockBinding(operation, baseenv())
    assign(operation, replacement, envir = baseenv())
    lockBinding(operation, baseenv())
  }
  lapply(names(originals), wrap)
  state$stop = function() {
    for (operation in names(originals)) {
      unlockBinding(operation, baseenv())
      assign(operation, originals[[operation]], envir = baseenv())
      lockBinding(operation, baseenv())
    }
    invisible(NULL)
  }
  invisible(state)
}
