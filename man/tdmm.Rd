\name{tdmm}
\alias{tdmm}
\title{Fit a Bayesian time-dynamic model with optional mixed effects}
\description{Fit Bayesian time-dynamic models with optional mixed effects for Gaussian, Bernoulli, or Poisson outcomes. Regression coefficients vary smoothly over time. A subject-specific random intercept supports repeated observations; models without it support independent observations.}
\usage{
tdmm(data, family = c("gaussian", "bernoulli", "poisson"), nknots = NULL, subject.var = "subject.ID", 
    time.var = "time", y.var = "y", x.var = NULL, degree = 3, n.chains = 3, n.iter = 10000, n.burn = 3000, 
    n.thin = 5, n.adapt = 5000, jags.dir = NULL, quiet = FALSE, n_basis = NULL, control = NULL, priors = NULL,
    random_intercept = TRUE)
}
\arguments{
\item{data}{Data frame with one row per observation and columns for subject ID, time, response, and covariates.}
\item{family}{One of "gaussian", "bernoulli", or "poisson".}
\item{nknots}{Deprecated \code{nknots} argument using the interval-count convention. Do not supply with \code{n_basis}.}
\item{subject.var}{Name of the subject ID column.}
\item{time.var}{Name of the numeric observation-time column.}
\item{y.var}{Name of the response column.}
\item{x.var}{Names of numeric covariates, in coefficient order; NULL selects all columns other than subject ID, time, and response.}
\item{degree}{B-spline polynomial degree; default 3 (cubic).}
\item{n.chains}{Number of chains; \code{control} is recommended.}
\item{n.iter}{Total iterations; \code{control} is recommended.}
\item{n.burn}{Burn-in iterations; \code{control} is recommended.}
\item{n.thin}{Thinning interval; \code{control} is recommended.}
\item{n.adapt}{Adaptation iterations; \code{control} is recommended.}
\item{jags.dir}{Optional model directory; ordinarily leave this \code{NULL}.}
\item{quiet}{Suppress JAGS progress output when TRUE.}
\item{n_basis}{Actual number of B-spline basis functions. Omission resolves to 8.}
\item{control}{Optional list from tdmm_control() controlling chains, iterations, burn-in, thinning, adaptation, seed, parallel execution, and cores.}
\item{priors}{Optional family-specific list, normally obtained from tdmm.priors(family) and modified by the user.}
\item{random_intercept}{\code{TRUE} (the default) includes a subject-specific random intercept for repeated observations. \code{FALSE} fits without one for independent observations.}
}
\details{With repeated observations, subjects may have irregular observation times and unequal visit counts; numeric covariates may be constant or change within subject. For independent observations, time may represent age, time since an event, or time relative to an event. Coefficient functions use an extended uniform B-spline basis with a second-order coefficient-difference penalty. The default is cubic with eight basis functions. Use tdmm_control(parallel = TRUE, cores = ...) for parallel chains. The coefficient functions are on the identity, logit, or log link scale for Gaussian, Bernoulli, or Poisson responses, respectively.}
\value{A fitted object of class "tdmm" containing posterior samples, reconstructed coefficient functions, input metadata, variance summaries, and fitting settings.}
\seealso{\code{\link{tdmm.control}}, \code{\link{tdmm.priors}}, \code{\link{summary.tdmm}}, \code{\link{plot.tdmm}}}
\examples{
\dontrun{
# Requires JAGS and runs MCMC.
set.seed(42)
my_long_data <- do.call(rbind, lapply(seq_len(20), function(id) {
  time <- sort(runif(5))
  baseline <- rnorm(1)
  changing <- rnorm(5)
  data.frame(id = id, time = time, baseline = baseline,
             changing = changing,
             y = 0.5 + baseline * sin(2*pi*time) +
                 changing * (time - 0.5) + rnorm(5, sd = 0.3))
}))
fit <- tdmm(my_long_data, family = "gaussian", subject.var = "id",
            time.var = "time", y.var = "y", x.var = c("baseline", "changing"),
            random_intercept = TRUE, control = tdmm_control(seed = 42))
summary(fit)
plot(fit)
}
}
