## tdmm() fits a Bayesian time-dynamic mixed-effects model
## using the standard serial JAGS workflow.
##
## The function:
##   - checks the requested response family
##   - prepares the subject-level TDMM inputs
##   - builds the JAGS data list
##   - locates the correct JAGS model file
##   - runs the model using R2jags
##   - returns a fitted TDMM object
##
## The current implementation supports:
##   - Gaussian outcomes
##   - Bernoulli outcomes
##   - Poisson outcomes
##
## Baseline covariates are supplied through x.var.
## The user can pass one covariate or several covariates:
##
##   x.var = "x1"
##   x.var = c("x1", "x2", ...)
##
## If x.var is NULL, all columns except the subject ID, time,
## and response variables are treated as baseline covariates.
############################################################

tdmm <- function(data,
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
                 n.adapt = 5000,
                 jags.dir = NULL,
                 quiet = FALSE) {
  
  ## Match the requested family
  family <- match.arg(family)
  
  ##########
  ## Check the data before fitting
  ##########
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
  
  ##########
  ## Build subject-level inputs
  ##########
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
  
  ##########
  ## Build the JAGS data list
  ##########
  
  jags.data <- build.tdmm.jags.data(
    inputs = inputs,
    family = family
  )
  
  ##########
  ## Get the family-specific model configuration
  ##########
  ## The model configuration locates the JAGS file and selects
  ## the parameters to monitor for the requested family.
  
  config <- get.tdmm.family.config(
    family = family,
    jags.dir = jags.dir
  )
  
  ##########
  ## Store model settings
  ##########
  
  model.settings <- list(
    family = family,
    nknots = nknots,
    degree = degree,
    n.chains = n.chains,
    n.iter = n.iter,
    n.burn = n.burn,
    n.thin = n.thin,
    n.adapt = n.adapt,
    jags.dir = jags.dir,
    model.file = config$model.file,
    params = config$params,
    subject.var = subject.var,
    time.var = time.var,
    y.var = y.var,
    x.var = inputs$x.var,
    nX = inputs$nX,
    coef.names = inputs$coef.names
  )
  
  ##########
  ## Fit the model using JAGS
  ##########
  ## R2jags::jags() runs the MCMC sampler through JAGS.
  ## The model file depends on the selected response family.
  
  if (!quiet) {
    message("Fitting ", family, " TDMM with ", length(inputs$x.var), " baseline covariate(s).")
    message("Using JAGS model file: ", config$model.file)
  }
  
  fit <- R2jags::jags(
    data = jags.data,
    parameters.to.save = config$params,
    model.file = config$model.file,
    n.chains = n.chains,
    n.iter = n.iter,
    n.burnin = n.burn,
    n.thin = n.thin,
    n.adapt = n.adapt
  )
  
  ##########
  ## Build and return the fitted TDMM object
  ##########
  
  result <- build.tdmm.output(
    family = family,
    post.samples = fit,
    inputs = inputs,
    model.settings = model.settings
  )
  
  ## Add the data check output so users can inspect what was
  ## checked before fitting.
  result$data.check <- data.check
  
  result
}
