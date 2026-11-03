v04_t03 = function() {
  codes = c(
    paste0(
      "stopifnot(requireNamespace('edgeR',quietly=TRUE),requireNamespace('limma",
      "',quietly=TRUE)); stopifnot(is.matrix(raw$counts),identical(colnames(raw",
      "$counts),raw$samples$sample),!anyDuplicated(raw$samples$sample),all(is.f",
      "inite(raw$counts)),all(raw$counts>=0),all(raw$counts==round(raw$counts))",
      "); samples=raw$samples; samples$group=factor(samples$group,levels=c('Nor",
      "mal','Tumor')); samples$batch=factor(samples$batch)"
    ),
    paste0(
      "design=stats::model.matrix(~ batch + group,data=samples); stopifnot(qr(d",
      "esign)$rank==ncol(design)); library_size=colSums(raw$counts); stopifnot(",
      "all(library_size>0))"
    ),
    paste0(
      "sample_qc=data.frame(sample=samples$sample,patient=samples$patient,group",
      "=samples$group,batch=samples$batch,library_size=library_size,detected_ge",
      "nes=colSums(raw$counts>0)); write.csv(sample_qc,'sample-qc.csv',row.name",
      "s=FALSE)"
    ),
    paste0(
      "pair_table=table(samples$patient,samples$group); paired_patients=rowname",
      "s(pair_table)[rowSums(pair_table>0)==2]; write.csv(data.frame(patient=ro",
      "wnames(pair_table),normal=pair_table[,1],tumor=pair_table[,2]),'patient-",
      "pairing.csv',row.names=FALSE)"
    ),
    paste0(
      "dge=edgeR::DGEList(raw$counts); keep=edgeR::filterByExpr(dge,design=desi",
      "gn); dge=dge[keep,,keep.lib.sizes=FALSE]; dge=edgeR::calcNormFactors(dge",
      ",method='TMM'); stopifnot(nrow(dge)>20)"
    ),
    paste0(
      "log_cpm=edgeR::cpm(dge,log=TRUE,prior.count=2); pca=stats::prcomp(t(log_",
      "cpm),center=TRUE,scale.=FALSE); pca_table=data.frame(sample=samples$samp",
      "le,PC1=pca$x[,1],PC2=pca$x[,2],group=samples$group,batch=samples$batch);",
      " write.csv(pca_table,'pca.csv',row.names=FALSE)"
    ),
    paste0(
      "write.csv(data.frame(gene=rownames(raw$counts),retained=keep),'gene-filt",
      "er.csv',row.names=FALSE); write.csv(data.frame(sample=samples$sample,fac",
      "tor=dge$samples$norm.factors),'normalization.csv',row.names=FALSE)"
    ),
    "dge=edgeR::estimateDisp(dge,design,robust=FALSE)",
    paste0(
      "fit=edgeR::glmQLFit(dge,design,robust=FALSE); contrast_index=match('grou",
      "pTumor',colnames(design)); stopifnot(!is.na(contrast_index))"
    ),
    paste0(
      "test=edgeR::glmQLFTest(fit,coef=contrast_index); de=data.frame(gene=rown",
      "ames(test$table),test$table,check.names=FALSE); names(de)[names(de)=='PV",
      "alue']='p_value'; de$fdr=p.adjust(de$p_value,'BH')"
    ),
    paste0(
      "de=de[order(de$p_value,de$gene),]; write.csv(de,'differential-expression",
      ".csv',row.names=FALSE)"
    ),
    paste0(
      "write.csv(data.frame(gene=rownames(dge),common_dispersion=dge$common.dis",
      "persion,tagwise_dispersion=dge$tagwise.dispersion),'dispersion-diagnosti",
      "cs.csv',row.names=FALSE)"
    ),
    paste0(
      "universe=rownames(dge); selected=de$gene[de$fdr<0.05 & abs(de$logFC)>=1]",
      "; stopifnot(length(raw$pathways)>0)"
    ),
    paste0(
      "pathway_test=function(selected,universe,sets) { selected=intersect(selec",
      "ted,universe); out=lapply(names(sets),function(n) { g=intersect(unique(s",
      "ets[[n]]),universe); a=length(intersect(g,selected)); b=length(setdiff(s",
      "elected,g)); c=length(setdiff(g,selected)); d=length(setdiff(universe,un",
      "ion(g,selected))); z=stats::fisher.test(matrix(c(a,b,c,d),2)); data.fram",
      "e(pathway=n,background=length(universe),size=length(g),selected=length(s",
      "elected),hits=a,p_value=z$p.value) }); z=do.call(rbind,out); z$fdr=stats",
      "::p.adjust(z$p_value,'BH'); z[order(z$p_value,z$pathway),] }; environmen",
      "t(pathway_test)=baseenv()"
    ),
    paste0(
      "pathways=pathway_test(selected,universe,raw$pathways); write.csv(pathway",
      "s,'pathways.csv',row.names=FALSE)"
    ),
    paste0(
      "grDevices::pdf('expression-diagnostics.pdf'); graphics::plot(pca$x[,1:2]",
      ",col=as.integer(samples$group),pch=16,xlab='PC1',ylab='PC2'); graphics::",
      "plot(de$logFC,-log10(pmax(de$p_value,.Machine$double.xmin)),pch=16,cex=.",
      "3,xlab='Tumor versus normal log2 FC',ylab='-log10 P'); grDevices::dev.of",
      "f()"
    ),
    paste0(
      "write.csv(data.frame(n_samples=ncol(dge),n_genes=nrow(dge),n_pairs=lengt",
      "h(paired_patients),n_selected=length(selected),contrast='Tumor-Normal',m",
      "ethod='edgeR TMM quasi-likelihood negative binomial; batch-adjusted'),'a",
      "nalysis-audit.csv',row.names=FALSE)"
    ),
    paste0(
      "pair_samples=samples$patient %in% paired_patients; stopifnot(length(pair",
      "ed_patients)>=3); ps=droplevels(samples[pair_samples,,drop=FALSE]); pair",
      "ed_design=stats::model.matrix(~ factor(patient) + group,data=ps); stopif",
      "not(qr(paired_design)$rank==ncol(paired_design))"
    ),
    paste0(
      "pd=edgeR::DGEList(raw$counts[,pair_samples,drop=FALSE]); pk=edgeR::filte",
      "rByExpr(pd,design=paired_design); pd=edgeR::calcNormFactors(pd[pk,,keep.",
      "lib.sizes=FALSE]); pd=edgeR::estimateDisp(pd,paired_design); pf=edgeR::g",
      "lmQLFit(pd,paired_design); pt=edgeR::glmQLFTest(pf,coef=match('groupTumo",
      "r',colnames(paired_design)))"
    ),
    paste0(
      "paired=data.frame(gene=rownames(pt$table),logFC=pt$table$logFC,p_value=p",
      "t$table$PValue); paired$fdr=p.adjust(paired$p_value,'BH'); write.csv(pai",
      "red,'paired-expression.csv',row.names=FALSE)"
    ),
    paste0(
      "ak=rowSums(edgeR::cpm(raw$counts)>=2)>=min(table(samples$group)); ad=edg",
      "eR::calcNormFactors(edgeR::DGEList(raw$counts[ak,,drop=FALSE])); ad=edge",
      "R::estimateDisp(ad,design); af=edgeR::glmQLFit(ad,design); at=edgeR::glm",
      "QLFTest(af,coef=contrast_index); alternative=data.frame(gene=rownames(at",
      "$table),logFC=at$table$logFC,p_value=at$table$PValue); alternative$fdr=p",
      ".adjust(alternative$p_value,'BH')"
    ),
    paste0(
      "sensitivity=merge(de[c('gene','logFC','fdr')],paired[c('gene','logFC','f",
      "dr')],by='gene',suffixes=c('_full','_paired')); sensitivity=merge(sensit",
      "ivity,alternative[c('gene','logFC','fdr')],by='gene'); names(sensitivity",
      ")[names(sensitivity)=='logFC']='logFC_filter'; names(sensitivity)[names(",
      "sensitivity)=='fdr']='fdr_filter'; write.csv(sensitivity,'design-sensiti",
      "vity.csv',row.names=FALSE)"
    ),
    paste0(
      "paired_pathways=pathway_test(paired$gene[paired$fdr<.05 & abs(paired$log",
      "FC)>=1],paired$gene,raw$pathways); alternative_pathways=pathway_test(alt",
      "ernative$gene[alternative$fdr<.05 & abs(alternative$logFC)>=1],alternati",
      "ve$gene,raw$pathways); write.csv(paired_pathways,'paired-pathways.csv',r",
      "ow.names=FALSE); write.csv(alternative_pathways,'filter-pathways.csv',ro",
      "w.names=FALSE)"
    ),
    paste0(
      "writeLines(c('# TCGA-LUAD tumor-normal expression',sprintf('%d samples, ",
      "%d retained genes and %d paired patients.',nrow(samples),nrow(dge),lengt",
      "h(paired_patients)),'TMM normalization and negative-binomial quasi-likel",
      "ihood models adjust the full cohort for batch.','The paired sensitivity ",
      "design controls patient and tissue group.','Differential genes require B",
      "H FDR <0.05 and absolute log2 fold change >=1.','Pathway Fisher tests us",
      "e the actual tested-gene universe, with BH correction.',sprintf('Full ve",
      "rsus paired logFC Spearman correlation: %.4f.',stats::cor(sensitivity$lo",
      "gFC_full,sensitivity$logFC_paired,method='spearman')),'Interpret pathway",
      " stability from paired-pathways.csv and filter-pathways.csv.','Tumor-nor",
      "mal differences remain observational and can reflect cell composition.')",
      ",'research-report.md')"
    )
  )
  groups=rep(1:3,c(7,10,7))
  q1=c("samples","design","library_size","paired_patients","dge","pca","keep")
  q2=c("contrast_index","de","universe","selected","pathway_test","pathways")
  list(id="T03",dependencies=c("edgeR","limma"),
    artifacts=c("sample-qc.csv","pca.csv","differential-expression.csv","pathways.csv",
      "design-sensitivity.csv","patient-pairing.csv","gene-filter.csv","normalization.csv",
      "dispersion-diagnostics.csv","analysis-audit.csv","paired-expression.csv",
      "paired-pathways.csv","filter-pathways.csv","expression-diagnostics.pdf","research-report.md"),
    steps=lapply(seq_along(codes),function(i) list(request=groups[i],
      reads=if(i==1) "raw" else if(i==8) c("raw",q1) else if(i==18) c("raw",q1,q2) else character(),
      writes=if(i==7) q1 else if(i==17) q2 else character(),code=codes[i])))
}

v04_check_t03 = function(workspace,raw) {
  fail=character()
  tryCatch({
    read=function(n) utils::read.csv(file.path(workspace,n),stringsAsFactors=FALSE)
    stopifnot(all(file.exists(file.path(workspace,v04_t03()$artifacts))))
    q=read("sample-qc.csv"); d=read("differential-expression.csv"); p=read("pathways.csv")
    s=read("design-sensitivity.csv"); filter=read("gene-filter.csv"); pc=read("pca.csv")
    if(is.null(filter$retained)) filter$retained=filter$keep
    stopifnot(is.logical(filter$retained),!anyNA(filter$retained),
      !anyDuplicated(filter$gene),setequal(filter$gene,rownames(raw$counts)))
    stopifnot(identical(q$sample,raw$samples$sample),all(q$library_size==colSums(raw$counts)),
      all(q$detected_genes==colSums(raw$counts>0)),!anyDuplicated(d$gene),
      setequal(d$gene,filter$gene[filter$retained]),all(d$p_value>=0 & d$p_value<=1),
      max(abs(d$fdr-p.adjust(d$p_value,"BH")))<1e-8,
      all(p$background==nrow(d)),max(abs(p$fdr-p.adjust(p$p_value,"BH")))<1e-8)
    # Re-estimate the model independently of the agent's fitted objects and exported statistics.
    meta=raw$samples;meta$group=factor(meta$group,levels=c('Normal','Tumor'))
    meta$batch=factor(meta$batch); design=stats::model.matrix(~batch+group,meta)
    reference=edgeR::DGEList(raw$counts)
    retained=edgeR::filterByExpr(reference,design=design)
    reference=edgeR::calcNormFactors(reference[retained,,keep.lib.sizes=FALSE])
    reference=edgeR::estimateDisp(reference,design,robust=FALSE)
    # edgeR 4.8 QL refits with adjusted dispersions; an ordinary NB fit is not equivalent.
    ql_fit=edgeR::glmQLFit(reference,design,robust=FALSE)
    ql_test=edgeR::glmQLFTest(ql_fit,coef=match('groupTumor',colnames(design)))$table
    j=match(d$gene,rownames(ql_test))
    stopifnot(!anyNA(j),max(abs(d$logFC-ql_test$logFC[j]))<1e-6,
      max(abs(d$p_value-ql_test$PValue[j]))<1e-6,
      max(abs(d$F-ql_test$F[j]))<1e-6,setequal(d$gene,rownames(reference)))
    audit=read('analysis-audit.csv');pair=table(meta$patient,meta$group)
    stopifnot(audit$n_samples==nrow(meta),audit$n_genes==nrow(reference),
      audit$n_pairs==sum(rowSums(pair>0)==2),audit$contrast=='Tumor-Normal')
    # Independently reconstruct pathway contingency tables from reported tested genes/effects.
    sel=d$gene[d$fdr<.05 & abs(d$logFC)>=1]
    for(i in seq_len(nrow(p))) {
      genes=intersect(unique(raw$pathways[[p$pathway[i]]]),d$gene)
      a=sum(sel %in% genes); b=length(sel)-a; c=length(genes)-a
      z=fisher.test(matrix(c(a,b,c,nrow(d)-a-b-c),2))
      stopifnot(p$hits[i]==a,p$size[i]==length(genes),abs(p$p_value[i]-z$p.value)<1e-8)
    }
    stopifnot(nrow(s)>20,all(is.finite(as.matrix(s[c('logFC_full','logFC_paired','logFC_filter')]))),
      identical(pc$sample,raw$samples$sample),abs(sum(pc$PC1))<1e-5,
      file.info(file.path(workspace,"research-report.md"))$size>100)
  },error=function(e) fail <<- conditionMessage(e))
  list(ok=length(fail)==0L,checks=list(input_and_filter=length(fail)==0L,
    multiple_testing=length(fail)==0L,pathway_recomputation=length(fail)==0L,
    design_sensitivity=length(fail)==0L),failures=fail)
}
