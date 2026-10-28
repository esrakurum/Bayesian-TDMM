# Poisson examples

Use `family = "poisson"` for counts. This page shows TDMM workflows for
both repeated observations (`random_intercept = TRUE`) and independent
observations (`random_intercept = FALSE`). Coefficient functions are on
the log-mean scale.

## Repeated observations

The [standalone runnable
example](https://github.com/esrakurum/Bayesian-TDMM/blob/main/examples/poisson-getting-started.R)
generates subject-specific irregular visits, a baseline covariate, and a
genuinely time-varying covariate with within-time variation; it fits
with `random_intercept = TRUE`.

From the repository root:

``` r
library(TDMM)
source("examples/poisson-getting-started.R")
fit <- run_small_poisson()
summary(fit)
plot(fit)
plot.trace.tdmm(fit, c("sigma.b", "tau.alpha[1]"))
```

Check reconstructed coefficient curves and chain diagnostics, and
compare posterior count behavior with the observed counts. [Getting
Started](https://esrakurum.github.io/Bayesian-TDMM/articles/getting-started.md)
covers the common data format and fit controls.

## Independent observations

The Poisson simulation helper generates one count per subject when
`random_intercept = FALSE`. For independent observations, time may
represent age, time since an event, or time relative to an event. The
helper defaults to 2,200 subjects in this setting.

``` r
independent_data <- data.gen.tdmm.pois(random_intercept = FALSE, seed = 27181)
fit_independent <- tdmm(independent_data, family = "poisson",
                        x.var = c("x1", "x2"),
                        random_intercept = FALSE,
                        control = tdmm_control(seed = 77181))
summary(fit_independent)
plot(fit_independent)
```
