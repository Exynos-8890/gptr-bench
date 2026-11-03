v04_t04 = function() {
  list(id = "T04",
    artifacts = c("sample-qc.csv", "variant-qc.csv", "within-population-hwe.csv", "pca.csv", "fst.csv", "robustness.csv", "pca-subspace.csv", "pruned-variants.csv", "sensitivity-pruned-variants.csv", "ld-audit.csv", "design-audit.csv", "population-pca.png", "research-report.md"),
    steps = list(
    list(request = 1L, reads = c("raw"), writes = c("emit"), code = r"---(stopifnot(is.matrix(raw$genotypes),nrow(raw$genotypes)==nrow(raw$samples),ncol(raw$genotypes)==nrow(raw$variants),identical(rownames(raw$genotypes),raw$samples$sample),all(is.na(raw$genotypes) | raw$genotypes %in% 0:2))
emit = function(x,p) utils::write.csv(x,p,row.names=FALSE)
environment(emit)=baseenv())---"),
    list(request = 1L, reads = c("raw", "emit"), writes = c("sample_qc"), code = r"---(sample_qc=data.frame(sample=raw$samples$sample,pop=raw$samples$pop,super_pop=raw$samples$super_pop,missing=rowMeans(is.na(raw$genotypes)),heterozygosity=rowMeans(raw$genotypes==1,na.rm=TRUE))
emit(sample_qc,'sample-qc.csv'))---"),
    list(request = 1L, reads = c("raw"), writes = c("variant_qc"), code = r"---(af=colMeans(raw$genotypes,na.rm=TRUE)/2
variant_qc=data.frame(id=raw$variants$id,position=raw$variants$position,missing=colMeans(is.na(raw$genotypes)),maf=pmin(af,1-af)))---"),
    list(request = 1L, reads = c("raw"), writes = c("hwe_fn"), code = r"---(hwe_fn=function(g,pops) {
 do.call(rbind,lapply(sort(unique(pops)),function(pop){
 x=g[pops==pop,,drop=FALSE]
 observed=rbind(colSums(x==0,na.rm=TRUE),colSums(x==1,na.rm=TRUE),colSums(x==2,na.rm=TRUE))
 n=colSums(observed); p=colMeans(x,na.rm=TRUE)/2
 expected=rbind(n*(1-p)^2,n*2*p*(1-p),n*p^2)
 chi=colSums((observed-expected)^2/pmax(expected,1e-12))
 data.frame(pop=pop,id=colnames(g),n=n,p_value=stats::pchisq(chi,df=1,lower.tail=FALSE))
 }))
}
environment(hwe_fn)=baseenv())---"),
    list(request = 1L, reads = c("raw", "hwe_fn"), writes = c("hwe"), code = r"---(hwe=hwe_fn(raw$genotypes,raw$samples$pop)
hwe$fdr=stats::p.adjust(hwe$p_value,'BH'))---"),
    list(request = 1L, reads = c("hwe", "variant_qc", "sample_qc"), writes = c("keep_samples", "keep_variants"), code = r"---(keep_samples=sample_qc$missing<=.02
minimum_hwe=tapply(hwe$p_value,hwe$id,min,na.rm=TRUE)
variant_qc$min_within_population_hwe=as.numeric(minimum_hwe[variant_qc$id])
keep_variants=variant_qc$missing<=.02 & variant_qc$maf>=.05 & variant_qc$min_within_population_hwe>=1e-6
stopifnot(sum(keep_samples)>=20,sum(keep_variants)>=10))---"),
    list(request = 1L, reads = c("variant_qc", "hwe", "sample_qc", "keep_samples", "keep_variants", "emit"), writes = character(), code = r"---(variant_qc$keep=keep_variants
sample_qc$keep=keep_samples
emit(variant_qc,'variant-qc.csv');emit(sample_qc,'sample-qc.csv');emit(hwe,'within-population-hwe.csv'))---"),
    list(request = 2L, reads = c("raw", "keep_samples", "keep_variants"), writes = c("g", "position", "labels"), code = r"---(g=raw$genotypes[keep_samples,keep_variants,drop=FALSE]
position=raw$variants$position[keep_variants]
labels=raw$samples[keep_samples,]
for(j in seq_len(ncol(g))) g[is.na(g[,j]),j]=mean(g[,j],na.rm=TRUE))---"),
    list(request = 2L, reads = c("g", "position"), writes = c("ld_fn"), code = r"---(ld_fn=function(g,position,r2=.2,window=500000) {
 retain=integer()
 for(j in seq_len(ncol(g))) {
  neighbours=retain[position[j]-position[retain]<=window]
  if(!length(neighbours) || all(stats::cor(g[,j],g[,neighbours,drop=FALSE])^2<=r2,na.rm=TRUE)) retain=c(retain,j)
 }
 retain
}
environment(ld_fn)=baseenv())---"),
    list(request = 2L, reads = c("g", "position", "ld_fn"), writes = c("pruned"), code = r"---(pruned=ld_fn(g,position,.2,500000)
stopifnot(length(pruned)>=5))---"),
    list(request = 2L, reads = c("g", "pruned"), writes = c("standardized", "frequency"), code = r"---(frequency=colMeans(g[,pruned,drop=FALSE])/2
standardized=sweep(sweep(g[,pruned,drop=FALSE],2,2*frequency,'-'),2,sqrt(2*frequency*(1-frequency)),'/'))---"),
    list(request = 2L, reads = c("standardized", "labels", "emit"), writes = c("pca", "pca_table"), code = r"---(pca=stats::prcomp(standardized,center=FALSE,scale.=FALSE,rank.=5)
pca_table=data.frame(sample=labels$sample,super_pop=labels$super_pop,pca$x[,seq_len(min(5,ncol(pca$x))),drop=FALSE])
emit(pca_table,'pca.csv'))---"),
    list(request = 2L, reads = c("g", "labels"), writes = c("fst_fn"), code = r"---(fst_fn=function(g,groups) {
 pairs=utils::combn(sort(unique(groups)),2,simplify=FALSE)
 do.call(rbind,lapply(pairs,function(pair){
 a=g[groups==pair[1],,drop=FALSE];b=g[groups==pair[2],,drop=FALSE]
 n1=colSums(!is.na(a));n2=colSums(!is.na(b));p1=colMeans(a,na.rm=TRUE)/2;p2=colMeans(b,na.rm=TRUE)/2
 numerator=(p1-p2)^2-p1*(1-p1)/pmax(1,2*n1-1)-p2*(1-p2)/pmax(1,2*n2-1)
 denominator=p1*(1-p2)+p2*(1-p1)
 data.frame(pop1=pair[1],pop2=pair[2],n1=nrow(a),n2=nrow(b),variants=ncol(g),fst=sum(numerator,na.rm=TRUE)/sum(denominator,na.rm=TRUE))
 }))
}
environment(fst_fn)=baseenv())---"),
    list(request = 2L, reads = c("raw", "keep_samples", "keep_variants", "labels", "fst_fn"), writes = c("fst"), code = r"---(fst=fst_fn(raw$genotypes[keep_samples,keep_variants,drop=FALSE],labels$super_pop))---"),
    list(request = 2L, reads = c("fst", "pruned", "g", "emit"), writes = c("ld_audit"), code = r"---(emit(fst,'fst.csv')
ld_audit=data.frame(variants_before=ncol(g),variants_after=length(pruned),r_squared=.2,window_bp=500000)
emit(ld_audit,'ld-audit.csv');emit(data.frame(id=colnames(g)[pruned]),'pruned-variants.csv'))---"),
    list(request = 2L, reads = c("pca_table"), writes = character(), code = r"---(grDevices::png('population-pca.png',width=1000,height=750)
colors=as.integer(factor(pca_table$super_pop));graphics::plot(pca_table$PC1,pca_table$PC2,col=colors,pch=16,xlab='PC1',ylab='PC2')
graphics::legend('topright',legend=levels(factor(pca_table$super_pop)),col=seq_along(unique(colors)),pch=16)
grDevices::dev.off())---"),
    list(request = 3L, reads = c("g", "position", "ld_fn"), writes = c("alt_pruned", "alt_standardized"), code = r"---(alt_pruned=ld_fn(g,position,.1,500000)
p_alt=colMeans(g[,alt_pruned,drop=FALSE])/2
alt_standardized=sweep(sweep(g[,alt_pruned,drop=FALSE],2,2*p_alt,'-'),2,sqrt(2*p_alt*(1-p_alt)),'/'))---"),
    list(request = 3L, reads = c("alt_standardized", "pca"), writes = c("alt_pca", "alignment"), code = r"---(alt_pca=stats::prcomp(alt_standardized,center=FALSE,scale.=FALSE,rank.=5)
u=qr.Q(qr(pca$x[,1:5,drop=FALSE]));v=qr.Q(qr(alt_pca$x[,1:5,drop=FALSE]))
alignment=svd(crossprod(u,v),nu=0,nv=0)$d)---"),
    list(request = 3L, reads = c("raw", "keep_samples", "variant_qc", "labels", "fst_fn"), writes = c("strict_fst"), code = r"---(strict_variants=variant_qc$missing<=.01 & variant_qc$maf>=.10 & variant_qc$min_within_population_hwe>=1e-6
strict_fst=fst_fn(raw$genotypes[keep_samples,strict_variants,drop=FALSE],labels$super_pop))---"),
    list(request = 3L, reads = c("fst", "strict_fst", "alignment", "emit", "alt_pruned"), writes = c("robustness"), code = r"---(robustness=merge(fst[c('pop1','pop2','fst')],strict_fst[c('pop1','pop2','fst')],by=c('pop1','pop2'),suffixes=c('_baseline','_strict'))
robustness$absolute_change=abs(robustness$fst_strict-robustness$fst_baseline)
emit(robustness,'robustness.csv');emit(data.frame(component=seq_along(alignment),cos_principal_angle=alignment),'pca-subspace.csv')
emit(data.frame(id=colnames(g)[alt_pruned]),'sensitivity-pruned-variants.csv'))---"),
    list(request = 3L, reads = c("raw", "variant_qc", "sample_qc", "pruned", "emit"), writes = c("design_audit"), code = r"---(design_audit=data.frame(samples_input=nrow(raw$genotypes),variants_input=ncol(raw$genotypes),samples_kept=sum(sample_qc$keep),variants_kept=sum(variant_qc$keep),variants_ld=length(pruned),hwe_unit='within original population',fst_method='Hudson ratio of summed numerator/denominator')
emit(design_audit,'design-audit.csv'))---"),
    list(request = 3L, reads = c("design_audit", "robustness", "alignment"), writes = character(), code = r"---(writeLines(c('# Population structure and differentiation',paste('Samples:',design_audit$samples_kept,'QC variants:',design_audit$variants_kept,'LD-pruned:',design_audit$variants_ld),
'QC uses missingness2%, MAF5%, minimum within-population Pearson HWE P1e-6.',
'PCA uses mean-imputed genotypes standardized by sqrt(2p(1-p)); LD pruning r2=.2 in500kb.',
'Hudson Fst uses un-imputed QC dosages and the ratio of summed unbiased numerator to heterozygosity denominator.',
paste('Minimum principal-subspace cosine under r2=.1:',min(alignment)),
paste('Maximum absolute Fst change under stricter MAF/missingness:',max(robustness$absolute_change)),
'Population labels describe sampled ancestry structure; they are not discrete biological races. Finite-sample Fst can be negative.',
'Chr22 and deterministic4000bp sampling limit genome-wide inference. HWE is assessed within populations, not across mixed ancestry.'),'research-report.md'))---")
    ))
}

v04_check_t04 = function(workspace,raw) {
 failures=character();checks=list()
 check=function(n,x){checks[[n]] <<- isTRUE(x);if(!isTRUE(x))failures <<- c(failures,n)}
 tryCatch({
 read=function(n)utils::read.csv(file.path(workspace,n),stringsAsFactors=FALSE)
 sample=read('sample-qc.csv');variant=read('variant-qc.csv');pca=read('pca.csv');fst=read('fst.csv')
 check('sample_ids',identical(as.character(sample$sample),raw$samples$sample))
 check('variant_ids',identical(as.character(variant$id),raw$variants$id))
 check('missingness',max(abs(sample$missing-rowMeans(is.na(raw$genotypes))))<1e-10)
 expected_maf=pmin(colMeans(raw$genotypes,na.rm=TRUE)/2,1-colMeans(raw$genotypes,na.rm=TRUE)/2)
 check('maf',max(abs(variant$maf-expected_maf))<1e-10)
 check('pca_sample_set',setequal(pca$sample,sample$sample[sample$keep]))
 scores=as.matrix(pca[paste0('PC',1:5)])
 check('pca_centered',max(abs(colMeans(scores)))<1e-6)
 check('pca_orthogonal',max(abs(stats::cor(scores)-diag(5)))<1e-6)
 check('fst_pairs',nrow(fst)==choose(length(unique(pca$super_pop)),2))
 check('fst_range',all(is.finite(fst$fst)&fst$fst<=1&fst$fst>= -1))
 genotype = raw$genotypes[sample$keep, variant$keep, drop = FALSE]
 super = raw$samples$super_pop[sample$keep]
 expected_fst = vapply(seq_len(nrow(fst)), function(i) {
   first = genotype[super == fst$pop1[i], , drop = FALSE]
   second = genotype[super == fst$pop2[i], , drop = FALSE]
   n_first = 2 * colSums(!is.na(first))
   n_second = 2 * colSums(!is.na(second))
   p_first = colSums(first, na.rm = TRUE) / n_first
   p_second = colSums(second, na.rm = TRUE) / n_second
   numerator = (p_first - p_second)^2 - p_first * (1 - p_first) / (n_first - 1) -
     p_second * (1 - p_second) / (n_second - 1)
   denominator = p_first + p_second - 2 * p_first * p_second
   sum(numerator, na.rm = TRUE) / sum(denominator, na.rm = TRUE)
 }, numeric(1))
 check('fst_independent_numerical', max(abs(expected_fst - fst$fst)) < 1e-8)
 pruned=read('pruned-variants.csv')$id
 check('ld_subset',all(pruned %in% variant$id[variant$keep])&&!anyDuplicated(pruned))
 g=raw$genotypes[sample$keep,match(pruned,raw$variants$id),drop=FALSE]
 for(j in seq_len(ncol(g)))g[is.na(g[,j]),j]=mean(g[,j],na.rm=TRUE)
 pos=raw$variants$position[match(pruned,raw$variants$id)]
 indices=unique(as.integer(round(seq(1,ncol(g),length.out=min(50,ncol(g))))))
 ld_ok=all(vapply(indices,function(j){i=which(seq_len(ncol(g))<j & pos[j]-pos<=500000);!length(i)||all(stats::cor(g[,j],g[,i,drop=FALSE])^2<=.200001)},logical(1)))
 check('ld_independent_spot_check',ld_ok)
 angles=read('pca-subspace.csv')$cos_principal_angle
 check('subspace_values',length(angles)==5&&all(angles>=0&angles<=1.000001))
 hwe=read('within-population-hwe.csv')
 check('hwe_not_pooled',setequal(hwe$pop,raw$samples$pop))
 check('hwe_fdr',max(abs(hwe$fdr-stats::p.adjust(hwe$p_value,'BH')))<1e-6)
 },error=function(e)failures <<- c(failures,conditionMessage(e)))
 list(ok=length(failures)==0,checks=checks,failures=failures)
}
