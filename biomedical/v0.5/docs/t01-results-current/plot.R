args = commandArgs(TRUE)
root = normalizePath(args[[1]])
stats = read.csv(file.path(root, "group-statistics.csv"))
delta = read.csv(file.path(root, "additive-mean-differences.csv"))
timeline = read.csv(file.path(root, "timeline.csv"))
ink = "#243544"; muted = "#657688"; grid = "#E3EAF0"
blue = "#2776B9"; orange = "#D77B35"; green = "#27836C"; gray = "#8799AA"
begin = function(name, height = 800, left = 7) {
 png(file.path(root, name), width = 1800, height = height, res = 150, type = "cairo", bg = "white")
 par(mar = c(4, left, 4.3, 2), family = "sans", col = ink, fg = ink,
     col.axis = muted, xaxs = "i", yaxs = "i", cex = 1.05)
}
select = function(metric) {
 z = stats[stats$metric == metric, ]; z[match(c("A1", "C1"), z$arm), ]
}
begin("comparison.png", 1100)
layout(matrix(1:2, 2, 1), heights = c(1.25, 1))
z = select("wall_s")
plot(NA, xlim = c(0, 365), ylim = c(.2, 2.7), axes = FALSE, xlab = "", ylab = "")
for (x in seq(0, 300, 50)) segments(x, .4, x, 2.2, col = grid)
axis(1, at = seq(0, 300, 50), tick = FALSE)
axis(2, at = c(1.7, .7), labels = c("A1 · Peter", "C1 · Codex"), las = 1, tick = FALSE, font = 2)
for (i in 1:2) {
 y = c(1.7, .7)[i]
 rect(0, y-.25, z$median[i], y+.25, col = c(blue, orange)[i], border = NA)
 segments(z$minimum[i], y, z$maximum[i], y, col = ink, lwd = 3)
 segments(z$minimum[i], y-.30, z$minimum[i], y+.30, col = ink, lwd = 2)
 segments(z$maximum[i], y-.30, z$maximum[i], y+.30, col = ink, lwd = 2)
 points(z$median[i], y, pch = 21, bg = "white", col = ink, cex = 1.6, lwd = 2)
 text(z$median[i]-8, y, sprintf("Median %.2f s", z$median[i]), adj = 1, col = "white", font = 2, cex = 1.2)
 text(z$maximum[i]+4, y, sprintf("%.2f–%.2f", z$minimum[i], z$maximum[i]), adj = 0, font = 2, cex = 1.04)
}
mtext("T01: A1 median wall time is 38.64 s lower (13.6%)", 3, line = 2.6, adj = 0, font = 2, cex = 1.4)
mtext("n=3 per arm | Bar and white dot: median; black range: min–max | Seconds", 3, line = 1, adj = 0, col = muted)
par(mar = c(4.1, 7, 2.2, 2))
z = select("actual_calls")
plot(NA, xlim = c(0, 29), ylim = c(.2, 2.5), axes = FALSE, xlab = "", ylab = "")
for (x in seq(0, 25, 5)) segments(x, .4, x, 2.1, col = grid)
axis(1, at = seq(0, 25, 5), tick = FALSE)
axis(2, at = c(1.7, .7), labels = c("A1 · Peter", "C1 · Codex"), las = 1, tick = FALSE, font = 2)
for (i in 1:2) {
 y = c(1.7, .7)[i]
 rect(0, y-.24, z$median[i], y+.24, col = c(blue, orange)[i], border = NA)
 segments(z$minimum[i], y, z$maximum[i], y, col = ink, lwd = 3)
 segments(z$minimum[i], y-.29, z$minimum[i], y+.29, col = ink, lwd = 2)
 segments(z$maximum[i], y-.29, z$maximum[i], y+.29, col = ink, lwd = 2)
 points(z$median[i], y, pch = 21, bg = "white", cex = 1.5, lwd = 2)
 text(z$median[i]-.7, y, sprintf("Median %d", z$median[i]), adj = 1, col = "white", font = 2, cex = 1.1)
 text(z$maximum[i]+.6, y, sprintf("Min %d | Max %d", z$minimum[i], z$maximum[i]), adj = 0, font = 2, cex = 1.02)
}
mtext("Actual tool calls across all three requests", 3, line = 1, adj = 0, font = 2, cex = 1.25)
mtext("C1 includes commands, file edits and polling. Outer exec wrappers are excluded; tool calls differ from Rscript jobs.", 1, line = 2.5, adj = 0, col = muted, cex = .95)
dev.off()

begin("signed-time.png", 890, 13)
v = delta$mean_C1_minus_A1_s
plot(NA, xlim = c(0, 72), ylim = c(.3, 6.6), axes = FALSE, xlab = "", ylab = "")
for (x in seq(0, 70, 10)) segments(x, .5, x, 5.6, col = grid)
axis(1, at = seq(0, 70, 10), tick = FALSE)
axis(2, at = 5:1, labels = c("Original input reads", "Other RDS reads/writes", "Other R execution", "Remaining time", "Net difference"), las = 1, tick = FALSE, font = 2)
a = 0
for (i in 1:4) {
 b = a+v[i]; y = 6-i
 rect(min(a,b), y-.23, max(a,b), y+.23, col = c(orange, "#A48D50", blue, gray)[i], border = NA)
 text(max(a,b)+1, y, sprintf("%+.2f s", v[i]), adj = 0, font = 2, cex = 1.18)
 if (i < 4) segments(b, y-.25, b, y-.75, lty = 2, col = muted)
 a = b
}
rect(0, .77, v[5], 1.23, col = green, border = NA)
text(v[5]+1, 1, sprintf("+%.2f s", v[5]), adj = 0, font = 2, cex = 1.2)
mtext("Time difference: C1 − A1; positive values favor A1", 3, line = 2.6, adj = 0, font = 2, cex = 1.35)
mtext("Means of three paired differences allow addition. Main outcome above uses group medians.", 3, line = 1, adj = 0, col = muted)
mtext("Reads include decoding. R intervals include framework overhead. Remaining time includes model, network and other tools.", 1, line = 2.5, adj = 0, col = muted, cex = .94)
dev.off()

begin("gantt.png", 970, 10)
plot(NA, xlim = c(0, 300), ylim = c(.4, 8.8), axes = FALSE, xlab = "", ylab = "")
for (x in seq(0, 300, 25)) segments(x, .6, x, 7.6, col = grid)
axis(1, at = seq(0, 300, 25), tick = FALSE)
axis(2, at = c(7,6,5,3.5,2.5,1.5), labels = c("A1 requests", "R execution", "Input reads", "C1 requests", "R execution", "Input reads"), las = 1, tick = FALSE, font = 2)
for (i in seq_len(nrow(timeline))) {
 z = timeline[i, ]; y = if (z$arm == "A1") 7 else 3.5
 y = y-switch(z$kind, request = 0, execution = 1, read = 2)
 col = switch(z$kind, request = if (z$arm == "A1") blue else orange, execution = gray, read = green)
 rect(z$start, y-.28, z$finish, y+.28, col = col, border = "white", lwd = .5)
 if (z$kind == "request") text((z$start+z$finish)/2, y, paste0("Request ", z$label), col = "white", font = 2, cex = 1.1)
}
abline(h = 4.25, col = grid, lwd = 2)
mtext("Gantt chart: actual median-duration run from each arm", 3, line = 2.6, adj = 0, font = 2, cex = 1.35)
mtext("Both medians are trial 3. Each arm starts at episode time zero, including input loading.", 3, line = 1, adj = 0, col = muted)
mtext("R execution: A1 tool dispatch to return; C1 Rscript start to finish. Green reads overlap gray execution; do not add them.", 1, line = 2.5, adj = 0, col = muted, cex = .91)
dev.off()
