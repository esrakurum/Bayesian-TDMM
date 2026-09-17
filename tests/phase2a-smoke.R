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
stopifnot(as.character(packageVersion("TDMM")) == "0.1.0.9000")
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
    stopifnot(inherits(fit, "tdmm"), fit$family == family,
              all(is.finite(fit$beta.hat)), nrow(fit$beta.hat) == 5,
              all(c("sigma.b", "sigma2.b") %in% colnames(fit$post.mat)),
              isTRUE(fit$data.check$structure.check$x.constant.within.subject))
    sm <- summary(fit)
    stopifnot(sm$N == 30, sm$n.total == 30)
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
  names(dat)[names(dat) == "time"] <- "visit"
  args <- list(data=dat, family="gaussian", time.var="visit", n.chains=2,
               n.iter=100, n.burn=50, n.thin=1, n.adapt=100, quiet=TRUE)
  if (method == "parallel") args$n.cores <- 2
  fit <- suppressWarnings(do.call(if (method == "serial") tdmm else tdmm.parallel, args))
  z <- fit$inputs
  stopifnot(z$N == nrow(dat), nrow(z$bases.obs) == nrow(dat),
            identical(z$time.obs, z$data$visit),
            all(z$X.obs[, "x.tv"] == z$data$x.tv),
            all(z$subject.levels[z$subject.ID] == as.character(z$data$subject.ID)),
            nrow(fit$beta.hat) == length(unique(dat$visit)),
            ncol(z$X.subject) == 2,
            isTRUE(fit$data.check$structure.check$has.time.varying.covariates))
  grDevices::pdf(file=tempfile(fileext=".pdf"))
  plot.tdmm(dat, fit) # Uses stored custom time.var.
  plot.trace.tdmm(fit, c("sigma.b", "sigma2.b"))
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
stopifnot(helper(d, nknots=15)$N == nrow(d)-1)
cat("PASS documented missing-value entry-point difference\n")
