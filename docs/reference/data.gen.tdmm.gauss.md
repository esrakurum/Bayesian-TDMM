# Generate a balanced-grid Gaussian simulation dataset

Generate a balanced-grid Gaussian simulation dataset for TDMM examples.

## Usage

``` r
data.gen.tdmm.gauss(n.subject = 200, n.time = 20, sigma2.b = 0.5, sigma2.e = 0.1, seed = NULL)
```

## Arguments

  - n.subject:
    
    Number of subjects.

  - n.time:
    
    Number of observations per subject.

  - sigma2.b:
    
    Random-intercept variance.

  - sigma2.e:
    
    Gaussian residual variance.

  - seed:
    
    Optional random seed.

## Value

A simulated long-format data frame or list as returned by the generator.

## Examples

``` r
set.seed(1)
d <- data.gen.tdmm.gauss(n.subject = 5, n.time = 4)
```
