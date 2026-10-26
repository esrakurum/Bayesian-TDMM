# Generate Bernoulli TDMM simulation data

Generate Bernoulli outcomes with time-varying sine and cosine
coefficients. The default uses repeated measurements and a
subject-specific random intercept; `random_intercept = FALSE` generates
independent observations.

## Usage

``` r
data.gen.tdmm.bern(n.subject = 200, n.time = 20, sigma2.b = 0.5,
  seed = NULL, random_intercept = TRUE)
```

## Arguments

  - n.subject:

    Number of subjects. If omitted, the default is 200 with a random
    intercept and 2500 without one. An explicitly supplied value is used
    in either case.

  - n.time:

    Number of observations per subject when `random_intercept = TRUE`;
    unused otherwise.

  - sigma2.b:

    Random-intercept variance when `random_intercept = TRUE`; unused
    otherwise.

  - seed:

    Optional random seed.

  - random\_intercept:

    A single logical value. `TRUE` generates repeated observations on a
    common time grid with a subject-specific random intercept. `FALSE`
    generates one independent observation per subject with time drawn
    uniformly from 0 to 1.

## Details

Both settings use `beta0(t) = sin(2*pi*t)` and `beta1(t) = cos(2*pi*t)`.
With `random_intercept = FALSE`, `x1` is drawn independently from a
standard Normal distribution for each subject, and the logit probability
is `beta0(time) + x1*beta1(time)`. With `random_intercept = TRUE`, a
subject-specific random intercept is added to that expression.

## Value

A data frame with `subject.ID`, `time`, `y`, and `x1`.

## Examples

``` r
d <- data.gen.tdmm.bern(n.subject = 5, n.time = 4, seed = 1)
d.independent <- data.gen.tdmm.bern(n.subject = 10,
  random_intercept = FALSE, seed = 1)
```
