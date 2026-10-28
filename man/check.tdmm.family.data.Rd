\name{check.tdmm.family.data}
\alias{check.tdmm.family.data}
\title{Check TDMM data for an outcome family}
\description{Apply structural and family-specific response checks to TDMM data with one row per observation.}
\usage{
check.tdmm.family.data(data, family = c("gaussian", "bernoulli", "poisson"), subject.var = "subject.ID", time.var = "time", 
    y.var = "y", x.var = NULL, stop.on.fail = TRUE) 
}
\arguments{
\item{data}{Data frame with one row per observation.}
\item{family}{One of "gaussian", "bernoulli", or "poisson".}
\item{subject.var}{Subject ID column name.}
\item{time.var}{Numeric observation-time column name.}
\item{y.var}{Response column name.}
\item{x.var}{Numeric covariate column names; NULL selects remaining columns.}
\item{stop.on.fail}{If TRUE, stop on invalid data; otherwise return diagnostics.}
}
\value{A list of data-check diagnostics and selected covariates; invalid input raises an error when stop.on.fail is TRUE.}
\seealso{\code{\link{tdmm}}}
\examples{
d <- data.frame(subject.ID = rep(1:3, each = 3),
                time = rep(c(0, 0.5, 1), 3), y = rnorm(9), x = rnorm(9))
check.tdmm.family.data(d, family = "gaussian", x.var = "x")
}
