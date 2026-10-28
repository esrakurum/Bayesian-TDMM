\name{tdmm.parallel}
\alias{tdmm.parallel}
\title{Parallel TDMM fitting wrapper}
\description{Fit TDMM with parallel chains through \code{tdmm()}.}
\usage{
tdmm.parallel(data, family = c("gaussian", "bernoulli", "poisson"), nknots = NULL, subject.var = "subject.ID", 
    time.var = "time", y.var = "y", x.var = NULL, degree = 3, n.chains = 3, n.iter = 10000, n.burn = 3000, 
    n.thin = 5, n.adapt = 10000, n.cores = min(n.chains, parallel::detectCores()), jags.dir = NULL, quiet = FALSE, 
    seed = NULL, n_basis = NULL, control = NULL, priors = NULL, random_intercept = TRUE)
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
\item{n.cores}{Number of parallel cores; \code{control} is recommended.}
\item{jags.dir}{Optional model directory; ordinarily leave this \code{NULL}.}
\item{quiet}{Suppress JAGS progress output when TRUE.}
\item{seed}{Random seed; \code{control} is recommended.}
\item{n_basis}{Actual number of B-spline basis functions. Omission resolves to 8.}
\item{control}{Optional list from tdmm_control() controlling chains, iterations, burn-in, thinning, adaptation, seed, parallel execution, and cores.}
\item{priors}{Optional family-specific list, normally obtained from tdmm.priors(family) and modified by the user.}
\item{random_intercept}{\code{TRUE} (the default) includes a subject-specific random intercept for repeated observations. \code{FALSE} fits without one for independent observations.}
}
\details{For parallel fitting, \code{tdmm(control = tdmm_control(parallel = TRUE, cores = ...))} is recommended. This wrapper retains the existing \code{tdmm.parallel()} arguments and delegates fitting to \code{tdmm()}.}
\value{A fitted object of class "tdmm".}
\seealso{\code{\link{tdmm}}}
\examples{
\dontrun{
## my_long_data is a long-format data frame; see the tdmm() example.
fit <- tdmm.parallel(my_long_data, family = "gaussian",
                     subject.var = "id", time.var = "time", y.var = "y",
                     x.var = "baseline", random_intercept = TRUE,
                     n.cores = 2)
}
}
