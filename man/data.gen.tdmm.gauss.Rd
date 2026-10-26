\name{data.gen.tdmm.gauss}
\alias{data.gen.tdmm.gauss}
\title{Generate a Gaussian TDMM simulation dataset}
\description{Generate Gaussian simulation data with or without a subject-specific random intercept.}
\usage{
data.gen.tdmm.gauss(n.subject = 200, n.time = 20, sigma2.b = 0.5, sigma2.e = 0.1, seed = NULL, random_intercept = TRUE)
}
\arguments{
\item{n.subject}{Number of subjects. If omitted, the default is 200 with a random intercept and 300 without one. With \code{random_intercept = FALSE}, this is also the number of independent observations. An explicitly supplied value is used in either case.}
\item{n.time}{Number of observations per subject when \code{random_intercept = TRUE}; unused when \code{FALSE}.}
\item{sigma2.b}{Random-intercept variance when \code{random_intercept = TRUE}; unused when \code{FALSE}.}
\item{sigma2.e}{Gaussian residual variance.}
\item{seed}{Optional random seed.}
\item{random_intercept}{A single logical value. \code{TRUE} retains the balanced repeated-measures simulation. \code{FALSE} generates one independent observation per subject, with no random intercept.}
}
\value{A data frame with \code{subject.ID}, \code{time}, \code{y}, and \code{x1}. The \code{random_intercept = FALSE} case also has the time-varying covariate \code{x2}.}
\details{When \code{random_intercept = FALSE}, time and an independent variable \code{u} are each Uniform(0, 1), \code{x1} is standard normal, and \code{x2 = sin(2 * pi * u) + e} with \code{e} normal with standard deviation 0.25. The coefficient functions are \code{sin(2 * pi * time)}, \code{cos(2 * pi * time)}, and \code{1.5 * (time - 0.5)} for the intercept, \code{x1}, and \code{x2}, respectively. Residual errors are independent normal with variance \code{sigma2.e}.}
\examples{
set.seed(1)
d <- data.gen.tdmm.gauss(n.subject = 5, n.time = 4)
d.independent <- data.gen.tdmm.gauss(n.subject = 10,
  random_intercept = FALSE, seed = 1)
}
