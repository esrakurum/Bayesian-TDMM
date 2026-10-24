# Final centered null-space Bernoulli V2 validation

This is one dataset, not a repeated simulation study. The public interface is
`tdmm(data, family="bernoulli", subject.var="id", x.var=c("baseline","changing"))`;
`tdmm.parallel()` uses the same statistical backend on macOS/Linux. Users do not
supply matrices, eigenvalues, or JAGS paths. Existing spline/MCMC arguments and
deprecated nknots handling are preserved. No new public prior-control argument
is introduced; priors remain fixed pending the common prior-control design.

## Approved specification and compatibility

Cubic B-splines: degree 3, order 4, default n_basis=8, extended uniform knots,
splines::splineDesign evaluation, second coefficient-difference penalty.
For each coefficient function, alpha = U.null gamma + U.pen theta:

- Two null coordinates: gamma ~ Normal(0,100), precision .01.
- Six penalized coordinates at n_basis=8:
  theta[r] | tau.alpha ~ Normal(0, 1/(tau.alpha * lambda.pen[r])).
- tau.alpha ~ Gamma(shape=1, rate=.001), independently per coefficient function.
- sigma.b ~ Uniform(0,5); b[i] | sigma.b ~ Normal(0,sigma.b^2).
- y[j] ~ Bernoulli(p[j]); logit(p[j]) = sum_k X[j,k] beta_k(time[j]) + b[id[j]].

The eigendecomposition exactly follows the approved targeted comparison:
eigen(D2'D2 + 1e-6 I), remove 1e-6 from penalized eigenvalues, and assign the
separate fixed null prior. There is no ridge prior on the null directions.
The SD prior was explicitly approved during integration; it replaces the
retained V1 Gamma(1,.005) precision prior. New Bernoulli fits therefore intentionally
change statistical results relative to V1. Old saved objects retain their
original alpha and spline metadata; their reconstruction is not changed.
Gaussian and Poisson statistical formulations are untouched.

Production monitors alpha, gamma, theta, tau.alpha, b, tau.b, sigma.b, sigma2.b.
Ordinary summaries and coefficient plots operate on reconstructed coefficient
functions, not transformed coordinates. Advanced traceplots can request any
monitored parameter by its exact name. The fitted object records the decomposition
and centered prior label for auditing; no user interaction with these is required.

## Dataset and interpretation

Seed 20261021; 200 subjects; 8–14 independently sampled visits per subject;
independent Uniform(0,1) times. Baseline covariate, subject predictor component,
and standardized random intercept are independent normal draws. The time-varying
predictor is subject_component + .5*time + Normal(0,.5^2) observation noise.
True random-intercept SD is sqrt(.5). True log-odds coefficient functions are
beta0(t)=-.5+.75*sin(2*pi*t), beta1(t)=.75*cos(2*pi*t), beta2(t)=.5+.25*t.
This retains substantial predictor variation at a given time, rather than using
a nonlinear time pattern duplicating the intercept truth. Realized associations
are reported in design-checks.csv. The generator preserves the caller's RNG state.

Fitting uses package-default initialization, a separate fitting seed 87181,
three chains, 20,000 iterations, 10,000 burn-in, thinning 5, adaptation 5,000.
The primary targets are the three reconstructed curves. tau.alpha diagnostics
are retained as secondary evidence, not an automatic failure criterion.
Coverage here means the fraction of this dataset's grid points covered by pointwise
intervals, not a repeated-sampling coverage estimate. Probability, Brier and
classification checks are conditional in-sample checks, not held-out performance.

## Install and run in R/RStudio

```r
setwd("/Users/esrakurum/Library/CloudStorage/Dropbox/Work/Bayesian-VCM w:Makena/Bayesian-VCM/TDMM-development")
.libPaths(c("/private/tmp/tdmm-spline-library", .libPaths()))
install.packages(".", repos=NULL, type="source", lib=.libPaths()[1])
# Restart R after installation if TDMM was already loaded, then setwd/.libPaths again.
library(TDMM)
source("simulations/bernoulli-v2-validation.R")
run_bernoulli_validation(check_only=TRUE) # No fit.
# Only if you need a NEW fit and the results directory does not already exist:
run_bernoulli_validation()
```

The script refuses to overwrite previous validation results. The implementation
session runs this single validation once; inspect that saved run before deciding
to run another. Approximate runtime is five minutes, depending on hardware.
To inspect without running any MCMC:

```r
source("simulations/bernoulli-v2-validation.R")
fit <- inspect_bernoulli_validation()
summary(fit)
# Figures are already saved under results/bernoulli-v2-validation.
```

Return coefficient-metrics.csv, pointwise.csv, parameter-diagnostics.csv,
variance-recovery.csv, probability-checks.csv, design-checks.csv,
chain-curve-means.csv, summary.txt, warnings.txt, run-notes.txt, sessionInfo.txt,
package.txt, and the PDFs truth-comparison.pdf, package-coefficients.pdf,
traces.pdf, curve-traces.pdf. Keep fit.rds, simulation.rds, data.rds, settings.rds,
probability-fitted.csv and predictive-prevalence.rds locally for further review.
No formal repeated study or automatic statistical pass/fail is performed.

## Software checks in the integration session

Installation/loading and all seven regression scripts passed: Bernoulli
serial/parallel smoke tests, Bernoulli decomposition/data-flow checks, Gaussian
data-flow tests, all-family legacy/interface smoke tests, Poisson data-flow and
serial/parallel smoke tests, and the spline framework tests. `R CMD check
--no-manual --no-build-vignettes` completed with zero errors, one existing warning
(missing exported-function help pages), and two existing notes (MIT license
metadata). Suggested package panelr was unavailable; force-suggests was disabled.
These packaging issues remain before release; they do not represent a Bernoulli
execution failure. Parallel fitting uses the existing macOS/Linux fork backend;
Windows multicore support is not added by this integration.

## Completed single-dataset result

The one production fit completed in 298.3 seconds with no recorded sampler
warnings. beta0/beta1/beta2 mean pointwise squared errors were .01580/.00771/.00129;
pointwise interval coverage fractions were 1/1/1. Maximum curve R-hat was 1.00135
and minimum curve ESS was 5271.5. Estimated sigma.b was .6634 versus truth .7071;
sigma.b R-hat was 1.00022. The three tau.alpha R-hats were
1.00087/1.00191/1.00055. Observed prevalence was .4079 and posterior fitted mean
probability .4083; the predictive prevalence interval was [.3836,.4332].
This supports implementation completion on this dataset, not formal calibration
or proof that difficult-seed smoothing diagnostics are resolved.

The standalone user example is `examples/bernoulli-v2-example.R`, containing the
same generator without external source-file dependencies. Inspect/reuse the
completed validation fit without additional MCMC:

```r
source("examples/bernoulli-v2-example.R")
example <- run_bernoulli_example(out="results/bernoulli-v2-validation")
```

Calling `run_bernoulli_example()` with its default output directory instead will
fit a new example if that directory has no saved fit. For a future repeated
study, source `simulations/bernoulli-v2-generator.R` and call
`simulate_bernoulli_v2(seed=...)`; no repeated study is run here.
