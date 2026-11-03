# Deterministic stratified cell selection.
t01_select = function(metadata, cells = 150000L, seed = 20261031L) {
  fields = c("Patient", "Tissue", "Treatment", "MajorCellType")
  labels = lapply(metadata[fields], function(x) ifelse(is.na(x), "<missing>", x))
  key = do.call(paste, c(labels, sep = "|"))
  groups = sort(unique(key))
  group = match(key, groups)
  sizes = tabulate(group, length(groups))
  capacity = sizes - 1L
  allocation = if (sum(capacity)) (as.double(cells) - length(groups)) * capacity / sum(capacity) else
    rep(0, length(groups))
  quotas = 1L + floor(allocation)
  remaining = cells - sum(quotas)
  if (remaining) {
    eligible = which(quotas < sizes)
    rank = eligible[order(-(allocation[eligible] - floor(allocation[eligible])),
                          groups[eligible], method = "radix")]
    quotas[rank[seq_len(remaining)]] = quotas[rank[seq_len(remaining)]] + 1L
  }
  hashes = as.character(openssl::sha256(paste0(seed, "|", rownames(metadata))))
  ranked = order(group, hashes, rownames(metadata), method = "radix")
  within = sequence(sizes)
  selected = sort(ranked[within <= quotas[group[ranked]]])
  list(selected = selected, quotas = data.frame(stratum = groups, source_cells = sizes,
    selected_cells = as.integer(quotas), inclusion_fraction = quotas / sizes))
}
