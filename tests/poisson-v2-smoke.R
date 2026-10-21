library(TDMM)
set.seed(321)
dat <- do.call(rbind,lapply(1:12,function(i) {
  t <- sort(runif(3+i%%4))
  data.frame(id=paste0("p",i),visit=t,y=rpois(length(t),2),
             baseline=i%%2,changing=sin(t*6)+i/20)
}))
dat$id <- factor(dat$id,levels=c(unique(dat$id),"unused"))
dat <- dat[nrow(dat):1,]
for (method in c("serial","parallel")) {
  args <- list(data=dat,family="poisson",subject.var="id",time.var="visit",
    x.var=c("baseline","changing"),n.chains=2,n.iter=200,n.burn=100,
    n.thin=1,n.adapt=100,quiet=TRUE)
  if(method=="parallel") {args$n.cores <- 2; args$seed <- 322}
  fit <- suppressWarnings(do.call(if(method=="serial") tdmm else tdmm.parallel,args))
  z <- fit$inputs
  stopifnot(z$n_basis==8, z$degree==3, z$spline$order==4,
    z$n.subject==12, z$N==nrow(dat),
    all(z$subject.levels[z$subject.ID]==as.character(z$data$id)),
    identical(z$X.obs[,"changing"],z$data$changing),
    all(is.finite(fit$post.mat)), nrow(fit$beta.hat)==length(unique(dat$visit)),
    ncol(fit$beta.hat)==3,
    all(c("tau.alpha[1]","tau.alpha[2]","tau.alpha[3]","sigma.b","sigma2.b","tau.b","b[1]") %in% colnames(fit$post.mat)),
    max(abs(fit$post.mat[,"sigma.b"]^2-fit$post.mat[,"sigma2.b"]))<1e-8,
    max(abs(1/fit$post.mat[,"sigma2.b"]-fit$post.mat[,"tau.b"]))<1e-6,
    identical(fit$model.settings$implementation,"V2 observation-level"))
  sm <- summary(fit)
  stopifnot(sm$n_basis==8)
  pdf(tempfile(fileext=".pdf"))
  p <- plot.tdmm(dat,fit,grid=fit$time.points)
  plot.trace.tdmm(fit,c("sigma.b","sigma2.b","tau.alpha[1]","alpha[1,1]"))
  dev.off()
  stopifnot(isTRUE(all.equal(unname(do.call(cbind,p$summaries$beta.mean)),
                            unname(fit$beta.hat),tolerance=1e-10)))
  # Chain-resolved curve and smoothing diagnostics execute for both backends.
  chains <- if(method=="parallel") lapply(fit$post.samples,as.matrix) else
    lapply(1:2,function(ch) fit$post.samples$BUGSoutput$sims.array[,ch,])
  curve <- lapply(chains,function(a) a[,paste0("alpha[1,",1:8,"]")] %*% t(p$bases.grid))
  mc <- coda::mcmc.list(lapply(curve,coda::mcmc))
  stopifnot(all(is.finite(coda::effectiveSize(mc))),
    nrow(coda::gelman.diag(mc,multivariate=FALSE,autoburnin=FALSE)$psrf)==nrow(p$bases.grid))
  cat("PASS Poisson V2",method,"public workflow, scales, alignment and curve diagnostics\n")
}
for (bad in list(-1,.5,Inf,"not a count")) {
  d <- dat; d$y[1] <- bad
  stopifnot(inherits(try(tdmm(d,family="poisson",subject.var="id",time.var="visit",
    x.var=c("baseline","changing")),silent=TRUE),"try-error"))
}

# Lock the supplied V2 likelihood/prior specification against accidental drift.
model <- paste(readLines(system.file("jags","TDMM_Poisson_JAGS.txt",package="TDMM")),collapse=" ")
for (term in c("log(lambda[j]) <- eta[j]", "y[j] ~ dpois(lambda[j])",
               "b[subject.ID[j]]", "sigma.b ~ dunif(0, 5)",
               "tau.alpha[k] ~ dgamma(1, 0.001)")) {
  stopifnot(grepl(term,model,fixed=TRUE))
}
