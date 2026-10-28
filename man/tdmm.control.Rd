\name{tdmm.control}
\alias{tdmm.control}
\alias{tdmm_control}
\title{Computational controls for TDMM fits}
\usage{tdmm.control(chains = 3L, iterations = 10000L, burn_in = 3000L,
  thin = 5L, adapt = 5000L, seed = NULL, cores = NULL,
  parallel = FALSE)
tdmm_control(chains = 3L, iterations = 10000L, burn_in = 3000L,
  thin = 5L, adapt = 5000L, seed = NULL, cores = NULL,
  parallel = FALSE)}
\arguments{
\item{chains}{Number of independent MCMC chains.}
\item{iterations}{Total iterations per chain, including burn-in.}
\item{burn_in}{Burn-in iterations per chain. Must be less than iterations.}
\item{thin}{Posterior thinning interval.}
\item{adapt}{JAGS adaptation iterations.}
\item{seed}{Optional nonnegative integer seed for the fitter.}
\item{cores}{Optional positive integer core count when parallel execution is enabled.}
\item{parallel}{Use separate chains on forked workers when \code{TRUE}.}
}
\description{Construct a named computational control list for \code{tdmm()}.
\code{tdmm.control()} is retained as an alias of \code{tdmm_control()}.
A partial named list can also be passed directly.}
\details{Individual MCMC arguments remain available. Supplying the same setting in
both places is an error. An omitted control list retains the serial defaults;
the \code{tdmm.parallel()} compatibility wrapper retains its existing adaptation default.
Parallel execution uses macOS/Linux forked workers. Evaluation
and plotting grids are selected by \code{plot()} or \code{plot.tdmm()}, rather
than by fitting control. Setting a seed affects the R random-number generator.}
\value{A named list of computational settings.}
\examples{tdmm.control(chains = 3, iterations = 10000, burn_in = 3000,
  seed = 218)}
