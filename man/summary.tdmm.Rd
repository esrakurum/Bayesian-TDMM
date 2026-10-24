\name{summary.tdmm}
\alias{summary.tdmm}
\title{Summarize a fitted TDMM model}
\description{Print model dimensions, MCMC settings, prior settings, and variance estimates, then return a summary list invisibly.}
\usage{
\method{summary}{tdmm}(object, ...) 
}
\arguments{
\item{object}{A fitted tdmm object.}
\item{...}{Reserved for compatibility with the summary generic.}
}
\value{An invisible list with family, dimensions, coefficient estimates, variance summaries, and model settings.}
\seealso{\code{\link{tdmm}}}
\examples{
\dontrun{
summary(fit)
}
}
