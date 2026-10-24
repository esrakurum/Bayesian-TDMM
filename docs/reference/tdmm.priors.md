# Family-specific default TDMM priors

Return the family-specific structured prior defaults used by `tdmm()`. A
partial nested list can be passed as `priors=` to change supported prior
parameters.

## Usage

``` r
tdmm.priors(family = c("gaussian", "bernoulli", "poisson"))
```

## Arguments

  - family:
    
    Response family.

## Details

All Gamma distributions use shape and rate. The smoothing prior is
`smoothing = list(shape = 1, rate = 0.001)` for every family. Gaussian
uses Gamma(1, 0.005) priors on random-intercept and residual precisions.
Bernoulli and Poisson use a Uniform(0, 5) prior on the random-intercept
standard deviation. Bernoulli uses a Normal(0, 100) prior for each of
its two null-space coordinates, corresponding to `null_space = list(sd
= 10)`. The approved distribution family is fixed for each response
family; users may change positive shape, rate, maximum standard
deviation, or null-space standard deviation parameters. Basis
eigenvectors and numerical ridge constants are not prior controls.

## Value

A named list with `smoothing`, `random_intercept`, and family-specific
`residual` or `null_space` groups.

## Examples

``` r
 tdmm.priors("bernoulli")
#> $smoothing
#> $smoothing$shape
#> [1] 1
#> 
#> $smoothing$rate
#> [1] 0.001
#> 
#> 
#> $random_intercept
#> $random_intercept$distribution
#> [1] "uniform_sd"
#> 
#> $random_intercept$max_sd
#> [1] 5
#> 
#> 
#> $null_space
#> $null_space$sd
#> [1] 10
#> 
#> 
 # Example partial override: priors = list(smoothing = list(rate = 0.002))
```
