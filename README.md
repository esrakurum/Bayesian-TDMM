# Bayesian Varying-Coefficient Models

This repository contains code for fitting Bayesian time-dynamic mixed-effects models for longitudinal data. The goal of this project is to provide a clear and reproducible workflow for estimating time-varying coefficient functions using Bayesian mixed-effects models.

The current implementation focuses on models where the regression coefficients vary smoothly over time and subject-level random effects account for repeated measurements within individuals.

## Project overview

The main model is a time-dynamic mixed-effects model of the form

$$
g(\mu_{ij}) = \beta_0(t_{ij}) + \beta_1(t_{ij})x_i + b_i,
$$

where:

- $y_{ij}$ is the observed response for subject $i$ at time point $j$
- $t_{ij}$ is the observed time point
- $x_i$ is a subject-level covariate
- $\beta_0(t)$ is the time-varying intercept function
- $\beta_1(t)$ is the time-varying covariate effect
- $b_i$ is a subject-level random intercept
- $g(\cdot)$ is the link function for the outcome family

The package currently supports:

- Gaussian outcomes
- Bernoulli outcomes
- Poisson outcomes

Model fitting is done using JAGS through R.

## Main functions

- `tdmm()` fits a TDMM using the standard serial JAGS workflow.
- `tdmm.parallel()` fits the same model using chain-level parallelization.
- `check.tdmm.family.data()` checks the data structure and family-specific response behavior.
- `summary.tdmm()` summarizes a fitted TDMM object.
- `plot.tdmm()` plots estimated time-varying coefficient functions.
- `plot.trace.tdmm()` produces traceplots for selected posterior parameters.

## Repository structure

```text
Bayesian-Varying-Coefficient-Models/
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
│   ├── find.jags.file.R
│   ├── spline.basis.R
│   ├── prepare.tdmm.data.R
│   ├── plot.tdmm.R
│   ├── summary.tdmm.R
│   └── diagnostics.R
│
├── jags/
│   ├── TDMM_Gaussian_JAGS.txt
│   ├── TDMM_Bernoulli_JAGS.txt
│   └── TDMM_Poisson_JAGS.txt
│
├── examples/
│   ├── gaussian_simulation_example.R
│   ├── bernoulli_simulation_example.R
|   ├── poisson_simulation_example.R 
│   └── wage_data_example.R
│
└── figures/
    └── README.md
