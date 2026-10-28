\name{check.bernoulli.balance}
\alias{check.bernoulli.balance}
\title{Check a binary Bernoulli response.}
\description{Check a binary Bernoulli response.}
\usage{
check.bernoulli.balance(data, y.var = "y", time.var = "time") 
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
