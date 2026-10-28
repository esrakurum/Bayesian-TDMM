\name{plot.tdmm}
\alias{plot.tdmm}
\title{Plot TDMM coefficient functions}
\description{Plot posterior mean coefficient functions and pointwise credible or standard-deviation bands.}
\usage{
\method{plot}{tdmm}(x = NULL, result = NULL, sd = FALSE, level = 0.95, grid = NULL, n.grid = 100, time.var = "time", 
    nknots = NULL, degree = NULL, file = NULL, lwd.mean = 2, lty.band = 3, show.band = TRUE, x.axis.values = NULL, 
    x.axis.labels = NULL, xlab = "time", coef.labels = NULL, panel.labels = NULL, show.panel.labels = TRUE, 
    ylim = NULL, cex.axis = 1, cex.lab = 1, cex.main = 0.95, cex.panel = 1.05, font.lab = 1, las = 1, 
    width = 2200, height = 700, res = 150, n_basis = NULL, data = NULL, ...) 
}
\arguments{
\item{x}{A fitted tdmm object for plot(fit), or the data argument in the two-argument calling form.}
\item{result}{A fitted tdmm object when data and result are supplied separately.}
\item{sd}{If TRUE, show posterior standard-deviation bands rather than credible intervals.}
\item{level}{Pointwise credible level.}
\item{grid}{Optional numeric evaluation times within the fitted time domain.}
\item{n.grid}{Number of plotting-grid points when grid is NULL.}
\item{time.var}{Observation-time column name when data and result are supplied separately.}
\item{nknots}{Deprecated basis argument; fitted metadata takes precedence.}
\item{degree}{Optional degree check; cannot differ from fitted degree.}
\item{file}{Optional PNG output path.}
\item{lwd.mean}{Line width of the posterior mean curves.}
\item{lty.band}{Line type for uncertainty-band boundaries.}
\item{show.band}{Whether to show uncertainty bands.}
\item{x.axis.values}{Numeric x-axis tick positions; supply with x.axis.labels.}
\item{x.axis.labels}{Labels corresponding to x.axis.values.}
\item{xlab}{Horizontal-axis label.}
\item{coef.labels}{Optional coefficient labels.}
\item{panel.labels}{Optional panel labels.}
\item{show.panel.labels}{Whether panel labels are drawn.}
\item{ylim}{Optional vertical limits, shared across panels or supplied per panel.}
\item{cex.axis}{Axis text size multiplier.}
\item{cex.lab}{Axis label size multiplier.}
\item{cex.main}{Main title size multiplier.}
\item{cex.panel}{Panel label size multiplier.}
\item{font.lab}{Axis label font.}
\item{las}{Axis label orientation.}
\item{width}{PNG width in pixels when file is supplied.}
\item{height}{PNG height in pixels when file is supplied.}
\item{res}{PNG resolution when file is supplied.}
\item{n_basis}{Optional basis-dimension check; cannot differ from fitted dimension.}
\item{data}{Optional original data; usually taken from the fitted object.}
\item{...}{Additional graphical arguments.}
}
\details{Calling plot(fit) uses the data and spline metadata stored in the fitted object. A fitted degree or basis dimension cannot be changed at plotting time. The curves are on the model linear-predictor scale.}
\value{Creates a plot; returns invisibly.}
\seealso{\code{\link{tdmm}}, \code{\link{plot.trace.tdmm}}}
\examples{
\dontrun{
plot(fit)
plot(fit, file = "tdmm-coefficients.png")
}
}
