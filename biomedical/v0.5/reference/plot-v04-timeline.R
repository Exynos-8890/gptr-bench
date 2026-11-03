args = commandArgs(TRUE)
data = utils::read.csv(args[[1L]], stringsAsFactors = FALSE)
colors = c(Request = "#9DB4C0", Tool = "#0072B2", RDS = "#D55E00", Rscript = "#009E73")
grDevices::png(args[[2L]], width = 1500, height = max(650, 35 * nrow(data) + 160), res = 120)
graphics::par(mar = c(5, 17, 3, 1))
graphics::plot(NA, xlim = range(c(0, data$end_s)), ylim = c(0.5, nrow(data) + .5),
               axes = FALSE, xlab = "Seconds from measured execution start", ylab = "",
               main = "Three requests, R execution and RDS loading")
graphics::axis(1)
y = rev(seq_len(nrow(data)))
graphics::axis(2, at = y, labels = paste0("Q", data$request, " ", data$label),
               las = 2, cex.axis = .75, tick = FALSE)
graphics::rect(data$start_s, y - .32, data$end_s, y + .32,
               col = colors[data$kind], border = NA)
graphics::legend("bottomright", legend = names(colors), fill = colors, bty = "n", cex = .8)
grDevices::dev.off()
