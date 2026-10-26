\name{data.gen.tdmm.bern}
\alias{data.gen.tdmm.bern}
\title{Generate Bernoulli TDMM simulation data}
\description{Generate Bernoulli outcomes with time-varying sine and cosine coefficients. The default uses repeated measurements and a subject-specific random intercept; \code{random_intercept = FALSE} generates independent observations.}
\usage{
data.gen.tdmm.bern(n.subject = 200, n.time = 20, sigma2.b = 0.5,
  seed = NULL, random_intercept = TRUE)
}
\arguments{
\item{n.subject}{Number of subjects. If omitted, the default is 200 with a random intercept and 2500 without one. An explicitly supplied value is used in either case.}
\item{n.time}{Number of observations per subject when \code{random_intercept = TRUE}; unused otherwise.}
\item{sigma2.b}{Random-intercept variance when \code{random_intercept = TRUE}; unused otherwise.}
\item{seed}{Optional random seed.}
\item{random_intercept}{A single logical value. \code{TRUE} generates repeated observations on a common time grid with a subject-specific random intercept. \code{FALSE} generates one independent observation per subject with time drawn uniformly from 0 to 1.}
}
\details{Both settings use \code{beta0(t) = sin(2*pi*t)} and \code{beta1(t) = cos(2*pi*t)}. With \code{random_intercept = FALSE}, \code{x1} is drawn independently from a standard Normal distribution for each subject, and the logit probability is \code{beta0(time) + x1*beta1(time)}. With \code{random_intercept = TRUE}, a subject-specific random intercept is added to that expression.}
\value{A data frame with \code{subject.ID}, \code{time}, \code{y}, and \code{x1}.}
\examples{
d <- data.gen.tdmm.bern(n.subject = 5, n.time = 4, seed = 1)
d.independent <- data.gen.tdmm.bern(n.subject = 10,
  random_intercept = FALSE, seed = 1)
}
