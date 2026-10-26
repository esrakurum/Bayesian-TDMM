# Small Bernoulli and Poisson examples

From the TDMM repository root, install the package and system
JAGS, then run either example in RStudio. Sourcing defines a function and does
not fit anything. Data-only calls are useful for inspecting the long-format
structure. An explicit fit call uses `tdmm()`, saves the
fit, and reuses it on later calls with the same data.

```r
library(TDMM)
source('examples/bernoulli-getting-started.R')
bernoulli_data <- run_small_bernoulli(fit_model=FALSE)
head(bernoulli_data)
bernoulli_fit <- run_small_bernoulli()
```

```r
source('examples/poisson-getting-started.R')
poisson_data <- run_small_poisson(fit_model=FALSE)
head(poisson_data)
poisson_fit <- run_small_poisson()
```

The scripts reuse the simulation generators in
`bernoulli-example.R` and `poisson-example.R` with fewer subjects and
visits. They keep the default family priors, cubic degree 3, and `n_basis=8`.
The shorter chains are intended to illustrate package use. For substantive
analyses, inspect convergence diagnostics and choose MCMC settings appropriate
for the application. Inspect
`summary.txt`, `coefficients.pdf`, and `traces.pdf` in each output directory.
