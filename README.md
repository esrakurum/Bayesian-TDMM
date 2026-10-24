# TDMM

TDMM fits Bayesian time-dynamic mixed-effects models for longitudinal **Gaussian, Bernoulli, and Poisson** outcomes. It estimates time-varying coefficient functions with subject-specific random intercepts. Data may have irregular subject-specific observation times, unequal visit counts, baseline covariates, and covariates that vary by visit.

The default spline uses **eight cubic B-spline basis functions** (polynomial degree 3, spline order 4) with a second-order coefficient-difference penalty. JAGS performs posterior sampling.

## Install

Install [JAGS](https://mcmc-jags.sourceforge.io/) first, then install TDMM in R:

```r
install.packages("remotes")
remotes::install_github("esrakurum/Bayesian-TDMM")
library(TDMM)
```

## Fit a model

Supply one row per observed visit. Here `baseline` is constant within subject and `changing` varies by visit:

```r
fit <- tdmm(long_data, family = "gaussian",
            subject.var = "id", time.var = "time", y.var = "y",
            x.var = c("baseline", "changing"), n_basis = 8,
            control = tdmm_control(chains = 3, seed = 123))
summary(fit)
plot(fit)
plot.trace.tdmm(fit, c("sigma.b", "sigma2.e", "tau.alpha[1]"))
```

Use `family = "bernoulli"` for binary outcomes or `family = "poisson"` for counts. See [Getting Started](https://esrakurum.github.io/Bayesian-TDMM/articles/getting-started.html) for data layout, interpretation, and diagnostics. The [Gaussian](https://esrakurum.github.io/Bayesian-TDMM/articles/gaussian.html), [Bernoulli](https://esrakurum.github.io/Bayesian-TDMM/articles/bernoulli.html), [Poisson](https://esrakurum.github.io/Bayesian-TDMM/articles/poisson.html), and [PBC2](https://esrakurum.github.io/Bayesian-TDMM/articles/pbc2.html) examples give fuller workflows. The [vignette source](https://github.com/esrakurum/Bayesian-TDMM/blob/main/vignettes/getting-started.Rnw) and [example scripts](https://github.com/esrakurum/Bayesian-TDMM/tree/main/examples) are also available in the repository.

## Citation

For v0.2.0, use `citation("TDMM")` or the repository's [citation metadata](https://github.com/esrakurum/Bayesian-TDMM/blob/main/CITATION.cff). The [Zenodo DOI 10.5281/zenodo.20617705](https://doi.org/10.5281/zenodo.20617705) identifies the historical **v0.1.0** release; it is not a DOI for v0.2.0.

TDMM is released under the [MIT license](LICENSE.md).
