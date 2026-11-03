clinical_data = function(n = NULL, seed = 20261027L) {
  if (is.null(n)) return(survival::veteran)
  withr::local_seed(seed)
  trt = sample(1:2, n, replace = TRUE)
  age = pmin(90, pmax(25, stats::rnorm(n, 60, 10)))
  karno = sample(seq(30, 100, 10), n, replace = TRUE)
  hazard = 0.01 * exp(0.15 * (trt - 1) + 0.02 * (age - 60) - 0.025 * (karno - 60))
  event_time = stats::rexp(n, hazard)
  censor_time = stats::rexp(n, 0.004)
  data.frame(trt = trt, age = age, karno = karno,
             time = pmin(event_time, censor_time), status = as.integer(event_time <= censor_time))
}

clinical_task = function() {
  list(
    id = "clinical", seed = 20261027L,
    instructions = paste(
      "Analyze this survival cohort in R. Use survival and base R; do not install packages.",
      "Use the full input, not a sample. Reuse previous work across requests.",
      "Write CSV files in the working directory, with headers and without row names.",
      "Use ordinary R code for file output. All required coefficient tables have columns",
      "term, estimate (log hazard ratio), se. Do not round numeric results."
    ),
    prompts = list(
      paste("Clean the input by retaining complete cases for time, status, trt, age and karno,",
            "with time > 0 and status in 0:1. Keep this cohort for later requests.",
            "Encode trt as a factor with levels 1, 2, and event as status == 1.",
            "Write qc.csv with one row and columns n_input, n, events."),
      paste("Using that cohort, fit Kaplan-Meier curves by trt and a Cox model with trt and age",
            "(Efron ties). Write km.csv with columns time, surv, stratum, where stratum is",
            "trt=1 or trt=2. Include all unique observed times per treatment group, including",
            "censoring-only times with no events. Write cox.csv with the",
            "Cox coefficients and standard errors; use term names trt2 and age."),
      paste("Revise the Cox model by adding karno, using the same cohort and Efron ties.",
            "Write revised.csv with terms trt2, age and karno. Keep earlier output files.")
    ),
    steps = list(
      list(reads = "raw", writes = "cohort", code = paste(
        "keep = complete.cases(raw[c('time', 'status', 'trt', 'age', 'karno')])",
        "cohort = raw[keep & raw$time > 0 & raw$status %in% 0:1, ]",
        "cohort$trt = factor(cohort$trt, levels = c(1, 2))",
        "cohort$event = as.integer(cohort$status == 1)",
        "utils::write.csv(data.frame(n_input = nrow(raw), n = nrow(cohort),",
        "  events = sum(cohort$event)), 'qc.csv', row.names = FALSE)", sep = "\n")),
      list(reads = "cohort", writes = c("km", "fit"), code = paste(
        "km = survival::survfit(survival::Surv(time, event) ~ trt, data = cohort)",
        "utils::write.csv(data.frame(time = km$time, surv = km$surv,",
        "  stratum = rep(names(km$strata), km$strata)), 'km.csv', row.names = FALSE)",
        "fit = survival::coxph(survival::Surv(time, event) ~ trt + age, data = cohort,",
        "  ties = 'efron')",
        "utils::write.csv(data.frame(term = names(stats::coef(fit)),",
        "  estimate = stats::coef(fit), se = sqrt(diag(stats::vcov(fit)))),",
        "  'cox.csv', row.names = FALSE)", sep = "\n")),
      list(reads = "cohort", writes = "revised", code = paste(
        "revised = survival::coxph(survival::Surv(time, event) ~ trt + age + karno,",
        "  data = cohort, ties = 'efron')",
        "utils::write.csv(data.frame(term = names(stats::coef(revised)),",
        "  estimate = stats::coef(revised), se = sqrt(diag(stats::vcov(revised)))),",
        "  'revised.csv', row.names = FALSE)", sep = "\n"))
    )
  )
}
