# Source this file in R/RStudio, then call run_poisson_validation().
# No model is fitted merely by sourcing the file.
run_poisson_validation <- function(out=file.path("results","poisson-v2-validation"),
                                  check_only=FALSE, n.iter=8000L, n.burn=3000L,
                                  n.thin=5L, n.adapt=5000L) {
library(TDMM)
truth <- function(t) cbind(beta0=sin(2*pi*t), beta1=cos(2*pi*t), beta2=1.5*(t-.5))
data.seed <- 37181L
fit.seed <- 87181L
set.seed(data.seed)
dat <- do.call(rbind, lapply(seq_len(200), function(i) {
  n <- sample(5:10, 1)
  time <- sort(runif(n))
  baseline <- rnorm(1)
  changing <- sin(2*pi*time) + rnorm(n, sd=.25)
  b <- rnorm(1, sd=sqrt(.5))
  beta <- truth(time)
  y <- rpois(n, exp(beta[,1] + baseline*beta[,2] + changing*beta[,3] + b))
  data.frame(id=paste0("person-", i), time=time, y=y,
             baseline=baseline, changing=changing)
}))
grid <- seq(.01, .99, length.out=100)
stopifnot(min(dat$time)<min(grid), max(dat$time)>max(grid),
          length(unique(table(dat$id)))>1)
dat$id <- factor(dat$id, levels=c(unique(dat$id), "unused"))
dat <- dat[sample.int(nrow(dat)), ]
checked <- suppressWarnings(check.tdmm.family.data(dat, family="poisson",
  subject.var="id", x.var=c("baseline", "changing")))
stopifnot(checked$structure.check$subject.balance$n.subject==200,
          identical(checked$structure.check$baseline.covariates, "baseline"),
          identical(checked$structure.check$time.varying.covariates, "changing"))
if (check_only) {
  cat("PASS deterministic dataset and installed public data checks; no fit run.\n")
  return(invisible(dat))
}
if (dir.exists(out)) stop("Preserve/rename the existing results/poisson-v2-validation directory before rerunning.")
dir.create(out, recursive=TRUE)
saveRDS(dat, file.path(out, "data.rds"))
writeLines(capture.output(sessionInfo()), file.path(out, "sessionInfo.txt"))
settings <- list(data.seed=data.seed, fit.seed=fit.seed, n_basis=8L,
  degree=3L, order=4L, n.subject=200L, n.chains=3L, n.iter=n.iter,
  n.burn=n.burn, n.thin=n.thin, n.adapt=n.adapt, variance.b=.5)
saveRDS(settings, file.path(out, "settings.rds"))
writeLines(capture.output(packageDescription("TDMM")), file.path(out, "package.txt"))
warning.log <- character()
writeLines("Warnings will be recorded here, including row-order and sampler warnings.",
           file.path(out,"warnings.txt"))
record.warning <- function(w) {
  warning.log <<- c(warning.log, conditionMessage(w))
  writeLines(warning.log,file.path(out,"warnings.txt"))
}
set.seed(fit.seed)
# Omit n_basis deliberately to verify the finalized effective default of eight.
elapsed <- system.time(fit <- withCallingHandlers(tdmm(dat, family="poisson", subject.var="id",
  x.var=c("baseline", "changing"), n.chains=settings$n.chains,
  n.iter=settings$n.iter, n.burn=settings$n.burn, n.thin=settings$n.thin,
  n.adapt=settings$n.adapt, quiet=TRUE), warning=record.warning))
saveRDS(fit, file.path(out, "fit.rds"))
stopifnot(fit$inputs$n_basis==8L, fit$inputs$spline$degree==3,
          fit$inputs$spline$order==4, fit$inputs$spline$intervals==5,
          nrow(fit$beta.hat)==length(unique(dat$time)), ncol(fit$beta.hat)==3)
writeLines(capture.output(summary(fit)), file.path(out, "summary.txt"))
pdf(file.path(out, "package-coefficients.pdf"), width=10, height=4)
curves <- plot.tdmm(dat, fit, grid=grid)
dev.off()
pdf(file.path(out, "traces.pdf"), width=10, height=8)
plot.trace.tdmm(fit, c("sigma.b", "sigma2.b", paste0("tau.alpha[",1:3,"]")))
dev.off()
a <- fit$post.samples$BUGSoutput$sims.array
chain.stats <- function(chains) withCallingHandlers({
  m <- coda::mcmc.list(lapply(chains, coda::mcmc))
  ans <- list(rhat=coda::gelman.diag(m, multivariate=FALSE, autoburnin=FALSE)$psrf[,1],
              ess=coda::effectiveSize(m))
  if(any(!is.finite(c(ans$rhat,ans$ess)))) warning("Nonfinite MCMC diagnostic; inspect saved chains.")
  ans
}, warning=record.warning)
rows <- lapply(1:3, function(k) {
  cols <- paste0("alpha[",k,",",1:8,"]")
  chains <- lapply(seq_len(dim(a)[2]), function(ch)
    a[,ch,cols] %*% t(curves$bases.grid))
  dg <- chain.stats(chains)
  mu <- curves$summaries$beta.mean[[k]]
  lo <- curves$summaries$beta.lower[[k]]
  hi <- curves$summaries$beta.upper[[k]]
  target <- truth(grid)[,k]
  data.frame(coefficient=paste0("beta",k-1), time=grid, truth=target,
    estimate=mu, lower=lo, upper=hi, bias=mu-target,
    squared.error=(mu-target)^2, covered=lo<=target & target<=hi,
    rhat=dg$rhat, ess=dg$ess)
})
pw <- do.call(rbind, rows)
write.csv(pw, file.path(out,"pointwise.csv"), row.names=FALSE)
metrics <- do.call(rbind,lapply(rows,function(z) data.frame(
  coefficient=z$coefficient[1], mean.pointwise.bias=mean(z$bias),
  mean.pointwise.squared.error=mean(z$squared.error),
  pointwise.coverage.fraction=mean(z$covered),
  max.curve.rhat=max(z$rhat), min.curve.ess=min(z$ess))))
write.csv(metrics,file.path(out,"coefficient-metrics.csv"),row.names=FALSE)
cols <- c("sigma.b","sigma2.b","tau.b",paste0("tau.alpha[",1:3,"]"))
dg <- chain.stats(lapply(seq_len(dim(a)[2]),function(ch) a[,ch,cols]))
write.csv(data.frame(parameter=cols, mean=colMeans(fit$post.mat[,cols]),
  rhat=dg$rhat,ess=dg$ess),file.path(out,"parameter-diagnostics.csv"),row.names=FALSE)
write.csv(data.frame(parameter=c("sigma.b","sigma2.b"), truth=c(sqrt(.5),.5),
  estimate=c(fit$sigma.b,fit$sigma2.b)),
  file.path(out,"variance-recovery.csv"),row.names=FALSE)
pdf(file.path(out,"truth-comparison.pdf"),width=11,height=4)
par(mfrow=c(1,3))
for(z in rows) {
  plot(z$time,z$estimate,type="n",ylim=range(z$truth,z$lower,z$upper),
       xlab="Time",ylab=z$coefficient[1])
  polygon(c(z$time,rev(z$time)),c(z$lower,rev(z$upper)),col="grey90",border=NA)
  lines(z$time,z$estimate,col="blue",lwd=2)
  lines(z$time,z$truth,lty=2,lwd=2)
  legend("topright",c("Posterior mean","Truth"),col=c("blue","black"),
         lty=c(1,2),bty="n",cex=.7)
}
dev.off()
writeLines(c(paste("Fit seconds:",unname(elapsed["elapsed"])),
  "One dataset only: pointwise coverage fraction is not repeated-sampling coverage.",
  "Review curves, mixing, variance recovery and diagnostics; no automatic statistical pass/fail."),
  file.path(out,"run-notes.txt"))
print(metrics)
# Conditional count-scale checks, retaining within-subject random intercepts.
# These are posterior predictive checks, not independent validation data.
set.seed(97181L)
ix <- unique(round(seq(1,nrow(fit$post.mat),length.out=min(500,nrow(fit$post.mat)))))
z <- fit$inputs
count.stats <- function(y) c(mean=mean(y),variance=var(y),zero.fraction=mean(y==0),maximum=max(y))
rep.stats <- matrix(NA_real_,length(ix),4,dimnames=list(NULL,names(count.stats(z$y))))
lambda.mean <- numeric(z$N)
for (j in seq_along(ix)) {
  draw <- fit$post.mat[ix[j],]
  eta <- draw[paste0("b[",z$subject.ID,"]")]
  for(k in 1:3) eta <- eta + as.vector(z$bases.obs %*%
    draw[paste0("alpha[",k,",",1:8,"]")]) * z$X.obs[,k]
  lambda <- exp(eta)
  if(any(!is.finite(lambda))) stop("Nonfinite count intensity; inspect saved fit.")
  lambda.mean <- lambda.mean + lambda/length(ix)
  rep.stats[j,] <- count.stats(rpois(z$N,lambda))
}
write.csv(data.frame(statistic=colnames(rep.stats),observed=count.stats(z$y),
  predictive.mean=colMeans(rep.stats),lower=apply(rep.stats,2,quantile,.025),
  upper=apply(rep.stats,2,quantile,.975)),file.path(out,"count-checks.csv"),row.names=FALSE)
saveRDS(rep.stats,file.path(out,"count-replicates.rds"))
write.csv(data.frame(id=as.character(z$data$id),time=z$time.obs,y=z$y,
  posterior.mean.lambda=lambda.mean),file.path(out,"count-fitted.csv"),row.names=FALSE)
cat("Completed single-dataset Poisson validation. Return outputs from:",out,"\n")

invisible(fit)
}
