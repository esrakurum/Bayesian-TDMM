# Fit a Bayesian time-dynamic regression model

Fit Bayesian time-dynamic regression models for Gaussian, Bernoulli, or
Poisson outcomes. Regression coefficients vary smoothly over time; a
subject-specific random intercept is optional.

## Usage

``` r
tdmm(data, family = c("gaussian", "bernoulli", "poisson"), nknots = NULL, subject.var = "subject.ID",
    time.var = "time", y.var = "y", x.var = NULL, degree = 3, n.chains = 3, n.iter = 10000, n.burn = 3000,
    n.thin = 5, n.adapt = 5000, jags.dir = NULL, quiet = FALSE, n_basis = NULL, control = NULL, priors = NULL,
    random_intercept = TRUE)
```

## Arguments

  - data:

    Data frame with one row per observation and columns for subject ID,
    time, response, and covariates.

  - family:

    One of "gaussian", "bernoulli", or "poisson".

  - nknots:

    Deprecated compatibility argument with its historical interval-count
    interpretation. Do not supply with n\_basis.

  - subject.var:

    Name of the subject ID column.

  - time.var:

    Name of the numeric observation-time column.

  - y.var:

    Name of the response column.

  - x.var:

    Names of numeric covariates, in coefficient order; NULL selects all
    columns other than subject ID, time, and response.

  - degree:

    B-spline polynomial degree; default 3 (cubic).

  - n.chains:

    Number of chains; `control` is recommended.

  - n.iter:

    Total iterations; `control` is recommended.

  - n.burn:

    Burn-in iterations; `control` is recommended.

  - n.thin:

    Thinning interval; `control` is recommended.

  - n.adapt:

    Adaptation iterations; `control` is recommended.

  - jags.dir:

    Optional model directory; ordinarily leave this `NULL`.

  - quiet:

    Suppress JAGS progress output when TRUE.

  - n\_basis:

    Actual number of B-spline basis functions. Omission resolves to 8.

  - control:

    Optional list from tdmm\_control() controlling chains, iterations,
    burn-in, thinning, adaptation, seed, parallel execution, and cores.

  - priors:

    Optional family-specific list, normally obtained from
    tdmm.priors(family) and modified by the user.

  - random\_intercept:

    `TRUE` (the default) includes a subject-specific random intercept
    for repeated observations. `FALSE` fits without one for independent
    observations.

## Details

With repeated observations, subjects may have irregular observation
times and unequal visit counts; numeric covariates may be constant or
change within subject. For independent observations, time may represent
age, time since an event, or time relative to an event. Coefficient
functions use an extended uniform B-spline basis with a second-order
coefficient-difference penalty. The default is cubic with eight basis
functions. Use tdmm\_control(parallel = TRUE, cores = ...) for parallel
chains. The coefficient functions are on the identity, logit, or log
link scale for Gaussian, Bernoulli, or Poisson responses, respectively.

## Value

A fitted object of class "tdmm" containing posterior samples,
reconstructed coefficient functions, input metadata, variance summaries,
and fitting settings.

## See also

`tdmm.control`, `tdmm.priors`, `summary.tdmm`, `plot.tdmm`

## Examples

``` r
if (FALSE) { # \dontrun{
# Requires JAGS and runs MCMC.
set.seed(42)
my_long_data <- do.call(rbind, lapply(seq_len(20), function(id) {
  time <- sort(runif(5))
  baseline <- rnorm(1)
  changing <- rnorm(5)
  data.frame(id = id, time = time, baseline = baseline,
             changing = changing,
             y = 0.5 + baseline * sin(2*pi*time) +
                 changing * (time - 0.5) + rnorm(5, sd = 0.3))
}))
fit <- tdmm(my_long_data, family = "gaussian", subject.var = "id",
            time.var = "time", y.var = "y", x.var = c("baseline", "changing"),
            control = tdmm_control(seed = 42))
summary(fit)
plot(fit)
} # }
```
