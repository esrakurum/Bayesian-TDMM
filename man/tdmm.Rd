\name{tdmm}
\alias{tdmm}
\title{Fit a time-dynamic mixed-effects model}
\description{Fit Gaussian, Bernoulli, or Poisson longitudinal outcomes with time-varying coefficient functions and subject-specific random intercepts.}
\usage{
tdmm(data, family = c("gaussian", "bernoulli", "poisson"), nknots = NULL, subject.var = "subject.ID", 
    time.var = "time", y.var = "y", x.var = NULL, degree = 3, n.chains = 3, n.iter = 10000, n.burn = 3000, 
    n.thin = 5, n.adapt = 5000, jags.dir = NULL, quiet = FALSE, n_basis = NULL, control = NULL, priors = NULL) 
}
\arguments{
\item{data}{Long-format data frame: one row per observed subject and time.}
\item{family}{One of "gaussian", "bernoulli", or "poisson".}
\item{nknots}{Deprecated compatibility argument with its historical interval-count interpretation. Do not supply with n_basis.}
\item{subject.var}{Name of the subject ID column.}
\item{time.var}{Name of the numeric observation-time column.}
\item{y.var}{Name of the response column.}
\item{x.var}{Names of numeric covariates, in coefficient order; NULL selects all columns other than subject ID, time, and response.}
\item{degree}{B-spline polynomial degree; default 3 (cubic).}
\item{n.chains}{Legacy number of chains; prefer control.}
\item{n.iter}{Legacy total iterations; prefer control.}
\item{n.burn}{Legacy burn-in iterations; prefer control.}
\item{n.thin}{Legacy thinning interval; prefer control.}
\item{n.adapt}{Legacy adaptation iterations; prefer control.}
\item{jags.dir}{Legacy model-directory override for compatibility; ordinary users should leave this NULL.}
\item{quiet}{Suppress JAGS progress output when TRUE.}
\item{n_basis}{Actual number of B-spline basis functions. Omission resolves to 8.}
\item{control}{Optional list from tdmm_control() controlling chains, iterations, burn-in, thinning, adaptation, seed, parallel execution, and cores.}
\item{priors}{Optional family-specific list, normally obtained from tdmm.priors(family) and modified by the user.}
}
\details{Rows may have irregular subject-specific times and unequal visit counts. Numeric covariates may be constant or change within subject. Coefficient functions use an extended uniform B-spline basis with a second-order coefficient-difference penalty. The default is cubic with eight basis functions. Use tdmm_control(parallel = TRUE, cores = ...) for parallel chains. The coefficient functions are on the identity, logit, or log link scale for Gaussian, Bernoulli, or Poisson responses, respectively.}
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
            control = tdmm_control(seed = 42))
summary(fit)
plot(fit)
}
}
