\name{recover.tdmm.betas.ci}
\alias{recover.tdmm.betas.ci}
\title{Reconstruct TDMM coefficient-function intervals}
\description{Reconstruct posterior coefficient functions from spline-coefficient draws and an evaluation basis.}
\usage{
recover.tdmm.betas.ci(post.mat, bases.grid, nX, coef.names = NULL, level = 0.95) 
}
\arguments{
\item{post.mat}{Posterior draw matrix with alpha coefficient columns.}
\item{bases.grid}{Spline basis matrix on the desired evaluation grid.}
\item{nX}{Number of coefficient functions including intercept.}
\item{coef.names}{Optional coefficient-function names.}
\item{level}{Pointwise credible level.}
}
\value{Posterior coefficient-function means and pointwise intervals.}
\examples{
\dontrun{
# Normally called by plot(fit); users rarely need direct reconstruction.
}
}
