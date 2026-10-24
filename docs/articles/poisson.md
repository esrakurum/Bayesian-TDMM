# Poisson example

Use `family = "poisson"` for counts. Coefficient functions are on the
log-mean scale. The [standalone runnable
example](https://github.com/esrakurum/Bayesian-TDMM/blob/main/examples/poisson-v2-getting-started.R)
generates subject-specific irregular visits, a baseline covariate, and a
genuinely time-varying covariate with within-time variation.

From the repository root:

``` r
library(TDMM)
source("examples/poisson-v2-getting-started.R")
fit <- run_small_poisson_v2()
summary(fit)
plot(fit)
plot.trace.tdmm(fit, c("sigma.b", "tau.alpha[1]"))
```

Check reconstructed coefficient curves and chain diagnostics, and
compare posterior count behavior with the observed counts. [Getting
Started](https://esrakurum.github.io/Bayesian-TDMM/articles/getting-started.md)
covers the common data format and fit controls.
