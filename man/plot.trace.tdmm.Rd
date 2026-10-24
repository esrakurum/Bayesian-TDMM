\name{plot.trace.tdmm}
\alias{plot.trace.tdmm}
\title{Plot TDMM posterior traces}
\description{Display chain-specific traces for monitored posterior parameter names.}
\usage{
\method{plot.trace}{tdmm}(result, params, file = NULL, ncol = 2, width = 1800, height = NULL, res = 150, lwd = 0.4, col = NULL, 
    show.legend = FALSE, cex.axis = 0.85, cex.lab = 0.9, cex.main = 1) 
}
\arguments{
\item{result}{A fitted tdmm object.}
\item{params}{Character vector of monitored parameter names.}
\item{file}{Optional PNG output path.}
\item{ncol}{Number of plot columns.}
\item{width}{PNG width in pixels.}
\item{height}{PNG height in pixels; computed automatically if NULL.}
\item{res}{PNG resolution.}
\item{lwd}{Trace line width.}
\item{col}{Optional chain colors.}
\item{show.legend}{Whether to show chain legend.}
\item{cex.axis}{Axis text scaling.}
\item{cex.lab}{Axis-label scaling.}
\item{cex.main}{Title scaling.}
}
\details{Parameter names must match the fitted posterior matrix exactly. For example, "sigma.b" is random-effect standard deviation and "sigma2.b" is variance. Spline smoothing parameters have names such as "tau.alpha[1]".}
\value{Creates trace plots; returns invisibly.}
\seealso{\code{\link{tdmm}}, \code{\link{plot.tdmm}}}
\examples{
\dontrun{
plot.trace.tdmm(fit, c("sigma.b", "tau.alpha[1]"))
}
}
