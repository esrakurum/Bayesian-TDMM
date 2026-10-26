\name{make.tdmm.plot.grid}
\alias{make.tdmm.plot.grid}
\title{Construct a TDMM plotting grid}
\description{Create evaluation times and a spline basis consistent with a fitted TDMM object.}
\usage{
make.tdmm.plot.grid(data, grid = NULL, n.grid = 100, time.var = "time", nknots = NULL, degree = 3, n_basis = NULL, 
    result = NULL) 
}
\arguments{
\item{data}{Long-format data frame or fitted TDMM object.}
\item{grid}{Optional numeric evaluation times.}
\item{n.grid}{Number of points when grid is NULL.}
\item{time.var}{Observation-time column name.}
\item{nknots}{Deprecated \code{nknots} argument.}
\item{degree}{Spline degree for new grids.}
\item{n_basis}{Number of basis functions for new grids.}
\item{result}{Optional fitted tdmm object whose spline metadata is authoritative.}
}
\details{When result is supplied, its recorded spline convention, degree, basis dimension, and time domain are used. This preserves reconstruction of older fitted objects.}
\value{A list containing the plotting grid and evaluated basis.}
\seealso{\code{\link{plot.tdmm}}}
\examples{
\dontrun{
grid <- make.tdmm.plot.grid(fit)
}
}
