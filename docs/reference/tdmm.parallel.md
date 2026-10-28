# Parallel TDMM fitting wrapper

Fit TDMM with parallel chains through `tdmm()`.

## Usage

``` r
tdmm.parallel(data, family = c("gaussian", "bernoulli", "poisson"), nknots = NULL, subject.var = "subject.ID",
    time.var = "time", y.var = "y", x.var = NULL, degree = 3, n.chains = 3, n.iter = 10000, n.burn = 3000,
    n.thin = 5, n.adapt = 10000, n.cores = min(n.chains, parallel::detectCores()), jags.dir = NULL, quiet = FALSE,
    seed = NULL, n_basis = NULL, control = NULL, priors = NULL, random_intercept = TRUE)
```

## Arguments

  - data:

    Data frame with one row per observation and columns for subject ID,
    time, response, and covariates.

  - family:

    One of "gaussian", "bernoulli", or "poisson".

  - nknots:

    Deprecated `nknots` argument using the interval-count convention. Do
    not supply with `n_basis`.

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

  - n.cores:

    Number of parallel cores; `control` is recommended.

  - jags.dir:

    Optional model directory; ordinarily leave this `NULL`.

  - quiet:

    Suppress JAGS progress output when TRUE.

  - seed:

    Random seed; `control` is recommended.

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

For parallel fitting, `tdmm(control = tdmm_control(parallel = TRUE,
cores = ...))` is recommended. This wrapper retains the existing
`tdmm.parallel()` arguments and delegates fitting to `tdmm()`.

## Value

A fitted object of class "tdmm".

## See also

`tdmm`

## Examples

``` r
if (FALSE) { # \dontrun{
## my_long_data is a long-format data frame; see the tdmm() example.
fit <- tdmm.parallel(my_long_data, family = "gaussian",
                     subject.var = "id", time.var = "time", y.var = "y",
                     x.var = "baseline", random_intercept = TRUE,
                     n.cores = 2)
} # }
```
