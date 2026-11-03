v04_t05 = function() {
  list(id = "T05",
    artifacts = c("gwas-qc.csv", "distribution.csv", "gwas-qq.png", "lead-regions.csv", "gene-annotation.csv", "gene-background.csv", "functional-enrichment.csv", "sensitivity.csv", "lead-regions-250kb.csv", "window-annotation.csv", "window-enrichment.csv", "evidence-audit.csv", "research-report.md"),
    steps = list(
    list(request = 1L, reads = c("raw"), writes = c("emit"), code = r"---(stopifnot(identical(raw$genome_build,'GRCh37'),all(c('id','chr','position','effect_allele','other_allele','beta','se','p') %in% names(raw$associations)),all(c('gene','chr','tss') %in% names(raw$genes)),length(raw$pathways)>0)
emit=function(x,p)utils::write.csv(x,p,row.names=FALSE);environment(emit)=baseenv())---"),
    list(request = 1L, reads = c("raw"), writes = c("valid", "duplicates"), code = r"---(a=raw$associations
valid=is.finite(a$p)&a$p>0&a$p<=1&is.finite(a$se)&a$se>0&is.finite(a$beta)&is.finite(a$position)&a$position>=1&a$chr %in% as.character(1:22)&a$effect_allele %in% c('A','C','G','T')&a$other_allele %in% c('A','C','G','T')&a$effect_allele!=a$other_allele
key=paste(a$chr,a$position,a$effect_allele,a$other_allele,sep=':');duplicates=duplicated(key)
valid=valid & !duplicates)---"),
    list(request = 1L, reads = c("raw", "valid", "duplicates", "emit"), writes = c("association", "qc"), code = r"---(association=raw$associations[valid,]
association=association[order(as.integer(association$chr),association$position,association$id),]
qc=data.frame(n_input=nrow(raw$associations),n_valid=nrow(association),duplicates=sum(duplicates),invalid=sum(!valid),genome_build='GRCh37')
emit(qc,'gwas-qc.csv');stopifnot(nrow(association)>10))---"),
    list(request = 1L, reads = c("association"), writes = c("inflation"), code = r"---(z=association$beta/association$se
inflation=stats::median(z^2)/stats::qchisq(.5,df=1)
stopifnot(is.finite(inflation)))---"),
    list(request = 1L, reads = c("association", "inflation", "emit"), writes = c("distribution"), code = r"---(probabilities=c(.001,.01,.1,.5,.9,.99,.999)
distribution=data.frame(probability=probabilities,p_quantile=stats::quantile(association$p,probabilities,names=FALSE),lambda_gc=inflation,n_significant=sum(association$p<5e-8))
emit(distribution,'distribution.csv'))---"),
    list(request = 1L, reads = c("association"), writes = character(), code = r"---(grDevices::png('gwas-qq.png',width=900,height=800)
n=min(nrow(association),100000L);indices=unique(as.integer(round(seq(1,nrow(association),length.out=n))))
observed=sort(association$p);ranks=indices
graphics::plot(-log10((ranks-.5)/nrow(association)),-log10(observed[ranks]),pch=16,cex=.3,xlab='Expected -log10 P',ylab='Observed -log10 P');graphics::abline(0,1,col='red');grDevices::dev.off())---"),
    list(request = 2L, reads = c("association"), writes = c("region_fn"), code = r"---(region_fn=function(a,gap){
 sig=a[a$p<5e-8,,drop=FALSE]
 if(!nrow(sig))return(data.frame(chr=character(),region=integer(),start=numeric(),end=numeric(),lead_id=character(),lead_position=numeric(),lead_p=numeric(),variants=integer()))
 group=cumsum(c(TRUE,sig$chr[-1]!=sig$chr[-nrow(sig)] | diff(sig$position)>gap))
 do.call(rbind,lapply(split(sig,group),function(d){i=order(d$p,d$position,d$id)[1];data.frame(chr=d$chr[1],region=group[match(rownames(d)[1],rownames(sig))],start=min(d$position),end=max(d$position),lead_id=d$id[i],lead_position=d$position[i],lead_p=d$p[i],variants=nrow(d))}))
}
environment(region_fn)=baseenv())---"),
    list(request = 2L, reads = c("association", "region_fn"), writes = c("regions"), code = r"---(regions=region_fn(association,500000))---"),
    list(request = 2L, reads = c("raw"), writes = c("nearest_fn"), code = r"---(nearest_fn=function(chr,position,genes,max_distance=1e6){
 result=rep(NA_character_,length(chr));distance=rep(NA_real_,length(chr))
 for(c in unique(chr)){
  idx=which(chr==c);g=genes[genes$chr==c & !is.na(genes$gene),c('gene','tss')];g=g[order(g$tss,g$gene),]
  g=g[!duplicated(g$tss),,drop=FALSE]
  if(!nrow(g))next
  left=pmax(1,pmin(nrow(g),findInterval(position[idx],g$tss)))
  right=pmin(nrow(g),left+1L)
  choose=ifelse(abs(position[idx]-g$tss[left])<=abs(position[idx]-g$tss[right]),left,right)
  delta=abs(position[idx]-g$tss[choose]);ok=delta<=max_distance
  result[idx[ok]]=g$gene[choose[ok]];distance[idx[ok]]=delta[ok]
 }
 data.frame(gene=result,distance=distance)
}
environment(nearest_fn)=baseenv())---"),
    list(request = 2L, reads = c("regions", "raw", "nearest_fn"), writes = c("annotation"), code = r"---(annotation=nearest_fn(regions$chr,regions$lead_position,raw$genes,1e6)
annotation=data.frame(lead_id=regions$lead_id,chr=regions$chr,lead_position=regions$lead_position,annotation,method=rep('nearest_tss_1Mb',nrow(regions))))---"),
    list(request = 2L, reads = c("association", "raw", "nearest_fn"), writes = c("background"), code = r"---(background=unique(stats::na.omit(nearest_fn(association$chr,association$position,raw$genes,1e6)$gene))
stopifnot(length(background)>0))---"),
    list(request = 2L, reads = c("raw", "background", "annotation"), writes = c("enrich_fn"), code = r"---(enrich_fn=function(hits,universe,pathways){
 hits=intersect(unique(hits),universe)
 out=do.call(rbind,lapply(names(pathways),function(name){
  members=intersect(unique(pathways[[name]]),universe);a=length(intersect(hits,members));b=length(setdiff(hits,members));c=length(setdiff(members,hits));d=length(setdiff(universe,union(hits,members)))
  p=if(length(members)>=5 && length(hits))stats::fisher.test(matrix(c(a,b,c,d),2),alternative='greater')$p.value else 1
  data.frame(pathway=name,background=length(universe),pathway_genes=length(members),selected=length(hits),overlap=a,p_value=p)
 }));out$fdr=stats::p.adjust(out$p_value,'BH');out
}
environment(enrich_fn)=baseenv())---"),
    list(request = 2L, reads = c("annotation", "background", "raw", "enrich_fn"), writes = c("enrichment"), code = r"---(enrichment=enrich_fn(annotation$gene,background,raw$pathways))---"),
    list(request = 2L, reads = c("regions", "annotation", "background", "enrichment", "emit"), writes = character(), code = r"---(emit(regions,'lead-regions.csv');emit(annotation,'gene-annotation.csv');emit(data.frame(gene=background),'gene-background.csv');emit(enrichment,'functional-enrichment.csv'))---"),
    list(request = 3L, reads = c("association", "region_fn"), writes = c("regions250"), code = r"---(regions250=region_fn(association,250000))---"),
    list(request = 3L, reads = c("regions", "raw"), writes = c("window_annotation"), code = r"---(window_annotation=do.call(rbind,lapply(seq_len(nrow(regions)),function(i){
 genes=raw$genes[raw$genes$chr==regions$chr[i] & abs(raw$genes$tss-regions$lead_position[i])<=500000,]
 if(!nrow(genes))return(NULL)
 data.frame(lead_id=regions$lead_id[i],gene=genes$gene,distance=abs(genes$tss-regions$lead_position[i]),method='all_tss_500kb')
}))
if(is.null(window_annotation))window_annotation=data.frame(lead_id=character(),gene=character(),distance=numeric(),method=character()))---"),
    list(request = 3L, reads = c("window_annotation", "background", "raw", "enrich_fn"), writes = c("window_enrichment"), code = r"---(window_enrichment=enrich_fn(window_annotation$gene,background,raw$pathways))---"),
    list(request = 3L, reads = c("regions", "regions250", "annotation", "window_annotation", "enrichment", "window_enrichment", "emit"), writes = c("sensitivity"), code = r"---(baseline_hits=unique(stats::na.omit(annotation$gene));window_hits=intersect(unique(window_annotation$gene),background)
sensitivity=data.frame(setting=c('gap250kb','all_tss500kb'),n_regions=c(nrow(regions250),nrow(regions)),n_genes=c(NA_integer_,length(window_hits)),gene_jaccard=c(NA_real_,if(length(union(baseline_hits,window_hits)))length(intersect(baseline_hits,window_hits))/length(union(baseline_hits,window_hits)) else 1),enriched_fdr05=c(NA_integer_,sum(window_enrichment$fdr<.05)))
emit(sensitivity,'sensitivity.csv');emit(regions250,'lead-regions-250kb.csv');emit(window_annotation,'window-annotation.csv');emit(window_enrichment,'window-enrichment.csv'))---"),
    list(request = 3L, reads = c("annotation", "regions", "emit"), writes = c("evidence"), code = r"---(evidence=data.frame(lead_id=annotation$lead_id,gene=annotation$gene,distance=annotation$distance,position_evidence=rep('nearest transcription start site only',nrow(annotation)),causal_evidence=rep('not established',nrow(annotation)))
emit(evidence,'evidence-audit.csv'))---"),
    list(request = 3L, reads = c("qc", "inflation", "regions", "enrichment", "sensitivity", "raw"), writes = character(), code = r"---(writeLines(c('# BMI GWAS candidate regions and functional evidence',paste('Accession:',raw$accession,'build:',raw$genome_build,'valid variants:',qc$n_valid),
 paste('Genomic-control lambda:',inflation,'distance-defined regions:',nrow(regions)),
 'P<5e-8 variants are grouped by500kb consecutive gaps; minimum-P representative is reported. These are positional regions, not LD-independent signals.',
 'Nearest TSS within1Mb supplies candidate genes; tested-variant nearest genes define the functional-enrichment universe; Reactome Fisher P values useBH.',
 paste('Pathways with FDR<.05:',sum(enrichment$fdr<.05)),
 'Sensitivity changes gap to250kb and gene mapping to all TSS within500kb; gene-set Jaccard and enrichment are retained.',
 'Nearest-gene assignment and enrichment are hypothesis generating. No LD clumping, fine mapping, colocalization or causal inference was performed.',
 'Allele and coordinate audit removes invalid data; genomic inflation can reflect polygenicity and confounding. European-ancestry association results do not automatically generalize.'),'research-report.md'))---")
    ))
}

v04_check_t05 = function(workspace,raw) {
 failures=character();checks=list()
 check=function(n,x){checks[[n]] <<- isTRUE(x);if(!isTRUE(x))failures <<- c(failures,n)}
 tryCatch({
 read=function(n)utils::read.csv(file.path(workspace,n),stringsAsFactors=FALSE)
 qc=read('gwas-qc.csv');regions=read('lead-regions.csv');annotation=read('gene-annotation.csv');enrichment=read('functional-enrichment.csv')
 check('input_count',qc$n_input==nrow(raw$associations)&&qc$n_valid+qc$invalid==qc$n_input)
 check('coordinate_build',identical(qc$genome_build,raw$genome_build))
 check('significant_leads',all(regions$lead_p<5e-8)&&all(regions$lead_id %in% raw$associations$id))
 check('representatives_in_region',all(regions$lead_position>=regions$start&regions$lead_position<=regions$end))
 if(nrow(regions)){
 ix=match(regions$lead_id,raw$associations$id)
 check('lead_p_matches_source',all(abs(regions$lead_p-raw$associations$p[ix])<1e-15))
 }
 check('annotation_gene_universe',all(is.na(annotation$gene)|annotation$gene %in% raw$genes$gene))
 check('distance_limit',all(is.na(annotation$distance)|annotation$distance<=1e6))
 closest_valid = vapply(seq_len(nrow(annotation)), function(i) {
   candidates = raw$genes[raw$genes$chr == annotation$chr[i] &
                            !is.na(raw$genes$gene), ]
   distances = abs(candidates$tss - annotation$lead_position[i])
   if (!length(distances) || min(distances) > 1e6) return(is.na(annotation$gene[i]))
   candidate = order(distances, candidates$tss, candidates$gene)[1L]
   identical(as.character(annotation$gene[i]), as.character(candidates$gene[candidate])) &&
     abs(annotation$distance[i] - distances[candidate]) < 1e-8
 }, logical(1))
 check('actual_nearest_gene', all(closest_valid))
 check('fdr',max(abs(enrichment$fdr-stats::p.adjust(enrichment$p_value,'BH')))<1e-6)
 check('valid_fisher_counts',all(enrichment$overlap<=enrichment$selected&enrichment$overlap<=enrichment$pathway_genes&enrichment$pathway_genes<=enrichment$background))
 background=read('gene-background.csv')$gene
 check('explicit_background',length(unique(background))==length(background)&&all(background %in% raw$genes$gene))
 hits = intersect(unique(stats::na.omit(annotation$gene)), background)
 correct_enrichment = vapply(seq_len(nrow(enrichment)), function(i) {
   members = intersect(raw$pathways[[enrichment$pathway[i]]], background)
   overlap = length(intersect(hits, members))
   expected_p = if (length(members) < 5L || !length(hits)) 1 else
     stats::phyper(overlap - 1L, length(members), length(background) - length(members),
                   length(hits), lower.tail = FALSE)
   enrichment$overlap[i] == overlap && abs(enrichment$p_value[i] - expected_p) < 1e-8
 }, logical(1))
 check('independent_hypergeometric', all(correct_enrichment))
 sensitivity=read('sensitivity.csv')
 check('mapping_and_region_sensitivity',setequal(sensitivity$setting,c('gap250kb','all_tss500kb')))
 check('smaller_gap_more_regions',sensitivity$n_regions[sensitivity$setting=='gap250kb']>=nrow(regions))
 evidence=read('evidence-audit.csv')
 check('no_causal_overclaim',all(evidence$causal_evidence=='not established'))
 },error=function(e)failures <<- c(failures,conditionMessage(e)))
 list(ok=length(failures)==0,checks=checks,failures=failures)
}
