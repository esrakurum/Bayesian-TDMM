# Construct a TDMM plotting grid

Create evaluation times and a spline basis consistent with a fitted TDMM
object.

## Usage

``` r
make.tdmm.plot.grid(data, grid = NULL, n.grid = 100, time.var = "time", nknots = NULL, degree = 3, n_basis = NULL, 
    result = NULL)
```

## Arguments

  - data:
    
    Long-format data frame or fitted TDMM object.

  - grid:
    
    Optional numeric evaluation times.

  - n.grid:
    
    Number of points when grid is NULL.

  - time.var:
    
    Observation-time column name.

  - nknots:
    
    Deprecated `nknots` argument.

  - degree:
    
    Spline degree for new grids.

  - n\_basis:
    
    Number of basis functions for new grids.

  - result:
    
    Optional fitted tdmm object whose spline metadata is authoritative.

## Details

When result is supplied, its recorded spline convention, degree, basis
dimension, and time domain are used. This preserves reconstruction of
older fitted objects.

## Value

A list containing the plotting grid and evaluated basis.

## See also

`plot.tdmm`

## Examples

``` r
if (FALSE) { # \dontrun{
grid <- make.tdmm.plot.grid(fit)
} # }
```
