# Plot TDMM coefficient functions

Plot posterior mean coefficient functions and pointwise credible or
standard-deviation bands.

## Usage

``` r
# S3 method for class 'tdmm'
plot(x = NULL, result = NULL, sd = FALSE, level = 0.95, grid = NULL, n.grid = 100, time.var = "time", 
    nknots = NULL, degree = NULL, file = NULL, lwd.mean = 2, lty.band = 3, show.band = TRUE, x.axis.values = NULL, 
    x.axis.labels = NULL, xlab = "time", coef.labels = NULL, panel.labels = NULL, show.panel.labels = TRUE, 
    ylim = NULL, cex.axis = 1, cex.lab = 1, cex.main = 0.95, cex.panel = 1.05, font.lab = 1, las = 1, 
    width = 2200, height = 700, res = 150, n_basis = NULL, data = NULL, ...)
```

## Arguments

  - x:
    
    A fitted tdmm object for plot(fit), or legacy data argument.

  - result:
    
    A fitted tdmm object for the legacy plot.tdmm(data, result) call.

  - sd:
    
    If TRUE, show posterior standard-deviation bands rather than
    credible intervals.

  - level:
    
    Pointwise credible level.

  - grid:
    
    Optional numeric evaluation times within the fitted time domain.

  - n.grid:
    
    Number of plotting-grid points when grid is NULL.

  - time.var:
    
    Observation-time column name for legacy calls.

  - nknots:
    
    Deprecated legacy basis argument; fitted metadata takes precedence.

  - degree:
    
    Optional degree check; cannot differ from fitted degree.

  - file:
    
    Optional PNG output path.

  - lwd.mean:
    
    Line width of the posterior mean curves.

  - lty.band:
    
    Line type for uncertainty-band boundaries.

  - show.band:
    
    Whether to show uncertainty bands.

  - x.axis.values:
    
    Numeric x-axis tick positions; supply with x.axis.labels.

  - x.axis.labels:
    
    Labels corresponding to x.axis.values.

  - xlab:
    
    Horizontal-axis label.

  - coef.labels:
    
    Optional coefficient labels.

  - panel.labels:
    
    Optional panel labels.

  - show.panel.labels:
    
    Whether panel labels are drawn.

  - ylim:
    
    Optional vertical limits, shared across panels or supplied per
    panel.

  - cex.axis:
    
    Axis text size multiplier.

  - cex.lab:
    
    Axis label size multiplier.

  - cex.main:
    
    Main title size multiplier.

  - cex.panel:
    
    Panel label size multiplier.

  - font.lab:
    
    Axis label font.

  - las:
    
    Axis label orientation.

  - width:
    
    PNG width in pixels when file is supplied.

  - height:
    
    PNG height in pixels when file is supplied.

  - res:
    
    PNG resolution when file is supplied.

  - n\_basis:
    
    Optional basis-dimension check; cannot differ from fitted dimension.

  - data:
    
    Optional original data; usually taken from the fitted object.

  - ...:
    
    Additional graphical arguments.

## Details

Calling plot(fit) uses the data and spline metadata stored in the fitted
object. A fitted degree or basis dimension cannot be changed at plotting
time. The curves are on the model linear-predictor scale.

## Value

Creates a plot; returns invisibly.

## See also

`tdmm`, `plot.trace.tdmm`

## Examples

``` r
if (FALSE) { # \dontrun{
plot(fit)
plot(fit, file = "tdmm-coefficients.png")
} # }
```
