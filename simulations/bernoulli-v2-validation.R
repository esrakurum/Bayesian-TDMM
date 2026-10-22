# Source this file in R/RStudio, then call run_bernoulli_validation().
# No model is fitted merely by sourcing the file.
run_bernoulli_validation <- function(out=file.path("results","bernoulli-v2-validation"),
                                  check_only=FALSE, n.iter=20000L, n.burn=10000L,
                                  n.thin=5L, n.adapt=5000L) {
library(TDMM)
model.path <- system.file("jags","TDMM_Bernoulli_JAGS.txt",package="TDMM")
model.text <- readLines(model.path)
if(!any(grepl("theta[k,r] ~ dnorm(0,tau.alpha[k]*lambda.pen[r])",model.text,fixed=TRUE)))
  stop("Install the current centered null-space TDMM development package first.")
source("simulations/bernoulli-v2-generator.R")
truth <- bernoulli_v2_truth
sim <- simulate_bernoulli_v2(seed=20261021L)
data.seed <- sim$settings$seed
fit.seed <- 87181L
dat <- sim$data
grid <- seq(.01, .99, length.out=100)
stopifnot(min(dat$time)<min(grid), max(dat$time)>max(grid),
          length(unique(table(dat$id)))>1)
checked <- suppressWarnings(check.tdmm.family.data(dat, family="bernoulli",
  subject.var="id", x.var=c("baseline", "changing")))
stopifnot(checked$structure.check$subject.balance$n.subject==200,
          identical(checked$structure.check$baseline.covariates, "baseline"),
          identical(checked$structure.check$time.varying.covariates, "changing"))
if (check_only) {
  cat("PASS deterministic dataset and installed public data checks; no fit run.\n")
  return(invisible(dat))
}
if (dir.exists(out)) stop("Results already exist. Use inspect_bernoulli_validation(out) to inspect without fitting again.")
dir.create(out, recursive=TRUE)
writeLines(model.text,file.path(out,"production-model.txt"))
saveRDS(dat, file.path(out, "data.rds"))
saveRDS(sim,file.path(out,"simulation.rds"))
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
elapsed <- system.time(fit <- withCallingHandlers(tdmm(dat, family="bernoulli", subject.var="id",
  x.var=c("baseline", "changing"), n.chains=settings$n.chains,
  n.iter=settings$n.iter, n.burn=settings$n.burn, n.thin=settings$n.thin,
  n.adapt=settings$n.adapt, quiet=TRUE), warning=record.warning))
saveRDS(fit, file.path(out, "fit.rds"))
stopifnot(fit$inputs$n_basis==8L, fit$inputs$spline$degree==3,
          fit$inputs$spline$order==4, fit$inputs$spline$intervals==5,
          nrow(fit$beta.hat)==length(unique(dat$time)), ncol(fit$beta.hat)==3)
stopifnot(identical(fit$model.settings$spline.prior,"centered null-space"))
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
cols <- c("sigma.b","sigma2.b","tau.b",paste0("tau.alpha[",1:3,"]"),
  grep("^(alpha|theta|gamma)\\[",colnames(fit$post.mat),value=TRUE))
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
# In-sample conditional probability checks, NOT held-out classification accuracy.
set.seed(97181L)
ix <- unique(round(seq(1,nrow(fit$post.mat),length.out=min(500,nrow(fit$post.mat)))))
z <- fit$inputs
prob.mean <- numeric(z$N)
rep.prevalence <- numeric(length(ix))
for(j in seq_along(ix)) {
  draw <- fit$post.mat[ix[j],]
  eta <- draw[paste0("b[",z$subject.ID,"]")]
  for(k in 1:3) eta <- eta + as.vector(z$bases.obs %*%
    draw[paste0("alpha[",k,",",1:8,"]")]) * z$X.obs[,k]
  pr <- plogis(eta)
  prob.mean <- prob.mean + pr/length(ix)
  rep.prevalence[j] <- mean(rbinom(z$N,1,pr))
}
stopifnot(identical(z$data,sim$data))
write.csv(data.frame(observed.prevalence=mean(z$y),
  true.mean.probability=mean(sim$probability),fitted.mean.probability=mean(prob.mean),
  fitted.min=min(prob.mean),fitted.max=max(prob.mean),
  probability.mse=mean((prob.mean-sim$probability)^2),
  in.sample.brier=mean((prob.mean-z$y)^2),
  in.sample.accuracy=mean((prob.mean>=.5)==z$y),
  predictive.prevalence.lower=quantile(rep.prevalence,.025),
  predictive.prevalence.upper=quantile(rep.prevalence,.975)),
  file.path(out,"probability-checks.csv"),row.names=FALSE)
write.csv(data.frame(id=z$data$id,time=z$time.obs,y=z$y,
  true.probability=sim$probability,posterior.mean.probability=prob.mean),
  file.path(out,"probability-fitted.csv"),row.names=FALSE)
saveRDS(rep.prevalence,file.path(out,"predictive-prevalence.rds"))
write.csv(data.frame(cor.time=cor(dat$changing,dat$time),
  cor.beta0=cor(dat$changing,truth(dat$time)[,1]),
  fraction.explained.by.time.basis=1-sum(lm.fit(z$bases.obs,dat$changing)$residuals^2)/
    sum((dat$changing-mean(dat$changing))^2),
  subjects=z$n.subject,observations=z$N,min.visits=min(z$n.obs.subject),
  max.visits=max(z$n.obs.subject)),file.path(out,"design-checks.csv"),row.names=FALSE)
# Separate chain means and curve traces retain the primary inferential diagnostics.
pdf(file.path(out,"curve-traces.pdf"),width=10,height=8)
par(mfrow=c(3,2))
chain.rows <- list()
for(k in 1:3) {
  cc <- lapply(1:3,function(ch) a[,ch,paste0("alpha[",k,",",1:8,"]")] %*% t(curves$bases.grid))
  for(pt in c(25,75)) matplot(sapply(cc,function(m)m[,pt]),type="l",lty=1,col=1:3,
    xlab="Retained draw",ylab=paste0("beta",k-1," at t=",round(grid[pt],2)))
  chain.rows[[k]] <- data.frame(coefficient=paste0("beta",k-1),time=grid,
    chain1=colMeans(cc[[1]]),chain2=colMeans(cc[[2]]),chain3=colMeans(cc[[3]]))
}
dev.off()
write.csv(do.call(rbind,chain.rows),file.path(out,"chain-curve-means.csv"),row.names=FALSE)
cat("Completed single-dataset Bernoulli validation. Return outputs from:",out,"\n")

invisible(fit)
}

# Read-only inspection; never calls a fitter.
inspect_bernoulli_validation <- function(out="results/bernoulli-v2-validation") {
  for(f in c("coefficient-metrics.csv","variance-recovery.csv","probability-checks.csv")) {
    cat("\n",f,"\n"); print(read.csv(file.path(out,f)))
  }
  p <- read.csv(file.path(out,"parameter-diagnostics.csv"))
  print(p[grepl("^tau.alpha|^sigma.b$",p$parameter),])
  cat(readLines(file.path(out,"warnings.txt")),sep="\n")
  invisible(readRDS(file.path(out,"fit.rds")))
}
