# TDMM: Bayesian Time-Dynamic Mixed-Effects Models

This repository contains the `TDMM` R package for fitting Bayesian time-dynamic mixed-effects models for longitudinal data.

The package provides tools for estimating time-varying coefficient functions while accounting for within-subject dependence through subject-specific random effects. The current implementation focuses on longitudinal data with baseline covariates. It can handle irregularly spaced measurement times when subjects share the same observation grid, but it assumes a balanced repeated-measures structure with the same number of observations per subject.

A full package handbook/tutorial is included separately and describes the statistical model, Bayesian estimation framework, data requirements, fitting functions, diagnostics, visualization tools, and implementation examples.

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
devtools::install_github("esrakurum/Bayesian-TDMM")
library(TDMM)
```
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
│   ├── tdmm.data.generation.R
│   ├── tdmm.data.checks.R
│   ├── tdmm.helpers.R
│   ├── plot.tdmm.R
│   ├── plot.trace.tdmm.R
│   └── summary.tdmm.R
│
├── jags/
│   ├── TDMM_Gaussian_JAGS.txt
│   ├── TDMM_Bernoulli_JAGS.txt
│   └── TDMM_Poisson_JAGS.txt
│
├── examples/
│   ├── tdmm/
│   │   ├── gaussian_simulation.R
│   │   ├── bernoulli_simulation.R
│   │   ├── poisson_simulation.R
│   │   └── WageData_TDMM.R
│   │
│   └── tdmm.parallel/
│       ├── gaussian_parallel.R
│       ├── bernoulli_parallel.R
│       └── poisson_parallel.R
│
└── figures/
    ├── tdmm/
    │   ├── gaussian/
    │   ├── bernoulli/
    │   ├── poisson/
    │   └── wagedata/
    │
    └── tdmm.parallel/
        ├── gaussian/
        ├── bernoulli/
        └── poisson/
