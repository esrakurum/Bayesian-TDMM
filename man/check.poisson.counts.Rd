\name{check.poisson.counts}
\alias{check.poisson.counts}
\title{Check a nonnegative integer Poisson response.}
\description{Check a nonnegative integer Poisson response.}
\usage{
check.poisson.counts(data, y.var = "y", time.var = "time") 
}
\arguments{
\item{data}{Data frame with one row per observation.}
\item{y.var}{Response column name.}
\item{time.var}{Numeric observation-time column name.}
}
\value{A family-specific response diagnostic list.}
\seealso{\code{\link{check.tdmm.family.data}}}
\examples{
\dontrun{
# For full input checking, use check.tdmm.family.data(data, family = "gaussian").
}
}
