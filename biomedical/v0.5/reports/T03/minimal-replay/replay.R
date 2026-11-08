# gptr 1.0.1 commit 5e2992b13824fbf5218428d379a336dd44acddbb
# Run with Rscript --vanilla replay.R. Setup downloads packages, not scientific data.
main = function() {
  work = tempfile("gptr-minimal-")
  lib = tempfile("gptr-library-")
  original_directory = getwd()
  on.exit({
    setwd(original_directory)
    unlink(c(work, lib), recursive = TRUE)
  }, add = TRUE)
  dir.create(work)
  setwd(work)
  Sys.setenv(R_USER_CONFIG_DIR = work, R_USER_DATA_DIR = work, R_USER_CACHE_DIR = work, GPTR_PROJECT_ROOT = work)
  # Install packages temporarily; normal completion or an R error triggers cleanup.
  dir.create(lib)
  .libPaths(c(lib, .Library), include.site = FALSE)
  Sys.setenv(R_LIBS_USER = lib, R_LIBS_SITE = "")
  options(repos = c(CRAN = "https://cloud.r-project.org"), timeout = 600)
  install.packages("remotes", lib = lib, quiet = TRUE)
  commit = "5e2992b13824fbf5218428d379a336dd44acddbb"
  remotes::install_github("Broccolito/gptr", ref = commit, auth_token = NULL,
    lib = lib, dependencies = NA, upgrade = "never", quiet = TRUE)
  library(gptr)
  print(data.frame(R = R.version.string, gptr = as.character(packageVersion("gptr")),
    commit = packageDescription("gptr")$RemoteSha))
  options(gptr.quiet = TRUE, gptr.interactive = FALSE, gptr.project_root = work)

  # Synthetic IDs stand in for data already retained in memory.
  home = new.env()
  home$x = sprintf("gene_%08d", seq_len(4000000))
  s = peter("Strip digits from existing IDs and count the remaining characters", model = gptr_fake_provider("Done"),
    envir = home, mode = "auto", tools = "minimal", .run = FALSE)

  # Measure the same start/end events and internal elapsed as the original trace.
  started = 0
  gptr_on(s, "tool_execution_start", function(event, ctx) {
    started <<- proc.time()[["elapsed"]]
  })
  gptr_on(s, "tool_execution_end", function(event, ctx) {
    outer = proc.time()[["elapsed"]] - started
    print(data.frame(outer_s = outer, internal_s = event$elapsed,
      gap_s = outer - event$elapsed, ratio = outer / event$elapsed, error = event$is_error))
  })

  # The fallback assignment is never executed: x already exists.
  # It remains visible to the code's risk analysis, as in the original T03 calls.
  gptr_on(s, "before_request", function(event, ctx) {
    gptr:::mcp_dispatch_local(list(jsonrpc = "2.0", id = 1L, method = "tools/call",
      params = list(name = "r", arguments = list(
        code = 'if (!exists("x")) x = NULL; sum(nchar(gsub("[0-9]", "", x)))'))), ctx$session)
    NULL
  })
  invisible(gptr_wait(s))
}
main()
