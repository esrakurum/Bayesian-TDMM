## tdmm.parallel() fits a Bayesian time-dynamic mixed-effects
## model using chain-level parallelization.
##
## The function follows the same general workflow as tdmm():
##   - checks the requested response family
##   - prepares the subject-level TDMM inputs
##   - builds the JAGS data list
##   - locates the correct JAGS model file
##   - runs separate MCMC chains in parallel
##   - combines the chains into one fitted TDMM object
##
## Note:
## This version uses parallel::mclapply(), which is designed for
## systems such as macOS and Linux. This works well for
## HPCC/Linux workflows, but Windows users may need a future PSOCK
## cluster version.
############################################################

tdmm.parallel <- function(data,
                          family = c("gaussian", "bernoulli", "poisson"),
                          nknots = 15,
                          subject.var = "subject.ID",
                          time.var = "time",
                          y.var = "y",
                          x.var = NULL,
                          degree = 2,
                          n.chains = 3,
                          n.iter = 10000,
                          n.burn = 3000,
                          n.thin = 5,
                          n.adapt = 10000,
                          n.cores = min(n.chains, parallel::detectCores()),
                          jags.dir = NULL,
                          quiet = FALSE,
                          seed = NULL) {
  
  #########
  ## Match the requested family
  #########
  
  family <- match.arg(family)
  
  #########
  ## Check the data before fitting
  #########
  ## This checks the shared TDMM data structure and the
  ## family-specific response behavior.
  
  data.check <- check.tdmm.family.data(
    data = data,
    family = family,
    subject.var = subject.var,
    time.var = time.var,
    y.var = y.var,
    x.var = x.var,
    stop.on.fail = TRUE
  )
  
  #########
  ## Build subject-level inputs
  #########
  ## This prepares the response vector, covariate matrices,
  ## subject indexing, spline basis, and penalty matrix.
  
  inputs <- build.tdmm.subject.inputs(
    data = data,
    nknots = nknots,
    subject.var = subject.var,
    time.var = time.var,
    y.var = y.var,
    x.var = data.check$covariates,
    degree = degree
  )
  
  #########
  ## Build the JAGS data list
  #########
  
  jags.data <- build.tdmm.jags.data(
    inputs = inputs,
    family = family
  )
  
  #########
  ## Get the family-specific model configuration
  #########
  ## The model configuration locates the JAGS file and selects
  ## the parameters to monitor for the requested family.
  
  config <- get.tdmm.family.config(
    family = family,
    jags.dir = jags.dir
  )
  
  #########
  ## Store model settings
  #########
  
  model.settings <- list(
    family = family,
    nknots = nknots,
    degree = degree,
    n.chains = n.chains,
    n.iter = n.iter,
    n.burn = n.burn,
    n.thin = n.thin,
    n.adapt = n.adapt,
    n.cores = n.cores,
    jags.dir = jags.dir,
    model.file = config$model.file,
    params = config$params,
    subject.var = subject.var,
    time.var = time.var,
    y.var = y.var,
    x.var = inputs$x.var,
    nX = inputs$nX,
    coef.names = inputs$coef.names,
    seed = seed,
    parallel.method = "mclapply"
  )
  
  #########
  ## Print fitting information
  #########
  
  if (!quiet) {
    message("Fitting ", family, " TDMM with ", length(inputs$x.var), " baseline covariate(s).")
    message("Using JAGS model file: ", config$model.file)
    message("Running ", n.chains, " chain(s) on ", n.cores, " core(s).")
  }
  
  ##########
  ## Fit one chain
  #########
  ## This function is called separately for each chain.
  ## Each chain uses the same model and data, but runs as a
  ## separate JAGS chain.
  
  fit.one.chain <- function(chain.id) {
    
    ## Optional chain-specific seed for reproducibility.
    if (!is.null(seed)) {
      set.seed(seed + chain.id)
    }
    
    ## Build one JAGS model for this chain.
    model <- rjags::jags.model(
      file = config$model.file,
      data = jags.data,
      n.chains = 1,
      n.adapt = n.adapt,
      quiet = quiet
    )
    
    ## Burn-in period.
    update(model, n.iter = n.burn)
    
    ## Posterior sampling.
    samples <- rjags::coda.samples(
      model = model,
      variable.names = config$params,
      n.iter = n.iter - n.burn,
      thin = n.thin
    )
    
    ## coda.samples() returns an mcmc.list even with one chain.
    ## Return the first chain object.
    samples[[1]]
  }
  
  #########
  ## Run chains in parallel
  #########
  ## mclapply() runs the chains in parallel on Unix-like systems.
  ## This is appropriate for macOS and Linux/HPCC workflows.
  
  chain.samples <- parallel::mclapply(
    X = seq_len(n.chains),
    FUN = fit.one.chain,
    mc.cores = n.cores
  )
  
  ## If any chain failed, stop before trying to combine chains.
  chain.errors <- vapply(chain.samples, inherits, logical(1), "try-error")
  
  if (any(chain.errors)) {
    print(chain.samples[chain.errors])
    stop("At least one parallel MCMC chain failed.", call. = FALSE)
  }
  
  #########
  ## Combine chains
  #########
  
  post.samples <- coda::mcmc.list(chain.samples)
  
  #########
  ## Build and return the fitted TDMM object
  #########
  
  result <- build.tdmm.output(
    family = family,
    post.samples = post.samples,
    inputs = inputs,
    model.settings = model.settings
  )
  
  ## Add the data check output so users can inspect what was
  ## checked before fitting.
  result$data.check <- data.check
  
  result
}
