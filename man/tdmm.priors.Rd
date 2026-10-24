\name{tdmm.priors}
\alias{tdmm.priors}
\title{Family-specific default TDMM priors}
\usage{tdmm.priors(family = c("gaussian", "bernoulli", "poisson"))}
\arguments{\item{family}{Response family.}}
\description{Return the family-specific structured prior defaults used by
\code{tdmm()}. A partial nested list can be passed
as \code{priors=} to change supported prior parameters.}
\details{All Gamma distributions use shape and rate. The smoothing prior is
\code{smoothing = list(shape = 1, rate = 0.001)} for every family.
Gaussian uses Gamma(1, 0.005) priors on random-intercept and residual
precisions. Bernoulli and Poisson use a Uniform(0, 5) prior on the random-intercept
standard deviation. Bernoulli uses a Normal(0, 100) prior for each of its two
null-space coordinates, corresponding to \code{null_space = list(sd = 10)}.
The approved distribution family is fixed for each response family; users may
change positive shape, rate, maximum standard deviation, or null-space standard
deviation parameters. Basis eigenvectors and numerical ridge constants are not
prior controls.}
\value{A named list with \code{smoothing}, \code{random_intercept}, and
family-specific \code{residual} or \code{null_space} groups.}
\examples{
 tdmm.priors("bernoulli")
 # Example partial override: priors = list(smoothing = list(rate = 0.002))
}
