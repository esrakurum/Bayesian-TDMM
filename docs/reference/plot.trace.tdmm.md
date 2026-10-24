# Plot TDMM posterior traces

Display chain-specific traces for monitored posterior parameter names.

## Usage

``` r
# S3 method for class 'tdmm'
plot.trace(result, params, file = NULL, ncol = 2, width = 1800, height = NULL, res = 150, lwd = 0.4, col = NULL, 
    show.legend = FALSE, cex.axis = 0.85, cex.lab = 0.9, cex.main = 1)
```

## Arguments

  - result:
    
    A fitted tdmm object.

  - params:
    
    Character vector of monitored parameter names.

  - file:
    
    Optional PNG output path.

  - ncol:
    
    Number of plot columns.

  - width:
    
    PNG width in pixels.

  - height:
    
    PNG height in pixels; computed automatically if NULL.

  - res:
    
    PNG resolution.

  - lwd:
    
    Trace line width.

  - col:
    
    Optional chain colors.

  - show.legend:
    
    Whether to show chain legend.

  - cex.axis:
    
    Axis text scaling.

  - cex.lab:
    
    Axis-label scaling.

  - cex.main:
    
    Title scaling.

## Details

Parameter names must match the fitted posterior matrix exactly. For
example, "sigma.b" is random-effect standard deviation and "sigma2.b" is
variance. Spline smoothing parameters have names such as
"tau.alpha\[1\]".

## Value

Creates trace plots; returns invisibly.

## See also

`tdmm`, `plot.tdmm`

## Examples

``` r
if (FALSE) { # \dontrun{
plot.trace.tdmm(fit, c("sigma.b", "tau.alpha[1]"))
} # }
```
