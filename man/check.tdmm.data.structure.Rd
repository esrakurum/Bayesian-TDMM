\name{check.tdmm.data.structure}
\alias{check.tdmm.data.structure}
\title{Check TDMM long-format input structure}
\description{Check required columns, data types, missingness, repeated measurements, and covariate structure before model fitting.}
\usage{
check.tdmm.data.structure(data, subject.var = "subject.ID", time.var = "time", y.var = "y", x.var = NULL, stop.on.fail = TRUE) 
}
\arguments{
\item{data}{Long-format data frame.}
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
check.tdmm.data.structure(d, x.var = "x")
}
