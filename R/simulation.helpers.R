## Simulation data for Gaussian, Bernoulli, and Poisson TDMM examples.
## Each data frame contains subject.ID, time, y, and x1. Gaussian and
## Poisson independent-observation examples also contain x2. With a
## random intercept, subjects have repeated visits on a common time grid;
## without one, each subject has one observation.
############################################################


############################################################
## Gaussian TDMM data generator
############################################################

data.gen.tdmm.gauss <- function(n.subject = 200,
                                n.time = 20,
                                sigma2.b = 0.5,
                                sigma2.e = 0.1,
                                seed = NULL,
                                random_intercept = TRUE) {

  if (!is.logical(random_intercept) || length(random_intercept) != 1L ||
      is.na(random_intercept)) {
    stop("random_intercept must be a single non-missing logical value.",
         call. = FALSE)
  }

  if (!random_intercept) {
    ## One observation per subject, with covariates drawn independently of time.
    if (missing(n.subject)) n.subject <- 300L
    if (!is.null(seed)) set.seed(seed)
    subject.ID <- seq_len(n.subject)
    time <- stats::runif(n.subject)
    x1 <- rnorm(n.subject)
    x2.time <- stats::runif(n.subject)
    x2 <- sin(2 * pi * x2.time) + rnorm(n.subject, sd = 0.25)
    beta0.t <- sin(2 * pi * time)
    beta1.t <- cos(2 * pi * time)
    beta2.t <- 1.5 * (time - 0.5)
    y <- beta0.t + beta1.t * x1 + beta2.t * x2 +
      rnorm(n.subject, sd = sqrt(sigma2.e))
    return(data.frame(subject.ID = subject.ID, time = time,
                      y = y, x1 = x1, x2 = x2))
  }
  
  ## Optional seed for reproducibility.
  if (!is.null(seed)) {
    set.seed(seed)
  }
  
  ## Common time grid shared by all subjects.
  time.points <- seq(0, 1, length.out = n.time)
  
  ## Subject ID.
  ## Each subject appears n.time times.
  subject.ID <- rep(1:n.subject, each = n.time)
  
  ## Repeated measurement times.
  ## Subject 1 receives all time points, then subject 2, etc.
  time <- rep(time.points, times = n.subject)
  
  ## Baseline subject-level covariate.
  ## x1.subject has one value per subject.
  ## x1 repeats that subject-level value across all time points.
  x1.subject <- rnorm(n.subject, mean = 0, sd = 1)
  x1 <- rep(x1.subject, each = n.time)
  
  ## Subject-level random intercept.
  b.subject <- rnorm(n.subject, mean = 0, sd = sqrt(sigma2.b))
  b <- b.subject[subject.ID]
  
  ## True time-varying coefficient functions.
  beta0.t <- sin(2 * pi * time)
  beta1.t <- cos(2 * pi * time)
  
  ## Gaussian residual error.
  eps <- rnorm(n.subject * n.time, mean = 0, sd = sqrt(sigma2.e))
  
  ## Gaussian response model.
  y <- beta0.t + beta1.t * x1 + b + eps
  
  ## Return the simulated data in long format.
  data <- data.frame(subject.ID = subject.ID, time = time, y = y, x1 = x1)
  
  ## Keep rows ordered by subject and time.
  data <- data[order(data$subject.ID, data$time), ]
  
  rownames(data) <- NULL
  
  data
}


############################################################
## Bernoulli TDMM data generator
############################################################

data.gen.tdmm.bern <- function(n.subject = 200,
                               n.time = 20,
                               sigma2.b = 0.5,
                               seed = NULL,
                               random_intercept = TRUE) {

  if (!is.logical(random_intercept) || length(random_intercept) != 1L ||
      is.na(random_intercept)) {
    stop("random_intercept must be a single non-missing logical value.",
         call. = FALSE)
  }

  if (!random_intercept) {
    if (missing(n.subject)) n.subject <- 2500L
    if (!is.null(seed)) set.seed(seed)
    subject.ID <- seq_len(n.subject)
    time <- stats::runif(n.subject)
    x1 <- rnorm(n.subject)
    beta0.t <- sin(2 * pi * time)
    beta1.t <- cos(2 * pi * time)
    p <- plogis(beta0.t + x1 * beta1.t)
    y <- rbinom(n.subject, size = 1L, prob = p)
    return(data.frame(subject.ID = subject.ID, time = time,
                      y = y, x1 = x1))
  }
  
  ## Optional seed for reproducibility.
  if (!is.null(seed)) {
    set.seed(seed)
  }
  
  ## Common time grid shared by all subjects.
  time.points <- seq(0, 1, length.out = n.time)
  
  ## Subject ID.
  ## Each subject appears n.time times.
  subject.ID <- rep(1:n.subject, each = n.time)
  
  ## Repeated measurement times.
  time <- rep(time.points, times = n.subject)
  
  ## Baseline subject-level covariate.
  ## x1.subject has one value per subject.
  ## x1 repeats that subject-level value across all time points.
  x1.subject <- rnorm(n.subject, mean = 0, sd = 1)
  x1 <- rep(x1.subject, each = n.time)
  
  ## Subject-level random intercept.
  b.subject <- rnorm(n.subject, mean = 0, sd = sqrt(sigma2.b))
  b <- b.subject[subject.ID]
  
  ## True time-varying coefficient functions.
  beta0.t <- sin(2 * pi * time)
  beta1.t <- cos(2 * pi * time)
  
  ## Bernoulli linear predictor.
  eta <- beta0.t + beta1.t * x1 + b
  
  ## Convert the linear predictor to a probability using
  ## the logistic link.
  p <- plogis(eta)
  
  ## Bernoulli response.
  y <- rbinom(n.subject * n.time, size = 1, prob = p)
  
  ## Return the simulated data in long format.
  data <- data.frame(subject.ID = subject.ID, time = time, y = y, x1 = x1)
  
  ## Keep rows ordered by subject and time.
  data <- data[order(data$subject.ID, data$time), ]
  
  rownames(data) <- NULL
  
  data
}


############################################################
## Poisson TDMM data generator
############################################################

data.gen.tdmm.pois <- function(n.subject = 200,
                               n.time = 20,
                               sigma2.b = 0.5,
                               seed = NULL,
                               random_intercept = TRUE) {

  if (!is.logical(random_intercept) || length(random_intercept) != 1L ||
      is.na(random_intercept)) {
    stop("random_intercept must be a single non-missing logical value.",
         call. = FALSE)
  }

  if (!random_intercept) {
    if (missing(n.subject)) n.subject <- 2200L
    if (!is.null(seed)) set.seed(seed)
    subject.ID <- seq_len(n.subject)
    time <- stats::runif(n.subject)
    x1 <- rnorm(n.subject)
    subject.component <- rnorm(n.subject)
    x2 <- subject.component + 0.5 * time + rnorm(n.subject, sd = 0.5)
    beta0.t <- 0.25 + 0.35 * sin(2 * pi * time)
    beta1.t <- 0.35 * cos(2 * pi * time)
    beta2.t <- 0.25 + 0.20 * time
    lambda <- exp(beta0.t + x1 * beta1.t + x2 * beta2.t)
    y <- rpois(n.subject, lambda = lambda)
    return(data.frame(subject.ID = subject.ID, time = time,
                      y = y, x1 = x1, x2 = x2))
  }
  
  ## Optional seed for reproducibility.
  if (!is.null(seed)) {
    set.seed(seed)
  }
  
  ## Common time grid shared by all subjects.
  time.points <- seq(0, 1, length.out = n.time)
  
  ## Subject ID.
  ## Each subject appears n.time times.
  subject.ID <- rep(1:n.subject, each = n.time)
  
  ## Repeated measurement times.
  time <- rep(time.points, times = n.subject)
  
  ## Baseline subject-level covariate.
  ## x1.subject has one value per subject.
  ## x1 repeats that subject-level value across all time points.
  x1.subject <- rnorm(n.subject, mean = 0, sd = 1)
  x1 <- rep(x1.subject, each = n.time)
  
  ## Subject-level random intercept.
  b.subject <- rnorm(n.subject, mean = 0, sd = sqrt(sigma2.b))
  b <- b.subject[subject.ID]
  
  ## True time-varying coefficient functions.
  beta0.t <- sin(2 * pi * time)
  beta1.t <- cos(2 * pi * time)
  
  ## Poisson linear predictor.
  eta <- beta0.t + beta1.t * x1 + b
  
  ## Poisson mean count.
  lambda <- exp(eta)
  
  ## Poisson response.
  y <- rpois(n.subject * n.time, lambda = lambda)
  
  ## Return the simulated data in long format.
  data <- data.frame(subject.ID = subject.ID, time = time, y = y, x1 = x1)
  
  ## Keep rows ordered by subject and time.
  data <- data[order(data$subject.ID, data$time), ]
  
  rownames(data) <- NULL
  
  data
}
