v04_t10 = function() {
  list(id = "T10",
    artifacts = c("spot-qc.csv", "graph-audit.csv", "variable-genes.csv", "spatial-domains.csv", "spatial-genes.csv", "permutation.csv", "domain-markers.csv", "marker-programs.csv", "neighborhood-sensitivity.csv", "qc-sensitivity.csv", "domain-alignment.csv", "domain-stability.csv", "graph-sensitivity.csv", "spatial-domains.png", "research-report.md"),
    steps = list(
    list(request = 1L, reads = c("raw"), writes = c("emit"), code = r"---(stopifnot(inherits(raw$counts,'sparseMatrix'),ncol(raw$counts)==nrow(raw$positions),identical(colnames(raw$counts),raw$positions$barcode),nrow(raw$counts)==nrow(raw$features),all(raw$positions$in_tissue==1))
emit=function(x,p)utils::write.csv(x,p,row.names=FALSE);environment(emit)=baseenv())---"),
    list(request = 1L, reads = c("raw", "emit"), writes = c("qc", "keep"), code = r"---(qc=data.frame(barcode=raw$positions$barcode,total_umi=Matrix::colSums(raw$counts),n_genes=Matrix::colSums(raw$counts>0))
keep=qc$total_umi>=1000 & qc$n_genes>=200
qc$keep=keep;emit(qc,'spot-qc.csv');stopifnot(sum(keep)>=20))---"),
    list(request = 1L, reads = c("raw", "qc", "keep"), writes = c("normalized"), code = r"---(normalized=raw$counts[,keep,drop=FALSE] %*% Matrix::Diagonal(x=1e4/qc$total_umi[keep])
normalized@x=log1p(normalized@x))---"),
    list(request = 1L, reads = c("normalized", "raw", "keep"), writes = c("selected", "expression", "coords"), code = r"---(gene_variance=Matrix::rowMeans(normalized^2)-Matrix::rowMeans(normalized)^2
eligible=which(Matrix::rowSums(normalized>0)>=max(10,ceiling(.05*ncol(normalized))))
selected=eligible[order(-gene_variance[eligible],eligible)][seq_len(min(500,length(eligible)))]
stopifnot(length(selected)>=10)
expression=t(as.matrix(normalized[selected,,drop=FALSE]));colnames(expression)=raw$features$gene_id[selected]
coords=as.matrix(raw$positions[keep,c('pixel_row','pixel_col')]))---"),
    list(request = 1L, reads = c("coords"), writes = c("graph_fn"), code = r"---(graph_fn=function(coords,k) {
 distances=as.matrix(stats::dist(coords));diag(distances)=Inf
 neighbours=t(apply(distances,1,function(x)order(x,seq_along(x))[seq_len(min(k,length(x)-1L))]))
 w=Matrix::sparseMatrix(i=rep(seq_len(nrow(coords)),each=ncol(neighbours)),j=as.vector(t(neighbours)),x=1,dims=rep(nrow(coords),2))
 w=((w+Matrix::t(w))>0)*1
 w
}
environment(graph_fn)=baseenv())---"),
    list(request = 1L, reads = c("coords", "graph_fn"), writes = c("weights"), code = r"---(weights=graph_fn(coords,8)
stopifnot(all(Matrix::rowSums(weights)>0),all(Matrix::diag(weights)==0)))---"),
    list(request = 1L, reads = c("weights", "emit", "selected", "raw"), writes = c("graph_audit"), code = r"---(graph_audit=data.frame(spots=nrow(weights),directed_edges=sum(weights),isolated=sum(Matrix::rowSums(weights)==0),min_degree=min(Matrix::rowSums(weights)),max_degree=max(Matrix::rowSums(weights)),k=8)
emit(graph_audit,'graph-audit.csv');emit(data.frame(gene_id=raw$features$gene_id[selected],gene=raw$features$gene[selected]),'variable-genes.csv'))---"),
    list(request = 2L, reads = c("expression"), writes = c("pca", "scores"), code = r"---(pca=stats::prcomp(expression,center=TRUE,scale.=FALSE,rank.=10)
scores=pca$x[,seq_len(min(10,ncol(pca$x))),drop=FALSE])---"),
    list(request = 2L, reads = c("weights", "scores"), writes = c("smoothed"), code = r"---(row_weight=Matrix::Diagonal(x=1/Matrix::rowSums(weights)) %*% weights
smoothed=(scores+as.matrix(row_weight%*%scores))/2)---"),
    list(request = 2L, reads = c("smoothed", "raw", "keep", "emit"), writes = c("domains"), code = r"---(set.seed(20261027)
domains=stats::kmeans(smoothed,centers=5,nstart=10,iter.max=100)$cluster
emit(data.frame(barcode=raw$positions$barcode[keep],domain=domains),'spatial-domains.csv'))---"),
    list(request = 2L, reads = c("expression", "weights"), writes = c("moran_fn", "gene_test"), code = r"---(moran_fn=function(x,w){z=sweep(x,2,colMeans(x),'-');as.numeric(nrow(x)/sum(w)*Matrix::colSums(z*(w%*%z))/colSums(z^2))}
environment(moran_fn)=baseenv()
gene_test=seq_len(min(200,ncol(expression))))---"),
    list(request = 2L, reads = c("expression", "weights", "moran_fn", "gene_test"), writes = c("moran"), code = r"---(moran=moran_fn(expression[,gene_test,drop=FALSE],weights))---"),
    list(request = 2L, reads = c("expression", "weights", "moran_fn", "gene_test", "moran"), writes = c("exceed", "permutations"), code = r"---(set.seed(20261027)
permutations=199L;exceed=integer(length(gene_test))
for(b in seq_len(permutations)){
 idx=sample.int(nrow(expression));null=moran_fn(expression[idx,gene_test,drop=FALSE],weights)
 exceed=exceed+as.integer(null>=moran)
})---"),
    list(request = 2L, reads = c("moran", "exceed", "permutations", "selected", "gene_test", "raw", "emit"), writes = c("spatial_result"), code = r"---(spatial_result=data.frame(gene_id=raw$features$gene_id[selected[gene_test]],gene=raw$features$gene[selected[gene_test]],moran_i=moran,p_value=(1+exceed)/(1+permutations))
spatial_result$fdr=stats::p.adjust(spatial_result$p_value,'BH')
emit(spatial_result,'spatial-genes.csv');emit(data.frame(gene_id=spatial_result$gene_id,exceed=exceed,permutations=permutations),'permutation.csv'))---"),
    list(request = 2L, reads = c("expression", "domains", "selected", "raw", "emit"), writes = c("domain_markers"), code = r"---(domain_markers=do.call(rbind,lapply(sort(unique(domains)),function(d){
 inside=colMeans(expression[domains==d,,drop=FALSE]);outside=colMeans(expression[domains!=d,,drop=FALSE]);ix=order(inside-outside,decreasing=TRUE)[seq_len(min(10,ncol(expression)))]
 data.frame(domain=d,gene_id=raw$features$gene_id[selected[ix]],gene=raw$features$gene[selected[ix]],difference=inside[ix]-outside[ix])
}))
emit(domain_markers,'domain-markers.csv'))---"),
    list(request = 2L, reads = c("raw", "selected", "spatial_result", "emit"), writes = c("functional"), code = r"---(programs=list(T_lymphoid=c('CD3D','CD3E','TRAC','CD8A'),B_lymphoid=c('MS4A1','CD79A','CD79B','CD74'),epithelial=c('EPCAM','KRT8','KRT18','KRT19'),stromal=c('COL1A1','COL1A2','DCN','LUM'),myeloid=c('LYZ','LST1','TYROBP','FCER1G'))
universe=unique(spatial_result$gene);hits=unique(spatial_result$gene[spatial_result$fdr<.05 & spatial_result$moran_i>0])
functional=do.call(rbind,lapply(names(programs),function(n){
 members=intersect(programs[[n]],universe);a=length(intersect(hits,members));b=length(setdiff(hits,members));c=length(setdiff(members,hits));d=length(setdiff(universe,union(hits,members)))
 p=if(length(members)&&length(hits))stats::fisher.test(matrix(c(a,b,c,d),2),alternative='greater')$p.value else 1
 data.frame(program=n,universe=length(universe),members=length(members),hits=a,p_value=p)
}));functional$fdr=stats::p.adjust(functional$p_value,'BH');emit(functional,'marker-programs.csv'))---"),
    list(request = 2L, reads = c("coords", "domains"), writes = character(), code = r"---(grDevices::png('spatial-domains.png',width=1000,height=850)
graphics::plot(coords[,2],-coords[,1],col=domains,pch=16,asp=1,xlab='Pixel column',ylab='Negative pixel row')
grDevices::dev.off())---"),
    list(request = 3L, reads = c("coords", "graph_fn", "scores"), writes = c("weights_alt", "alt_domains"), code = r"---(weights_alt=graph_fn(coords,12)
alt_smooth=(scores+as.matrix(Matrix::Diagonal(x=1/Matrix::rowSums(weights_alt))%*%weights_alt%*%scores))/2
set.seed(20261027);alt_domains=stats::kmeans(alt_smooth,centers=5,nstart=10,iter.max=100)$cluster)---"),
    list(request = 3L, reads = c("domains", "alt_domains"), writes = c("ari_fn", "ari"), code = r"---(ari_fn=function(a,b){tab=table(a,b);comb=function(x)x*(x-1)/2;n=sum(tab);x=sum(comb(tab));r=sum(comb(rowSums(tab)));c=sum(comb(colSums(tab)));expected=r*c/comb(n);(x-expected)/((r+c)/2-expected)}
environment(ari_fn)=baseenv();ari=ari_fn(domains,alt_domains))---"),
    list(request = 3L, reads = c("expression", "gene_test", "weights_alt", "moran_fn", "spatial_result", "emit"), writes = c("sensitivity"), code = r"---(alt_moran=moran_fn(expression[,gene_test,drop=FALSE],weights_alt)
sensitivity=data.frame(gene_id=spatial_result$gene_id,moran_baseline=spatial_result$moran_i,moran_k12=alt_moran,absolute_change=abs(alt_moran-spatial_result$moran_i))
emit(sensitivity,'neighborhood-sensitivity.csv'))---"),
    list(request = 3L, reads = c("qc", "keep", "coords", "graph_fn", "scores", "domains", "ari_fn", "emit"), writes = c("strict_audit"), code = r"---(strict=qc$total_umi[keep]>=1500 & qc$n_genes[keep]>=500
strict_audit=data.frame(setting='strictQC',spots=sum(strict),adjusted_rand=NA_real_)
if(sum(strict)>=20){
 w=graph_fn(coords[strict,,drop=FALSE],8)
 smooth=(scores[strict,,drop=FALSE]+as.matrix(Matrix::Diagonal(x=1/Matrix::rowSums(w))%*%w%*%scores[strict,,drop=FALSE]))/2
 set.seed(20261027);clusters=stats::kmeans(smooth,centers=5,nstart=10,iter.max=100)$cluster
 strict_audit$adjusted_rand=ari_fn(domains[strict],clusters)
}
emit(strict_audit,'qc-sensitivity.csv'))---"),
    list(request = 3L, reads = c("weights", "weights_alt", "emit"), writes = c("graph_sensitivity"), code = r"---(graph_sensitivity=data.frame(baseline_edges=sum(weights),k12_edges=sum(weights_alt),edge_jaccard=sum((weights>0)&(weights_alt>0))/sum((weights>0)|(weights_alt>0)))
emit(graph_sensitivity,'graph-sensitivity.csv'))---"),
    list(request = 3L, reads = c("domains", "alt_domains", "ari", "raw", "keep", "emit"), writes = character(), code = r"---(emit(data.frame(barcode=raw$positions$barcode[keep],baseline=domains,k12=alt_domains),'domain-alignment.csv')
emit(data.frame(setting='k12',adjusted_rand=ari),'domain-stability.csv'))---"),
    list(request = 3L, reads = c("spatial_result", "sensitivity", "ari", "strict_audit", "functional"), writes = character(), code = r"---(writeLines(c('# Spatial organization of breast cancer tissue',
'All input spots were aligned to tissue coordinates; QC1000UMI/200genes; log1p10000-normalized expression.',
'Symmetric8-nearest spatial graph; top500 variance genes by coordinate-independent variance; PCA10 and one-step spatial smoothing, kmeans5domains.',
'Top200 variance genes tested with Moran I and199 coordinate-label permutations; upper-tail P=(1+exceed)/200; BH across tested genes.',
paste('Spatial-positive genes with FDR<.05:',sum(spatial_result$fdr<.05 & spatial_result$moran_i>0)),
paste('Domain adjusted Rand at k12:',ari),paste('Strict QC retained spots:',strict_audit$spots),
'Marker-program tests are exploratory fixed four-gene programs with tested-gene background, not comprehensive pathway enrichment.',
'Interpret domain-markers.csv alongside spatial-domains.png and marker-programs.csv; labels do not establish histological identity.',
'Only one tissue section/donor is measured. Spot mixtures and exploratory programs prevent cell-type or causal assertions. Permutation resolution is1/200.'),'research-report.md'))---")
    ))
}

v04_check_t10 = function(workspace,raw) {
 failures=character();checks=list()
 check=function(n,x){checks[[n]] <<- isTRUE(x);if(!isTRUE(x))failures <<- c(failures,n)}
 tryCatch({
 read=function(n)utils::read.csv(file.path(workspace,n),stringsAsFactors=FALSE)
 present=all(file.exists(file.path(workspace,v04_t10()$artifacts)))
 check('required_artifacts',present)
 if(!present) stop('Required spatial task artifact missing')
 qc=read('spot-qc.csv');graph=read('graph-audit.csv');domains=read('spatial-domains.csv');genes=read('spatial-genes.csv');perm=read('permutation.csv')
 check('spot_alignment',identical(as.character(qc$barcode),raw$positions$barcode))
 check('counts',max(abs(qc$total_umi-Matrix::colSums(raw$counts)))==0)
 check('detected_genes',identical(as.numeric(qc$n_genes),
   as.numeric(Matrix::colSums(raw$counts>0))))
 check('qc_threshold',identical(as.logical(qc$keep),qc$total_umi>=1000 & qc$n_genes>=200))
 check('spot_set',setequal(domains$barcode,qc$barcode[qc$keep]))
 check('graph_spots',graph$spots==sum(qc$keep)&&graph$isolated==0&&graph$min_degree>=8)
 check('gene_ids',all(genes$gene_id %in% raw$features$gene_id)&&!anyDuplicated(genes$gene_id))
 check('permutation_p',all(abs(genes$p_value-(1+perm$exceed)/(1+perm$permutations))<1e-10))
 check('fdr',max(abs(genes$fdr-stats::p.adjust(genes$p_value,'BH')))<1e-6)
 check('valid_moran',all(is.finite(genes$moran_i)))
 coords = as.matrix(raw$positions[qc$keep, c('pixel_row', 'pixel_col')])
 edges = do.call(rbind, lapply(seq_len(nrow(coords)), function(i) {
   distance = rowSums(sweep(coords, 2L, coords[i, ], '-')^2)
   distance[i] = Inf
   neighbours = order(distance, seq_along(distance))[seq_len(8L)]
   cbind(from = i, to = neighbours)
 }))
 edges = unique(rbind(edges, edges[, c('to', 'from'), drop = FALSE]))
 spot_check = unique(as.integer(round(seq(1L, nrow(genes), length.out = min(6L, nrow(genes))))))
 numerical_moran = vapply(spot_check, function(i) {
   row = match(genes$gene_id[i], raw$features$gene_id)
   value = log1p(as.numeric(raw$counts[row, qc$keep]) * 1e4 / qc$total_umi[qc$keep])
   centered = value - mean(value)
   expected = length(value) / nrow(edges) *
     sum(centered[edges[, 1L]] * centered[edges[, 2L]]) / sum(centered^2)
   abs(expected - genes$moran_i[i]) < 1e-8
 }, logical(1))
 check('moran_independent_edges', all(numerical_moran))
 # Reconstruct a deterministic subset of all199 shared permutations using edge products.
 check('permutation_gene_alignment',identical(genes$gene_id,perm$gene_id))
 check('permutation_count',all(perm$permutations==199L))
 values=vapply(spot_check,function(i) {
   row=match(genes$gene_id[i],raw$features$gene_id)
   log1p(as.numeric(raw$counts[row,qc$keep])*1e4/qc$total_umi[qc$keep])
 },numeric(sum(qc$keep)))
 centered=sweep(values,2,colMeans(values),'-');denominator=colSums(centered^2)
 exceed=integer(length(spot_check))
 withr::local_seed(20261027)
 for(b in seq_len(199L)) {
   index=sample.int(nrow(centered));z=centered[index,,drop=FALSE]
   null=nrow(z)/nrow(edges)*colSums(z[edges[,1L],,drop=FALSE]*
     z[edges[,2L],,drop=FALSE])/denominator
   exceed=exceed+as.integer(null>=genes$moran_i[spot_check])
 }
 check('independent_permutation_counts',identical(as.integer(perm$exceed[spot_check]),exceed))
 check('domains_nonempty',length(unique(domains$domain))==5)
 sensitivity=read('neighborhood-sensitivity.csv')
 check('sensitivity_same_genes',identical(as.character(sensitivity$gene_id),as.character(genes$gene_id)))
 check('sensitivity_delta',max(abs(sensitivity$absolute_change-abs(sensitivity$moran_k12-sensitivity$moran_baseline)))<1e-8)
 check('sensitivity_baseline',max(abs(sensitivity$moran_baseline-genes$moran_i))<1e-8)
 edges_for=function(points,k) {
   result=do.call(rbind,lapply(seq_len(nrow(points)),function(i) {
     distance=rowSums(sweep(points,2,points[i,],'-')^2);distance[i]=Inf
     cbind(from=i,to=order(distance,seq_along(distance))[seq_len(k)])
   }))
   unique(rbind(result,result[,c('to','from'),drop=FALSE]))
 }
 alternate_edges=edges_for(coords,12L)
 alternate_moran=nrow(centered)/nrow(alternate_edges)*
   colSums(centered[alternate_edges[,1L],,drop=FALSE]*
     centered[alternate_edges[,2L],,drop=FALSE])/denominator
 check('independent_k12_moran',max(abs(alternate_moran-
   sensitivity$moran_k12[spot_check]))<1e-8)
 # Verify selection and clustering without using the agent's stored graph/PCA objects.
 normalized=raw$counts[,qc$keep,drop=FALSE]%*%
   Matrix::Diagonal(x=1e4/qc$total_umi[qc$keep]);normalized@x=log1p(normalized@x)
 variance=Matrix::rowMeans(normalized^2)-Matrix::rowMeans(normalized)^2
 eligible=which(Matrix::rowSums(normalized>0)>=max(10,ceiling(.05*ncol(normalized))))
 selected=eligible[order(-variance[eligible],eligible)][seq_len(min(500,length(eligible)))]
 variable=read('variable-genes.csv')
 check('independent_variable_genes',identical(variable$gene_id,raw$features$gene_id[selected]))
 check('tested_gene_selection',identical(genes$gene_id,
   raw$features$gene_id[head(selected,200L)]))
 expression=t(as.matrix(normalized[selected,,drop=FALSE]))
 scores=stats::prcomp(expression,center=TRUE,scale.=FALSE,rank.=10)$x
 cluster_from_edges=function(points,scores,edges) {
   neighbors=split(edges[,2L],edges[,1L])
   smoothed=scores
   for(i in seq_len(nrow(scores))) {
     smoothed[i,]=(scores[i,]+colMeans(scores[neighbors[[as.character(i)]],,drop=FALSE]))/2
   }
   set.seed(20261027)
   stats::kmeans(smoothed,centers=5,nstart=10,iter.max=100)$cluster
 }
 same_partition=function(a,b) {
   membership=table(a,b)
   all(rowSums(membership>0)==1L)&&all(colSums(membership>0)==1L)
 }
 expected=cluster_from_edges(coords,scores,edges)
 check('independent_baseline_domains',same_partition(domains$domain,expected))
 alternate=cluster_from_edges(coords,scores,alternate_edges)
 alignment=read('domain-alignment.csv')
 check('alignment_spots',identical(alignment$barcode,domains$barcode))
 check('alignment_baseline',identical(alignment$baseline,domains$domain))
 check('independent_alternate_domains',same_partition(alignment$k12,alternate))
 markers=read('domain-markers.csv')
 marker_ok=vapply(seq_len(nrow(markers)),function(i) {
   j=match(markers$gene_id[i],variable$gene_id)
   if(is.na(j)) return(FALSE)
   delta=mean(expression[domains$domain==markers$domain[i],j])-
     mean(expression[domains$domain!=markers$domain[i],j])
   abs(delta-markers$difference[i])<1e-8
 },logical(1))
 check('independent_domain_markers',nrow(markers)==50L&&all(marker_ok))
 graph_sensitivity=read('graph-sensitivity.csv')
 keys=function(e)paste(e[,1L],e[,2L],sep='|')
 jaccard=length(intersect(keys(edges),keys(alternate_edges)))/
   length(union(keys(edges),keys(alternate_edges)))
 check('independent_graph_sensitivity',graph_sensitivity$baseline_edges==nrow(edges)&&
   graph_sensitivity$k12_edges==nrow(alternate_edges)&&
   abs(graph_sensitivity$edge_jaccard-jaccard)<1e-8)
 adjusted_rand=function(a,b) {
   tab=table(a,b);pairs=function(n)n*(n-1)/2
   expectation=sum(pairs(rowSums(tab)))*sum(pairs(colSums(tab)))/pairs(sum(tab))
   (sum(pairs(tab))-expectation)/
     ((sum(pairs(rowSums(tab)))+sum(pairs(colSums(tab))))/2-expectation)
 }
 strict=qc$total_umi[qc$keep]>=1500&qc$n_genes[qc$keep]>=500
 strict_result=read('qc-sensitivity.csv')
 check('strict_qc_spots',strict_result$spots==sum(strict))
 if(sum(strict)>=20L) {
   strict_edges=edges_for(coords[strict,,drop=FALSE],8L)
   strict_domains=cluster_from_edges(coords[strict,,drop=FALSE],
     scores[strict,,drop=FALSE],strict_edges)
   check('independent_qc_sensitivity',abs(strict_result$adjusted_rand-
     adjusted_rand(domains$domain[strict],strict_domains))<1e-8)
 } else check('insufficient_strict_qc',is.na(strict_result$adjusted_rand))
 ari=read('domain-stability.csv')$adjusted_rand
 check('label_invariant_stability',is.finite(ari)&&ari<=1&&ari>= -1)
 check('independent_domain_stability',abs(ari-
   adjusted_rand(domains$domain,alignment$k12))<1e-8)
 programs=read('marker-programs.csv')
 check('program_fdr',max(abs(programs$fdr-stats::p.adjust(programs$p_value,'BH')))<1e-6)
 },error=function(e)failures <<- c(failures,conditionMessage(e)))
 list(ok=length(failures)==0,checks=checks,failures=failures)
}
