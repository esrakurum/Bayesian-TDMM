\name{data.gen.tdmm.pois}
\alias{data.gen.tdmm.pois}
\title{Generate Poisson TDMM simulation data}
\description{Generate Poisson counts for TDMM examples. The default uses repeated measurements and a subject-specific random intercept; \code{random_intercept = FALSE} generates independent observations with two predictors.}
\usage{
data.gen.tdmm.pois(n.subject = 200, n.time = 20, sigma2.b = 0.5,
  seed = NULL, random_intercept = TRUE)
}
\arguments{
\item{n.subject}{Number of subjects. If omitted, the default is 200 with a random intercept and 2200 without one. An explicitly supplied value is used in either case.}
\item{n.time}{Number of observations per subject when \code{random_intercept = TRUE}; unused otherwise.}
\item{sigma2.b}{Random-intercept variance when \code{random_intercept = TRUE}; unused otherwise.}
\item{seed}{Optional random seed.}
\item{random_intercept}{A single logical value. \code{TRUE} generates repeated observations on a common time grid with a subject-specific random intercept. \code{FALSE} generates one independent observation per subject with time drawn uniformly from 0 to 1.}
}
\details{With \code{random_intercept = FALSE}, \code{x1} is standard Normal and \code{x2 = u + 0.5*time + e}, where \code{u} is standard Normal and \code{e} is Normal with standard deviation 0.5, independently drawn for each subject. The log mean is \code{beta0(time) + x1*beta1(time) + x2*beta2(time)}, where \code{beta0(t) = 0.25 + 0.35*sin(2*pi*t)}, \code{beta1(t) = 0.35*cos(2*pi*t)}, and \code{beta2(t) = 0.25 + 0.20*t}.}
\value{A data frame with \code{subject.ID}, \code{time}, \code{y}, and \code{x1}; the independent-observation design also has \code{x2}.}
\examples{
d <- data.gen.tdmm.pois(n.subject = 5, n.time = 4, seed = 1,
  random_intercept = TRUE)
d.independent <- data.gen.tdmm.pois(n.subject = 10,
  random_intercept = FALSE, seed = 1)
}
