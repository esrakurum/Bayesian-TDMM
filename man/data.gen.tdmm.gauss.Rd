\name{data.gen.tdmm.gauss}
\alias{data.gen.tdmm.gauss}
\title{Generate a balanced-grid Gaussian simulation dataset}
\description{Generate a balanced-grid Gaussian simulation dataset for compatibility examples. This legacy helper is separate from the irregular-time V2 simulation examples.}
\usage{
data.gen.tdmm.gauss(n.subject = 200, n.time = 20, sigma2.b = 0.5, sigma2.e = 0.1, seed = NULL) 
}
\arguments{
\item{n.subject}{Number of subjects.}
\item{n.time}{Number of observations per subject.}
\item{sigma2.b}{Random-intercept variance.}
\item{sigma2.e}{Gaussian residual variance.}
\item{seed}{Optional random seed.}
}
\value{A simulated long-format data frame or list as returned by the generator.}
\examples{
set.seed(1)
d <- data.gen.tdmm.gauss(n.subject = 5, n.time = 4)
}
