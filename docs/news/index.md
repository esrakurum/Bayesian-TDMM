# Changelog

## TDMM 0.3.0

  - `tdmm()` and `tdmm.parallel()` support models with or without a
    subject-specific random intercept through `random_intercept`; `TRUE`
    remains the default.
  - Gaussian, Bernoulli, and Poisson simulation helpers generate
    independent-observation data directly when `random_intercept =
    FALSE`.
  - Repeated-observation models with a subject-specific random intercept
    remain supported.

## TDMM 0.2.0

  - Fit Gaussian, Bernoulli, and Poisson longitudinal outcomes with
    subject-specific irregular observation times, unequal visit counts,
    baseline covariates, and time-varying covariates.
  - Use cubic B-splines (degree 3, order 4) with a second-order
    coefficient-difference penalty and eight basis functions by default.
    `n_basis` specifies the basis dimension directly; the older `nknots`
    argument remains supported with a deprecation warning.
  - Fit serial or parallel chains through `tdmm()` and structured
    `tdmm_control()` and `tdmm.priors()` settings. `tdmm.parallel()`
    remains a compatibility wrapper.
  - Existing Gaussian and Poisson model specifications are retained.

## TDMM 0.1.0

  - Initial archived release. See the [v0.1.0
    release](https://github.com/esrakurum/Bayesian-TDMM/releases/tag/v0.1.0)
    for its source and documentation.
