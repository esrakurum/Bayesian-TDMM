# Summarize a fitted TDMM model

Print model dimensions, MCMC settings, prior settings, and variance
estimates, then return a summary list invisibly.

## Usage

``` r
# S3 method for class 'tdmm'
summary(object, ...)
```

## Arguments

  - object:
    
    A fitted tdmm object.

  - ...:
    
    Reserved for compatibility with the summary generic.

## Value

An invisible list with family, dimensions, coefficient estimates,
variance summaries, and model settings.

## See also

`tdmm`

## Examples

``` r
if (FALSE) { # \dontrun{
summary(fit)
} # }
```
