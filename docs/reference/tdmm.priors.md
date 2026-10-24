# Family-specific default TDMM priors

Return the family-specific prior defaults used by `tdmm()`. A partial
named list can be supplied through `priors=` to modify supported prior
parameters.

## Usage

``` r
tdmm.priors(family = c("gaussian", "bernoulli", "poisson"))
```

## Arguments

  - family:
    
    Response family.

## Details

All Gamma distributions use shape and rate parameterization.

For all response families, the smoothing precision has a Gamma(1, 0.001)
prior.

For Gaussian outcomes, the random-intercept precision and residual
precision each have Gamma(1, 0.005) priors.

For Bernoulli and Poisson outcomes, the random-intercept standard
deviation has a Uniform(0, 5) prior.

For Bernoulli outcomes, `null_space = list(sd = 10)` specifies the
standard deviation used for the two unpenalized spline components.

Users may modify the numerical parameters of these priors, but the prior
distribution associated with each response family is fixed.

## Value

A named list containing the prior settings for the selected response
family. The list includes `smoothing` and `random_intercept`, with
additional family-specific components where applicable.

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

# Example partial override:
priors <- list(smoothing = list(rate = 0.002))
```
