# One persistent R session, three shared prompts, no reference answer or scoring code.
bench_json = function(x, path) {
  jsonlite::write_json(x, path, auto_unbox = TRUE, pretty = TRUE, null = "null",
                       na = "null", digits = 16)
}
bench_now = function() as.numeric(proc.time()[["elapsed"]])

bench_main = function() {
  cfg = jsonlite::read_json(commandArgs(TRUE)[[2L]])
  aws = cfg$aws
  prompts = jsonlite::read_json(cfg$prompt_file)[[cfg$task_id]]
  setwd(cfg$workspace)
  Sys.setenv(R_USER_CONFIG_DIR = file.path(cfg$private, "config"),
             R_USER_DATA_DIR = file.path(cfg$private, "data"),
             R_USER_CACHE_DIR = file.path(cfg$private, "cache"),
             GPTR_PROJECT_ROOT = cfg$workspace, GPTR_REPLAY = "live")
  options(gptr.quiet = TRUE, gptr.interactive = FALSE, gptr.project_root = cfg$workspace,
          gptr.cli_turn_timeout = cfg$timeout)
  pkgload::load_all(cfg$gptr_source, quiet = TRUE, helpers = FALSE, attach_testthat = FALSE)
  if (is.null(model_resolve(cfg$model, strict = FALSE))) {
    gptr_register(gptr_spec("model", cfg$model, label = cfg$model,
      context = 272000, max_output = 64000, input = "text", tool_call = TRUE, reasoning = TRUE))
  }
  gptr_config(egress = list(codex = "ack"), .scope = "user")
  gptr_config(budget = list(tokens = cfg$token_limit, cost = cfg$cost_limit, turns = 100),
              .scope = "session")
  source(file.path(aws, "shared", "io.R"), local = TRUE)
  io = bench_io_start(cfg$io_events, "A1", 0L)
  on.exit(io$stop(), add = TRUE)
  loadNamespace("Matrix")
  bench_json(list(unix = as.numeric(Sys.time())), cfg$ready)
  home = new.env(parent = globalenv())
  started = bench_now()
  home$raw = readRDS(cfg$input)
  load_ms = 1000 * (bench_now() - started)
  trace = file(cfg$trace, "at")
  on.exit(close(trace), add = TRUE)
  seen = new.env(parent = emptyenv())
  seen$turn = 1L
  seen$r_calls = 0L
  seen$all_calls = 0L
  seen$errors = 0L
  seen$starts = list()
  seen$tool_ms = 0
  seen$budget = FALSE
  record = function(event, ctx = NULL) {
    if (identical(event$type, "tool_execution_start")) seen$all_calls = seen$all_calls + 1L
    if (identical(event$type, "tool_execution_start") && identical(event$tool_name, "r")) {
      seen$r_calls = seen$r_calls + 1L
      seen$starts[[event$tool_call_id]] = bench_now()
    }
    if (identical(event$type, "tool_execution_end") && identical(event$tool_name, "r")) {
      seen$errors = seen$errors + as.integer(isTRUE(event$is_error))
      seen$tool_ms = seen$tool_ms + 1000 * (bench_now() - seen$starts[[event$tool_call_id]])
    }
    if (!is.null(event$message$content)) {
      event$message$content = Filter(function(b) b$type %in% c("text", "tool_call"),
                                      event$message$content)
    }
    line = list(schema_version = 1L, task = cfg$task_id, arm = "A1", turn = seen$turn,
      dataset_sha256 = cfg$dataset_sha256, time_ms = 1000 * (bench_now() - started),
      type = event$type, data = event)
    writeLines(jsonlite::toJSON(line, auto_unbox = TRUE, null = "null", na = "null"), trace)
    flush(trace)
  }

  s = peter(prompt = prompts[[1L]], model = cfg$model,
            mode = "auto", tools = "minimal", envir = home, .run = FALSE)
  for (event in c("message_end", "tool_execution_start", "tool_execution_end", "usage")) {
    gptr_on(s, event, record)
  }
  failure = NULL
  tryCatch({
    for (turn in seq_along(prompts)) {
      seen$turn = turn
      io$request = turn
      record(list(type = "request_start", prompt = prompts[[turn]], unix = as.numeric(Sys.time())))
      if (turn == 1L) gptr_wait(s) else peter(s, prompt = prompts[[turn]])
      record(list(type = "request_end", unix = as.numeric(Sys.time()), status = s$status))
      used = sum(s$usage$input + s$usage$cache_read + s$usage$cache_write_5m +
                   s$usage$cache_write_1h + s$usage$output)
      if (isTRUE(used > cfg$token_limit)) {
        seen$budget = TRUE
        stop("Task token ceiling reached")
      }
      if (!identical(s$status, "idle")) stop("Peter ended with status: ", s$status)
    }
  }, error = function(e) failure <<- conditionMessage(e))
  bench_json(s$usage, file.path(dirname(cfg$result), "usage.json"))
  metrics = list(arm = "A1", pid = Sys.getpid(), dataset_load_ms = load_ms,
    tool_calls = seen$r_calls, r_tool_calls = seen$r_calls, all_tool_calls = seen$all_calls,
    tool_wall_ms = seen$tool_ms, tool_errors = seen$errors, provider_requests = nrow(s$usage),
    input_tokens = sum(s$usage$input + s$usage$cache_read + s$usage$cache_write_5m + s$usage$cache_write_1h),
    output_tokens = sum(s$usage$output), cost = NULL, budget_exceeded = seen$budget,
    review_status = "pending", error = failure)
  bench_json(metrics, cfg$result)
  if (!is.null(failure)) stop(failure, call. = FALSE)
}

if (sys.nframe() == 0L) bench_main()
