# Small Bernoulli and Poisson V2 examples

From the TDMM repository root, install the package and system
JAGS, then run either example in RStudio. Sourcing defines a function and does
not fit anything. Data-only calls are useful for inspecting the long-format
structure. An explicit fit call uses `tdmm()`, saves the
fit, and reuses it on later calls with the same data.

```r
library(TDMM)
source('examples/bernoulli-v2-getting-started.R')
bernoulli_data <- run_small_bernoulli_v2(fit_model=FALSE)
head(bernoulli_data)
bernoulli_fit <- run_small_bernoulli_v2()
```

```r
source('examples/poisson-v2-getting-started.R')
poisson_data <- run_small_poisson_v2(fit_model=FALSE)
head(poisson_data)
poisson_fit <- run_small_poisson_v2()
```

The scripts reuse the simulation generators in
`bernoulli-v2-example.R` and `poisson-v2-example.R` with fewer subjects and
visits. They keep the default family priors, cubic degree 3, and `n_basis=8`.
The shorter chains are intended to illustrate package use. For substantive
analyses, inspect convergence diagnostics and choose MCMC settings appropriate
for the application. Inspect
`summary.txt`, `coefficients.pdf`, and `traces.pdf` in each output directory.

