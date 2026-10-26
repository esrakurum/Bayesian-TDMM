# Optional lists for computational settings and family-specific priors.
# If no control list is provided, model defaults are used.
tdmm.control <- function(chains = 3L, iterations = 10000L,
                         burn_in = 3000L, thin = 5L, adapt = 5000L,
                         seed = NULL, cores = NULL, parallel = FALSE) {
  .validate.tdmm.control(list(chains = chains, iterations = iterations,
    burn_in = burn_in, thin = thin, adapt = adapt, seed = seed,
    cores = cores, parallel = parallel))
}

tdmm_control <- tdmm.control

.validate.tdmm.control <- function(x) {
  allowed <- c("chains", "iterations", "burn_in", "thin", "adapt",
               "seed", "cores", "parallel")
  if (!is.list(x) || (length(x) > 0L && is.null(names(x))) || anyNA(names(x)) ||
      any(names(x) == "") || anyDuplicated(names(x)) ||
      any(!names(x) %in% allowed))
    stop("control must be a named list using chains, iterations, burn_in, thin, adapt, seed, cores or parallel.",
         call. = FALSE)
  if (!is.null(x$parallel) &&
      (!is.logical(x$parallel) || length(x$parallel) != 1L || is.na(x$parallel)))
    stop("control$parallel must be TRUE or FALSE.", call. = FALSE)
  whole <- function(v, minimum = 0) is.numeric(v) && length(v) == 1L &&
    is.finite(v) && v == floor(v) && v >= minimum
  for (nm in c("chains", "iterations", "thin", "adapt"))
    if (!is.null(x[[nm]]) && !whole(x[[nm]], if (nm == "adapt") 0 else 1))
      stop("control$", nm, " must be a finite integer in its valid range.", call. = FALSE)
  if (!is.null(x$burn_in) && !whole(x$burn_in))
    stop("control$burn_in must be a nonnegative integer.", call. = FALSE)
  for (nm in c("seed", "cores"))
    if (!is.null(x[[nm]]) && !whole(x[[nm]], if (nm == "seed") 0 else 1))
      stop("control$", nm, " must be a finite integer in its valid range.", call. = FALSE)
  if (!is.null(x$iterations) && !is.null(x$burn_in) &&
      x$iterations <= x$burn_in)
    stop("control$iterations must exceed control$burn_in.", call. = FALSE)
  x
}

.resolve.tdmm.control <- function(control, legacy, supplied,
                                  allow_parallel = TRUE) {
  if (is.null(control)) control <- list()
  control <- .validate.tdmm.control(control)
  mapping <- c(chains = "n.chains", iterations = "n.iter",
    burn_in = "n.burn", thin = "n.thin", adapt = "n.adapt",
    seed = "seed", cores = "n.cores")
  for (nm in intersect(names(control), names(mapping))) {
    if (!is.null(control[[nm]]) && isTRUE(supplied[mapping[[nm]]]))
      stop("Specify either control$", nm, " or ", mapping[[nm]],
           ", not both.", call. = FALSE)
  }
  out <- list(chains = legacy$n.chains, iterations = legacy$n.iter,
    burn_in = legacy$n.burn, thin = legacy$n.thin, adapt = legacy$n.adapt,
    seed = legacy$seed, cores = legacy$n.cores, parallel = FALSE)
  for (nm in names(control)) out[nm] <- list(control[[nm]])
  out <- .validate.tdmm.control(out)
  if (out$iterations <= out$burn_in)
    stop("iterations must exceed burn-in.", call. = FALSE)
  if (!allow_parallel && isTRUE(out$parallel))
    stop("This fitter cannot enable parallel execution.", call. = FALSE)
  if (!isTRUE(out$parallel) && !is.null(out$cores))
    stop("control$cores requires control$parallel = TRUE.", call. = FALSE)
  if (isTRUE(out$parallel) && is.null(out$cores)) {
    available <- parallel::detectCores()
    if (!is.finite(available) || available < 1L) available <- 1L
    out$cores <- min(out$chains, available)
  }
  out
}

tdmm.priors <- function(family = c("gaussian", "bernoulli", "poisson")) {
  family <- match.arg(family)
  p <- list(smoothing = list(shape = 1, rate = .001),
    random_intercept = if (family == "gaussian")
      list(distribution = "gamma_precision", shape = 1, rate = .005)
    else list(distribution = "uniform_sd", max_sd = 5))
  if (family == "gaussian")
    p$residual <- list(shape = 1, rate = .005)
  if (family == "bernoulli")
    p$null_space <- list(sd = 10)
  p
}

.resolve.tdmm.priors <- function(family, priors) {
  out <- tdmm.priors(family)
  if (is.null(priors)) return(out)
  if (!is.list(priors) || (length(priors) > 0L && is.null(names(priors))) || anyNA(names(priors)) ||
      any(names(priors) == "") || anyDuplicated(names(priors)) ||
      any(!names(priors) %in% names(out)))
    stop("priors must be a named list of supported prior groups for this family.",
         call. = FALSE)
  for (group in names(priors)) {
    x <- priors[[group]]
    if (!is.list(x) || is.null(names(x)) || anyNA(names(x)) ||
        any(names(x) == "") || anyDuplicated(names(x)) ||
        any(!names(x) %in% names(out[[group]])))
      stop("priors$", group, " contains an unsupported field.", call. = FALSE)
    for (nm in names(x)) out[[group]][nm] <- list(x[[nm]])
  }
  expected <- tdmm.priors(family)$random_intercept$distribution
  if (!identical(out$random_intercept$distribution, expected))
    stop("The random-intercept prior family is fixed for this response family; only its parameters can be changed.",
         call. = FALSE)
  positive <- function(v) is.numeric(v) && length(v) == 1L && is.finite(v) && v > 0
  check <- function(x, nm) for (field in nm)
    if (!positive(x[[field]]))
      stop("Prior parameter ", field, " must be one positive finite number.", call. = FALSE)
  check(out$smoothing, c("shape", "rate"))
  check(out$random_intercept,
    if (family == "gaussian") c("shape", "rate") else "max_sd")
  if (family == "gaussian") check(out$residual, c("shape", "rate"))
  if (family == "bernoulli") check(out$null_space, "sd")
  if (family == "bernoulli" && !is.finite(1 / out$null_space$sd^2))
    stop("priors$null_space$sd implies a nonfinite precision.", call. = FALSE)
  out
}

.tdmm.prior.jags.data <- function(family, priors) {
  d <- list(smoothing.shape = priors$smoothing$shape,
            smoothing.rate = priors$smoothing$rate)
  if (family == "gaussian") {
    d$random.shape <- priors$random_intercept$shape
    d$random.rate <- priors$random_intercept$rate
    d$residual.shape <- priors$residual$shape
    d$residual.rate <- priors$residual$rate
  } else d$random.sd.max <- priors$random_intercept$max_sd
  if (family == "bernoulli") d$tau.null <- 1 / priors$null_space$sd^2
  d
}
