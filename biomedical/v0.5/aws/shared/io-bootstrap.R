# bench-rscript supplies the user's file/expression. No dataset/answer code lives here.
mode = Sys.getenv("GPTR_BENCH_PROGRAM_MODE")
program = Sys.getenv("GPTR_BENCH_PROGRAM")
if (!mode %in% c("expression", "file") || !nzchar(program)) {
  stop("Invalid benchmark R launcher arguments")
}
source(Sys.getenv("GPTR_BENCH_IO_HELPER"), local = TRUE)
io = bench_io_start(Sys.getenv("GPTR_BENCH_IO_EVENTS"), "C1",
                    as.integer(Sys.getenv("GPTR_BENCH_REQUEST", "0")))
started = proc.time()[["elapsed"]]
started_unix = as.numeric(Sys.time())
success = FALSE
connection = NULL
io$finish("rscript_start", if (identical(mode, "file")) program else "<expression>",
          started, started_unix, TRUE)
invisible(tryCatch({
  if (identical(mode, "expression")) {
    connection = textConnection(program)
    source(connection, local = globalenv(), echo = FALSE, print.eval = TRUE)
  } else {
    source(program, local = globalenv(), chdir = FALSE, echo = FALSE, print.eval = TRUE)
  }
  success = TRUE
}, finally = {
  io$finish("rscript", if (identical(mode, "file")) program else "<expression>",
            started, started_unix, success)
  io$stop()
  if (!is.null(connection)) close(connection)
}))
