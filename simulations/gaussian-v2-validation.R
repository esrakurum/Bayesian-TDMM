#!/usr/bin/env Rscript
# Single-dataset implementation validation, not a simulation study.
library(TDMM)
args <- commandArgs(trailingOnly=TRUE)
if (length(args) && !identical(args, "--check")) stop("Only --check is supported.")
script <- sub("^--file=", "", grep("^--file=", commandArgs(), value=TRUE)[1])
root <- normalizePath(file.path(dirname(script), ".."))
out <- file.path(root, "results", "gaussian-v2-validation")
truth <- function(t) cbind(beta0=sin(2*pi*t), beta1=cos(2*pi*t), beta2=1.5*(t-.5))
data.seed <- 27181L
fit.seed <- 77181L
set.seed(data.seed)
dat <- do.call(rbind, lapply(seq_len(200), function(i) {
  n <- sample(5:10, 1)
  time <- sort(runif(n))
  baseline <- rnorm(1)
  changing <- sin(2*pi*time) + rnorm(n, sd=.25)
  b <- rnorm(1, sd=sqrt(.5))
  beta <- truth(time)
  y <- rnorm(n, beta[,1] + baseline*beta[,2] + changing*beta[,3] + b, sqrt(.1))
  data.frame(id=paste0("person-", i), time=time, y=y,
             baseline=baseline, changing=changing)
}))
grid <- seq(.01, .99, length.out=100)
stopifnot(min(dat$time)<min(grid), max(dat$time)>max(grid),
          length(unique(table(dat$id)))>1)
dat$id <- factor(dat$id, levels=c(unique(dat$id), "unused"))
dat <- dat[sample.int(nrow(dat)), ]
checked <- suppressWarnings(check.tdmm.family.data(dat, family="gaussian",
  subject.var="id", x.var=c("baseline", "changing")))
stopifnot(checked$structure.check$subject.balance$n.subject==200,
          identical(checked$structure.check$baseline.covariates, "baseline"),
          identical(checked$structure.check$time.varying.covariates, "changing"))
if (identical(args, "--check")) {
  cat("PASS deterministic dataset and installed public data checks; no fit run.\n")
  quit(status=0)
}
if (dir.exists(out)) stop("Preserve/rename the existing results/gaussian-v2-validation directory before rerunning.")
dir.create(out, recursive=TRUE)
saveRDS(dat, file.path(out, "data.rds"))
writeLines(capture.output(sessionInfo()), file.path(out, "sessionInfo.txt"))
settings <- list(data.seed=data.seed, fit.seed=fit.seed, n_basis=8L,
  degree=3L, order=4L, n.subject=200L, n.chains=3L, n.iter=8000L,
  n.burn=3000L, n.thin=5L, n.adapt=5000L, variance.b=.5, variance.e=.1)
saveRDS(settings, file.path(out, "settings.rds"))
writeLines(capture.output(packageDescription("TDMM")), file.path(out, "package.txt"))
set.seed(fit.seed)
# Omit n_basis deliberately to verify the finalized effective default of eight.
elapsed <- system.time(fit <- tdmm(dat, family="gaussian", subject.var="id",
  x.var=c("baseline", "changing"), n.chains=settings$n.chains,
  n.iter=settings$n.iter, n.burn=settings$n.burn, n.thin=settings$n.thin,
  n.adapt=settings$n.adapt, quiet=TRUE))
saveRDS(fit, file.path(out, "fit.rds"))
stopifnot(fit$inputs$n_basis==8L, fit$inputs$spline$degree==3,
          fit$inputs$spline$order==4, fit$inputs$spline$intervals==5,
          nrow(fit$beta.hat)==length(unique(dat$time)), ncol(fit$beta.hat)==3)
writeLines(capture.output(summary(fit)), file.path(out, "summary.txt"))
pdf(file.path(out, "package-coefficients.pdf"), width=10, height=4)
curves <- plot.tdmm(dat, fit, grid=grid)
dev.off()
pdf(file.path(out, "traces.pdf"), width=10, height=8)
plot.trace.tdmm(fit, c("sigma2.b", "sigma2.e", paste0("tau.alpha[",1:3,"]")))
dev.off()
a <- fit$post.samples$BUGSoutput$sims.array
chain.stats <- function(chains) {
  m <- coda::mcmc.list(lapply(chains, coda::mcmc))
  list(rhat=coda::gelman.diag(m, multivariate=FALSE, autoburnin=FALSE)$psrf[,1],
       ess=coda::effectiveSize(m))
}
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
cols <- c("sigma2.b","sigma2.e",paste0("tau.alpha[",1:3,"]"))
dg <- chain.stats(lapply(seq_len(dim(a)[2]),function(ch) a[,ch,cols]))
write.csv(data.frame(parameter=cols, mean=colMeans(fit$post.mat[,cols]),
  rhat=dg$rhat,ess=dg$ess),file.path(out,"parameter-diagnostics.csv"),row.names=FALSE)
write.csv(data.frame(parameter=c("sigma2.b","sigma2.e"), truth=c(.5,.1),
  estimate=c(fit$sigma2.b,fit$sigma2.e)),
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
cat("Completed single-dataset Gaussian validation. Return outputs from:",out,"\n")
