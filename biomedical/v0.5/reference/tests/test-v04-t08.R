testthat::test_that("T08 specifies moderated proteome models and missingness sensitivity", {
  source(file.path('..','tasks','v04','t08.R'),local=TRUE)
  task=v04_t08()
  testthat::expect_equal(length(task$steps),22)
  testthat::expect_equal(as.integer(table(vapply(task$steps,`[[`,integer(1),'request'))),c(6L,9L,7L))
  testthat::expect_true(all(vapply(task$steps,function(x) length(parse(text=x$code))>0,logical(1))))
  testthat::expect_identical(task$dependencies,'limma')
})

testthat::test_that("T08 coefficients agree with independent least squares and reject tampering", {
  testthat::skip_if_not_installed('limma')
  source(file.path('..','tasks','v04','t08.R'),local=TRUE)
  withr::local_seed(824)
  samples=data.frame(sample=paste0('S',1:32),patient=paste0('P',1:32),
    subtype=rep(c('LumA','Basal','Her2','LumB'),each=8),batch=rep(c('A','B'),16),
    channel=rep(c('itraq_114','itraq_115'),16),is_reference=FALSE)
  x=matrix(stats::rnorm(120*32),120,32,dimnames=list(paste0('G',1:120),samples$sample))
  x[1:20,samples$subtype=='Basal']=x[1:20,samples$subtype=='Basal']+2
  x[90:110,1:2]=NA_real_
  raw=list(abundance=x,samples=samples,scale='log2_ratio_to_reference',
    pathways=list(set1=paste0('G',1:30),set2=paste0('G',60:100)))
  directory=tempfile();dir.create(directory);withr::local_dir(directory)
  home=new.env(parent=globalenv());home$raw=raw
  for(step in v04_t08()$steps) eval(parse(text=step$code),home)
  testthat::expect_true(v04_check_t08(directory,raw)$ok)
  e=utils::read.csv('protein-effects.csv');e$logFC=e$logFC+1
  utils::write.csv(e,'protein-effects.csv',row.names=FALSE)
  testthat::expect_false(v04_check_t08(directory,raw)$ok)
})
