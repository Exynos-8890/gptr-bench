# Offline A1-2 tool-input replay through the pinned gptr MCP dispatcher.
# No native-document replay and no live model; retain default checkpoint settings.
a = commandArgs(TRUE)
work = normalizePath(a[1]); calls_path = normalizePath(a[2]); aws = normalizePath(a[3])
smoke = length(a) > 3 && a[4] == "smoke"
setwd(work)
Sys.setenv(R_USER_CONFIG_DIR = file.path(work, "private/config"),
 R_USER_DATA_DIR = file.path(work, "private/data"), R_USER_CACHE_DIR = file.path(work, "private/cache"),
 GPTR_PROJECT_ROOT = work, GPTR_REPLAY = "live", GPTR_BENCH_INPUT_FORMAT = "star-counts-native")
options(gptr.quiet = TRUE, gptr.interactive = FALSE, gptr.project_root = work)
pkgload::load_all(Sys.getenv("GPTR_SOURCE"), quiet = TRUE, helpers = FALSE, attach_testthat = FALSE)
ns = asNamespace("gptr")
source(file.path(aws, "shared/io.R"))
io = bench_io_start(file.path(work, "io.jsonl"), "A1-replay", 0L)
loadNamespace("Matrix")
calls = jsonlite::read_json(calls_path)
clock = function() as.numeric(proc.time()[["elapsed"]])
state = new.env(); state$request = 0L; state$starts = list(); state$rows = list()
emit = function(x, file) cat(jsonlite::toJSON(x, auto_unbox = TRUE, digits = 16, null = "null"), "\n", file = file, append = TRUE)
profile_mark = function(fn, stage) emit(list(request = state$request, function_name = fn, stage = stage,
 elapsed_clock_s = clock(), unix = as.numeric(Sys.time())), "profile.jsonl")
# Timing-only runtime instrumentation; the package checkout is unchanged.
for (fn in c("mcp_serve_gate", "checkpoint_before", "checkpoint_after", "ckpt_objects_before",
 "ckpt_files_before", "env_snapshot", "ckpt_write_image", "mcp_serve_r")) {
 trace(fn, where = ns, print = FALSE,
  tracer = substitute(get("profile_mark", .GlobalEnv)(FN, "enter"), list(FN = fn)),
  exit = substitute(get("profile_mark", .GlobalEnv)(FN, "exit"), list(FN = fn)))
}
keep = function(event, ctx = NULL) {
 t = clock()
 emit(list(request = state$request, elapsed_clock_s = t, event = event), "events.jsonl")
 if (event$type == "tool_execution_start") state$starts[[event$tool_call_id]] = t
 if (event$type == "tool_execution_end") {
  outer = t - state$starts[[event$tool_call_id]]
  state$rows[[length(state$rows) + 1L]] = data.frame(request = state$request,
    outer_s = outer, internal_elapsed_s = event$elapsed, gap_s = outer-event$elapsed,
    is_error = isTRUE(event$is_error))
  write.csv(do.call(rbind, state$rows), "timing.csv", row.names = FALSE)
 }
 NULL
}
gptr_register(gptr_hook("tool_execution_start", keep))
gptr_register(gptr_hook("tool_execution_end", keep))
gptr_register(gptr_hook("before_request", function(event, ctx) {
 state$request = state$request + 1L
 io$request = state$request
 input = calls$calls[[state$request]]$input
 if (smoke) input = list(code = c("x = 1:10", "y = sum(x)", "z = y + 1")[[state$request]])
 params = list(name = "r", arguments = input)
 params[["_meta"]] = list("io.modelcontextprotocol/protocolVersion" = "2026-07-28",
  "io.modelcontextprotocol/clientCapabilities" = structure(list(), names = character()),
  "io.modelcontextprotocol/clientInfo" = list(name = "offline-a1-replay", version = "1"))
 result = get("mcp_dispatch_local", ns)(list(jsonrpc = "2.0", id = 2L,
   method = "tools/call", params = params), ctx$session)
 emit(list(request = state$request, result = result), "rpc-results.jsonl")
 if (!is.null(result$error) || isTRUE(result$result$isError)) stop("Recorded MCP call failed; see rpc-results.jsonl")
 NULL
}))
fake = gptr_fake_provider(list("Recorded tool call completed offline."), name = "mcp-trace-replay")
home = new.env(parent = globalenv())
s = peter(calls$prompts[[1]], model = fake, mode = "auto", tools = "minimal", envir = home)
for (i in 2:3) peter(s, prompt = calls$prompts[[i]])
io$stop()
jsonlite::write_json(list(status = "completed", trial = "A1-2", source = Sys.getenv("GPTR_SOURCE"),
 checkpoint = get("setting_get", ns)("checkpoint", default = "on"), smoke = smoke,
 model_requests = 0, route = "mcp_dispatch_local from before_request; offline provider, no CLI transport",
 limitation = "Fake-provider route differs from original CLI file-watcher lifecycle; original tool inputs unchanged."),
 "result.json", auto_unbox = TRUE, pretty = TRUE)
