############################################################
## TDMM helper functions
############################################################
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
  ##   alpha[k, 1:nknots]
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
                                      nknots,
                                      subject.var = "subject.ID",
                                      time.var = "time",
                                      y.var = "y",
                                      x.var = NULL,
                                      degree = 2) {
  
  ## This helper prepares the data objects used by the JAGS
  ## fitting functions.
  ##
  ## The data are expected to be in long format, with repeated
  ## observations grouped by subject and time.
  ##
  ## x.var can be one covariate or any number of baseline
  ## covariates:
  ##
  ##   x.var = "x1"
  ##   x.var = c("x1", "x2", ...)
  ##
  ## If x.var is NULL, all columns except subject, time, and y
  ## are treated as baseline covariates.
  
  ##########
  ## Identify covariates
  ##########
  
  if (is.null(x.var)) {
    x.var <- setdiff(names(data), c(subject.var, time.var, y.var))
  }
  
  if (length(x.var) == 0) {
    stop("No baseline covariates were provided or detected.", call. = FALSE)
  }
  
  ##########
  ## Check required columns
  ##########
  
  required.cols <- c(subject.var, time.var, y.var, x.var)
  missing.cols <- setdiff(required.cols, names(data))
  
  if (length(missing.cols) > 0) {
    stop(
      "data is missing required column(s): ",
      paste(missing.cols, collapse = ", "),
      call. = FALSE
    )
  }
  
  ##########
  ## Order the data
  ##########
  ## The JAGS model uses subject-level indexing, so we keep the
  ## data ordered by subject and time.
  
  data <- data[order(data[[subject.var]], data[[time.var]]), ]
  rownames(data) <- NULL
  
  ##########
  ## Subject and time information
  ##########
  
  subject.ID <- data[[subject.var]]
  subject.levels <- unique(subject.ID)
  n.subject <- length(subject.levels)
  
  time.points <- sort(unique(data[[time.var]]))
  n.time <- length(time.points)
  
  ## Number of observations per subject.
  n.obs.subject <- as.numeric(table(subject.ID))
  
  ## ni follows the indexing structure used in the current JAGS files.
  ## The first entry is 0, followed by the number of observations for
  ## each subject.
  ## For example, if each subject has 20 observations, then:
  ##   ni = c(0, 20, 20, 20, ...)
  ## The JAGS files use sums of ni to find each subject's row range.
  
  ni <- c(0, n.obs.subject)
  
  ##########
  ## Response and covariate objects
  ##########
  
  y <- data[[y.var]]
  
  ## Build subject-level covariate matrix.
  ## Since x.var are baseline covariates, each subject should
  ## have one value for each covariate.
  
  X.subject <- do.call(
    rbind,
    lapply(subject.levels, function(id) {
      subject.rows <- data[data[[subject.var]] == id, , drop = FALSE]
      as.numeric(subject.rows[1, x.var, drop = TRUE])
    })
  )
  
  X.subject <- as.matrix(X.subject)
  colnames(X.subject) <- x.var
  
  ## Observation-level design matrix.
  ## The first column is the intercept. The remaining columns are
  ## the user-specified baseline covariates repeated across time.
  ##
  ## This matches the JAGS model files, where nX is the total
  ## number of coefficient functions:
  ##   beta_0(t), beta_1(t), beta_2(t), ...
  
  X <- cbind(Intercept = 1, as.matrix(data[, x.var, drop = FALSE]))
  
  ## nX is the total number of coefficient functions, including
  ## the intercept.
  
  nX <- ncol(X)
  
  ## Store readable coefficient names.
  ## beta0 corresponds to the intercept.
  ## beta_x1, beta_x2, ... correspond to the selected covariates.
  ##
  ## These are R column names. In the handbook/math notation,
  ## the fitted functions can be written as beta hats:
  ##   beta0     -> \hat{beta}_0(t)
  ##   beta_x1   -> \hat{beta}_{x1}(t)
  ##   beta_x2   -> \hat{beta}_{x2}(t)
  
  coef.names <- paste0("beta", seq_len(nX) - 1, ".hat")
  
  ##########
  ## Spline basis
  ##########
  
  tlo <- min(time.points)
  thi <- max(time.points)
  
  ## nseg controls the number of intervals used in the spline
  ## basis construction.
  
  nseg <- nknots - 2
  
  basis <- bbase(
    x = time.points,
    xl = tlo,
    xr = thi,
    ndx = nseg,
    deg = degree
  )
  
  nbasis <- ncol(basis)
  
  ##########
  ## Penalty matrix
  ##########
  
  ## Second-order difference penalty for smoothing spline
  ## coefficients.
  
  D2 <- diff(diag(nbasis), differences = 2)
  Penalty.bases <- t(D2) %*% D2
  
  ## Small ridge term for numerical stability.
  
  Penalty.bases <- Penalty.bases + diag(1e-06, nbasis)
  
  ##########
  ## Return processed inputs
  ##########
  
  list(
    data = data,
    y = y,
    X = X,
    X.subject = X.subject,
    x.var = x.var,
    coef.names = coef.names,
    nX = nX,
    subject.ID = subject.ID,
    subject.levels = subject.levels,
    n.subject = n.subject,
    n.obs.subject = n.obs.subject,
    n.total = length(y),
    ni = ni,
    time.points = time.points,
    n.time = n.time,
    nknots = nknots,
    degree = degree,
    nseg = nseg,
    tlo = tlo,
    thi = thi,
    basis = basis,
    nbasis = nbasis,
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
  ##   nknots is the number of spline basis functions
  
  family <- match.arg(family)
  
  jags.data <- list(
    y = inputs$y,
    X = inputs$X,
    nX = inputs$nX,
    n.subject = inputs$n.subject,
    n.time = inputs$n.time,
    ni = inputs$ni,
    bases.time = inputs$basis,
    nknots = inputs$nbasis,
    Penalty.bases = inputs$Penalty.bases
  )
  
  jags.data
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
  ##   family is not stored as a top-level output element because
  ##   it is already stored in model.settings$family.
  
  family <- match.arg(family, c("gaussian", "bernoulli", "poisson"))
  
  ##########
  ## Convert posterior samples to a matrix
  ##########
  
  ## post.samples may already be a matrix, a coda object, or an
  ## R2jags object. This keeps the helper flexible.
  
  if (is.matrix(post.samples)) {
    post.mat <- post.samples
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
