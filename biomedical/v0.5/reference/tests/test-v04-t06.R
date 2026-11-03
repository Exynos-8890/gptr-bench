testthat::test_that("T06 has substantive groups and independently checked interval outputs", {
  source(file.path("..","tasks","v04","t06.R"),local=TRUE)
  task=v04_t06()
  testthat::expect_equal(length(task$steps),20L)
  testthat::expect_equal(as.integer(table(vapply(task$steps,`[[`,integer(1),"request"))),c(6L,8L,6L))
  p=data.frame(chr=rep(c('chr1','chr2'),each=12),start=rep(seq(1000,23000,2000),2),
    end=rep(seq(1000,23000,2000),2)+200,score=seq_len(24))
  p2=p; p2$start=p2$start+50; p2$end=p2$end+50
  raw=list(peaks=list(p,p2),genes=data.frame(chr=rep(c('chr1','chr2'),each=12),
    tss=rep(seq(1100,23100,2000),2),gene=paste0('G',seq_len(24))),
    chromosomes=data.frame(chr=c('chr1','chr2'),length=c(100000,100000)))
  directory=tempfile();dir.create(directory)
  withr::local_dir(directory); withr::local_seed(19)
  home=new.env(parent=globalenv());home$raw=raw
  for(step in task$steps) eval(parse(text=step$code),envir=home)
  testthat::expect_true(v04_check_t06(directory,raw)$ok)
  # A plausible-looking but wrong TSS distance must fail the independent verifier.
  a=utils::read.csv('annotations.csv');a$distance_to_tss[1]=1e9
  utils::write.csv(a,'annotations.csv',row.names=FALSE)
  testthat::expect_false(v04_check_t06(directory,raw)$ok)
  # Helpers must not capture the entire raw input in a parent environment.
  testthat::expect_identical(parent.env(environment(home$promoter_hits)),baseenv())
  testthat::expect_false(exists('raw',envir=environment(home$promoter_hits),inherits=FALSE))
})

testthat::test_that("T06 grouped state survives fresh-process serialization without raw capture", {
  source(file.path("..","tasks","v04","t06.R"),local=TRUE)
  task=v04_t06();testthat::expect_length(task$prompts,3)
  testthat::expect_true(all(vapply(task$steps,function(x) length(parse(text=x$code))>0,logical(1))))
  p=data.frame(chr=rep(c('chr1','chr2'),each=12),start=rep(seq(1000,23000,2000),2),
    end=rep(seq(1000,23000,2000),2)+200,score=seq_len(24))
  raw=list(peaks=list(p,p),genes=data.frame(chr=rep(c('chr1','chr2'),each=12),
    tss=rep(seq(1100,23100,2000),2),gene=paste0('G',seq_len(24))),
    chromosomes=data.frame(chr=c('chr1','chr2'),length=c(100000,100000)))
  directory=tempfile();dir.create(directory);withr::local_dir(directory)
  withr::local_seed(19)
  state=new.env(parent=emptyenv())
  for(request in 1:3) {
    home=new.env(parent=globalenv());home$raw=raw
    block=task$steps[vapply(task$steps,`[[`,integer(1),'request')==request]
    reads=setdiff(unique(unlist(lapply(block,`[[`,'reads'))),'raw')
    for(name in reads) assign(name,unserialize(state[[name]]),home)
    for(step in block) eval(parse(text=step$code),home)
    for(name in unique(unlist(lapply(block,`[[`,'writes')))) {
      state[[name]]=serialize(get(name,home),NULL)
    }
  }
  testthat::expect_true(v04_check_t06(directory,raw)$ok)
  testthat::expect_lt(length(state$helpers),1e6)
})
