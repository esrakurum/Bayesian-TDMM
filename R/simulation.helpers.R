## This file contains helper functions for generating simulated
## longitudinal data sets from the three TDMM response families:
##
##   - Gaussian
##   - Bernoulli
##   - Poisson
##
## These functions are useful for examples, testing, and simulation
## studies. They are not required for fitting a TDMM to a user's
## own data.
##
## Each simulated data set is returned in long format with columns:
##
##   subject.ID
##   time
##   y
##   x1
##
## Current simulation setup:
##   - all subjects share the same time grid
##   - x1 is a baseline subject-level covariate
##   - x1 is constant within subject
##   - each subject has one random intercept
##   - beta_0(t) = sin(2*pi*t)
##   - beta_1(t) = cos(2*pi*t)
##
## Note:
## These simulation helpers intentionally use one covariate, x1,
## to keep the examples simple. The main tdmm() fitting functions
## can still fit data sets with multiple covariates using x.var.
############################################################


############################################################
## Gaussian TDMM data generator
############################################################

data.gen.tdmm.gauss <- function(n.subject = 200,
                                n.time = 20,
                                sigma2.b = 0.5,
                                sigma2.e = 0.1,
                                seed = NULL) {
  
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
                               seed = NULL) {
  
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
                               seed = NULL) {
  
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
