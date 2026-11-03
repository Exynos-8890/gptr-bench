# MTBLS90: all preprocessing is fitted inside the relevant training partition.
v04_t09 = function() {
  block = function(request, code, reads = "state", writes = "state") {
    list(request = request, reads = reads, writes = writes, code = code)
  }
  list(id = "T09", seed = 20261030L, packages = c("glmnet", "Matrix"),
      artifacts = c("data-audit.csv", "missingness.csv", "splits.csv", "training-folds.csv",
      "preprocessing-audit.csv", "train-intensity.png", "nested-cv.csv", "outer-predictions.csv",
      "selected-lambda.csv", "final-tuning.csv", "heldout-predictions.csv", "heldout-metrics.csv",
      "calibration.csv", "coefficients.csv", "calibration.png", "permutation.csv",
      "permutation-test.csv", "preprocessing-sensitivity.csv", "uncertainty.csv",
      "feature-stability.csv", "prediction.png", "research-report.md"), steps = list(
      block(1L, r"---(
stopifnot(is.matrix(raw$x),nrow(raw$x)==length(raw$y),ncol(raw$x)==length(raw$metabolites),
  length(raw$sample_id)==nrow(raw$x),!anyDuplicated(raw$sample_id),all(raw$y %in% 0:1))
state=list(lambdas=c(1,.1,.01))
utils::write.csv(data.frame(n_samples=nrow(raw$x),n_features=ncol(raw$x),
  n_positive=sum(raw$y==1),n_negative=sum(raw$y==0),missing=sum(!is.finite(raw$x))),
  'data-audit.csv',row.names=FALSE)
)---", "raw"),
      block(1L, r"---(
utils::write.csv(data.frame(metabolite=raw$metabolites,missing=colSums(!is.finite(raw$x))),
  'missingness.csv',row.names=FALSE)
)---", c("raw", "state")),
      block(1L, r"---(
set.seed(20261030L)
state$test=sort(unlist(lapply(0:1,function(y) {
  j=which(raw$y==y); sample(j,floor(length(j)/3))
})))
state$train=setdiff(seq_len(nrow(raw$x)),state$test)
utils::write.csv(data.frame(id=raw$sample_id,
  subset=ifelse(seq_len(nrow(raw$x)) %in% state$test,'test','train'),y=raw$y),
  'splits.csv',row.names=FALSE)
)---", c("raw", "state")),
      block(1L, r"---(
state$auc=function(y,p) {
  n1=sum(y==1);n0=sum(y==0)
  if(n1==0 || n0==0) return(NA_real_)
  (sum(rank(p)[y==1])-n1*(n1+1)/2)/(n1*n0)
}
state$fold=function(y) {
  out=integer(length(y))
  for(k in 0:1) {j=which(y==k);out[j]=(seq_along(j)-1L)%%3L+1L}
  out
}
environment(state$auc)=baseenv();environment(state$fold)=baseenv()
utils::write.csv(data.frame(id=raw$sample_id[state$train],
  outer_fold=state$fold(raw$y[state$train])),'training-folds.csv',row.names=FALSE)
)---", c("raw", "state")),
      block(1L, r"---(
state$prep=function(x,newx,mode='median') {
  x[!is.finite(x)|x<=0]=NA_real_;newx[!is.finite(newx)|newx<=0]=NA_real_
  x=log(x);newx=log(newx)
  med=vapply(seq_len(ncol(x)),function(j) {
    z=x[,j];z=z[is.finite(z)]
    if(!length(z)) return(0)
    if(mode=='half_min') min(z)-log(2) else stats::median(z)
  },0)
  for(j in seq_len(ncol(x))) {
    x[!is.finite(x[,j]),j]=med[j];newx[!is.finite(newx[,j]),j]=med[j]
  }
  mu=colMeans(x);sd=vapply(seq_len(ncol(x)),function(j) stats::sd(x[,j]),0)
  keep=is.finite(sd)&sd>1e-8
  if(!any(keep)) stop('No varying training features')
  list(x=sweep(sweep(x[,keep,drop=FALSE],2,mu[keep]),2,sd[keep],'/'),
    newx=sweep(sweep(newx[,keep,drop=FALSE],2,mu[keep]),2,sd[keep],'/'),
    median=med,mean=mu,sd=sd,keep=keep)
}
state$fit=function(x,y,newx,lambdas,prep,mode='median') {
  pp=prep(x,newx,mode)
  fit=glmnet::glmnet(pp$x,y,family='binomial',alpha=.5,lambda=lambdas,
    standardize=FALSE,maxit=100000)
  list(prob=as.matrix(stats::predict(fit,pp$newx,s=lambdas,type='response')),
    fit=fit,prep=pp)
}
environment(state$prep)=baseenv();environment(state$fit)=baseenv()
)---"),
      block(1L, r"---(
pp=state$prep(raw$x[state$train,,drop=FALSE],raw$x[state$test,,drop=FALSE])
utils::write.csv(data.frame(metabolite=raw$metabolites,log_median=pp$median,
  log_mean=pp$mean,log_sd=pp$sd),'preprocessing-audit.csv',row.names=FALSE)
state$train_mean=mean(raw$y[state$train])
)---", c("raw", "state"), c("state", "pp")),
      block(1L, r"---(
grDevices::png('train-intensity.png',width=1000,height=650)
graphics::boxplot(pp$x[,seq_len(min(15,ncol(pp$x))),drop=FALSE],las=2,
  ylab='Training-only log, imputed and scaled intensity',main='Development data audit')
grDevices::dev.off()
)---", c("state", "pp")),
      block(2L, r"---(
state$nested=function(x,y,ids,lambdas,fit,prep,fold,auc) {
  outer=fold(y); tables=list();preds=list();tunes=list()
  for(o in 1:3) {
    tr=which(outer!=o);te=which(outer==o);inner=fold(y[tr])
    scores=matrix(NA_real_,3,length(lambdas))
    for(i in 1:3) {
      it=tr[inner!=i];iv=tr[inner==i]
      p=fit(x[it,,drop=FALSE],y[it],x[iv,,drop=FALSE],lambdas,prep)$prob
      scores[i,]=vapply(seq_along(lambdas),function(j) auc(y[iv],p[,j]),0)
    }
    selected=which.max(colMeans(scores))
    p=fit(x[tr,,drop=FALSE],y[tr],x[te,,drop=FALSE],lambdas[selected],prep)$prob[,1]
    baseline=rep(mean(y[tr]),length(te))
    tables[[o]]=data.frame(fold=o,model=c('baseline','elastic_net'),
      auc=c(auc(y[te],baseline),auc(y[te],p)),
      brier=c(mean((baseline-y[te])^2),mean((p-y[te])^2)),lambda=c(NA,lambdas[selected]))
    preds[[o]]=rbind(data.frame(id=ids[te],fold=o,y=y[te],probability=baseline,model='baseline'),
      data.frame(id=ids[te],fold=o,y=y[te],probability=p,model='elastic_net'))
    tunes[[o]]=data.frame(fold=o,lambda=lambdas,inner_auc=colMeans(scores))
  }
  list(table=do.call(rbind,tables),predictions=do.call(rbind,preds),tuning=do.call(rbind,tunes))
}
environment(state$nested)=baseenv()
)---"),
      block(2L, r"---(
state$cv=state$nested(raw$x[state$train,,drop=FALSE],raw$y[state$train],
  raw$sample_id[state$train],state$lambdas,state$fit,state$prep,state$fold,state$auc)
)---", c("raw", "state")),
      block(2L, r"---(
utils::write.csv(state$cv$table,'nested-cv.csv',row.names=FALSE)
utils::write.csv(state$cv$predictions,'outer-predictions.csv',row.names=FALSE)
utils::write.csv(state$cv$tuning,'outer-tuning.csv',row.names=FALSE)
)---"),
      block(2L, r"---(
stopifnot(all(state$cv$predictions$id %in% raw$sample_id[state$train]),
  !any(state$cv$predictions$id %in% raw$sample_id[state$test]),
  nrow(state$cv$predictions)==2*length(state$train))
state$observed_cv=mean(state$cv$table$auc[state$cv$table$model=='elastic_net'])
)---", c("raw", "state")),
      block(2L, r"---(
state$inner=state$fold(raw$y[state$train])
scores=matrix(NA_real_,3,length(state$lambdas))
for(i in 1:3) {
  tr=state$train[state$inner!=i];va=state$train[state$inner==i]
  p=state$fit(raw$x[tr,,drop=FALSE],raw$y[tr],raw$x[va,,drop=FALSE],
    state$lambdas,state$prep)$prob
  scores[i,]=vapply(seq_along(state$lambdas),function(j) state$auc(raw$y[va],p[,j]),0)
}
state$lambda=state$lambdas[which.max(colMeans(scores))]
utils::write.csv(data.frame(lambda=state$lambdas,mean_auc=colMeans(scores)),
  'final-tuning.csv',row.names=FALSE)
utils::write.csv(data.frame(lambda=state$lambda,inner_auc=max(colMeans(scores))),
  'selected-lambda.csv',row.names=FALSE)
)---", c("raw", "state")),
      block(2L, r"---(
state$final=state$fit(raw$x[state$train,,drop=FALSE],raw$y[state$train],
  raw$x[state$test,,drop=FALSE],state$lambda,state$prep)
state$pred=state$final$prob[,1]
)---", c("raw", "state")),
      block(2L, r"---(
state$heldout=rbind(data.frame(id=raw$sample_id[state$test],y=raw$y[state$test],
  probability=state$train_mean,model='baseline'),
  data.frame(id=raw$sample_id[state$test],y=raw$y[state$test],
  probability=state$pred,model='elastic_net'))
utils::write.csv(state$heldout,'heldout-predictions.csv',row.names=FALSE)
)---", c("raw", "state")),
      block(2L, r"---(
state$metrics=do.call(rbind,lapply(split(state$heldout,state$heldout$model),function(d) {
  p=pmin(1-1e-8,pmax(1e-8,d$probability))
  data.frame(model=d$model[1],auc=state$auc(d$y,d$probability),
    brier=mean((d$probability-d$y)^2),logloss=-mean(d$y*log(p)+(1-d$y)*log(1-p)),
    accuracy=mean((d$probability>=.5)==d$y))
}))
utils::write.csv(state$metrics,'heldout-metrics.csv',row.names=FALSE)
)---"),
      block(2L, r"---(
dd=data.frame(y=raw$y[state$test],lp=stats::qlogis(pmin(1-1e-8,pmax(1e-8,state$pred))))
cal=stats::glm(y~lp,data=dd,family=stats::binomial())
utils::write.csv(data.frame(intercept=stats::coef(cal)[1],slope=stats::coef(cal)[2]),
  'calibration.csv',row.names=FALSE)
grDevices::png('calibration.png',width=900,height=650)
g=cut(state$pred,breaks=seq(0,1,.1),include.lowest=TRUE)
graphics::plot(tapply(state$pred,g,mean),tapply(dd$y,g,mean),xlim=c(0,1),ylim=c(0,1),
  xlab='Mean predicted male probability',ylab='Observed male fraction')
graphics::abline(0,1,lty=2);grDevices::dev.off()
)---", c("raw", "state")),
      block(2L, r"---(
b=as.matrix(stats::coef(state$final$fit,s=state$lambda))[-1,1]
utils::write.csv(data.frame(metabolite=raw$metabolites[state$final$prep$keep],coefficient=b),
  'coefficients.csv',row.names=FALSE)
)---", c("raw", "state")),
      block(3L, r"---(
set.seed(20261031L)
state$null=vapply(seq_len(20),function(i) {
  yy=sample(raw$y[state$train])
  cv=state$nested(raw$x[state$train,,drop=FALSE],yy,raw$sample_id[state$train],
    state$lambdas,state$fit,state$prep,state$fold,state$auc)
  mean(cv$table$auc[cv$table$model=='elastic_net'])
},0)
utils::write.csv(data.frame(replicate=1:20,mean_auc=state$null),'permutation.csv',row.names=FALSE)
)---", c("raw", "state")),
      block(3L, r"---(
state$perm_p=(1+sum(state$null>=state$observed_cv))/21
utils::write.csv(data.frame(observed_auc=state$observed_cv,p=state$perm_p),
  'permutation-test.csv',row.names=FALSE)
)---"),
      block(3L, r"---(
pp=state$fit(raw$x[state$train,,drop=FALSE],raw$y[state$train],
  raw$x[state$test,,drop=FALSE],state$lambda,state$prep,mode='half_min')$prob[,1]
utils::write.csv(data.frame(method=c('median','half_min'),
  auc=c(state$auc(raw$y[state$test],state$pred),state$auc(raw$y[state$test],pp)),
  brier=c(mean((state$pred-raw$y[state$test])^2),mean((pp-raw$y[state$test])^2))),
  'preprocessing-sensitivity.csv',row.names=FALSE)
)---", c("raw", "state")),
      block(3L, r"---(
set.seed(20261032L)
bb=replicate(100,{
  j=sample.int(length(state$test),replace=TRUE);y=raw$y[state$test][j];p=state$pred[j]
  c(auc=state$auc(y,p),brier=mean((p-y)^2))
})
utils::write.csv(data.frame(metric=rownames(bb),
  lower=apply(bb,1,stats::quantile,.025,na.rm=TRUE),
  upper=apply(bb,1,stats::quantile,.975,na.rm=TRUE),n_valid=rowSums(is.finite(bb))),
  'uncertainty.csv',row.names=FALSE)
)---", c("raw", "state")),
      block(3L, r"---(
set.seed(20261033L)
state$stability=matrix(0,ncol(raw$x),10)
for(i in 1:10) {
  j=sample(state$train,length(state$train),replace=TRUE)
  fit=state$fit(raw$x[j,,drop=FALSE],raw$y[j],raw$x[state$test,,drop=FALSE],
    state$lambda,state$prep)
  state$stability[fit$prep$keep,i]=as.matrix(stats::coef(fit$fit,s=state$lambda))[-1,1]
}
utils::write.csv(data.frame(metabolite=raw$metabolites,
  selection_frequency=rowMeans(abs(state$stability)>1e-8),
  median_coefficient=apply(state$stability,1,stats::median)),
  'feature-stability.csv',row.names=FALSE)
)---", c("raw", "state")),
      block(3L, r"---(
grDevices::png('prediction.png',width=1000,height=650)
graphics::boxplot(state$pred~raw$y[state$test],xlab='Observed sex label',
  ylab='Heldout predicted male probability',main='Frozen test-set discrimination')
grDevices::dev.off()
)---", c("raw", "state")),
      block(3L, r"---(
met=state$metrics[state$metrics$model=='elastic_net',]
writeLines(c('# MTBLS90 prediction and validation study',
  sprintf('%d development and %d heldout samples; test labels were excluded from tuning.',
    length(state$train),length(state$test)),
  'All log imputation and scaling parameters were estimated inside each training fold.',
  'Nested 3x3 cross-validation compared an intercept baseline and elastic-net logistic regression.',
  sprintf('Heldout AUC %.4f, Brier %.4f, logloss %.4f.',met$auc,met$brier,met$logloss),
  sprintf('Nested-CV permutation p %.4f; twenty permutations imply minimum p=1/21.',state$perm_p),
  'Heldout bootstrap intervals quantify sampling variability, not external transportability.',
  'Feature frequencies from ten development bootstraps are coarse stability estimates.',
  'Sex-associated metabolites are observational correlates, not causal biomarkers.',
  'Check calibration, alternative imputation and cohort sources before biological extrapolation.'),
  'research-report.md')
)---")))
}

v04_check_t09 = function(workspace, raw) {
  failures = character()
  checks = list()
  demand = function(value, name) {
    checks[[name]] <<- isTRUE(value)
    if (!isTRUE(value)) failures <<- c(failures, name)
  }
  read = function(name) utils::read.csv(file.path(workspace, name), stringsAsFactors = FALSE)
  close = function(x, y) isTRUE(all.equal(as.numeric(x), as.numeric(y), tolerance = 1e-6))
  auc = function(y, p) {
    n1 = sum(y == 1)
    n0 = sum(y == 0)
    (sum(rank(p)[y == 1]) - n1 * (n1 + 1) / 2) / (n1 * n0)
  }
  tryCatch({
    demand(all(file.exists(file.path(workspace, v04_t09()$artifacts))), "required_artifacts")
    audit = read("data-audit.csv")
    demand(audit$n_samples == nrow(raw$x) && audit$n_features == ncol(raw$x) &&
      audit$n_positive == sum(raw$y) && audit$missing == sum(!is.finite(raw$x)), "sample_audit")
    split = read("splits.csv")
    demand(identical(split$id, raw$sample_id) && identical(as.integer(split$y),
      as.integer(raw$y)), "labels_and_ids")
    withr::local_seed(20261030L)
    test = sort(unlist(lapply(0:1, function(y) {
      j = which(raw$y == y)
      sample(j, floor(length(j) / 3))
    })))
    train = setdiff(seq_len(nrow(raw$x)), test)
    demand(identical(which(split$subset == "test"), test), "frozen_stratified_test")
    missing = !is.finite(raw$x[train, , drop = FALSE]) | raw$x[train, , drop = FALSE] <= 0
    logx = suppressWarnings(log(raw$x[train, , drop = FALSE]))
    logx[missing] = NA_real_
    med = vapply(seq_len(ncol(logx)), function(j) {
      z = logx[, j]
      if (all(!is.finite(z))) 0 else stats::median(z[is.finite(z)])
    }, 0)
    prep = read("preprocessing-audit.csv")
    demand(identical(prep$metabolite, raw$metabolites) && close(prep$log_median, med),
      "training_only_imputation")
    ref_transform = function(train_index, new_index) {
      a = raw$x[train_index, , drop = FALSE]
      b = raw$x[new_index, , drop = FALSE]
      a[!is.finite(a) | a <= 0] = NA_real_
      b[!is.finite(b) | b <= 0] = NA_real_
      a = log(a)
      b = log(b)
      for (j in seq_len(ncol(a))) {
        good = a[is.finite(a[, j]), j]
        m = if (length(good)) stats::median(good) else 0
        a[!is.finite(a[, j]), j] = m
        b[!is.finite(b[, j]), j] = m
      }
      center = colMeans(a)
      scale = apply(a, 2, stats::sd)
      keep = is.finite(scale) & scale > 1e-8
      list(a = scale(a[, keep, drop = FALSE], center[keep], scale[keep]),
        b = scale(b[, keep, drop = FALSE], center[keep], scale[keep]),
        center = center, scale = scale)
    }
    transformed = ref_transform(train, test)
    demand(close(prep$log_mean, transformed$center) && close(prep$log_sd, transformed$scale),
      "training_only_center_scale")
    selected = read("selected-lambda.csv")
    demand(nrow(selected) == 1 && selected$lambda %in% c(1, .1, .01), "frozen_lambda_grid")
    fit = glmnet::glmnet(transformed$a, raw$y[train], family = "binomial", alpha = .5,
      lambda = selected$lambda, standardize = FALSE, maxit = 100000)
    reference_probability = as.vector(stats::predict(fit, transformed$b,
      s = selected$lambda, type = "response"))
    h = read("heldout-predictions.csv")
    metrics = read("heldout-metrics.csv")
    for (nm in c("baseline", "elastic_net")) {
      rows = h[h$model == nm, ]
      demand(identical(rows$id, raw$sample_id[test]) && close(rows$y, raw$y[test]) &&
        all(is.finite(rows$probability) & rows$probability >= 0 & rows$probability <= 1),
        paste0(nm, "_heldout_rows"))
      p = rows$probability
      clipped = pmin(1 - 1e-8, pmax(1e-8, p))
      row = metrics[metrics$model == nm, ]
      demand(nrow(row) == 1 && close(row$auc, auc(rows$y, p)) &&
        close(row$brier, mean((p - rows$y)^2)) &&
        close(row$logloss, -mean(rows$y * log(clipped) + (1 - rows$y) * log(1 - clipped))) &&
        close(row$accuracy, mean((p >= .5) == rows$y)), paste0(nm, "_metrics"))
      if (nm == "baseline") demand(close(p, rep(mean(raw$y[train]), length(test))),
        "training_prevalence_baseline")
      if (nm == "elastic_net") demand(close(p, reference_probability), "independent_heldout_refit")
    }
    outer = read("outer-predictions.csv")
    nested = read("nested-cv.csv")
    demand(nrow(outer) == 2 * length(train) && !any(outer$id %in% raw$sample_id[test]) &&
      setequal(outer$id, raw$sample_id[train]) && nrow(nested) == 6L, "nested_partition")
    for (i in 1:3) for (nm in c("baseline", "elastic_net")) {
      z = outer[outer$fold == i & outer$model == nm, ]
      r = nested[nested$fold == i & nested$model == nm, ]
      demand(nrow(r) == 1 && close(r$auc, auc(z$y, z$probability)) &&
        close(r$brier, mean((z$y - z$probability)^2)), paste0("outer_metrics_", i, "_", nm))
    }
    null = read("permutation.csv")
    perm = read("permutation-test.csv")
    observed = mean(nested$auc[nested$model == "elastic_net"])
    demand(nrow(null) == 20 && setequal(null$replicate, 1:20) &&
      close(perm$observed_auc, observed) &&
      close(perm$p, (1 + sum(null$mean_auc >= observed)) / 21), "permutation_test")
    st = read("feature-stability.csv")
    demand(identical(st$metabolite, raw$metabolites) &&
      all(st$selection_frequency >= 0 & st$selection_frequency <= 1), "feature_stability")
    uncertainty = read("uncertainty.csv")
    demand(setequal(uncertainty$metric, c("auc", "brier")) &&
      all(uncertainty$n_valid <= 100 & uncertainty$n_valid >= 90) &&
      all(uncertainty$lower <= uncertainty$upper), "bootstrap_intervals")
  }, error = function(e) failures <<- c(failures, conditionMessage(e)))
  list(ok = !length(failures), checks = checks, failures = failures)
}
