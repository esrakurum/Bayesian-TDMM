##
## These helper functions support the main tdmm() and
## tdmm.parallel() fitting functions.
##
## They handle:
##   - locating the family-specific JAGS model file
##   - preparing subject-level inputs
##   - building the JAGS data list
##   - selecting monitored parameters by family
##   - recovering fitted coefficient functions
##   - constructing the fitted TDMM output object
##
## These are mostly internal package helpers. Most users will
## interact with tdmm(), tdmm.parallel(), summary.tdmm(),
## plot.tdmm(), and plot.trace.tdmm() instead.
############################################################


############################################################
## Locate the JAGS model file
############################################################

get.tdmm.model.file <- function(family, jags.dir = NULL) {

  ## Select the JAGS model file that matches the requested
  ## response family.
  ##
  ## If jags.dir is supplied, the function looks there first.
  ## This is useful during local development when the model
  ## files are stored in the top-level jags/ folder.
  ##
  ## If jags.dir is not supplied, the function tries to find
  ## the model file from the installed package.

  family <- match.arg(family, c("gaussian", "bernoulli", "poisson"))

  model.file <- switch(
    family,
    gaussian  = "TDMM_Gaussian_JAGS.txt",
    bernoulli = "TDMM_Bernoulli_JAGS.txt",
    poisson   = "TDMM_Poisson_JAGS.txt"
  )

  ##########
  ## First try the user-supplied JAGS directory
  ##########

  if (!is.null(jags.dir)) {

    model.path <- file.path(jags.dir, model.file)

    if (file.exists(model.path)) {
      return(model.path)
    }

    stop(
      "Could not find the JAGS model file: ", model.file,
      "\nExpected location: ", model.path,
      "\nCheck that jags.dir points to the folder containing the JAGS model files.",
      call. = FALSE
    )
  }

  ##########
  ## Then try the installed package location
  ##########

  installed.path <- system.file("jags", model.file, package = "TDMM")

  if (installed.path != "") {
    return(installed.path)
  }

  ##########
  ## If neither location works, stop with a clear message
  ##########

  stop(
    "Could not find the JAGS model file: ", model.file,
    "\nIf you are working locally, try setting jags.dir = 'jags'.",
    "\nIf the package was installed from GitHub, make sure the JAGS files are included in the installed package.",
    call. = FALSE
  )
}


############################################################
## Family-specific model configuration
############################################################

get.tdmm.family.config <- function(family, jags.dir = NULL) {

  ## This helper stores the family-specific settings used by
  ## tdmm() and tdmm.parallel().
  ##
  ## The monitored parameters include the spline coefficients,
  ## smoothing parameters, random intercept variance, and, for
  ## Gaussian outcomes, the residual variance.

  family <- match.arg(family, c("gaussian", "bernoulli", "poisson"))

  model.file <- get.tdmm.model.file(
    family = family,
    jags.dir = jags.dir
  )

  ## The JAGS model files use matrix-style spline coefficients:
  ##   alpha[k, 1:n_basis]
  ##
  ## where k = 1, ..., nX.
  ##
  ## nX includes the intercept function and all baseline
  ## covariate coefficient functions.

  params <- c(
    "alpha",
    "tau.alpha",
    "tau.b",
    "sigma2.b",
    "sigma.b"
  )

  if (family == "gaussian") {
    params <- c(params, "tau.e", "sigma2.e", "sigma.e")
  }

  if (family %in% c("poisson", "bernoulli")) params <- c(params, "b")
  if (family == "bernoulli") params <- c(params, "theta", "gamma")

  list(
    family = family,
    model.file = model.file,
    params = unique(params)
  )
}


############################################################
## Build subject-level TDMM inputs
############################################################

build.tdmm.subject.inputs <- function(data,
                                      n_basis,
                                      subject.var = "subject.ID",
                                      time.var = "time",
                                      y.var = "y",
                                      x.var = NULL,
                                      degree = 3) {

  ##########
  ## Basic checks
  ##########

  if (!is.data.frame(data)) {
    stop("data must be a data frame.", call. = FALSE)
  }

  required.cols <- c(subject.var, time.var, y.var)
  missing.required <- setdiff(required.cols, names(data))

  if (length(missing.required) > 0) {
    stop(
      "data is missing required column(s): ",
      paste(missing.required, collapse = ", "),
      call. = FALSE
    )
  }

  ##########
  ## Select covariates
  ##########

  if (is.null(x.var)) {
    x.var <- setdiff(names(data), required.cols)
  }

  if (length(x.var) == 0) {
    stop("No covariates were provided or detected.", call. = FALSE)
  }

  missing.x <- setdiff(x.var, names(data))

  if (length(missing.x) > 0) {
    stop(
      "data is missing covariate column(s): ",
      paste(missing.x, collapse = ", "),
      call. = FALSE
    )
  }

  ##########
  ## Keep complete observations
  ##########

  data.use <- data[, c(required.cols, x.var), drop = FALSE]
  data.use <- data.use[stats::complete.cases(data.use), , drop = FALSE]

  if (nrow(data.use) == 0) {
    stop("No complete observations remain after removing missing values.",
         call. = FALSE)
  }

  ##########
  ## Sort by subject and time
  ##########

  data.use <- data.use[order(data.use[[subject.var]], data.use[[time.var]]), ,
                       drop = FALSE]
  rownames(data.use) <- NULL

  ##########
  ## Response and time
  ##########

  y <- data.use[[y.var]]
  time.obs <- data.use[[time.var]]

  if (!is.numeric(time.obs)) {
    stop("time.var must be numeric.", call. = FALSE)
  }

  ##########
  ## Subject indexing
  ##########

  subject.factor <- factor(data.use[[subject.var]])
  subject.ID <- as.integer(subject.factor)
  subject.levels <- levels(subject.factor)

  N <- length(y)
  n.subject <- length(subject.levels)

  n.obs.subject <- as.numeric(table(subject.ID))
  ni <- c(0, n.obs.subject)

  ##########
  ## Observation-level covariate matrix
  ##########

  X.cov <- data.use[, x.var, drop = FALSE]

  if (!all(sapply(X.cov, is.numeric))) {
    stop("All covariates in x.var must be numeric. Convert factors to dummy variables first.",
         call. = FALSE)
  }

  X.cov <- as.matrix(X.cov)
  X.obs <- cbind(Intercept = 1, X.cov)

  nX <- ncol(X.obs)

  ##########
  ## Coefficient names
  ##########

  coef.names <- paste0("beta", seq_len(nX) - 1, ".hat")
  x.names <- colnames(X.obs)

  ##########
  ## Spline basis
  ##########

  tlo <- min(time.obs)
  thi <- max(time.obs)
  spline <- .make.spline.spec(tlo, thi, n_basis, degree)
  nseg <- spline$intervals
  bases.obs <- .evaluate.spline(time.obs, spline)
  nbasis <- spline$n_basis
  time.points <- sort(unique(time.obs))
  basis <- .evaluate.spline(time.points, spline)

  ##########
  ## Penalty matrix
  ##########

  D2 <- diff(diag(nbasis), differences = 2)
  Penalty.bases <- t(D2) %*% D2

  Penalty.bases <- Penalty.bases + diag(1e-06, nbasis)

  ##########
  ## Dimension checks
  ##########

  if (nrow(X.obs) != N) {
    stop("X.obs rows do not match the number of observations.",
         call. = FALSE)
  }

  if (nrow(bases.obs) != N) {
    stop("bases.obs rows do not match the number of observations.",
         call. = FALSE)
  }

  if (ncol(bases.obs) != ncol(basis)) {
    stop("Observed basis and unique-time basis have different numbers of columns.",
         call. = FALSE)
  }

  if (nrow(Penalty.bases) != nbasis || ncol(Penalty.bases) != nbasis) {
    stop("Penalty.bases dimensions do not match the number of basis functions.",
         call. = FALSE)
  }

  ##########
  ## First covariate row by subject
  ##########

  first.rows <- match(seq_len(n.subject), subject.ID)
  X.subject <- X.cov[first.rows, , drop = FALSE]

  ##########
  ## Return inputs
  ##########

  list(
    data = data.use,
    data.long = data.use,

    y = y,

    X = X.obs,
    X.obs = X.obs,
    X.subject = X.subject,

    x.var = x.var,
    x.names = x.names,
    coef.names = coef.names,
    nX = nX,

    subject.ID = subject.ID,
    subject.levels = subject.levels,
    n.subject = n.subject,
    n.obs.subject = n.obs.subject,
    n.total = N,
    N = N,
    ni = ni,

    time.obs = time.obs,
    time.points = time.points,
    n.time = length(time.points),

    n_basis = nbasis,
    spline = spline,
    basis.convention = spline$convention,
    degree = degree,
    nseg = nseg,
    tlo = tlo,
    thi = thi,

    basis = basis,
    bases.obs = bases.obs,
    nbasis = nbasis,
    n.basis = nbasis,

    Penalty.bases = Penalty.bases,

    subject.var = subject.var,
    time.var = time.var,
    y.var = y.var
  )
}


############################################################
## Build the JAGS data list
############################################################

build.tdmm.jags.data <- function(inputs,
                                 family = c("gaussian", "bernoulli", "poisson")) {

  ## This helper builds the list passed to JAGS.
  ##
  ## The object names in this list match the variable names used
  ## inside the current JAGS model files.
  ##
  ## In the JAGS files:
  ##   X contains the intercept column and covariates
  ##   nX is the number of coefficient functions
  ##   bases.time is the spline basis evaluated on the observed time grid
  ##   n_basis is the number of spline basis functions

  family <- match.arg(family)

  if (family %in% c("gaussian", "poisson")) {
    return(list(N = inputs$N, n.subject = inputs$n.subject,
                nX = inputs$nX, n_basis = inputs$n_basis, y = inputs$y,
                subject.ID = inputs$subject.ID, X = inputs$X.obs,
                bases.obs = inputs$bases.obs,
                Penalty.bases = inputs$Penalty.bases))
  }
  # Approved centered null-space prior. Keep the exact targeted-comparison
  # eigendecomposition: remove the legacy ridge from penalized eigenvalues,
  # and give the two null directions independent fixed-variance priors.
  ns <- .bernoulli.null.space(inputs$Penalty.bases)
  c(list(N = inputs$N, n.subject = inputs$n.subject,
         nX = inputs$nX, n_basis = inputs$n_basis, y = inputs$y,
         subject.ID = inputs$subject.ID, X = inputs$X.obs,
         bases.obs = inputs$bases.obs), ns)

}


############################################################
## Extract spline coefficient draws
############################################################

.extract.alpha.draws <- function(post.mat,
                                 nX,
                                 nbasis) {

  ## This internal helper extracts posterior draws of the spline
  ## coefficients from the matrix of posterior samples.
  ##
  ## The JAGS model files use matrix-style coefficients:
  ##   alpha[1,1], alpha[1,2], ...
  ##   alpha[2,1], alpha[2,2], ...
  ##
  ## Row 1 corresponds to beta0(t), row 2 corresponds to the
  ## first covariate effect, and so on.

  coef.names <- colnames(post.mat)
  n.draws <- nrow(post.mat)

  alpha.draws <- array(
    NA_real_,
    dim = c(n.draws, nX, nbasis)
  )

  matrix.style.available <- all(
    unlist(
      lapply(seq_len(nX), function(k) {
        paste0("alpha[", k, ",", seq_len(nbasis), "]") %in% coef.names
      })
    )
  )

  if (matrix.style.available) {

    for (k in seq_len(nX)) {
      alpha.cols <- paste0("alpha[", k, ",", seq_len(nbasis), "]")
      alpha.draws[, k, ] <- as.matrix(post.mat[, alpha.cols, drop = FALSE])
    }

    return(alpha.draws)
  }

  stop(
    "Could not find spline coefficient samples in post.mat.\n",
    "Expected matrix-style names like alpha[1,1], alpha[1,2], etc.",
    call. = FALSE
  )
}


############################################################
## Recover posterior mean coefficient functions
############################################################

recover.tdmm.betas <- function(post.mat,
                               basis,
                               nX,
                               coef.names = NULL) {

  ## This helper converts posterior samples of spline
  ## coefficients back into fitted time-varying coefficient
  ## functions.

  nbasis <- ncol(basis)

  alpha.draws <- .extract.alpha.draws(
    post.mat = post.mat,
    nX = nX,
    nbasis = nbasis
  )

  n.draws <- dim(alpha.draws)[1]
  n.time <- nrow(basis)

  beta.draws <- array(
    NA_real_,
    dim = c(n.draws, n.time, nX)
  )

  for (k in seq_len(nX)) {
    beta.draws[, , k] <-
      alpha.draws[, k, , drop = FALSE][, 1, ] %*% t(basis)
  }

  ## Posterior mean fitted coefficient functions.
  beta.hat <- apply(beta.draws, c(2, 3), mean)

  if (is.null(coef.names)) {
    coef.names <- c("beta0", paste0("beta", seq_len(nX - 1)))
  }

  colnames(beta.hat) <- coef.names

  list(
    beta.draws = beta.draws,
    beta.hat = beta.hat,
    beta0.hat = beta.hat[, 1],
    beta.covariates.hat = beta.hat[, -1, drop = FALSE],
    beta.names = coef.names
  )
}


############################################################
## Build fitted TDMM output object
############################################################

build.tdmm.output <- function(family,
                              post.samples,
                              inputs,
                              model.settings) {

  ## This helper builds the object returned by tdmm() and
  ## tdmm.parallel().
  ##
  ## It keeps the output structure consistent across Gaussian,
  ## Bernoulli, and Poisson models.
  ##
  ## Note:
  ##   family is available at the top level and in model.settings.

  family <- match.arg(family, c("gaussian", "bernoulli", "poisson"))

  ##########
  ## Convert posterior samples to a matrix
  ##########

  ## post.samples may already be a matrix, a coda object, or an
  ## R2jags object. This keeps the helper flexible.

  if (is.matrix(post.samples)) {
    post.mat <- post.samples
  } else if (inherits(post.samples, "mcmc.list") || inherits(post.samples, "mcmc")) {
    post.mat <- as.matrix(post.samples)
  } else if (!is.null(post.samples$BUGSoutput$sims.matrix)) {
    post.mat <- post.samples$BUGSoutput$sims.matrix
  } else {
    post.mat <- as.matrix(post.samples)
  }

  ##########
  ## Recover fitted beta functions
  ##########

  beta.recovered <- recover.tdmm.betas(
    post.mat = post.mat,
    basis = inputs$basis,
    nX = inputs$nX,
    coef.names = inputs$coef.names
  )

  ##########
  ## Variance summaries
  ##########

  sigma2.b <- NA_real_
  sigma.b <- NA_real_
  sigma2.e <- NA_real_
  sigma.e <- NA_real_

  if ("sigma2.b" %in% colnames(post.mat)) {
    sigma2.b <- mean(post.mat[, "sigma2.b"])
  }

  if ("sigma.b" %in% colnames(post.mat)) {
    sigma.b <- mean(post.mat[, "sigma.b"])
  } else if (!is.na(sigma2.b)) {
    sigma.b <- sqrt(sigma2.b)
  }

  if (family == "gaussian") {

    if ("sigma2.e" %in% colnames(post.mat)) {
      sigma2.e <- mean(post.mat[, "sigma2.e"])
    }

    if ("sigma.e" %in% colnames(post.mat)) {
      sigma.e <- mean(post.mat[, "sigma.e"])
    } else if (!is.na(sigma2.e)) {
      sigma.e <- sqrt(sigma2.e)
    }
  }

  ##########
  ## Build output list
  ##########

  output <- list(
    family = family,
    post.samples = post.samples,
    post.mat = post.mat,

    ## General matrix of fitted coefficient functions.
    ## Columns are named using beta.names.
    beta.hat = beta.recovered$beta.hat,

    ## Matrix of fitted covariate effect functions only.
    beta.covariates.hat = beta.recovered$beta.covariates.hat,

    ## Names of the fitted coefficient functions.
    beta.names = beta.recovered$beta.names,

    time.points = inputs$time.points,
    inputs = inputs,
    model.settings = model.settings,
    sigma2.b = sigma2.b,
    sigma.b = sigma.b
  )

  ##########
  ## Add numbered beta*.hat outputs
  ##########

  ## beta0.hat is the fitted intercept function.
  ## beta1.hat, beta2.hat, ... are fitted covariate effect
  ## functions in the same order as x.var.
  ##
  ## For example:
  ##   x.var = c("x1", "x2")
  ## gives:
  ##   beta0.hat = intercept function
  ##   beta1.hat = effect of x1
  ##   beta2.hat = effect of x2

  for (k in seq_len(inputs$nX)) {
    output[[paste0("beta", k - 1, ".hat")]] <- beta.recovered$beta.hat[, k]
  }

  ##########
  ## Gaussian residual variance summaries
  ##########

  ## Gaussian models also include residual variance summaries.
  ## Bernoulli and Poisson models do not include sigma2.e or sigma.e.

  if (family == "gaussian") {
    output$sigma2.e <- sigma2.e
    output$sigma.e <- sigma.e
  }

  class(output) <- "tdmm"

  output
}

# Internal decomposition; users only supply data and the public spline controls.
.bernoulli.null.space <- function(penalty) {
  e <- eigen(penalty, symmetric = TRUE)
  lambda <- e$values - 1e-6
  nul <- which(lambda <= 1e-8)
  pen <- which(lambda > 1e-8)
  if (length(nul) != 2L || length(pen) != nrow(penalty) - 2L)
    stop("Invalid second-difference null-space decomposition.", call. = FALSE)
  list(n.null = length(nul), n.pen = length(pen),
       U.null = e$vectors[, nul, drop = FALSE],
       U.pen = e$vectors[, pen, drop = FALSE],
       lambda.pen = lambda[pen], tau.null = .01)
}
