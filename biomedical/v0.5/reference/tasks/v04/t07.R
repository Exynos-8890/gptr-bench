# GB1 measured multi-mutant fitness, with sparse additive and pairwise ridge features.
v04_t07 = function() {
  block = function(request, code, reads = "state", writes = "state") {
    list(request = request, reads = reads, writes = writes, code = code)
  }
  list(id = "T07", seed = 20261030L, packages = c("Matrix", "glmnet"),
      artifacts = c("variant-qc.csv", "splits.csv", "sequence-sites.csv", "feature-audit.csv",
      "validation-grid.csv", "selected-models.csv", "chosen-model.csv", "heldout-predictions.csv",
      "model-comparison.csv", "depth-performance.csv", "prediction-ranking.csv",
        "residual-audit.csv",
      "fitness-prediction.png", "candidates.csv", "candidate-tradeoffs.csv", "uncertainty.csv",
      "candidate-stability.csv", "candidate-audit.csv", "candidate-tradeoffs.png",
        "research-report.md"),
    steps = list(
      block(1L, r"---(
stopifnot(length(raw$sites)==4,!anyDuplicated(raw$sites),
  all(raw$sites>=1),all(raw$sites<=nchar(raw$wild_type)))
state=list(aa=strsplit('ACDEFGHIKLMNPQRSTVWY','')[[1]],lambdas=c(1,.1,.01,.001))
d=raw$variants[order(raw$variants$mutant),,drop=FALSE]
keep=is.finite(d$DMS_score)&!is.na(d$mutant)&!is.na(d$mutated_sequence)&
  nchar(d$mutated_sequence)==nchar(raw$wild_type)&!grepl('[^ACDEFGHIKLMNPQRSTVWY]',
    d$mutated_sequence)
state$d=d[keep&!duplicated(d$mutated_sequence),,drop=FALSE]
stopifnot(nrow(state$d)>=30,!anyDuplicated(state$d$mutant))
utils::write.csv(data.frame(n_input=nrow(raw$variants),n_valid=nrow(state$d),
  n_excluded=nrow(raw$variants)-nrow(state$d),n_sites=4), 'variant-qc.csv',row.names=FALSE)
)---", "raw"),
      block(1L, r"---(
state$letters=vapply(raw$sites,function(pos) substring(state$d$mutated_sequence,pos,pos),
  character(nrow(state$d)))
state$wild=substring(raw$wild_type,raw$sites,raw$sites)
state$depth=rowSums(sweep(state$letters,2,state$wild,'!='))
expected=rep(raw$wild_type,nrow(state$d))
for(k in seq_along(raw$sites)) substring(expected,raw$sites[k],raw$sites[k])=state$letters[,k]
stopifnot(identical(expected,state$d$mutated_sequence))
parts=strsplit(state$d$mutant,':',fixed=TRUE)
tokens=unlist(parts);ri=rep(seq_len(nrow(state$d)),lengths(parts))
wt=tokens=='WT';tokens=tokens[!wt];ri=ri[!wt]
stopifnot(all(grepl('^[A-Z][0-9]+[A-Z]$',tokens)))
pos=as.integer(gsub('[A-Z]','',tokens))
stopifnot(all(pos %in% raw$sites),!anyDuplicated(paste(ri,pos)),
  all(substring(tokens,1,1)==substring(raw$wild_type,pos,pos)),
  all(substring(tokens,nchar(tokens),nchar(tokens))==substring(state$d$mutated_sequence[ri],
    pos,pos)))
changes=substring(tokens,1,1)!=substring(tokens,nchar(tokens),nchar(tokens))
stopifnot(identical(as.integer(tabulate(ri[changes],nbins=nrow(state$d))),as.integer(state$depth)))
state$sequence=apply(state$letters,1,paste0,collapse='')
utils::write.csv(data.frame(id=state$d$mutant,site_sequence=state$sequence,depth=state$depth),
  'sequence-sites.csv',row.names=FALSE)
)---", c("raw", "state")),
      block(1L, r"---(
state$part=(seq_len(nrow(state$d))-1L)%%5L
state$train=which(state$part<3);state$validation=which(state$part==3)
state$test=which(state$part==4)
state$development=c(state$train,state$validation)
utils::write.csv(data.frame(id=state$d$mutant,
  subset=ifelse(state$part<3,'train',ifelse(state$part==3,'validation','test')),depth=state$depth),
  'splits.csv',row.names=FALSE)
)---"),
      block(1L, r"---(
state$codes=matrix(match(state$letters,state$aa),nrow=nrow(state$d),ncol=4)
stopifnot(!anyNA(state$codes),!anyDuplicated(state$sequence))
state$depth_audit=as.data.frame(table(subset=ifelse(state$part<3,'train',
  ifelse(state$part==3,'validation','test')),depth=state$depth))
utils::write.csv(state$depth_audit,'split-depth-audit.csv',row.names=FALSE)
)---"),
      block(1L, r"---(
n=nrow(state$d)
state$x_add=Matrix::sparseMatrix(i=rep(seq_len(n),4),
  j=as.vector(sweep(state$codes,2,20*(0:3),'+')),x=1,dims=c(n,80L))
)---"),
      block(1L, r"---(
state$pairs=utils::combn(1:4,2)
jj=vapply(seq_len(ncol(state$pairs)),function(k)
  (state$codes[,state$pairs[1,k]]-1)*20+state$codes[,state$pairs[2,k]]+400*(k-1L),
  numeric(nrow(state$d)))
state$x_pair=cbind(state$x_add,Matrix::sparseMatrix(i=rep(seq_len(nrow(state$d)),6),
  j=as.vector(jj),x=1,dims=c(nrow(state$d),2400L)))
)---"),
      block(1L, r"---(
utils::write.csv(data.frame(model=c('additive','pairwise'),n_rows=nrow(state$d),
  n_features=c(ncol(state$x_add),ncol(state$x_pair)),
  nonzero=c(length(state$x_add@x),length(state$x_pair@x))),
  'feature-audit.csv',row.names=FALSE)
stopifnot(all(Matrix::rowSums(state$x_add)==4),all(Matrix::rowSums(state$x_pair)==10))
)---"),
      block(2L, r"---(
state$add_fit=glmnet::glmnet(state$x_add[state$train,],state$d$DMS_score[state$train],
  family='gaussian',alpha=0,lambda=state$lambdas,standardize=FALSE)
state$add_val=as.matrix(stats::predict(state$add_fit,state$x_add[state$validation,],
  s=state$lambdas))
state$add_rmse=sqrt(colMeans((state$add_val-state$d$DMS_score[state$validation])^2))
)---"),
      block(2L, r"---(
state$pair_fit=glmnet::glmnet(state$x_pair[state$train,],state$d$DMS_score[state$train],
  family='gaussian',alpha=0,lambda=state$lambdas,standardize=FALSE)
state$pair_val=as.matrix(stats::predict(state$pair_fit,state$x_pair[state$validation,],
  s=state$lambdas))
state$pair_rmse=sqrt(colMeans((state$pair_val-state$d$DMS_score[state$validation])^2))
)---"),
      block(2L, r"---(
state$grid=data.frame(model=rep(c('additive','pairwise'),each=length(state$lambdas)),
  lambda=rep(state$lambdas,2),rmse=c(state$add_rmse,state$pair_rmse))
state$selected=data.frame(model=c('additive','pairwise'),
  lambda=c(state$lambdas[which.min(state$add_rmse)],state$lambdas[which.min(state$pair_rmse)]),
  validation_rmse=c(min(state$add_rmse),min(state$pair_rmse)))
state$chosen=state$selected$model[which.min(state$selected$validation_rmse)]
utils::write.csv(state$grid,'validation-grid.csv',row.names=FALSE)
utils::write.csv(state$selected,'selected-models.csv',row.names=FALSE)
utils::write.csv(data.frame(model=state$chosen),'chosen-model.csv',row.names=FALSE)
)---"),
      block(2L, r"---(
state$add_final=glmnet::glmnet(state$x_add[state$development,],state$d$DMS_score[state$development],
  family='gaussian',alpha=0,lambda=state$selected$lambda[1],standardize=FALSE)
state$pair_final=glmnet::glmnet(state$x_pair[state$development,],
  state$d$DMS_score[state$development],
  family='gaussian',alpha=0,lambda=state$selected$lambda[2],standardize=FALSE)
)---"),
      block(2L, r"---(
state$pred_add=as.vector(stats::predict(state$add_final,state$x_add[state$test,],
  s=state$selected$lambda[1]))
state$pred_pair=as.vector(stats::predict(state$pair_final,state$x_pair[state$test,],
  s=state$selected$lambda[2]))
utils::write.csv(data.frame(id=state$d$mutant[state$test],observed=state$d$DMS_score[state$test],
  pred_additive=state$pred_add,pred_pairwise=state$pred_pair,depth=state$depth[state$test]),
  'heldout-predictions.csv',row.names=FALSE)
)---"),
      block(2L, r"---(
state$metrics=do.call(rbind,lapply(c('additive','pairwise'),function(nm) {
  p=if(nm=='additive') state$pred_add else state$pred_pair;y=state$d$DMS_score[state$test]
  data.frame(model=nm,rmse=sqrt(mean((p-y)^2)),spearman=stats::cor(y,p,method='spearman'))
}))
utils::write.csv(state$metrics,'model-comparison.csv',row.names=FALSE)
)---"),
      block(2L, r"---(
state$by_depth=do.call(rbind,lapply(c('additive','pairwise'),function(nm) {
  p=if(nm=='additive') state$pred_add else state$pred_pair;y=state$d$DMS_score[state$test]
  do.call(rbind,lapply(sort(unique(state$depth[state$test])),function(dep) {
    j=which(state$depth[state$test]==dep)
    data.frame(model=nm,depth=dep,n=length(j),rmse=sqrt(mean((p[j]-y[j])^2)),
      spearman=if(length(j)>2&&stats::sd(y[j])>0&&stats::sd(p[j])>0)
        stats::cor(y[j],p[j],method='spearman') else NA_real_)
  }))
}))
utils::write.csv(state$by_depth,'depth-performance.csv',row.names=FALSE)
)---"),
      block(2L, r"---(
p=if(state$chosen=='additive') state$pred_add else state$pred_pair
state$ranked=data.frame(id=state$d$mutant[state$test],prediction=p,depth=state$depth[state$test],
  sequence=state$sequence[state$test],input_index=state$test,stringsAsFactors=FALSE)
state$ranked=state$ranked[order(-state$ranked$prediction,state$ranked$id),]
utils::write.csv(state$ranked[c('id','prediction','depth')],'prediction-ranking.csv',
  row.names=FALSE)
)---"),
      block(2L, r"---(
utils::write.csv(do.call(rbind,lapply(c('additive','pairwise'),function(nm) {
  e=(if(nm=='additive') state$pred_add else state$pred_pair)-state$d$DMS_score[state$test]
  data.frame(model=nm,mean_error=mean(e),mae=mean(abs(e)))
})),'residual-audit.csv',row.names=FALSE)
)---"),
      block(2L, r"---(
grDevices::png('fitness-prediction.png',width=1000,height=650)
graphics::plot(state$d$DMS_score[state$test],if(state$chosen=='additive') state$pred_add else
  state$pred_pair,pch=16,cex=.4,xlab='Heldout measured fitness',ylab='Predicted fitness',
  main=paste('Validation-chosen model:',state$chosen))
graphics::abline(0,1,lty=2);grDevices::dev.off()
)---"),
      block(3L, r"---(
state$pick=function(ranked,budget) {
  d=ranked[ranked$depth<=budget,,drop=FALSE];selected=integer()
  for(i in seq_len(nrow(d))) {
    s=strsplit(d$sequence[i],'')[[1]]
    distances=vapply(selected,function(j) sum(s!=strsplit(d$sequence[j],'')[[1]]),0L)
    if(!length(selected)||all(distances>=2)) selected=c(selected,i)
    if(length(selected)==10) break
  }
  d[selected,,drop=FALSE]
}
environment(state$pick)=baseenv()
state$candidates=do.call(rbind,lapply(2:4,function(budget) {
  d=state$pick(state$ranked,budget)
  data.frame(budget=rep(budget,nrow(d)),d[c('id','prediction','depth','sequence','input_index')])
}))
utils::write.csv(state$candidates[c('budget','id','prediction','depth')],
  'candidates.csv',row.names=FALSE)
)---"),
      block(3L, r"---(
state$tradeoffs=do.call(rbind,lapply(2:4,function(budget) {
  d=state$candidates[state$candidates$budget==budget,,drop=FALSE]
  distance=if(nrow(d)<2) NA_real_ else min(utils::combn(seq_len(nrow(d)),2,function(j)
    sum(strsplit(d$sequence[j[1]],'')[[1]]!=strsplit(d$sequence[j[2]],'')[[1]])))
  data.frame(budget=budget,n_selected=nrow(d),
    mean_prediction=if(nrow(d)) mean(d$prediction) else NA_real_,min_hamming=distance)
}))
utils::write.csv(state$tradeoffs,'candidate-tradeoffs.csv',row.names=FALSE)
)---"),
      block(3L, r"---(
set.seed(20261031L)
state$uncertainty=do.call(rbind,lapply(c('additive','pairwise'),function(nm) {
  p=if(nm=='additive') state$pred_add else state$pred_pair;y=state$d$DMS_score[state$test]
  b=replicate(100,{
    j=sample.int(length(y),replace=TRUE)
    c(rmse=sqrt(mean((p[j]-y[j])^2)),spearman=stats::cor(y[j],p[j],method='spearman'))
  })
  data.frame(model=nm,metric=rownames(b),lower=apply(b,1,stats::quantile,.025,na.rm=TRUE),
    upper=apply(b,1,stats::quantile,.975,na.rm=TRUE),n_valid=rowSums(is.finite(b)))
}))
utils::write.csv(state$uncertainty,'uncertainty.csv',row.names=FALSE)
)---"),
      block(3L, r"---(
set.seed(20261032L)
cand=state$candidates[state$candidates$budget==4,,drop=FALSE]
x=if(state$chosen=='additive') state$x_add else state$x_pair
lambda=state$selected$lambda[match(state$chosen,state$selected$model)]
state$candidate_boot=replicate(10,{
  j=sample(state$development,length(state$development),replace=TRUE)
  fit=glmnet::glmnet(x[j,],state$d$DMS_score[j],family='gaussian',alpha=0,
    lambda=lambda,standardize=FALSE)
  as.vector(stats::predict(fit,x[cand$input_index,,drop=FALSE],s=lambda))
})
state$candidate_boot=matrix(state$candidate_boot,nrow=nrow(cand),ncol=10)
utils::write.csv(data.frame(id=cand$id,mean_prediction=rowMeans(state$candidate_boot),
  sd_prediction=apply(state$candidate_boot,1,stats::sd),
  mean_rank=rowMeans(apply(state$candidate_boot,2,function(p) rank(-p,ties.method='min')))),
  'candidate-stability.csv',row.names=FALSE)
)---"),
      block(3L, r"---(
utils::write.csv(data.frame(budget=2:4,
  within_depth=vapply(2:4,
    function(b) all(state$candidates$depth[state$candidates$budget==b]<=b),TRUE),
  diverse=is.na(state$tradeoffs$min_hamming)|state$tradeoffs$min_hamming>=2,
  unseen=vapply(2:4,function(b) all(state$candidates$id[state$candidates$budget==b] %in%
    state$d$mutant[state$test]),TRUE)), 'candidate-audit.csv',row.names=FALSE)
)---"),
      block(3L, r"---(
grDevices::png('candidate-tradeoffs.png',width=1000,height=650)
graphics::plot(state$tradeoffs$budget,state$tradeoffs$mean_prediction,type='b',
  xlab='Maximum mutation depth',ylab='Mean selected predicted fitness',
  main='Prediction/diversity tradeoff; Hamming distance at least two')
grDevices::dev.off()
)---"),
      block(3L, r"---(
writeLines(c('# GB1 variant generalization and candidate prioritization',
  sprintf('%d measured unique sequences; %d train, %d validation, %d unseen test.',
    nrow(state$d),length(state$train),length(state$validation),length(state$test)),
  'Additive and pairwise ridge models use sparse sequence indicators and validation-only tuning.',
  sprintf('Candidate model chosen before test evaluation: %s.',state$chosen),
  'Mutation-depth stratification separates easy interpolation from higher-order variant behavior.',
  'Model differences suggest predictive epistasis, not a mechanistic proof.',
  'Candidates use predictions, mutation budgets and pairwise Hamming distance at least two.',
  'Heldout bootstraps estimate sampling uncertainty; development refits assess ranking stability.',
  'Candidate predictive uncertainty is approximate and does not establish wet-lab fitness.',
  'Assay holdouts prioritize experimental follow-up; no new protein has been validated.'),
  'research-report.md')
)---")))
}

v04_check_t07 = function(workspace, raw) {
  failures = character()
  checks = list()
  demand = function(value, name) {
    checks[[name]] <<- isTRUE(value)
    if (!isTRUE(value)) failures <<- c(failures, name)
  }
  read = function(name) utils::read.csv(file.path(workspace, name), stringsAsFactors = FALSE)
  close = function(x, y) isTRUE(all.equal(as.numeric(x), as.numeric(y), tolerance = 1e-6))
  tryCatch({
    demand(all(file.exists(file.path(workspace, v04_t07()$artifacts))), "required_artifacts")
    d = raw$variants[order(raw$variants$mutant), ]
    valid = is.finite(d$DMS_score) & !is.na(d$mutant) & !is.na(d$mutated_sequence) &
      nchar(d$mutated_sequence) == nchar(raw$wild_type) &
      !grepl("[^ACDEFGHIKLMNPQRSTVWY]", d$mutated_sequence)
    d = d[valid & !duplicated(d$mutated_sequence), ]
    split = read("splits.csv")
    expected = c("train", "train", "train", "validation", "test")
    demand(identical(split$id, d$mutant) && identical(split$subset,
      expected[(seq_len(nrow(d)) - 1L) %% 5L + 1L]), "frozen_sequence_split")
    letters = vapply(raw$sites, function(pos) substring(d$mutated_sequence, pos, pos),
      character(nrow(d)))
    depth = rowSums(sweep(letters, 2, substring(raw$wild_type, raw$sites, raw$sites), "!="))
    demand(close(split$depth, depth), "mutation_depth")
    feature = read("feature-audit.csv")
    demand(close(feature$n_features, c(80, 2480)) &&
      close(feature$nonzero, nrow(d) * c(4, 10)), "sparse_feature_geometry")
    selected = read("selected-models.csv")
    grid = read("validation-grid.csv")
    for (nm in c("additive", "pairwise")) {
      g = grid[grid$model == nm, ]
      row = selected[selected$model == nm, ]
      demand(nrow(row) == 1 && close(row$lambda, g$lambda[which.min(g$rmse)]) &&
        close(row$validation_rmse, min(g$rmse)), paste0(nm, "_validation_tuning"))
    }
    chosen = read("chosen-model.csv")$model
    demand(identical(chosen, selected$model[which.min(selected$validation_rmse)]),
      "candidate_model_selected_without_test")
    test = which(split$subset == "test")
    h = read("heldout-predictions.csv")
    demand(identical(h$id, d$mutant[test]) && close(h$observed, d$DMS_score[test]) &&
      close(h$depth, depth[test]), "unseen_variant_truth")
    alphabet = strsplit("ACDEFGHIKLMNPQRSTVWY", "")[[1]]
    code = matrix(match(letters, alphabet), nrow = nrow(d))
    additive = do.call(cbind, lapply(1:4, function(k)
      Matrix::sparseMatrix(i = seq_len(nrow(d)), j = code[, k], x = 1,
        dims = c(nrow(d), 20L))))
    pairs = utils::combn(1:4, 2)
    pairwise = cbind(additive, do.call(cbind, lapply(seq_len(ncol(pairs)), function(k) {
      col = (code[, pairs[1, k]] - 1L) * 20L + code[, pairs[2, k]]
      Matrix::sparseMatrix(i = seq_len(nrow(d)), j = col, x = 1,
        dims = c(nrow(d), 400L))
    })))
    train = which(split$subset == "train")
    validation = which(split$subset == "validation")
    development = c(train, validation)
    for (nm in c("additive", "pairwise")) {
      x = if (nm == "additive") additive else pairwise
      lambdas = c(1, .1, .01, .001)
      tuned = glmnet::glmnet(x[train, ], d$DMS_score[train], family = "gaussian",
        alpha = 0, lambda = lambdas, standardize = FALSE)
      vp = as.matrix(stats::predict(tuned, x[validation, ], s = lambdas))
      rmse = sqrt(colMeans((vp - d$DMS_score[validation])^2))
      g = grid[grid$model == nm, ]
      demand(close(g$rmse[match(lambdas, g$lambda)], rmse), paste0(nm, "_fit_validation"))
      lambda = selected$lambda[selected$model == nm]
      final = glmnet::glmnet(x[development, ], d$DMS_score[development],
        family = "gaussian", alpha = 0, lambda = lambda, standardize = FALSE)
      demand(close(h[[paste0("pred_", nm)]], as.vector(stats::predict(final, x[test, ],
        s = lambda))), paste0(nm, "_independent_refit"))
    }
    metrics = read("model-comparison.csv")
    for (nm in c("additive", "pairwise")) {
      p = h[[paste0("pred_", nm)]]
      m = metrics[metrics$model == nm, ]
      demand(nrow(m) == 1 && all(is.finite(p)) &&
        close(m$rmse, sqrt(mean((p - h$observed)^2))) &&
        close(m$spearman, stats::cor(p, h$observed, method = "spearman")),
        paste0(nm, "_heldout_metrics"))
    }
    candidates = read("candidates.csv")
    tradeoffs = read("candidate-tradeoffs.csv")
    for (budget in 2:4) {
      c = candidates[candidates$budget == budget, ]
      j = match(c$id, d$mutant)
      demand(nrow(c) <= 10 && !anyNA(j) && !anyDuplicated(c$id) &&
        all(j %in% test) && all(depth[j] <= budget), paste0("candidate_constraints_", budget))
      if (nrow(c) > 1) {
        dist = utils::combn(j, 2, function(k) sum(letters[k[1], ] != letters[k[2], ]))
        demand(min(dist) >= 2, paste0("candidate_diversity_", budget))
      }
      pred = h[[paste0("pred_", chosen)]][match(c$id, h$id)]
      demand(close(c$prediction, pred), paste0("candidate_predictions_", budget))
      t = tradeoffs[tradeoffs$budget == budget, ]
      demand(nrow(t) == 1 && t$n_selected == nrow(c) &&
        (nrow(c) == 0 || close(t$mean_prediction, mean(pred))), paste0("tradeoff_", budget))
    }
    u = read("uncertainty.csv")
    demand(nrow(u) == 4 && all(u$n_valid >= 90 & u$n_valid <= 100) &&
      all(u$lower <= u$upper), "performance_sampling_uncertainty")
    stability = read("candidate-stability.csv")
    demand(setequal(stability$id, candidates$id[candidates$budget == 4]) &&
      all(stability$sd_prediction >= 0 & is.finite(stability$sd_prediction)),
      "candidate_bootstrap_stability")
  }, error = function(e) failures <<- c(failures, conditionMessage(e)))
  list(ok = !length(failures), checks = checks, failures = failures)
}
