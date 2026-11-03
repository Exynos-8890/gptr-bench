# Load only the selected task in the benchmark child; never provide references to agents.
v04_load = function(id, bench, envir = parent.frame()) {
  filename = file.path(bench, "tasks", "v04", paste0(tolower(id), ".R"))
  source(filename, local = envir)
  task = get(paste0("v04_", tolower(id)), envir = envir)()
  if (!is.null(task$script)) {
    blocks = parse(file.path(dirname(filename), task$script), keep.source = TRUE)
    task$steps = Map(function(step, code) {
      step$code = paste(as.character(code), collapse = "\n")
      step
    }, task$steps, attr(blocks, "srcref"))
  }
  task$instructions = ""
  task$prompts = jsonlite::read_json(file.path(bench, "v0.5", "aws", "prompts.json"))[[id]]
  catalog = jsonlite::read_json(file.path(bench, "v04-tasks.json"))
  record = Filter(function(x) identical(x$id, id), catalog$tasks)[[1L]]
  task$packages = unique(c(unlist(task$packages), unlist(record$packages)))

  task
}

v04_check = function(id, workspace, raw, bench) {
  task = v04_load(id, bench)
  files = file.path(workspace, unlist(task$artifacts))
  missing = !file.exists(files) | is.na(file.info(files)$size) | file.info(files)$size <= 0
  if (any(missing)) {
    return(list(ok = FALSE, checks = list(required_artifacts = FALSE),
                failures = paste("Missing/empty artifact:", basename(files[missing]))))
  }
  if (!is.null(task$script)) {
    source(file.path(bench, "tasks", "v04", paste0(tolower(id), "-check.R")), local = TRUE)
  }
  checker = get(paste0("v04_check_", tolower(id)))
  result = checker(workspace, raw)
  result$checks$required_artifacts = TRUE
  result
}
