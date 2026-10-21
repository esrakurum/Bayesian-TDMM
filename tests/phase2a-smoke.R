library(TDMM)
# Deterministic execution fixtures, not simulation studies or convergence tests.
balanced <- expand.grid(time = c(0, .2, .5, .8, 1), subject.ID = c("s9", "s2", "s5", "s1", "s4", "s7"))
balanced <- balanced[order(balanced$subject.ID, balanced$time), ]
balanced$x <- rep(c(-1, -.6, -.2, .2, .6, 1), each = 5)
balanced$y <- sin(balanced$time) + balanced$x + rep(c(-.1, .1, 0), 10)
irregular <- balanced[-c(2, 8, 11, 19, 27), ]
irregular$time <- irregular$time + rep(c(0, .01, .02, .03, .04), length.out = nrow(irregular))
irregular$x.tv <- cos(seq_len(nrow(irregular)))
irregular <- irregular[rev(seq_len(nrow(irregular))), ]
expect.error <- function(expr, pattern) {
  error <- tryCatch({force(expr); NULL}, error = identity)
  stopifnot(inherits(error, "error"), grepl(pattern, conditionMessage(error), fixed = TRUE))
}
# Pin the legacy interface, not a development-version string.
legacy.args <- c("data", "family", "nknots", "subject.var", "time.var", "y.var",
                 "x.var", "degree", "n.chains", "n.iter", "n.burn", "n.thin",
                 "n.adapt", "jags.dir", "quiet")
stopifnot(all(legacy.args %in% names(formals(tdmm))),
          all(c(legacy.args, "n.cores", "seed") %in% names(formals(tdmm.parallel))),
          identical(formals(tdmm)$degree, 3), is.null(formals(tdmm)$nknots))
check.fit.interface <- function(fit, dat, family, method, time.var="time", nX=2L) {
  required <- c("post.samples", "post.mat", "beta.hat", "beta.covariates.hat",
                "beta.names", "time.points", "inputs", "model.settings",
                "sigma.b", "sigma2.b", "beta0.hat", "beta1.hat", "data.check")
  if (family == "gaussian") required <- c(required, "sigma.e", "sigma2.e")
  times <- sort(unique(dat[[time.var]]))
  stopifnot(all(required %in% names(fit)), is.matrix(fit$post.mat),
            nrow(fit$post.mat) > 0L, all(is.finite(fit$post.mat)),
            identical(dim(fit$beta.hat), c(length(times), nX)),
            identical(fit$time.points, times),
            identical(colnames(fit$beta.hat), fit$beta.names),
            identical(dim(fit$beta.covariates.hat), c(length(times), nX-1L)),
            fit$inputs$n.total == nrow(dat), fit$inputs$N == nrow(dat),
            fit$inputs$nX == nX, fit$model.settings$family == family,
            fit$model.settings$n.chains == 2L,
            file.exists(fit$model.settings$model.file))
  for (k in seq_len(nX)) {
    stopifnot(isTRUE(all.equal(unname(fit[[paste0("beta", k-1, ".hat")]]),
                              unname(fit$beta.hat[, k]))))
    expected.alpha <- paste0("alpha[", k, ",", seq_len(fit$inputs$nbasis), "]")
    stopifnot(all(expected.alpha %in% colnames(fit$post.mat)))
  }
  if (method == "parallel") {
    stopifnot(inherits(fit$post.samples, "mcmc.list"), length(fit$post.samples) == 2L)
  } else {
    stopifnot(dim(fit$post.samples$BUGSoutput$sims.array)[2L] == 2L)
  }
  if (family != "gaussian") {
    stopifnot(!any(c("sigma.e", "sigma2.e") %in% names(fit)),
              identical(fit$model.settings$implementation, "V1 retained pending review"))
  }
}
for (family in c("gaussian", "bernoulli", "poisson")) {
  for (method in c("serial", "parallel")) {
    dat <- balanced
    if (family == "bernoulli") dat$y <- rep(c(0, 1, 1), 10)
    if (family == "poisson") dat$y <- rep(c(0, 1, 2), 10)
    fitter <- if (method == "serial") tdmm else tdmm.parallel
    args <- list(data=dat, family=family, n.chains=2, n.iter=100,
                 n.burn=50, n.thin=1, n.adapt=100, quiet=TRUE)
    if (method == "parallel") args$n.cores <- 2
    fit <- do.call(fitter, args)
    check.fit.interface(fit, dat, family, method)
    stopifnot(inherits(fit, "tdmm"), fit$family == family,
              all(is.finite(fit$beta.hat)), nrow(fit$beta.hat) == 5,
              all(c("sigma.b", "sigma2.b") %in% colnames(fit$post.mat)),
              isTRUE(fit$data.check$structure.check$x.constant.within.subject))
    sm <- summary(fit)
    stopifnot(sm$N == 30, sm$n.total == 30, sm$n_basis == 8, sm$degree == 3)
    grDevices::pdf(file = tempfile(fileext=".pdf"))
    plot.tdmm(dat, fit)
    plot.trace.tdmm(fit, c("sigma.b", "sigma2.b"))
    # A V2-shaped SD-only object must not request or invent variance draws.
    sd.fit <- fit
    sd.fit$post.mat <- fit$post.mat[, colnames(fit$post.mat) != "sigma2.b", drop=FALSE]
    plot.trace.tdmm(sd.fit, "sigma.b")
    expect.error(plot.trace.tdmm(sd.fit, "sigma2.b"), "not found")
    grDevices::dev.off()
    cat("PASS", family, method, "V1-style fit, summary and plots\n")
  }
}
for (method in c("serial", "parallel")) {
  dat <- irregular
  dat$subject.ID <- factor(dat$subject.ID, levels=c(sort(unique(as.character(dat$subject.ID))), "unused"))
  names(dat)[names(dat) == "time"] <- "visit"
  args <- list(data=dat, family="gaussian", time.var="visit", n.chains=2,
               n.iter=100, n.burn=50, n.thin=1, n.adapt=100, quiet=TRUE)
  if (method == "parallel") { args$n.cores <- 2; args$nknots <- 7 }
  fit <- suppressWarnings(do.call(if (method == "serial") tdmm else tdmm.parallel, args))
  check.fit.interface(fit, dat, "gaussian", method, "visit", 3L)
  z <- fit$inputs
  stopifnot(z$n_basis == 8L, z$degree == 3, z$spline$order == 4, z$spline$intervals == 5)
  stopifnot(z$N == nrow(dat), nrow(z$bases.obs) == nrow(dat),
            identical(z$time.obs, z$data$visit),
            all(z$X.obs[, "x.tv"] == z$data$x.tv),
            all(z$subject.levels[z$subject.ID] == as.character(z$data$subject.ID)),
            nrow(fit$beta.hat) == length(unique(dat$visit)),
            ncol(z$X.subject) == 2,
            isTRUE(fit$data.check$structure.check$has.time.varying.covariates))
  grDevices::pdf(file=tempfile(fileext=".pdf"))
  sm <- summary(fit)
  stopifnot(sm$n_basis == 8L, sm$N == nrow(dat))
  plotted <- plot.tdmm(dat, fit, grid=fit$time.points)
  stopifnot(isTRUE(all.equal(unname(do.call(cbind, plotted$summaries$beta.mean)),
                            unname(fit$beta.hat), tolerance=1e-10)))
  # Stored observation, recovery and plotting grids agree exactly.
  stopifnot(isTRUE(all.equal(unname(plotted$bases.grid),
                            unname(z$basis), tolerance=1e-10)))
  plot.trace.tdmm(fit, c("sigma.b", "sigma2.b", "sigma2.e", "tau.alpha[1]", "alpha[1,1]"))
  grDevices::dev.off()
  cat("PASS gaussian", method, "irregular/time-varying fit, alignment and plots\n")
}
for (family in c("bernoulli", "poisson")) {
  d <- irregular; d$y <- rep(c(0,1), length.out=nrow(d))
  for (f in list(tdmm, tdmm.parallel)) {
    expect.error(suppressWarnings(f(d, family=family)), "pending Esra K review")
  }
  cat("PASS", family, "V2 hold in both fitters\n")
}
d <- balanced; d$y[1] <- NA
expect.error(tdmm(d), "Missing values")
helper <- getFromNamespace("build.tdmm.subject.inputs", "TDMM")
stopifnot(helper(d, n_basis=15)$N == nrow(d)-1)
cat("PASS documented missing-value entry-point difference\n")

# Invalid Gaussian inputs fail before JAGS, without changing missing-data policy.
for (f in list(tdmm, tdmm.parallel)) {
  d <- balanced; d$y <- as.character(d$y)
  expect.error(f(d), "must be numeric")
  d <- balanced; d$y[1] <- Inf
  expect.error(f(d), "finite")
  d <- balanced; d$x[1] <- Inf
  expect.error(f(d), "finite")
  d <- balanced; d$time[1] <- Inf
  expect.error(f(d), "finite")
}
