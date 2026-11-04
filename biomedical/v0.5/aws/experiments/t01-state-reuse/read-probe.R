# Measure readRDS only; package/process startup is outside the timed interval.
args = commandArgs(TRUE)
library(Matrix)
library(jsonlite)
started = proc.time()[['elapsed']]
raw = readRDS(args[[1]])
read_seconds = proc.time()[['elapsed']] - started
stopifnot(is.list(raw), inherits(raw$counts, 'dgCMatrix'),
          ncol(raw$counts) == nrow(raw$metadata), nrow(raw$counts) == nrow(raw$features))
cat(toJSON(list(read_seconds = read_seconds, object_bytes = as.numeric(object.size(raw)),
                cells = ncol(raw$counts), genes = nrow(raw$counts),
                nonzero = length(raw$counts@x), total_umi = sum(raw$counts@x)),
           auto_unbox = TRUE, digits = 16), '\n')
