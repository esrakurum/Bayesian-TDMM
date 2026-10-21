# Final Poisson V2 example and reusable simulation design

The generator is a script-level helper, not a change to the package fitting API.
Use simulations/poisson-v2-generator.R for later repeated validation. The
standalone examples/poisson-v2-example.R embeds the same generator so users need
only that file and the installed TDMM V2 package, not Dropbox source files.
No formal repeated study or repeated-study driver has been run or added.

## Exact data-generating mechanism

For each of 200 subjects, independently draw baseline x_i~N(0,1), covariate
component u_i~N(0,1), and random intercept b_i~N(0,0.5^2). Draw the number of
visits uniformly from integers 8 through 14, and sorted irregular times
independently from Uniform(0,1). At each visit draw e_ij~N(0,0.5^2), independent
of everything else, and set z_ij=u_i+0.5*t_ij+e_ij.

Log-rate coefficient truths:

- beta0(t)=0.25+0.35*sin(2*pi*t)
- beta1(t)=0.35*cos(2*pi*t)
- beta2(t)=0.25+0.20*t

eta_ij=beta0(t_ij)+x_i*beta1(t_ij)+z_ij*beta2(t_ij)+b_i;
y_ij~Poisson(exp(eta_ij)). There is no extra residual-error term.
The modest log-rate amplitudes match the historical Poisson design and avoid
extreme counts. Between-subject covariate SD is 1, within-subject observation
noise SD is 0.5; neither is a deterministic nonlinear copy of the intercept.
This supports separation but does not guarantee identifiability/convergence
for every random dataset. Simulation truth scale is not an inference prior.

Fit with the unchanged production model: degree 3/order 4, eight spline columns,
extended uniform knots, splineDesign evaluator, second-order difference penalty
plus the existing 1e-6 ridge. Existing Uniform(0,5) random-intercept SD and
Gamma(1,0.001) smoothing-precision priors are unchanged.

## Pre-fit design audit (seed 20261021, reported before fitting)

2,211 observations across 200 subjects. Subjects with 8,9,10,11,12,13,14 visits:
28,25,29,31,28,31,28. Covariate/time correlation 0.16194; covariate/beta0-pattern
correlation -0.13458. Eight-column cubic time basis explains 2.8716% of
covariate variation. Empirical covariate SD is 1.05456.

Conditional on generated covariates and true random intercepts: mean count
expectation 1.7125, expected zero fraction 0.2798, mixture variance 3.5847.
Intensities range 0.1334–17.4642, median 1.3999, 99th percentile 7.0821.
Realized counts range 0–17, median 1, 95th percentile 5, 99th percentile 9.
Poisson support is unbounded; these ranges are not hard truncation limits.

## One-fit validation

One fit only: data seed 20261021, fit seed 87181, 3 chains, 8,000 iterations,
3,000 burn-in, thinning 5, adaptation 5,000, default initialization. Runtime
136.373 seconds. No sampler warnings. No priors or fitting code were modified.

| Curve | Mean pointwise bias | Mean pointwise squared error | Pointwise 95% coverage fraction | Maximum R-hat | Minimum ESS |
| --- | ---: | ---: | ---: | ---: | ---: |
| beta0 | -0.027117 | 0.00146273 | 1.00 | 1.003482 | 964.7 |
| beta1 | -0.006173 | 0.00157737 | 1.00 | 1.003717 | 1145.5 |
| beta2 | -0.007151 | 0.00012736 | 1.00 | 1.003849 | 1054.4 |

Raw-alpha maximum R-hat was 1.003862 and minimum ESS 1008.3.

Random-intercept SD estimate 0.497012 versus truth 0.5 (R-hat 1.003226,
ESS 865.4); variance 0.248121 versus truth 0.25. Smoothing precisions:

| Parameter | Posterior mean | R-hat | ESS |
| --- | ---: | ---: | ---: |
| tau.alpha[1] | 7.8148 | 1.001754 | 1712.8 |
| tau.alpha[2] | 21.2394 | 1.001618 | 1556.1 |
| tau.alpha[3] | 2109.6168 | 1.000995 | 2145.1 |

Conditional posterior predictive mean/variance/zero fraction/maximum were
1.6966/3.4594/0.2843/17.326, compared with observed 1.6965/3.4965/0.2763/17;
each observed statistic lies within its saved 95% predictive interval.
These are in-sample conditional checks, not held-out or population-marginal
validation. R-hat/ESS use coda with autoburnin=FALSE on retained chain draws.
One-dataset interval coverage is not repeated-sampling coverage.

Full results, including raw alpha diagnostics and retained chain draws, are in
results/poisson-final-example/validation. The single check supports using this
example; formal repeated validation remains deferred.

## R/RStudio commands

In a fresh R session, use the project directory:

```r
setwd('/Users/esrakurum/Library/CloudStorage/Dropbox/Work/Bayesian-VCM w:Makena/Bayesian-VCM/TDMM-development')
.libPaths(c('/private/tmp/tdmm-spline-library', .libPaths()))
source('examples/poisson-v2-example.R')
# Inspect/replot the completed fit, without running MCMC again:
example <- run_poisson_example('results/poisson-final-example/validation')
summary(example$fit)
head(example$data)
example$truth(c(0, 0.5, 1))
```

For a new execution, users with TDMM V2 and JAGS installed can source the
standalone file anywhere and call run_poisson_example() (default output folder
poisson-example-output). This generates one dataset and fits once. It reuses
an existing matching saved fit if present. No JAGS filenames, spline matrices
or ID mapping are required. Retained samples are in example$fit$post.samples.

For future simulation work (generates data only; no repeated fitting):

```r
source('simulations/poisson-v2-generator.R')
sim <- simulate_poisson_v2(seed=2001, n_subject=200, visits=8:14, sigma_b=0.5)
head(sim$data)
# sim also retains truth, true_b, eta, lambda, subject-level variables and settings.
```

Choose explicit data seeds for later replications. The generator preserves the
caller's RNG state; set a separate fitting seed. The example embeds exactly the
shared generator source; keep the embedded copy synchronized if revising it.

## Historical and diagnostic provenance

simulations/poisson-v2-validation.R and its companion Markdown file retain the
old sin(2*pi*time)+noise scenario, now explicitly labeled diagnostic/stress-test
only. Their formulas, function body and saved results are unchanged. Prior
independent-covariate diagnostic datasets/results are also untouched. The older
examples/tdmm()/poisson_simulation.R remains a labeled legacy common-grid example.
