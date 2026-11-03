testthat::test_that("T03 freezes a valid count-model pipeline and grouped dependencies", {
  source(file.path('..','tasks','v04','t03.R'),local=TRUE)
  task=v04_t03()
  testthat::expect_equal(length(task$steps),24)
  testthat::expect_equal(as.integer(table(vapply(task$steps,`[[`,integer(1),'request'))),c(7L,10L,7L))
  testthat::expect_true(all(vapply(task$steps,function(x) length(parse(text=x$code))>0,logical(1))))
  testthat::expect_setequal(task$dependencies,c('edgeR','limma'))
})

testthat::test_that("T03 real count modelling produces independently checked scientific outputs", {
  testthat::skip_if_not_installed('edgeR');testthat::skip_if_not_installed('limma')
  source(file.path('..','tasks','v04','t03.R'),local=TRUE)
  withr::local_seed(831)
  samples=data.frame(sample=paste0('S',1:16),patient=rep(paste0('P',1:8),2),
    group=rep(c('Normal','Tumor'),each=8),batch=rep(c('A','B'),8))
  counts=matrix(stats::rnbinom(160*16,mu=60,size=4),160,16,
    dimnames=list(paste0('G',1:160),samples$sample))
  counts[1:30,9:16]=counts[1:30,9:16]*4L
  counts[158:160,]=0L
  raw=list(counts=counts,samples=samples,pathways=list(set1=paste0('G',1:40),set2=paste0('G',40:120)))
  directory=tempfile();dir.create(directory);withr::local_dir(directory)
  home=new.env(parent=globalenv());home$raw=raw
  for(step in v04_t03()$steps) eval(parse(text=step$code),home)
  testthat::expect_true(v04_check_t03(directory,raw)$ok)
  filter=utils::read.csv('gene-filter.csv')
  names(filter)[names(filter)=='retained']='keep'
  utils::write.csv(filter,'gene-filter.csv',row.names=FALSE)
  testthat::expect_true(v04_check_t03(directory,raw)$ok)
  omitted=filter[filter$keep,,drop=FALSE]
  utils::write.csv(omitted,'gene-filter.csv',row.names=FALSE)
  testthat::expect_false(v04_check_t03(directory,raw)$ok)
  utils::write.csv(filter,'gene-filter.csv',row.names=FALSE)
  d=utils::read.csv('differential-expression.csv');d$fdr=0
  utils::write.csv(d,'differential-expression.csv',row.names=FALSE)
  testthat::expect_false(v04_check_t03(directory,raw)$ok)
})
