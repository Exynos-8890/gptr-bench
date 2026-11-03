# METABRIC patient-level survival study. Reference blocks are hidden from live agents.
v04_t02 = function() {
  block = function(request, code, reads = "state", writes = "state") {
    list(request = request, reads = reads, writes = writes, code = code)
  }
  list(id = "T02", seed = 20261030L, packages = "survival",
      artifacts = c("missingness.csv", "cohort-qc.csv", "km.csv", "risk-table.csv",
      "survival.png", "cox-models.csv", "model-comparison.csv", "ph-diagnostics.csv",
      "influence.csv", "discrimination.csv", "ph-sensitive.csv", "bootstrap.csv",
      "bootstrap-draws.csv", "subgroups.csv", "influence-sensitivity.csv", "robustness.png",
      "research-report.md"), steps = list(
      block(1L, r"---(
stopifnot(!anyDuplicated(raw$id))
state = list()
state$clean_cox = function(fit) {
  if (!is.null(fit$terms)) attr(fit$terms, '.Environment') = baseenv()
  if (inherits(fit$formula, 'formula')) environment(fit$formula) = baseenv()
  model_terms = attr(fit$model, 'terms')
  if (!is.null(model_terms)) {
    attr(model_terms, '.Environment') = baseenv()
    attr(fit$model, 'terms') = model_terms
  }
  fit
}
environment(state$clean_cox) = baseenv()
state$missing = data.frame(variable = names(raw), missing = colSums(is.na(raw)))
utils::write.csv(state$missing, 'missingness.csv', row.names = FALSE)
)---", "raw"),
      block(1L, r"---(
keep = stats::complete.cases(raw[c('id','time','event','age','er','nodes','chemo')]) &
  is.finite(raw$time) & raw$time > 0 & raw$event %in% 0:1 &
  is.finite(raw$age) & is.finite(raw$nodes) & raw$nodes >= 0 &
  raw$er %in% c('Negative','Positive') & raw$chemo %in% c('NO','YES')
state$d = raw[keep, , drop = FALSE]
state$d$er = factor(state$d$er, levels = c('Negative','Positive'))
state$d$chemo = factor(state$d$chemo, levels = c('NO','YES'))
stopifnot(nrow(state$d) > 20, sum(state$d$event) > 10)
utils::write.csv(data.frame(n_input=nrow(raw),n=nrow(state$d),events=sum(state$d$event),
  censored=sum(state$d$event==0)), 'cohort-qc.csv', row.names=FALSE)
)---", c("raw", "state")),
      block(1L, r"---(
state$km = survival::survfit(survival::Surv(time,event)~er,data=state$d)
utils::write.csv(data.frame(time=state$km$time,surv=state$km$surv,
  stratum=rep(names(state$km$strata),state$km$strata)), 'km.csv',row.names=FALSE)
)---"),
      block(1L, r"---(
state$risk = expand.grid(stratum=levels(state$d$er),time=c(0,60,120,180,240),
  stringsAsFactors=FALSE)
state$risk$n_risk = vapply(seq_len(nrow(state$risk)),function(i)
  sum(state$d$er==state$risk$stratum[i] & state$d$time>=state$risk$time[i]),0L)
utils::write.csv(state$risk,'risk-table.csv',row.names=FALSE)
)---"),
      block(1L, r"---(
grDevices::png('survival.png',width=1000,height=700)
graphics::plot(state$km,col=c('#0072B2','#D55E00'),xlab='Months',ylab='Overall survival')
graphics::legend('topright',legend=levels(state$d$er),col=c('#0072B2','#D55E00'),lty=1)
grDevices::dev.off()
)---"),
      block(2L, r"---(
state$baseline = state$clean_cox(survival::coxph(survival::Surv(time,event)~age+er,
  data=state$d,ties='efron',model=TRUE))
)---"),
      block(2L, r"---(
state$full = state$clean_cox(survival::coxph(survival::Surv(time,event)~age+er+nodes+chemo,
  data=state$d,ties='efron',x=TRUE,model=TRUE))
)---"),
      block(2L, r"---(
state$coefs = do.call(rbind,lapply(c('baseline','full'),function(nm) {
  fit=state[[nm]]; b=stats::coef(fit); se=sqrt(diag(stats::vcov(fit)))
  data.frame(model=nm,term=names(b),estimate=as.vector(b),se=se,hr=exp(b),
    lower=exp(b-1.96*se),upper=exp(b+1.96*se),row.names=NULL)
}))
utils::write.csv(state$coefs,'cox-models.csv',row.names=FALSE)
)---"),
      block(2L, r"---(
ll0=stats::logLik(state$baseline); ll1=stats::logLik(state$full)
chisq=2*as.numeric(ll1-ll0); df=attr(ll1,'df')-attr(ll0,'df')
utils::write.csv(data.frame(chisq=chisq,df=df,p=stats::pchisq(chisq,df,lower.tail=FALSE)),
  'model-comparison.csv',row.names=FALSE)
)---"),
      block(2L, r"---(
state$ph = survival::cox.zph(state$full,transform='km')
utils::write.csv(data.frame(term=rownames(state$ph$table),state$ph$table,row.names=NULL),
  'ph-diagnostics.csv',row.names=FALSE)
)---"),
      block(2L, r"---(
state$influence = apply(abs(as.matrix(stats::residuals(state$full,type='dfbeta'))),1,max)
utils::write.csv(data.frame(id=state$d$id,max_abs_dfbeta=state$influence),
  'influence.csv',row.names=FALSE)
)---"),
      block(2L, r"---(
conc=summary(state$full)$concordance
utils::write.csv(data.frame(concordance=conc[[1]],se=conc[[2]]),
  'discrimination.csv',row.names=FALSE)
)---"),
      block(3L, r"---(
state$sensitive = state$clean_cox(survival::coxph(
  survival::Surv(time,event)~age+nodes+chemo+survival::strata(er),
  data=state$d,ties='efron',model=TRUE))
utils::write.csv(data.frame(term=names(stats::coef(state$sensitive)),
  estimate=as.vector(stats::coef(state$sensitive)),se=sqrt(diag(stats::vcov(state$sensitive)))),
  'ph-sensitive.csv',row.names=FALSE)
)---"),
      block(3L, r"---(
set.seed(20261030L)
state$boot = do.call(rbind,lapply(seq_len(100),function(b) {
  j=sample.int(nrow(state$d),replace=TRUE)
  cf=tryCatch(stats::coef(survival::coxph(survival::Surv(time,event)~age+er+nodes+chemo,
    data=state$d[j,],ties='efron')),error=function(e) rep(NA_real_,4))
  data.frame(replicate=b,term=names(stats::coef(state$full)),estimate=as.vector(cf))
}))
utils::write.csv(state$boot,'bootstrap-draws.csv',row.names=FALSE)
state$boot_summary=do.call(rbind,lapply(split(state$boot,state$boot$term),function(d) {
  b=d$estimate[is.finite(d$estimate)]
  data.frame(term=d$term[1],n_valid=length(b),median=stats::median(b),
    lower=stats::quantile(b,.025,names=FALSE),upper=stats::quantile(b,.975,names=FALSE))
}))
utils::write.csv(state$boot_summary,'bootstrap.csv',row.names=FALSE)
)---"),
      block(3L, r"---(
state$subgroups=do.call(rbind,lapply(levels(state$d$er),function(g) {
  d=state$d[state$d$er==g,]; fit=survival::coxph(survival::Surv(time,event)~age+nodes+chemo,
    data=d,ties='efron'); b=stats::coef(fit)
  data.frame(er=g,term=names(b),estimate=as.vector(b),se=sqrt(diag(stats::vcov(fit))),
    n=nrow(d),events=sum(d$event),row.names=NULL)
}))
utils::write.csv(state$subgroups,'subgroups.csv',row.names=FALSE)
)---"),
      block(3L, r"---(
state$trimmed=state$clean_cox(survival::coxph(survival::Surv(time,event)~age+er+nodes+chemo,
  data=state$d[state$influence<=stats::quantile(state$influence,.99),],ties='efron',model=TRUE))
utils::write.csv(data.frame(term=names(stats::coef(state$trimmed)),
  estimate=as.vector(stats::coef(state$trimmed)),se=sqrt(diag(stats::vcov(state$trimmed)))),
  'influence-sensitivity.csv',row.names=FALSE)
)---"),
      block(3L, r"---(
grDevices::png('robustness.png',width=1000,height=700)
b=state$boot_summary
graphics::plot(seq_len(nrow(b)),b$median,ylim=range(c(b$lower,b$upper)),xaxt='n',
  xlab='Term',ylab='Log hazard ratio; bootstrap percentile interval')
graphics::axis(1,at=seq_len(nrow(b)),labels=b$term)
graphics::segments(seq_len(nrow(b)),b$lower,seq_len(nrow(b)),b$upper)
graphics::abline(h=0,lty=2); grDevices::dev.off()
)---"),
      block(3L, r"---(
ph_min=min(state$ph$table[,'p'])
writeLines(c('# METABRIC survival association study',
  sprintf('Analysis retained %d of %d patients, with %d events and %d censored.',
    nrow(state$d),nrow(raw),sum(state$d$event),sum(state$d$event==0)),
  'Kaplan-Meier curves and risk tables describe the frozen complete-case ER groups.',
  'Baseline and adjusted Cox models use the same patients and Efron ties.',
  sprintf('Minimum proportional-hazards diagnostic p-value: %.5g.',ph_min),
  'ER stratification is a predeclared sensitivity analysis, not a causal model.',
  'Inspect ph-diagnostics.csv for non-ER violations that ER stratification cannot resolve.',
  'Patient bootstrap, ER subgroups and influence trimming assess different sensitivities.',
  'Observational associations are subject to residual confounding, missingness and selection.',
  'Differences across models should be judged by effects and uncertainty, not p-values alone.'),
  'research-report.md')
)---", c("raw", "state"))
    ))
}

v04_check_t02 = function(workspace, raw) {
  failures = character()
  checks = list()
  demand = function(value, name) {
    checks[[name]] <<- isTRUE(value)
    if (!isTRUE(value)) failures <<- c(failures, name)
  }
  read = function(name) utils::read.csv(file.path(workspace, name), stringsAsFactors = FALSE)
  close = function(x, y) isTRUE(all.equal(as.numeric(x), as.numeric(y), tolerance = 1e-6))
  tryCatch({
    demand(all(file.exists(file.path(workspace, v04_t02()$artifacts))), "required_artifacts")
    d = raw[stats::complete.cases(raw) & is.finite(raw$time) & raw$time > 0 &
      raw$event %in% 0:1 & is.finite(raw$age) & is.finite(raw$nodes) & raw$nodes >= 0 &
      raw$er %in% c("Negative", "Positive") & raw$chemo %in% c("NO", "YES"), ]
    d$er = factor(d$er, levels = c("Negative", "Positive"))
    d$chemo = factor(d$chemo, levels = c("NO", "YES"))
    qc = read("cohort-qc.csv")
    demand(nrow(qc) == 1 && qc$n == nrow(d) && qc$n_input == nrow(raw) &&
      qc$events == sum(d$event) && qc$censored == sum(d$event == 0), "cohort_and_events")
    fits = list(baseline = survival::coxph(survival::Surv(time, event) ~ age + er, data = d),
      full = survival::coxph(survival::Surv(time, event) ~ age + er + nodes + chemo, data = d))
    out = read("cox-models.csv")
    for (nm in names(fits)) {
      rows = out[out$model == nm, ]
      co = stats::coef(fits[[nm]])
      demand(setequal(rows$term, names(co)), paste0(nm, "_terms"))
      rows = rows[match(names(co), rows$term), ]
      demand(close(rows$estimate, co), paste0(nm, "_estimates"))
      demand(close(rows$se, sqrt(diag(stats::vcov(fits[[nm]])))) &&
        close(rows$hr, exp(co)), paste0(nm, "_uncertainty"))
    }
    km = survival::survfit(survival::Surv(time, event) ~ er, data = d)
    out = read("km.csv")
    demand(nrow(out) == length(km$time) && close(out$time, km$time) &&
      close(out$surv, km$surv) && identical(out$stratum, rep(names(km$strata), km$strata)),
      "kaplan_meier_including_censor_times")
    risk = read("risk-table.csv")
    risk$stratum = sub("^er=", "", risk$stratum)
    nr = vapply(seq_len(nrow(risk)), function(i)
      sum(d$er == risk$stratum[i] & d$time >= risk$time[i]), 0L)
    expected_keys = as.vector(outer(levels(d$er), c(0, 60, 120, 180, 240), paste))
    demand(nrow(risk) == 10 && setequal(paste(risk$stratum, risk$time), expected_keys) &&
      identical(as.integer(risk$n_risk), nr), "risk_table")
    ph = read("ph-diagnostics.csv")
    ref = survival::cox.zph(fits$full, transform = "km")$table
    demand(setequal(ph$term, rownames(ref)) &&
      close(ph$p[match(rownames(ref), ph$term)], ref[, "p"]), "ph_diagnostics")
    influence = read("influence.csv")
    demand(identical(influence$id, d$id) && close(influence$max_abs_dfbeta,
      apply(abs(as.matrix(stats::residuals(fits$full, type = "dfbeta"))), 1, max)),
      "patient_influence")
    boot = read("bootstrap-draws.csv")
    b = read("bootstrap.csv")
    demand(setequal(boot$replicate, 1:100) && nrow(boot) == 400L &&
      setequal(b$term, names(stats::coef(fits$full))), "patient_bootstrap_size")
    for (term in b$term) {
      x = boot$estimate[boot$term == term]
      x = x[is.finite(x)]
      row = b[b$term == term, ]
      demand(row$n_valid == length(x) && close(row$median, stats::median(x)) &&
        close(c(row$lower, row$upper), stats::quantile(x, c(.025, .975))),
        paste0("bootstrap_interval_", term))
    }
    sub = read("subgroups.csv")
    demand(setequal(sub$er, levels(d$er)) && all(sub$n > 0) && all(sub$events > 0),
      "er_subgroup_sensitivity")
    report = readLines(file.path(workspace, "research-report.md"), warn = FALSE)
    demand(length(report) >= 5 && any(grepl("observational|confound|causal", report,
      ignore.case = TRUE)), "observational_interpretation")
  }, error = function(e) failures <<- c(failures, conditionMessage(e)))
  list(ok = !length(failures), checks = checks, failures = failures)
}
