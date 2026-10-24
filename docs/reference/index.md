# Package index

## Fit and control

<!-- end list -->

  - `tdmm()` : Fit a time-dynamic mixed-effects model
  - `tdmm.control()` `tdmm_control()` : Computational controls for TDMM
    fits
  - `tdmm.priors()` : Family-specific default TDMM priors
  - `tdmm.parallel()` : Legacy parallel TDMM fitting wrapper

## Summaries, plots, and diagnostics

<!-- end list -->

  - `summary(<tdmm>)` : Summarize a fitted TDMM model
  - `plot(<tdmm>)` : Plot TDMM coefficient functions
  - `plot.trace(<tdmm>)` : Plot TDMM posterior traces
  - `recover.tdmm.betas.ci()` : Reconstruct TDMM coefficient-function
    intervals
  - `make.tdmm.plot.grid()` : Construct a TDMM plotting grid

## Data checks

<!-- end list -->

  - `check.bernoulli.balance()` : Check a binary Bernoulli response.
  - `check.gaussian.response()` : Check a numeric Gaussian response.
  - `check.poisson.counts()` : Check a nonnegative integer Poisson
    response.
  - `check.tdmm.data.structure()` : Check TDMM long-format input
    structure
  - `check.tdmm.family.data()` : Check TDMM data for an outcome family
  - `check.tdmm.subject.balance()` : Inspect subject visit counts

## Simulation helpers

<!-- end list -->

  - `data.gen.tdmm.bern()` : Generate a balanced-grid Bernoulli
    simulation dataset
  - `data.gen.tdmm.gauss()` : Generate a balanced-grid Gaussian
    simulation dataset
  - `data.gen.tdmm.pois()` : Generate a balanced-grid Poisson simulation
    dataset
