# Reconstruct TDMM coefficient-function intervals

Reconstruct posterior coefficient functions from spline-coefficient
draws and an evaluation basis.

## Usage

``` r
recover.tdmm.betas.ci(post.mat, bases.grid, nX, coef.names = NULL, level = 0.95)
```

## Arguments

  - post.mat:
    
    Posterior draw matrix with alpha coefficient columns.

  - bases.grid:
    
    Spline basis matrix on the desired evaluation grid.

  - nX:
    
    Number of coefficient functions including intercept.

  - coef.names:
    
    Optional coefficient-function names.

  - level:
    
    Pointwise credible level.

## Value

Posterior coefficient-function means and pointwise intervals.

## Examples

``` r
if (FALSE) { # \dontrun{
# Normally called by plot(fit); users rarely need direct reconstruction.
} # }
```
