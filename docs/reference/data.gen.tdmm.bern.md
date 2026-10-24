# Generate legacy Bernoulli TDMM simulation data

Generate a balanced-grid Bernoulli simulation dataset for compatibility
examples. This legacy helper is separate from the V2 irregular-time
validation generators.

## Usage

``` r
data.gen.tdmm.bern(n.subject = 200, n.time = 20, sigma2.b = 0.5, seed = NULL)
```

## Arguments

  - n.subject:
    
    Number of subjects.

  - n.time:
    
    Number of observations per subject.

  - sigma2.b:
    
    Random-intercept variance.

  - seed:
    
    Optional random seed.

## Value

A simulated long-format data frame or list as returned by the legacy
generator.

## Examples

``` r
set.seed(1)
d <- data.gen.tdmm.bern(n.subject = 5, n.time = 4)
```
