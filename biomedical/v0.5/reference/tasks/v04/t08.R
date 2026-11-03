v04_t08 = function() {
  codes=c(
    paste0(
      "stopifnot(requireNamespace('limma',quietly=TRUE),is.matrix(raw$abundance",
      "),identical(colnames(raw$abundance),raw$samples$sample),identical(raw$sc",
      "ale,'log2_ratio_to_reference')); samples=raw$samples; stopifnot(all(c('s",
      "ample','patient','subtype','batch','channel','is_reference') %in% names(",
      "samples)))"
    ),
    paste0(
      "protein_qc=data.frame(sample=samples$sample,patient=samples$patient,subt",
      "ype=samples$subtype,batch=samples$batch,channel=samples$channel,is_refer",
      "ence=samples$is_reference,n_observed=colSums(is.finite(raw$abundance)),m",
      "issing_fraction=colMeans(!is.finite(raw$abundance))); write.csv(protein_",
      "qc,'protein-qc.csv',row.names=FALSE)"
    ),
    paste0(
      "eligible=!samples$is_reference & !is.na(samples$subtype) & nzchar(sample",
      "s$subtype) & samples$subtype %in% c('Basal','Her2','LumA','LumB'); x=raw",
      "$abundance[,eligible,drop=FALSE]; samples=samples[eligible,,drop=FALSE];",
      " stopifnot(all(c('Basal','LumA') %in% samples$subtype))"
    ),
    paste0(
      "patients=unique(samples$patient); collapsed=vapply(patients,function(p) ",
      "rowMeans(x[,samples$patient==p,drop=FALSE],na.rm=TRUE),numeric(nrow(x)))",
      "; rownames(collapsed)=rownames(x); samples=samples[match(patients,sample",
      "s$patient),,drop=FALSE]; samples$sample=samples$patient; colnames(collap",
      "sed)=samples$patient; collapsed[!is.finite(collapsed)]=NA_real_; stopifn",
      "ot(!anyDuplicated(samples$patient))"
    ),
    paste0(
      "offsets=apply(collapsed,2,stats::median,na.rm=TRUE); normalized=sweep(co",
      "llapsed,2,offsets,'-'); observed_by_subtype=sapply(split(seq_len(ncol(no",
      "rmalized)),samples$subtype),function(j) rowMeans(is.finite(normalized[,j",
      ",drop=FALSE]))); keep=apply(observed_by_subtype,1,max)>=.8; expr=normali",
      "zed[keep,,drop=FALSE]; samples$subtype=factor(samples$subtype,levels=c('",
      "LumA','Basal','Her2','LumB')); samples$batch=factor(samples$batch)"
    ),
    paste0(
      "design=stats::model.matrix(~0+subtype+batch,data=samples); stopifnot(qr(",
      "design)$rank==ncol(design),all(colSums(is.finite(expr))>0)); pca_input=e",
      "xpr; for(i in seq_len(nrow(pca_input))) pca_input[i,!is.finite(pca_input",
      "[i,])]=stats::median(pca_input[i,],na.rm=TRUE); pca=stats::prcomp(t(pca_",
      "input),center=TRUE,scale.=FALSE); write.csv(data.frame(patient=samples$p",
      "atient,batch=samples$batch,subtype=samples$subtype,PC1=pca$x[,1],PC2=pca",
      "$x[,2],median_offset=offsets),'batch-diagnostics.csv',row.names=FALSE)"
    ),
    paste0(
      "fit=limma::lmFit(expr,design); contrast=rep(0,ncol(design)); names(contr",
      "ast)=colnames(design); contrast['subtypeBasal']=1; contrast['subtypeLumA",
      "']=-1"
    ),
    paste0(
      "fit_contrast=limma::contrasts.fit(fit,contrasts=matrix(contrast,ncol=1,d",
      "imnames=list(names(contrast),'Basal-LumA'))); fit_contrast=limma::eBayes",
      "(fit_contrast,trend=TRUE,robust=FALSE)"
    ),
    paste0(
      "effects=data.frame(protein=rownames(expr),logFC=fit_contrast$coefficient",
      "s[,1],se=fit_contrast$stdev.unscaled[,1]*sqrt(fit_contrast$s2.post),t=fi",
      "t_contrast$t[,1],df=fit_contrast$df.total,p_value=fit_contrast$p.value[,",
      "1]); effects$fdr=p.adjust(effects$p_value,'BH'); effects=effects[order(e",
      "ffects$p_value,effects$protein),]; write.csv(effects,'protein-effects.cs",
      "v',row.names=FALSE)"
    ),
    paste0(
      "selected=effects$protein[!is.na(effects$fdr) & effects$fdr<.05 & abs(eff",
      "ects$logFC)>=.5]; universe=effects$protein; stopifnot(length(raw$pathway",
      "s)>0)"
    ),
    paste0(
      "enrich=function(selected,universe,sets) { selected=intersect(selected,un",
      "iverse); out=do.call(rbind,lapply(names(sets),function(n) { g=intersect(",
      "unique(sets[[n]]),universe); a=length(intersect(selected,g)); b=length(s",
      "etdiff(selected,g)); c=length(setdiff(g,selected)); d=length(setdiff(uni",
      "verse,union(selected,g))); z=stats::fisher.test(matrix(c(a,b,c,d),2)); d",
      "ata.frame(pathway=n,background=length(universe),size=length(g),selected=",
      "length(selected),hits=a,p_value=z$p.value) })); out$fdr=stats::p.adjust(",
      "out$p_value,'BH'); out }; environment(enrich)=baseenv()"
    ),
    paste0(
      "functional=enrich(selected,universe,raw$pathways); write.csv(functional,",
      "'functional-results.csv',row.names=FALSE)"
    ),
    paste0(
      "write.csv(data.frame(protein=rownames(normalized),retained=keep,missing_",
      "fraction=rowMeans(!is.finite(normalized))),'protein-filter.csv',row.name",
      "s=FALSE); write.csv(data.frame(patient=samples$patient,subtype=samples$s",
      "ubtype,batch=samples$batch),'patient-design.csv',row.names=FALSE)"
    ),
    paste0(
      "grDevices::pdf('protein-diagnostics.pdf'); graphics::plot(pca$x[,1:2],co",
      "l=as.integer(samples$subtype),pch=16,xlab='PC1',ylab='PC2'); graphics::p",
      "lot(effects$logFC,-log10(pmax(effects$p_value,.Machine$double.xmin)),pch",
      "=16,cex=.4,xlab='Basal versus LumA log2 ratio',ylab='-log10 P'); grDevic",
      "es::dev.off()"
    ),
    paste0(
      "write.csv(data.frame(n_aliquots=sum(eligible),n_patients=nrow(samples),n",
      "_proteins=nrow(expr),n_selected=length(selected),contrast='Basal-LumA',r",
      "eference_scale=raw$scale),'analysis-audit.csv',row.names=FALSE)"
    ),
    paste0(
      "complete=expr[rowSums(!is.finite(expr))==0,,drop=FALSE]; stopifnot(nrow(",
      "complete)>=20); complete_fit=limma::eBayes(limma::contrasts.fit(limma::l",
      "mFit(complete,design),matrix(contrast,ncol=1)),trend=TRUE,robust=FALSE)"
    ),
    paste0(
      "imputed=expr; for(i in seq_len(nrow(imputed))) { observed=imputed[i,is.f",
      "inite(imputed[i,])]; imputed[i,!is.finite(imputed[i,])]=stats::quantile(",
      "observed,.05,names=FALSE) }; imputed_fit=limma::eBayes(limma::contrasts.",
      "fit(limma::lmFit(imputed,design),matrix(contrast,ncol=1)),trend=TRUE,rob",
      "ust=FALSE)"
    ),
    paste0(
      "strict_keep=rowMeans(is.finite(normalized))>=.9; strict=normalized[stric",
      "t_keep,,drop=FALSE]; stopifnot(nrow(strict)>=20); strict_fit=limma::eBay",
      "es(limma::contrasts.fit(limma::lmFit(strict,design),matrix(contrast,ncol",
      "=1)),trend=TRUE,robust=FALSE)"
    ),
    paste0(
      "sensitivity=rbind(data.frame(protein=rownames(complete),method='complete",
      "',logFC=complete_fit$coefficients[,1],p_value=complete_fit$p.value[,1],f",
      "dr=p.adjust(complete_fit$p.value[,1],'BH')),data.frame(protein=rownames(",
      "imputed),method='low_tail_imputed',logFC=imputed_fit$coefficients[,1],p_",
      "value=imputed_fit$p.value[,1],fdr=p.adjust(imputed_fit$p.value[,1],'BH')",
      "),data.frame(protein=rownames(strict),method='observed_90pct',logFC=stri",
      "ct_fit$coefficients[,1],p_value=strict_fit$p.value[,1],fdr=p.adjust(stri",
      "ct_fit$p.value[,1],'BH'))); write.csv(sensitivity,'missingness-sensitivi",
      "ty.csv',row.names=FALSE)"
    ),
    paste0(
      "sensitivity_function=do.call(rbind,lapply(split(sensitivity,sensitivity$",
      "method),function(z) { out=enrich(z$protein[z$fdr<.05 & abs(z$logFC)>=.5]",
      ",z$protein,raw$pathways); out$method=z$method[1]; out })); write.csv(sen",
      "sitivity_function,'functional-sensitivity.csv',row.names=FALSE)"
    ),
    paste0(
      "stability=do.call(rbind,lapply(split(sensitivity,sensitivity$method),fun",
      "ction(z) { common=match(z$protein,effects$protein); data.frame(method=z$",
      "method[1],n_proteins=nrow(z),spearman=stats::cor(z$logFC,effects$logFC[c",
      "ommon],use='complete.obs',method='spearman'),n_selected=sum(z$fdr<.05 & ",
      "abs(z$logFC)>=.5,na.rm=TRUE)) })); write.csv(stability,'effect-stability",
      ".csv',row.names=FALSE)"
    ),
    paste0(
      "writeLines(c('# CPTAC breast proteome subtype analysis',sprintf('%d elig",
      "ible aliquots collapsed to %d patients and %d tested proteins.',sum(elig",
      "ible),nrow(samples),nrow(expr)),'Input is log2 ratio to a common iTRAQ r",
      "eference; values were not logged twice.','Patient-level technical replic",
      "ates were averaged on the log2 scale; per-sample medians were removed.',",
      "'The primary limma model adjusts batch and tests Basal versus LumA with ",
      "empirical Bayes moderation.','Functional tests use the tested-protein un",
      "iverse and BH correction.','Complete-case, low-tail-imputation and stric",
      "ter-filter fits are sensitivity analyses, not proof that missingness is ",
      "ignorable.','Interpret functional and effect stability from functional-s",
      "ensitivity.csv and effect-stability.csv.','Subtype differences are obser",
      "vational and depend on the supplied subtype and channel mappings.'),'res",
      "earch-report.md')"
    )
  )
  groups=rep(1:3,c(6,9,7))
  q1=c("samples","eligible","offsets","normalized","expr","design","keep","pca")
  q2=c("contrast","effects","enrich","selected","universe","functional")
  list(id="T08",dependencies="limma",
    artifacts=c("protein-qc.csv","batch-diagnostics.csv","protein-effects.csv",
      "functional-results.csv","missingness-sensitivity.csv","protein-filter.csv",
      "patient-design.csv","analysis-audit.csv","protein-diagnostics.pdf",
      "functional-sensitivity.csv","effect-stability.csv","research-report.md"),
    steps=lapply(seq_along(codes),function(i) list(request=groups[i],
      reads=if(i==1) "raw" else if(i==7) c("raw",q1) else if(i==16) c("raw",q1,q2) else character(),
      writes=if(i==6) q1 else if(i==15) q2 else character(),code=codes[i])))
}

v04_check_t08 = function(workspace,raw) {
  fail=character()
  tryCatch({
    read=function(n) utils::read.csv(file.path(workspace,n),stringsAsFactors=FALSE)
    stopifnot(all(file.exists(file.path(workspace,v04_t08()$artifacts))))
    qc=read("protein-qc.csv"); e=read("protein-effects.csv"); f=read("functional-results.csv")
    s=read("missingness-sensitivity.csv"); patient=read("patient-design.csv")
    stopifnot(identical(qc$sample,raw$samples$sample),
      all(qc$n_observed==colSums(is.finite(raw$abundance))),!anyDuplicated(patient$patient),
      all(is.finite(e$logFC)),all(e$se>0),
      max(abs(e$fdr-p.adjust(e$p_value,"BH")),na.rm=TRUE)<1e-8,
      max(abs(e$t-e$logFC/e$se),na.rm=TRUE)<1e-6,
      max(abs(e$p_value-2*stats::pt(-abs(e$t),df=e$df)),na.rm=TRUE)<1e-8,
      all(f$background==nrow(e)),max(abs(f$fdr-p.adjust(f$p_value,"BH")))<1e-8,
      setequal(unique(s$method),c('complete','low_tail_imputed','observed_90pct')))
    for(z in split(s,s$method)) stopifnot(max(abs(z$fdr-p.adjust(z$p_value,'BH')),na.rm=TRUE)<1e-8)
    selected=e$protein[!is.na(e$fdr) & e$fdr<.05 & abs(e$logFC)>=.5]
    for(i in seq_len(nrow(f))) {
      genes=intersect(unique(raw$pathways[[f$pathway[i]]]),e$protein)
      a=length(intersect(selected,genes));b=length(setdiff(selected,genes))
      c=length(setdiff(genes,selected));d=length(setdiff(e$protein,union(selected,genes)))
      test=stats::fisher.test(matrix(c(a,b,c,d),2))
      stopifnot(f$hits[i]==a,f$size[i]==length(genes),abs(f$p_value[i]-test$p.value)<1e-8)
    }
    # Check primary coefficients using independent ordinary least squares on original data.
    eligible=!raw$samples$is_reference & raw$samples$subtype %in% c('Basal','Her2','LumA','LumB')
    meta=raw$samples[eligible,,drop=FALSE]; x=raw$abundance[,eligible,drop=FALSE]
    ids=unique(meta$patient); x=vapply(ids,function(p) rowMeans(x[,meta$patient==p,drop=FALSE],na.rm=TRUE),numeric(nrow(x)))
    rownames(x)=rownames(raw$abundance); meta=meta[match(ids,meta$patient),,drop=FALSE]
    x=sweep(x,2,apply(x,2,stats::median,na.rm=TRUE),'-')
    meta$subtype=factor(meta$subtype,levels=c('LumA','Basal','Her2','LumB')); meta$batch=factor(meta$batch)
    design=stats::model.matrix(~0+subtype+batch,meta)
    ix=unique(round(seq(1,nrow(e),length.out=min(31,nrow(e)))))
    for(i in ix) {
      y=x[e$protein[i],]; ok=is.finite(y); coef=stats::lm.fit(design[ok,,drop=FALSE],y[ok])$coefficients
      expected=coef[match('subtypeBasal',colnames(design))]-coef[match('subtypeLumA',colnames(design))]
      stopifnot(abs(expected-e$logFC[i])<1e-6)
    }
    stopifnot(file.info(file.path(workspace,'research-report.md'))$size>100)
  },error=function(e) fail <<- conditionMessage(e))
  list(ok=length(fail)==0L,checks=list(input_scale_and_patients=length(fail)==0L,
    independent_ols=length(fail)==0L,moderated_statistics=length(fail)==0L,
    missingness_sensitivity=length(fail)==0L),failures=fail)
}
