\name{check.gaussian.response}
\alias{check.gaussian.response}
\title{Check a numeric Gaussian response.}
\description{Check a numeric Gaussian response.}
\usage{
check.gaussian.response(data, y.var = "y", time.var = "time") 
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
