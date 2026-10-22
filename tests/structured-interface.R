library(TDMM)
stopifnot(identical(tdmm_control,tdmm.control),
  identical(tdmm_control()$parallel,FALSE),
  identical(tdmm_control(parallel=TRUE,cores=2)$cores,2))
err <- function(expr, pattern) {
  x <- tryCatch({force(expr);NULL}, error=identity)
  stopifnot(inherits(x,'error'),grepl(pattern,conditionMessage(x),fixed=TRUE))
}
stopifnot(identical(tdmm.priors('gaussian')$smoothing,list(shape=1,rate=.001)),
  identical(tdmm.priors('gaussian')$random_intercept,
    list(distribution='gamma_precision',shape=1,rate=.005)),
  identical(tdmm.priors('gaussian')$residual,list(shape=1,rate=.005)),
  identical(tdmm.priors('poisson')$random_intercept,
    list(distribution='uniform_sd',max_sd=5)),
  identical(tdmm.priors('bernoulli')$null_space$sd,10))
err(tdmm.control(chains=0),'control$chains')
err(tdmm.control(iterations=100,burn_in=100),'exceed')
err(tdmm.priors('other'),'arg')
resolve <- getFromNamespace('.resolve.tdmm.priors','TDMM')
for(f in c('gaussian','bernoulli','poisson')) {
  err(resolve(f,list(smoothing=list(foo=2))),'unsupported')
  err(resolve(f,list(smoothing=list(shape=-1))),'positive')
  err(resolve(f,list(random_intercept=list(distribution='other'))),'fixed')
}
err(resolve('poisson',list(residual=list(shape=1))),'supported')
err(resolve('bernoulli',list(null_space=list(sd=0))),'positive')
err(resolve('bernoulli',list(null_space=list(sd=1e-300))),'nonfinite precision')
set.seed(122)
dat <- do.call(rbind,lapply(1:8,function(i) {
  n<-3+i%%2;t<-sort(runif(n))
  data.frame(id=paste0('p',i),time=t,baseline=rep(i/4,n),
    changing=rnorm(n)+.2*t)
}))
for(f in c('gaussian','bernoulli','poisson')) for(method in c('serial','parallel')) {
  d <- dat
  if(f=='gaussian') d$y <- rnorm(nrow(d))
  if(f=='bernoulli') d$y <- rbinom(nrow(d),1,.5)
  if(f=='poisson') d$y <- rpois(nrow(d),2)
  prior <- list(smoothing=list(shape=1.5,rate=.002))
  if(f=='gaussian') prior$residual <- list(rate=.01)
  if(f=='bernoulli') prior$null_space <- list(sd=12)
  if(f!='gaussian') prior$random_intercept <- list(max_sd=4)
  ctrl <- list(chains=2L,iterations=120L,burn_in=60L,thin=2L,
    adapt=100L,seed=246L)
  if(method=='parallel') {ctrl$parallel <- TRUE;ctrl$cores <- 2L}
  fit <- suppressWarnings(do.call(tdmm,
    list(data=d,family=f,subject.var='id',x.var=c('baseline','changing'),
         control=ctrl,priors=prior,quiet=TRUE)))
  stopifnot(fit$model.settings$n.chains==2,fit$model.settings$n.iter==120,
    fit$model.settings$n.burn==60,fit$model.settings$n.thin==2,
    fit$model.settings$n.adapt==100,fit$model.settings$seed==246,
    fit$model.settings$control$seed==246,
    identical(fit$model.settings$control$parallel,method=='parallel'),
    fit$model.settings$priors$smoothing$shape==1.5,
    all(is.finite(fit$post.mat)),ncol(fit$beta.hat)==3,
    identical(fit$inputs$n_basis,8L),summary(fit)$n_basis==8)
  pdf(tempfile(fileext='.pdf'))
  p<-plot(fit)
  plot.trace.tdmm(fit,c('sigma.b','tau.alpha[1]'))
  dev.off()
  stopifnot(ncol(p$bases.grid)==8)
  if(f=='gaussian') stopifnot(fit$model.settings$priors$residual$rate==.01)
  if(f=='bernoulli') stopifnot(fit$inputs$null.space$tau.null==1/144)
  if(f!='gaussian') stopifnot(fit$model.settings$priors$random_intercept$max_sd==4)
  cat('PASS structured interface',f,method,'\n')
}
err(tdmm(d,family='poisson',n.iter=120,control=list(iterations=120)),
    'either control$iterations')
err(tdmm(d,family='poisson',control=list(cores=2)),'requires control$parallel')
err(tdmm(d,family='poisson',control=list(parallel=1)),'control$parallel')
err(tdmm.parallel(d,family='poisson',seed=1,control=list(seed=1)),
    'either control$seed')
stopifnot(identical(formals(tdmm.parallel)$n.adapt,10000))
# The old parallel entry point delegates to tdmm(), including old dotted
# control objects whose new parallel field defaults to FALSE.
legacy <- suppressWarnings(tdmm.parallel(d,family='poisson',subject.var='id',
  x.var=c('baseline','changing'),quiet=TRUE,
  control=tdmm.control(chains=2,iterations=100,burn_in=50,
    thin=1,adapt=100,cores=2,seed=246)))
stopifnot(inherits(legacy,'tdmm'),inherits(legacy$post.samples,'mcmc.list'),
  isTRUE(legacy$model.settings$control$parallel),
  identical(legacy$model.settings$parallel.method,'mclapply'))
