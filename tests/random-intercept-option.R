library(TDMM)

passed <- 0L
check <- function(label, expr) {
  force(expr)
  passed <<- passed + 1L
  cat("PASS random_intercept:", label, "\n")
}

dat <- expand.grid(time = c(0, .2, .5, .8, 1),
                   subject.ID = paste0("s", seq_len(6)))
dat$x <- rep(c(-1, -.6, -.2, .2, .6, 1), each = 5)
response <- list(
  gaussian = 1 + .3 * dat$time + .4 * dat$x + rep(c(-.1, .1, 0), 10),
  bernoulli = rep(c(0, 1, 1), 10),
  poisson = rep(c(0, 1, 2), 10)
)
fit.args <- list(n.chains = 2, n.iter = 100, n.burn = 50,
                 n.thin = 1, n.adapt = 100, quiet = TRUE)
fit.family <- function(family, fitter = tdmm, ...) {
  d <- dat
  d$y <- response[[family]]
  do.call(fitter, c(list(data = d, family = family), fit.args, list(...)))
}
random.names <- function(fit) {
  nm <- colnames(fit$post.mat)
  nm[startsWith(nm, "b[") | nm %in% c("tau.b", "sigma.b", "sigma2.b")]
}

check("default TRUE in both entry points", {
  stopifnot(identical(formals(tdmm)$random_intercept, TRUE),
            identical(formals(tdmm.parallel)$random_intercept, TRUE))
})

check("invalid values rejected", {
  d <- dat
  d$y <- response$gaussian
  for (fitter in list(tdmm, tdmm.parallel)) {
    for (value in list(NA, c(TRUE, FALSE), 1, "FALSE", NULL)) {
      error <- tryCatch(do.call(fitter,
        list(data = d, random_intercept = value)), error = identity)
      stopifnot(inherits(error, "error"),
                grepl("random_intercept must be a single non-missing logical",
                      conditionMessage(error), fixed = TRUE))
    }
  }
})

for (family in names(response)) {
  check(paste(family, "FALSE fit and summary"), {
    fit <- fit.family(family, random_intercept = FALSE)
    summary.lines <- capture.output(sm <- summary(fit))
    stopifnot(inherits(fit, "tdmm"),
              identical(fit$model.settings$random_intercept, FALSE),
              all(c("sigma.b", "sigma2.b") %in% names(fit)),
              is.null(fit$sigma.b), is.null(fit$sigma2.b),
              is.null(sm$sigma.b), is.null(sm$sigma2.b),
              length(random.names(fit)) == 0L,
              !any(grepl("^sigma(2)?[.]b:", summary.lines)),
              all(is.finite(fit$beta.hat)))
    if (family == "gaussian")
      stopifnot(is.finite(fit$sigma2.e), is.finite(sm$sigma2.e))
  })
}

check("default TRUE retains random-intercept output", {
  fit <- fit.family("gaussian")
  summary.lines <- capture.output(summary(fit))
  stopifnot(identical(fit$model.settings$random_intercept, TRUE),
            all(c("tau.b", "sigma.b", "sigma2.b") %in% random.names(fit)),
            is.finite(fit$sigma.b), is.finite(fit$sigma2.b),
            any(grepl("^sigma.b:", summary.lines)),
            any(grepl("^sigma2.b:", summary.lines)))
})

check("parallel wrapper forwards FALSE", {
  fit <- fit.family("gaussian", fitter = tdmm.parallel,
                    random_intercept = FALSE, n.cores = 1)
  stopifnot(inherits(fit$post.samples, "mcmc.list"),
            identical(fit$model.settings$random_intercept, FALSE),
            is.null(fit$sigma.b), is.null(fit$sigma2.b),
            length(random.names(fit)) == 0L)
})

cat("Random-intercept option cases passed:", passed, "\n")
