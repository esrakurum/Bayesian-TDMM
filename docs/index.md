# TDMM

TDMM provides Bayesian time-dynamic regression models for **Gaussian,
Bernoulli, and Poisson** outcomes. Regression coefficients vary smoothly
over time. With `random_intercept = TRUE` (the default), subjects may
have repeated observations, irregular observation times, unequal visit
counts, baseline covariates, and covariates that vary by visit. With
`random_intercept = FALSE`, the model omits the subject-specific random
intercept for independent observations; time may represent age, time
since an event, or time relative to an event.

The default spline uses **eight cubic B-spline basis functions**
(polynomial degree 3, spline order 4) with a second-order
coefficient-difference penalty. JAGS performs posterior sampling.

## Install

Install [JAGS](https://mcmc-jags.sourceforge.io/) first, then install
TDMM in R:

``` r
install.packages("remotes")
remotes::install_github("esrakurum/Bayesian-TDMM")
library(TDMM)
```

## Fit a model

Supply one row per observed visit. Here `baseline` is constant within
subject and `changing` varies by visit:

``` r
fit <- tdmm(long_data, family = "gaussian",
            subject.var = "id", time.var = "time", y.var = "y",
            x.var = c("baseline", "changing"), n_basis = 8,
            control = tdmm_control(chains = 3, seed = 123))
summary(fit)
plot(fit)
plot.trace.tdmm(fit, c("sigma.b", "sigma2.e", "tau.alpha[1]"))
```

Use `family = "bernoulli"` for binary outcomes or `family = "poisson"`
for counts. See [Getting
Started](https://esrakurum.github.io/Bayesian-TDMM/articles/getting-started.html)
for data layout, interpretation, and diagnostics. The
[Gaussian](https://esrakurum.github.io/Bayesian-TDMM/articles/gaussian.html),
[Bernoulli](https://esrakurum.github.io/Bayesian-TDMM/articles/bernoulli.html),
[Poisson](https://esrakurum.github.io/Bayesian-TDMM/articles/poisson.html),
and [PBC2](https://esrakurum.github.io/Bayesian-TDMM/articles/pbc2.html)
examples give fuller workflows. The [vignette
source](https://github.com/esrakurum/Bayesian-TDMM/blob/main/vignettes/getting-started.Rnw)
and [example
scripts](https://github.com/esrakurum/Bayesian-TDMM/tree/main/examples)
are also available in the repository.

## Citation

Use `citation("TDMM")` or the repository’s [citation
metadata](https://github.com/esrakurum/Bayesian-TDMM/blob/main/CITATION.cff).

The v0.2.0 release is archived at [Zenodo
DOI 10.5281/zenodo.23608508](https://doi.org/10.5281/zenodo.23608508);
the v0.1.0 release has [Zenodo
DOI 10.5281/zenodo.20617705](https://doi.org/10.5281/zenodo.20617705).

TDMM is released under the [MIT
license](https://esrakurum.github.io/Bayesian-TDMM/LICENSE.md).
