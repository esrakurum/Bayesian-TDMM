# TDMM: Bayesian Time-Dynamic Mixed-Effects Models

This repository contains the `TDMM` R package for fitting Bayesian time-dynamic mixed-effects models for longitudinal data.

**Development snapshot (0.1.0.9000; not a 0.2.0 release).** Gaussian fitting now accepts subject-specific times, unequal visit counts, and observation-level covariates. Bernoulli and Poisson retain their unchanged V1 models for common-grid baseline-covariate data; their V2 fitting paths are blocked pending statistical review and newer source files. See `PHASE2A_COMPATIBILITY.md` and `PHASE2A_CHANGELOG.md`.

The released V1 package provides tools for estimating time-varying coefficient functions while accounting for within-subject dependence through subject-specific random effects. The current implementation focuses on longitudinal data with baseline covariates. It can handle irregularly spaced measurement times when subjects share the same observation grid, but it assumes a balanced repeated-measures structure with the same number of observations per subject.

A full package tutorial is included separately and describes the statistical model, Bayesian estimation framework, data requirements, fitting functions, diagnostics, visualization tools, and implementation examples.

## Package overview

The main model is a Bayesian time-dynamic mixed-effects model of the form

$$
g\{\mu_i(t)\} = x_i^\top \beta(t) + b_i,
$$

where:

- $y_i(t)$ is the observed response for subject $i$ at time $t$
- $\mu_i(t) = E\{y_i(t) \mid x_i, b_i\}$
- $x_i$ is a vector of baseline subject-level covariates
- $\beta(t)$ is a vector of time-varying coefficient functions
- $b_i$ is a subject-specific random intercept
- $g(\cdot)$ is the link function for the outcome family

For the special case with one baseline covariate, the model can be written as

$$
g\{\mu_i(t)\} = \beta_0(t) + \beta_1(t)x_i + b_i.
$$

The package currently supports:

- Gaussian outcomes
- Bernoulli outcomes
- Poisson outcomes

Model fitting is performed using JAGS through R.

## Installation

The package depends on JAGS. Users should install JAGS before fitting models.

In R, install the package from GitHub using:

```r
devtools::install_github("esrakurum/Bayesian-TDMM", ref = "v0.2-development")
library(TDMM)
```
## Repository structure
```text
Bayesian-TDMM/
│
├── README.md
├── DESCRIPTION
├── NAMESPACE
├── .gitignore
├── .Rbuildignore
│
├── R/
│   ├── tdmm.R
│   ├── tdmm.parallel.R
│   ├── simulation.helpers.R
│   ├── data.checks.R
│   ├── tdmm.helpers.R
│   ├── plot.tdmm.R
│   ├── plot.trace.tdmm.R
│   └── summary.tdmm.R
│
├── inst/jags/
│   ├── TDMM_Gaussian_JAGS.txt
│   ├── TDMM_Bernoulli_JAGS.txt
│   └── TDMM_Poisson_JAGS.txt
│
├── examples/
    ├── tdmm()/
    │   ├── gaussian_simulation.R
    │   ├── bernoulli_simulation.R
    │   ├── poisson_simulation.R
    │   └── WageData_TDMM.R
    │
    └── tdmm.parallel()/
        ├── gaussian_parallel.R
        ├── bernoulli_parallel.R
        └── poisson_parallel.R
```
## Citation

If you use this package, please cite the software using the citation information provided in the `CITATION.cff` file and the archived V1 release Zenodo DOI (not an archive of this development snapshot): https://doi.org/10.5281/zenodo.20617705

## License

This package is licensed under the MIT License.

Copyright (c) 2026 Makena Grigsby and Esra Kürüm.

## V2 spline defaults and Gaussian workflow

New fits use cubic B-splines (`degree = 3`, order 4), evaluated with
`splines::splineDesign()`. Supply `n_basis` for the actual number of columns.
The default is **8 basis functions**. Esra selected eight after a matched
10-dataset Gaussian cubic pilot comparing 6, 8 and 10: eight balanced curve
recovery and shape with runtime (77.2 seconds per fit versus 129.8 for ten).
This small pilot informed the default; it is not a formal simulation study.
The formal argument remains `n_basis = NULL` so that omitted values resolve
to eight while deprecated `nknots` calls retain their historical mapping.

For degree `d` and `q = n_basis`, there are `q - d` equally spaced intervals
across the fitted time range. The knot vector extends `d` intervals beyond
both ends. The second-order coefficient-difference penalty and existing
family priors are unchanged. The JAGS dimension is named `n_basis`.

`nknots` remains in its original argument position but is deprecated. Its
historical rule is `intervals = nknots - 2`, so the actual dimension is
`nknots + degree - 2`. For example, `nknots = 6` now gives seven cubic bases;
`n_basis = 6` gives six. Supplying both arguments is an error. The cubic
default is an intentional behavior change; selecting `degree = 2` for a new
fit still uses the conventional positive basis, not the old signed raw-alpha
convention.

New fitted objects retain the exact knots, degree, dimension, and convention
in `inputs$spline`. Plotting uses this fitted specification, not the range
of replacement plotting data. Older objects retain their recorded degree;
for objects without convention metadata, reconstruction checks their saved
basis against the standard and historical signed constructors. Ambiguous or
incomplete objects fail explicitly rather than being reinterpreted as cubic.
The old signed evaluator is used only to reconstruct legacy objects.
There is no separate prediction method; the shared plot-grid/reconstruction
helpers evaluate new times from the same stored specification.

The quadratic Gaussian studies, basis sensitivity, Bernoulli diagnostics,
Poisson study, and PBC2 fits do not validate the new cubic specification.
Their fits/results and all package example outputs require rerunning before
being presented as V2 cubic results. No formal studies were rerun for this
API change.

A long-format Gaussian workflow requires only the installed package:

```r
library(TDMM)
fit <- tdmm(dat, family = "gaussian", subject.var = "id",
            time.var = "time", y.var = "y",
            x.var = c("baseline", "time_varying"))
summary(fit)
plot.tdmm(dat, fit)
plot.trace.tdmm(fit, c("sigma2.b", "sigma2.e", "tau.alpha[1]"))
# On macOS/Linux: same interface, independent chains on two cores.
# fit <- tdmm.parallel(dat, family="gaussian", subject.var="id",
#                     x.var=c("baseline", "time_varying"), n.cores=2, seed=218)
```

Rows may be unsorted, subject IDs need not be consecutive, visit counts may
differ, and covariates may vary within subject. Required columns must be
complete; response, times and covariates must be finite numeric values.
Encode categorical covariates as numeric indicators. Unused subject-factor
levels are ignored. The package locates its own JAGS model, maps subject IDs,
constructs observation-level matrices, and recovers curves on sorted unique
observed times. Plots use the saved spline specification on a regular grid
by default; `grid=fit$time.points` uses the exact recovery grid.

See `simulations/gaussian-v2-validation.md` for a single-dataset validation
using the installed package. Parallel execution currently uses forked chains
on macOS/Linux; multi-core Windows execution is not implemented.
