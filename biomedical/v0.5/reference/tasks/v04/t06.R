v04_t06 = function() {
  codes = c(
    paste0(
      "stopifnot(is.list(raw$peaks), length(raw$peaks) >= 2L, all(c('chr','tss'",
      ",'gene') %in% names(raw$genes))); set.seed(20261027); helpers=new.env(pa",
      "rent=baseenv())"
    ),
    paste0(
      "overlap_any = function(q, t) { out = rep(FALSE,nrow(q)); for(ch in inter",
      "sect(unique(q$chr),unique(t$chr))) { ii=which(q$chr==ch); z=t[t$chr==ch,",
      ",drop=FALSE]; z=z[order(z$start),,drop=FALSE]; j=findInterval(q$end[ii],",
      "z$start); out[ii]=j>0 & cummax(z$end)[pmax(1,j)]>=q$start[ii] }; out }; ",
      "peak_width = function(x) x$end-x$start+1; environment(overlap_any)=helpe",
      "rs; environment(peak_width)=helpers; helpers$overlap_any=overlap_any; he",
      "lpers$peak_width=peak_width"
    ),
    paste0(
      "stopifnot(all(vapply(raw$peaks,function(x) all(x$start>=1 & x$end>=x$sta",
      "rt & x$chr %in% raw$chromosomes$chr),logical(1)))); peak_qc=do.call(rbin",
      "d,lapply(seq_along(raw$peaks),function(i) data.frame(replicate=i,n=nrow(",
      "raw$peaks[[i]]),median_width=median(peak_width(raw$peaks[[i]]))))); writ",
      "e.csv(peak_qc,'peak-qc.csv',row.names=FALSE)"
    ),
    paste0(
      "replicate_hit=lapply(seq_along(raw$peaks),function(i) overlap_any(raw$pe",
      "aks[[i]],raw$peaks[[if(i==1) 2 else 1]])); concordance=data.frame(replic",
      "ate=seq_along(raw$peaks),n=vapply(raw$peaks,nrow,integer(1)),overlap_fra",
      "ction=vapply(replicate_hit,mean,numeric(1))); write.csv(concordance,'rep",
      "licate-concordance.csv',row.names=FALSE)"
    ),
    paste0(
      "peaks=raw$peaks[[1]][replicate_hit[[1]],,drop=FALSE]; stopifnot(nrow(pea",
      "ks)>0); peaks=peaks[!duplicated(peaks[c('chr','start','end')]),,drop=FAL",
      "SE]; peaks$peak_id=seq_len(nrow(peaks))"
    ),
    paste0(
      "audit=data.frame(n_replicates=length(raw$peaks),n_consensus=nrow(peaks),",
      "n_genes=nrow(raw$genes),coordinate_system='1-based closed; source BED st",
      "art plus one'); write.csv(audit,'data-audit.csv',row.names=FALSE)"
    ),
    paste0(
      "genes=raw$genes[order(raw$genes$chr,raw$genes$tss,raw$genes$gene),,drop=",
      "FALSE]; helpers$genes=genes; promoter_hits=function(p,window) { t=data.f",
      "rame(chr=genes$chr,start=pmax(1,genes$tss-window),end=genes$tss+window);",
      " overlap_any(p,t) }; environment(promoter_hits)=helpers; helpers$promote",
      "r_hits=promoter_hits"
    ),
    paste0(
      "nearest_gene=function(p) { ans=rep(NA_character_,nrow(p)); dist=rep(NA_r",
      "eal_,nrow(p)); for(ch in intersect(unique(p$chr),unique(genes$chr))) { i",
      "i=which(p$chr==ch); g=genes[genes$chr==ch,,drop=FALSE]; mid=(p$start[ii]",
      "+p$end[ii])/2; j=findInterval(mid,g$tss); left=pmax(1,pmin(nrow(g),j)); ",
      "right=pmax(1,pmin(nrow(g),j+1)); use=ifelse(abs(mid-g$tss[left])<=abs(mi",
      "d-g$tss[right]),left,right); ans[ii]=g$gene[use]; dist[ii]=abs(mid-g$tss",
      "[use]) }; data.frame(gene=ans,distance=dist) }; environment(nearest_gene",
      ")=helpers; helpers$nearest_gene=nearest_gene"
    ),
    paste0(
      "nearest=nearest_gene(peaks); annotation=data.frame(peak_id=peaks$peak_id",
      ",chr=peaks$chr,start=peaks$start,end=peaks$end,nearest_gene=nearest$gene",
      ",distance_to_tss=nearest$distance,promoter_2000=promoter_hits(peaks,2000",
      ")); write.csv(annotation,'annotations.csv',row.names=FALSE)"
    ),
    paste0(
      "set.seed(20261027); chrom_length=stats::setNames(raw$chromosomes$length,",
      "raw$chromosomes$chr); widths=peak_width(peaks); background=peaks; backgr",
      "ound$start=vapply(seq_len(nrow(peaks)),function(i) sample.int(as.integer",
      "(chrom_length[[peaks$chr[i]]]-widths[i]+1),1),integer(1)); background$en",
      "d=background$start+widths-1"
    ),
    paste0(
      "stopifnot(identical(background$chr,peaks$chr),identical(peak_width(backg",
      "round),peak_width(peaks)),all(background$end<=chrom_length[background$ch",
      "r])); write.csv(background,'matched-background.csv',row.names=FALSE)"
    ),
    paste0(
      "enrichment_test=function(fg,bg,window) { a=promoter_hits(fg,window); b=p",
      "romoter_hits(bg,window); groups=c('ALL',sort(intersect(unique(fg$chr),un",
      "ique(bg$chr)))); do.call(rbind,lapply(groups,function(ch) { i=if(ch=='AL",
      "L') rep(TRUE,nrow(fg)) else fg$chr==ch; j=if(ch=='ALL') rep(TRUE,nrow(bg",
      ")) else bg$chr==ch; tab=matrix(c(sum(a[i]),sum(!a[i]),sum(b[j]),sum(!b[j",
      "])),2,byrow=TRUE); test=stats::fisher.test(tab); data.frame(chr=ch,windo",
      "w=window,n_foreground=sum(i),n_background=sum(j),foreground_hits=sum(a[i",
      "]),background_hits=sum(b[j]),odds_ratio=unname(test$estimate),p_value=te",
      "st$p.value) })) }; environment(enrichment_test)=helpers; helpers$enrichm",
      "ent_test=enrichment_test"
    ),
    paste0(
      "enrichment=enrichment_test(peaks,background,2000); enrichment$fdr=p.adju",
      "st(enrichment$p_value,'BH'); write.csv(enrichment,'enrichment.csv',row.n",
      "ames=FALSE)"
    ),
    paste0(
      "grDevices::pdf('promoter-enrichment.pdf'); graphics::barplot(c(mean(anno",
      "tation$promoter_2000),mean(promoter_hits(background,2000))),names.arg=c(",
      "'ATAC consensus','Matched background'),ylab='Promoter overlap fraction')",
      "; grDevices::dev.off()"
    ),
    paste0(
      "window_sensitivity=do.call(rbind,lapply(c(500,2000,5000),function(w) enr",
      "ichment_test(peaks,background,w)[1,,drop=FALSE])); window_sensitivity$fi",
      "lter='all_consensus'"
    ),
    paste0(
      "top=peaks$score>=stats::median(peaks$score); filtered_sensitivity=enrich",
      "ment_test(peaks[top,,drop=FALSE],background[top,,drop=FALSE],2000)[1,,dr",
      "op=FALSE]; filtered_sensitivity$filter='top_half_score'"
    ),
    paste0(
      "sensitivity=rbind(window_sensitivity,filtered_sensitivity); sensitivity$",
      "fdr=p.adjust(sensitivity$p_value,'BH'); write.csv(sensitivity,'sensitivi",
      "ty.csv',row.names=FALSE)"
    ),
    paste0(
      "candidate_genes=sort(unique(annotation$nearest_gene[annotation$promoter_",
      "2000 & !is.na(annotation$nearest_gene)])); write.csv(data.frame(gene=can",
      "didate_genes),'candidate-genes.csv',row.names=FALSE)"
    ),
    paste0(
      "stability=data.frame(n_all=sum(annotation$promoter_2000),n_top=sum(annot",
      "ation$promoter_2000[top]),n_candidate_genes=length(candidate_genes)); wr",
      "ite.csv(stability,'candidate-stability.csv',row.names=FALSE)"
    ),
    paste0(
      "writeLines(c('# ATAC promoter association',sprintf('Two biological repli",
      "cates yield %d reproducible intervals.',nrow(peaks)),sprintf('Promoter o",
      "verlap: %.4f; chromosome/width-matched background %.4f.',mean(annotation",
      "$promoter_2000),mean(promoter_hits(background,2000))),'Coordinates were ",
      "converted from BED to 1-based closed intervals.','Report window and scor",
      "e sensitivity from sensitivity.csv.','The genomic background matches chr",
      "omosome and interval width, not GC or mappability.','ATAC overlap is ass",
      "ociation evidence and does not establish a regulatory mechanism.'),'rese",
      "arch-report.md')"
    )
  )
  groups = rep(1:3,c(6,8,6))
  q1=c("helpers","overlap_any","peak_width","replicate_hit","peaks")
  q2=c("genes","promoter_hits","nearest_gene","nearest","annotation","background",
        "enrichment_test","enrichment","chrom_length")
  list(id = "T06", artifacts = c("peak-qc.csv", "replicate-concordance.csv", "annotations.csv",
    "matched-background.csv", "enrichment.csv", "sensitivity.csv", "research-report.md",
    "data-audit.csv","candidate-genes.csv","candidate-stability.csv","promoter-enrichment.pdf"),
    steps = lapply(seq_along(codes),function(i) list(request=groups[i],reads=if(i==1) "raw" else if(i==7) c("raw",q1) else if(i==15) c("raw",q1,q2) else character(),
      writes=if(i==6) q1 else if(i==14) q2 else character(),code=codes[i])))
}

v04_check_t06 = function(workspace, raw) {
  fail = character()
  read = function(name) utils::read.csv(file.path(workspace,name),stringsAsFactors=FALSE)
  tryCatch({
    stopifnot(all(file.exists(file.path(workspace,v04_t06()$artifacts))))
    qc=read("peak-qc.csv"); a=read("annotations.csv"); b=read("matched-background.csv")
    e=read("enrichment.csv"); s=read("sensitivity.csv"); r=read("replicate-concordance.csv")
    stopifnot(identical(as.integer(qc$n),vapply(raw$peaks,nrow,integer(1))))
    stopifnot(nrow(a)==nrow(b),nrow(a)>0,all(a$chr==b$chr),
      all(a$end-a$start==b$end-b$start),all(b$start>=1),all(r$overlap_fraction>=0 & r$overlap_fraction<=1))
    chrom_length=stats::setNames(raw$chromosomes$length,raw$chromosomes$chr)
    stopifnot(all(b$end<=chrom_length[b$chr]),!anyDuplicated(a[c('chr','start','end')]))
    first_key=paste(raw$peaks[[1]]$chr,raw$peaks[[1]]$start,raw$peaks[[1]]$end)
    stopifnot(all(paste(a$chr,a$start,a$end) %in% first_key))
    # Independently verify nearest TSS and promoter hits for a spread of intervals.
    ix=unique(round(seq(1,nrow(a),length.out=min(101,nrow(a)))))
    for(i in ix) {
      replicate=raw$peaks[[2]]
      stopifnot(any(replicate$chr==a$chr[i] & replicate$start<=a$end[i] &
        replicate$end>=a$start[i]))
      g=raw$genes[raw$genes$chr==a$chr[i],,drop=FALSE]
      midpoint=(a$start[i]+a$end[i])/2
      d=abs(g$tss-midpoint); ord=order(d,g$tss,g$gene); j=ord[1]
      stopifnot(a$nearest_gene[i]==g$gene[j],abs(a$distance_to_tss[i]-d[j])<1e-8)
      hit=any(g$tss+2000>=a$start[i] & pmax(1,g$tss-2000)<=a$end[i])
      stopifnot(a$promoter_2000[i]==hit)
    }
    stopifnot(max(abs(e$fdr-p.adjust(e$p_value,"BH")))<1e-8,
      max(abs(s$fdr-p.adjust(s$p_value,"BH")))<1e-8,nrow(s)==4)
    stopifnot(e$foreground_hits[e$chr=='ALL']==sum(a$promoter_2000),
      e$n_foreground[e$chr=='ALL']==nrow(a),e$n_background[e$chr=='ALL']==nrow(b))
    for(i in seq_len(nrow(e))) {
      z=e[i,]; tab=matrix(c(z$foreground_hits,z$n_foreground-z$foreground_hits,
        z$background_hits,z$n_background-z$background_hits),2,byrow=TRUE)
      stopifnot(abs(fisher.test(tab)$p.value-z$p_value)<1e-8)
    }
    stopifnot(file.info(file.path(workspace,"research-report.md"))$size>100)
  },error=function(e) fail <<- conditionMessage(e))
  list(ok=length(fail)==0L,checks=list(coordinates=length(fail)==0L,
    nearest_tss_and_overlap=length(fail)==0L,statistical_recomputation=length(fail)==0L),failures=fail)
}
