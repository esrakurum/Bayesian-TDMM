# Parallel fitting wrapper; tdmm() also supports parallel chains through control.
tdmm.parallel <- function(data,
                          family = c("gaussian", "bernoulli", "poisson"),
                          nknots = NULL,
                          subject.var = "subject.ID",
                          time.var = "time",
                          y.var = "y",
                          x.var = NULL,
                          degree = 3,
                          n.chains = 3,
                          n.iter = 10000,
                          n.burn = 3000,
                          n.thin = 5,
                          n.adapt = 10000,
                          n.cores = min(n.chains, parallel::detectCores()),
                          jags.dir = NULL,
                          quiet = FALSE,
                          seed = NULL,
                          n_basis = NULL,
                          control = NULL,
                          priors = NULL,
                          random_intercept = TRUE) {
  family <- match.arg(family)
  if (is.null(control)) control <- list()
  if (!is.list(control))
    stop("control must be a named list.", call. = FALSE)
  # This wrapper selects parallel execution even if control$parallel is FALSE.
  control$parallel <- TRUE
  resolved <- .resolve.tdmm.control(control,
    legacy = list(n.chains = n.chains, n.iter = n.iter, n.burn = n.burn,
      n.thin = n.thin, n.adapt = n.adapt, seed = seed,
      n.cores = if (missing(n.cores)) NULL else n.cores),
    supplied = c(n.chains = !missing(n.chains), n.iter = !missing(n.iter),
      n.burn = !missing(n.burn), n.thin = !missing(n.thin),
      n.adapt = !missing(n.adapt), seed = !missing(seed),
      n.cores = !missing(n.cores)))
  # Use the same input checks and fitting path as tdmm().
  tdmm(data = data, family = family, nknots = nknots,
       subject.var = subject.var, time.var = time.var, y.var = y.var,
       x.var = x.var, degree = degree, jags.dir = jags.dir,
       quiet = quiet, n_basis = n_basis, control = resolved,
       priors = priors, random_intercept = random_intercept)
}

# Chain-level engine shared by tdmm() and tdmm.parallel().
.tdmm.parallel.samples <- function(jags.data, config, control, quiet) {
  fit.one.chain <- function(chain.id) {
    if (!is.null(control$seed)) set.seed(control$seed + chain.id)
    model <- rjags::jags.model(file = config$model.file, data = jags.data,
      n.chains = 1, n.adapt = control$adapt, quiet = quiet)
    stats::update(model, n.iter = control$burn_in)
    rjags::coda.samples(model = model, variable.names = config$params,
      n.iter = control$iterations - control$burn_in,
      thin = control$thin)[[1]]
  }
  chain.samples <- parallel::mclapply(seq_len(control$chains), fit.one.chain,
    mc.cores = control$cores)
  chain.errors <- vapply(chain.samples, inherits, logical(1), "try-error")
  if (any(chain.errors)) {
    print(chain.samples[chain.errors])
    stop("At least one parallel MCMC chain failed.", call. = FALSE)
  }
  coda::mcmc.list(chain.samples)
}
