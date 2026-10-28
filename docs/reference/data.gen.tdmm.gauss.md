# Generate a Gaussian TDMM simulation dataset

Generate Gaussian simulation data with or without a subject-specific
random intercept.

## Usage

``` r
data.gen.tdmm.gauss(n.subject = 200, n.time = 20, sigma2.b = 0.5, sigma2.e = 0.1, seed = NULL, random_intercept = TRUE)
```

## Arguments

  - n.subject:

    Number of subjects. If omitted, the default is 200 with a random
    intercept and 300 without one. With `random_intercept = FALSE`, this
    is also the number of independent observations. An explicitly
    supplied value is used in either case.

  - n.time:

    Number of observations per subject when `random_intercept = TRUE`;
    unused when `FALSE`.

  - sigma2.b:

    Random-intercept variance when `random_intercept = TRUE`; unused
    when `FALSE`.

  - sigma2.e:

    Gaussian residual variance.

  - seed:

    Optional random seed.

  - random\_intercept:

    A single logical value. `TRUE` retains the balanced
    repeated-measures simulation. `FALSE` generates one independent
    observation per subject, with no random intercept.

## Value

A data frame with `subject.ID`, `time`, `y`, and `x1`. The
`random_intercept = FALSE` case also has the time-varying covariate
`x2`.

## Details

When `random_intercept = FALSE`, time and an independent variable `u`
are each Uniform(0, 1), `x1` is standard normal, and `x2 = sin(2 * pi *
u) + e` with `e` normal with standard deviation 0.25. The coefficient
functions are `sin(2 * pi * time)`, `cos(2 * pi * time)`, and `1.5 *
(time - 0.5)` for the intercept, `x1`, and `x2`, respectively. Residual
errors are independent normal with variance `sigma2.e`.

## Examples

``` r
set.seed(1)
d <- data.gen.tdmm.gauss(n.subject = 5, n.time = 4,
  random_intercept = TRUE)
d.independent <- data.gen.tdmm.gauss(n.subject = 10,
  random_intercept = FALSE, seed = 1)
```
