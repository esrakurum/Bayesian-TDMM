# Poisson V2 integration and single-dataset validation preparation

Branch: v0.2-development. Gaussian single-dataset results reviewed numerically:
curve R-hat maxima 1.000631/1.002043/1.000450, minimum curve ESS >=2597;
scale/smoothing maximum R-hat 1.004303, minimum ESS 2161. Random-intercept
variance mean 0.428072 versus true 0.5; residual variance 0.104462 versus 0.1.
These are one-dataset results, not repeated-sampling validation. Gaussian is
implementation-complete per Esra; formal repeated validation remains deferred.

## Exact supplied Poisson specification

Source: TDMM_V2/01_code/jags/TDMM_Poisson_JAGS.txt.
Integrated model matches this source exactly apart from nknots -> n_basis and
a trailing newline. No new statistical choice was made.

y_j ~ Poisson(lambda_j);
log(lambda_j)=sum_k X_jk * (B(time_j) alpha_k) + b_subject.ID[j].
b_i ~ Normal(0, variance=sigma.b^2);
sigma.b ~ Uniform(0,5), tau.b=1/sigma.b^2, sigma2.b=sigma.b^2.
alpha_k ~ MVNormal(0, precision=tau.alpha[k]*P);
tau.alpha[k] ~ Gamma(shape=1, rate=0.001).
P = D2' D2 + 1e-6 I, D2 the second coefficient-difference matrix.
No residual Gaussian variance or separate null-space prior.
Common basis remains degree 3/order 4, default eight, splineDesign evaluator
and existing extended uniform knots. Gaussian/Bernoulli priors are untouched.

Compatibility: new Poisson fits, including common-grid baseline-only calls,
now use the supplied V2 Uniform SD prior rather than the retained V1
Gamma(1,0.005) random-intercept precision prior. Numerical posterior results
therefore need not match V1. Function arguments, deprecated nknots handling,
summary/plot interfaces and old fitted-object reconstruction remain unchanged.
Both sigma.b and sigma2.b are monitored on their own scales; mean(SD)^2 need
not equal mean(variance). New Poisson objects also monitor b for count checks.

## Files changed

| File | Change |
| --- | --- |
| inst/jags/TDMM_Poisson_JAGS.txt | Integrate supplied observation-level model, rename dimension |
| R/tdmm.helpers.R | Poisson observation-level JAGS data, remove Poisson hold, monitor b |
| R/tdmm.R | Record V2 Poisson implementation metadata |
| R/tdmm.parallel.R | Same metadata for parallel fits |
| R/data.checks.R | Reject nonnumeric/infinite Poisson counts before JAGS |
| DESCRIPTION | Declare Gaussian and Poisson irregular/TV support |
| README.md | Public workflow, priors and compatibility note |
| tests/phase2a-smoke.R | Update Poisson implementation expectation; retain Bernoulli V2 hold |
| tests/poisson-v2-data-flow.R | IDs, ordering, irregular/unequal visits, covariate/basis alignment and recovery |
| tests/poisson-v2-smoke.R | Serial/parallel fits, summaries/plots/traces, scale identities, curve diagnostics, invalid counts, model/prior regression |
| simulations/poisson-v2-validation.R | Sourceable validation function with full posterior, warnings, recovery, diagnostics and predictive counts |
| simulations/poisson-v2-validation.md | Exact R/RStudio/Terminal commands and return-file list |
| PHASE2A_POISSON_INTEGRATION.md | This integration record |

## Execution and remaining review

All five package test scripts pass, including legacy common-grid workflows,
Gaussian V2, spline/legacy-object tests and Poisson V2 serial/parallel smokes.
Package installation and loading pass. R CMD check --no-manual:
0 errors, 1 warning (existing missing exported-object help), 2 notes (existing
MIT/LICENSE metadata). Suggested panelr unavailable; force-suggests disabled.
The sourceable validation function's deterministic check and abbreviated
200-iteration/100-burn/100-adaptation run pass, producing all 18 expected files.
Short chains check software execution, not convergence or statistical recovery.
R-hat/ESS are recorded for review; no new convergence cutoff was introduced.

Poisson's full 8,000-iteration single-dataset validation is prepared for Esra
and has not been run here. It retains chain-resolved alpha, tau.alpha, b and
SD/variance/precision; reconstructed curves and all smoothing/scale diagnostics;
conditional predictive count mean/variance/zero fraction/maximum; warnings,
session information, truth data and settings. See the validation instructions.
No formal 100-replication study, PBC2 or Bernoulli V2 analysis ran.
No known software blocker remains for complete numeric Gaussian/Poisson data
on macOS/Linux. Poisson is pending the full single-dataset convergence/recovery
review before implementation-complete acceptance. Windows multicore support
and package help/license cleanup remain separate limitations.
