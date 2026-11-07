args = commandArgs(TRUE)
setwd(normalizePath(args[1]))
library(ggplot2)
library(patchwork)

# Data
runs = read.csv("all-attempts.csv")
requests = read.csv("request-stages.csv")

statistics = read.csv("group-statistics.csv")
phases = c("file_read_s", "tool_nonread_s", "harness_model_s")
phase_labels = c("File reads", "Tools excluding reads", "Harness + model + network")
arm_colors = c(A1 = "#2776B9", C1 = "#D77B35")
phase_colors = setNames(c("#27836C", "#2776B9", "#B8C2CC"), phase_labels)
summary = subset(statistics, metric %in% c("wall_s", "actual_calls"))
summary$arm = factor(summary$arm, c("C1", "A1"))
request_means = aggregate(requests[phases], requests[c("request", "arm")], mean)
stages = reshape(request_means, varying = phases, v.names = "seconds",
  timevar = "phase", times = phase_labels, direction = "long")
stages$phase = factor(stages$phase, phase_labels)
stages$arm = factor(stages$arm, c("C1", "A1"))
stages$request = paste("Request", stages$request)
request_means$total = rowSums(request_means[phases])
request_means$request = paste("Request", request_means$request)
v = sapply(c(phases, "wall_s"), function(m)
  mean(runs[runs$arm == "C1", m]) - mean(runs[runs$arm == "A1", m]))
waterfall = data.frame(label = c(phase_labels, "Net difference"), value = v,
  start = c(0, cumsum(v)[1:2], 0), end = c(cumsum(v)[1:3], v[4]), y = 4:1)
selected_trials = sapply(c("A1", "C1"), function(a) {
  z = runs[runs$arm == a, ]; z$trial[order(z$wall_s)][2]
})
timeline = read.csv("timeline.csv")
timeline$request = timeline$label
# Split tool activity at read boundaries; keep only its non-reading portions.
tools = subset(timeline, kind == "execution")
nonread = do.call(rbind, lapply(seq_len(nrow(tools)), function(i) {
  z = tools[i, ]; reads = subset(timeline, arm == z$arm & kind == "read")
  cuts = sort(unique(c(z$start, z$finish,
    pmax(z$start, pmin(z$finish, c(reads$start, reads$finish))))))
  a = head(cuts, -1); b = tail(cuts, -1); mid = (a + b) / 2
  keep = !vapply(mid, function(t) any(t >= reads$start & t < reads$finish), logical(1))
  out = z[rep(1, sum(keep)), ]; out$start = a[keep]; out$finish = b[keep]; out
}))
gantt = rbind(subset(timeline, kind != "execution"), nonread)
gantt$lane = c(request = 3, execution = 2, read = 1)[gantt$kind]
gantt$color = ifelse(gantt$kind == "request", arm_colors[gantt$arm],
  ifelse(gantt$kind == "read", phase_colors[1], phase_colors[2]))

p = {
base_theme = theme_minimal(base_size = 14) + theme(
  panel.grid.minor = element_blank(), panel.grid.major.y = element_blank(),
  plot.title = element_text(face = "bold"), legend.position = "top",
  legend.title = element_blank(), strip.text = element_text(face = "bold", hjust = 0),
  plot.margin = margin(12, 18, 12, 12))
comparison_plot = function(metric_name, title, axis_label) {
  z = subset(summary, metric == metric_name)
  ggplot(z, aes(x = median, y = arm, fill = arm)) +
    geom_col(width = .5) +
    geom_segment(aes(x = minimum, xend = maximum, yend = arm), linewidth = 1) +
    geom_point(aes(x = minimum), shape = 124, size = 7) +
    geom_point(aes(x = maximum), shape = 124, size = 7) +
    geom_point(shape = 21, size = 4, fill = "white") +
    geom_text(aes(x = maximum, label = sprintf("  %.2f [%.2f, %.2f]", median, minimum, maximum)),
      hjust = 0, size = 4) +
    scale_fill_manual(values = arm_colors) +
    scale_x_continuous(limits = c(0, max(z$maximum) * 1.65), expand = expansion(mult = 0)) +
    labs(title = title, x = axis_label, y = NULL) + base_theme + theme(legend.position = "none")
}
comparison_plot("wall_s", "Total wall time", "Seconds") /
  comparison_plot("actual_calls", "Actual tool calls", "Calls") +
  plot_annotation(subtitle = "Median [minimum, maximum] · Three runs per arm")
}
ggsave("comparison.png", p, width=11, height=7, dpi=180, bg="white")
p = {
ggplot(stages, aes(seconds, arm, fill = phase)) +
  geom_col(width = .55, position = position_stack(reverse = TRUE)) +
  geom_text(data = request_means, aes(total, arm, label = sprintf("  %.2f s", total)),
    inherit.aes = FALSE, hjust = 0, size = 4) +
  facet_grid(request ~ .) + scale_fill_manual(values = phase_colors) +
  scale_x_continuous(expand = expansion(mult = c(0, .18))) +
  labs(title = "Time per request", x = "Seconds · Mean of three runs", y = NULL) + base_theme
}
ggsave("request-stages.png", p, width=11, height=7, dpi=180, bg="white")
p = {
ggplot(waterfall) +
  geom_vline(xintercept = 0, color = "#8799AA") +
  geom_rect(aes(xmin = pmin(start, end), xmax = pmax(start, end),
    ymin = y - .25, ymax = y + .25, fill = label)) +
  geom_segment(data = waterfall[1:2, ], aes(x = end, xend = end, y = y - .25, yend = y - .75),
    linetype = "dashed", color = "#8799AA") +
  geom_text(aes(x = pmax(start, end) + 5, y = y, label = sprintf("%+.2f s", value)), hjust = 0) +
  scale_fill_manual(values = c(phase_colors, "Net difference" = arm_colors[["C1"]])) +
  scale_y_continuous(breaks = 4:1, labels = waterfall$label) +
  scale_x_continuous(expand = expansion(mult = c(.02, .28))) +
  labs(title = "Where the time difference comes from", subtitle = "C1 minus A1 · Positive means C1 is slower",
    x = "Seconds · Difference between means", y = NULL) + base_theme + theme(legend.position = "none")
}
ggsave("signed-time.png", p, width=11, height=4.5, dpi=180, bg="white")
p = {
ggplot(gantt) +
  geom_rect(aes(xmin = start, xmax = finish, ymin = lane - .25, ymax = lane + .25, fill = color)) +
  geom_segment(data = subset(gantt, kind == "request"),
    aes(x = start, xend = start, y = 2.75, yend = 3.25), color = "white", linewidth = .35) +
  geom_text(data = subset(gantt, kind == "request"),
    aes((start + finish) / 2, lane, label = paste0("R", request)), color = "white", fontface = "bold") +
  facet_grid(arm ~ .) + scale_fill_identity() +
  scale_y_continuous(breaks = 1:3, labels = c("File reads", "Tools excl. reads", "Requests")) +
  scale_x_continuous(expand = expansion(mult = c(.01, .02))) +
  labs(title = "Actual timeline of each arm's median-duration run",
    subtitle = "Green: reads · Blue: tools excluding reads · Shared time scale",
    x = "Seconds since run start", y = NULL) + base_theme
}
ggsave("gantt.png", p, width=11, height=6.5, dpi=180, bg="white")
