\name{tdmm.parallel}
\alias{tdmm.parallel}
\title{Legacy parallel TDMM fitting wrapper}
\description{Compatibility wrapper that delegates to tdmm() with parallel execution selected.}
\usage{
tdmm.parallel(data, family = c("gaussian", "bernoulli", "poisson"), nknots = NULL, subject.var = "subject.ID", 
    time.var = "time", y.var = "y", x.var = NULL, degree = 3, n.chains = 3, n.iter = 10000, n.burn = 3000, 
    n.thin = 5, n.adapt = 10000, n.cores = min(n.chains, parallel::detectCores()), jags.dir = NULL, quiet = FALSE, 
    seed = NULL, n_basis = NULL, control = NULL, priors = NULL) 
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
\item{n.cores}{Legacy number of parallel cores; prefer control.}
\item{jags.dir}{Legacy model-directory override for compatibility; ordinary users should leave this NULL.}
\item{quiet}{Suppress JAGS progress output when TRUE.}
\item{seed}{Legacy random seed; prefer control.}
\item{n_basis}{Actual number of B-spline basis functions. Omission resolves to 8.}
\item{control}{Optional list from tdmm_control() controlling chains, iterations, burn-in, thinning, adaptation, seed, parallel execution, and cores.}
\item{priors}{Optional family-specific list, normally obtained from tdmm.priors(family) and modified by the user.}
}
\details{For new analyses, call tdmm() with control = tdmm_control(parallel = TRUE, cores = ...). This wrapper retains legacy arguments and delegates data checking, model fitting, and output construction to tdmm().}
\value{A fitted object of class "tdmm".}
\seealso{\code{\link{tdmm}}}
\examples{
\dontrun{
## my_long_data is a long-format data frame; see the tdmm() example.
fit <- tdmm.parallel(my_long_data, family = "gaussian",
                     subject.var = "id", time.var = "time", y.var = "y",
                     x.var = "baseline", n.cores = 2)
}
}
