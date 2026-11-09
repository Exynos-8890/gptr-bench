library(ggplot2)
a = commandArgs(TRUE)
setwd(a[1])
d = read.csv("micro-phases.csv")
calls = read.csv("micro-calls.csv")
d$y = 4 - d$request
calls$y = 4 - calls$request
colors = c("Pre-gate processing" = "#D5A04B", "Permission gate" = "#BF684B",
 "Checkpoint before" = "#7567AA", "R tool execution" = "#2776B9", "Checkpoint after" = "#27836C")
d$phase = factor(d$phase, levels = names(colors))
d$label = sprintf("%.3f s", d$duration_s)
base = ggplot() +
 geom_rect(data = calls, aes(xmin = 0, xmax = outer_s, ymin = y - .16, ymax = y + .16), fill = "#DDE2E7") +
 geom_rect(data = d, aes(xmin = start_s, xmax = end_s, ymin = y - .16, ymax = y + .16, fill = phase)) +
 scale_fill_manual(values = colors, drop = FALSE) +
 scale_y_continuous(breaks = c(2,1), labels = c("Request 2", "Request 3"), limits = c(.45,2.55)) +
 labs(x = "Seconds since this tool call started", y = NULL, fill = NULL) +
 theme_minimal(base_size = 14) +
 theme(panel.grid.major.y = element_blank(), panel.grid.minor = element_blank(),
  legend.position = "bottom", plot.title = element_text(face = "bold"),
  plot.margin = margin(14,20,12,12)) +
 guides(fill = guide_legend(nrow = 2, byrow = TRUE))
major = subset(d, phase %in% c("Pre-gate processing", "Permission gate"))
overview = base +
 geom_text(data = major, aes(x = (start_s+end_s)/2, y = y, label = sprintf("%.2f s",duration_s)), color = "#FFFFFF", size = 5, fontface = "bold") +
 geom_text(data = calls, aes(x = outer_s, y = y+.32, label = sprintf("Total %.3f s",outer_s)), hjust = 1, size = 4.4) +
 scale_x_continuous(breaks = seq(0,30,5)) + coord_cartesian(xlim = c(0,31.2)) +
 labs(title = "One tool call per request: where the time goes",
 subtitle = "AWS offline MCP replay · A1-2 · gptr 1.0.1 (5e2992b)",
 caption = "Each row starts at its own tool-start event. Grey slivers are timing/event gaps, not extra calls.")
small = subset(d, phase %in% c("Checkpoint before", "R tool execution", "Checkpoint after"))
small$label_x = (small$start_s+small$end_s)/2
small$label_y = small$y + ifelse(small$phase == "R tool execution", -.33, .33)
small$label_x[small$phase == "Checkpoint after"] = small$end_s[small$phase == "Checkpoint after"] + .24
zoom = base +
 geom_segment(data = calls, aes(x = internal_start_s, xend = internal_start_s, y = y-.22, yend = y+.22), linetype = "dashed", linewidth = .75) +
 geom_segment(data = small, aes(x = (start_s+end_s)/2, xend = label_x,
  y = y + ifelse(phase == "R tool execution", -.17, .17), yend = label_y), color = "#626B75", linewidth = .35) +
 geom_label(data = small, aes(x = label_x, y = label_y, label = label, color = phase), fill = "white", size = 4.2, label.padding = grid::unit(.17,"lines"), show.legend = FALSE) +
 scale_color_manual(values = colors, drop = FALSE) +
 scale_x_continuous(breaks = seq(26,31,1)) + coord_cartesian(xlim = c(26,31.6)) +
 labs(title = "Zoom: the final seconds inside the same call",
 subtitle = "Same timestamps, expanded axis · dashed marker: start of internal elapsed (derived)",
 caption = "Internal elapsed also includes the green checkpoint-after segment and small boundary gaps.")
ggsave("micro-gantt.png", overview, width = 12, height = 4.6, dpi = 180, bg = "white")
ggsave("micro-gantt-zoom.png", zoom, width = 12, height = 4.9, dpi = 180, bg = "white")
