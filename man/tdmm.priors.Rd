\name{tdmm.priors}
\alias{tdmm.priors}
\title{Family-specific default TDMM priors}

\usage{
tdmm.priors(family = c("gaussian", "bernoulli", "poisson"))
}

\arguments{
\item{family}{Response family.}
}

\description{
Return the family-specific prior defaults used by \code{tdmm()}.
A partial named list can be supplied through \code{priors=} to modify
supported prior parameters.
}

\details{
All Gamma distributions use shape and rate parameterization.

For all response families, the smoothing precision has a
Gamma(1, 0.001) prior.

For Gaussian outcomes, the random-intercept precision and residual
precision each have Gamma(1, 0.005) priors.

For Bernoulli and Poisson outcomes, the random-intercept standard
deviation has a Uniform(0, 5) prior.

For Bernoulli outcomes, \code{null_space = list(sd = 10)} specifies
the standard deviation used for the two unpenalized spline components.

Users may modify the numerical parameters of these priors, but the
prior distribution associated with each response family is fixed.
}

\value{
A named list containing the prior settings for the selected response
family. The list includes \code{smoothing} and \code{random_intercept},
with additional family-specific components where applicable.
}

\examples{
tdmm.priors("bernoulli")

# Example partial override:
priors <- list(smoothing = list(rate = 0.002))
}
