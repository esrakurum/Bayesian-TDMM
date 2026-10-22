# Phase 2A compatibility and unresolved decisions

Base: main e6958e47d194a9adc89e61e94882bd03b5909be9. Development version: 0.1.0.9000.
The v0.1.0 tag remains 8d54f178b837253606e480257c144dd83ac142c7.
This is a partial integration, not a finalized V2 statistical specification or release.

## Enabled paths

Gaussian: supplied June observation-level indexing, shared preparation/checking, serial and parallel fitting.
Bernoulli/Poisson: original V1 JAGS files and monitored parameters remain unchanged. Only common-grid,
equal-count, baseline-covariate fits are enabled. V2 data produce an explicit review-pending error in both
fitters and the internal JAGS-data builder. Retaining the existing V1 execution path is not a decision
that its prior should be adopted for V2. No Uniform-SD candidate model is selected or exposed as a fallback.

## Interfaces preserved and differences

- All exported function names and arguments remain. Defaults (including degree=2 and nknots=15) remain.
- X, ni, n.total, nbasis, time.points, beta*.hat, sigma.b, sigma2.b and existing summary fields remain.
- New input aliases: X.obs, bases.obs, time.obs, N, n.basis, data.long and x.names.
- X.subject deliberately remains covariate-only, unlike the candidate's intercept-inclusive matrix.
- Internal subject.ID is now consecutive integer indexing; subject.levels maps back to original labels.
  Original IDs remain in inputs$data. Consumers of internal IDs must use this mapping.
- inputs$data now contains selected model columns (candidate behavior), rather than unused source columns.
- Checks retain x.constant.within.subject and add baseline/time-varying names and per-subject schedules.
  Generic structural/family checks describe valid V2-shaped data; passing them does not mean a held
  non-Gaussian V2 fitter is enabled. The fitters perform the separate implementation-scope check.
- Numeric time/covariate validation is explicit. Factors must be encoded by the user; no encoding is chosen.
- Summary retains n.total and adds N and scale fields; time count is labeled unique observed times.
- family is now consistently available at the top level for serial and parallel fitted objects.
- Traceplots use the exact requested monitored parameter. sigma.b now plots SD, not silently sigma2.b.
  Missing parameters produce an error: no posterior draws are squared, synthesized, or relabeled.
- Coefficient plots infer a custom time-column name from the fitted object when time.var is omitted.
  Existing reconstruction and credible-band calculations are unchanged. A caller must still supply the
  same analysis data/time range; changing the plotting data range can change the reconstructed basis.
- Simulation helpers and spline-basis functions are unchanged; example edits only repair installation calls.
- Existing automatic initialization is retained. Candidate Uniform-SD initializations are not imported.

## Missing values: unresolved, deliberately not harmonized

Public checks and both fitters still reject missing values in required model columns. The supplied V2
internal input helper removes incomplete rows if called directly. This candidate behavior is retained
and tested, not promoted to a public automatic-deletion policy. Compared with the original V1 internal
helper, direct-helper behavior changes; public behavior does not. A missing-data/API decision is needed.
No imputation, visit interpolation, or observation-process model has been added.

## Statistical decisions deferred to Esra K

1. Bernoulli/Poisson Gamma precision versus Uniform(0,5) random-intercept SD prior.
2. Bernoulli ridge versus null-space parameterization, including latest helper dependencies.
3. Smoothing hyperparameter treatment and convergence assessment.
4. Any ridge, penalty, degree or basis-dimension revisions. Existing values have not been changed.
5. Final non-Gaussian monitored quantities and reporting policy. Existing V1 quantities remain for V1 fits.
6. Public/internal missing-data behavior and final coefficient-recovery-grid conventions.

The August 24 report mentions a common 100-point recovery grid, quadratic basis sensitivity, completed
Gaussian simulations and PBC2, and ongoing Bernoulli smoothing difficulties. These are not instructions
to change defaults. The corresponding newer source/results are still needed.

## Wait for newer uploads

Reconcile the actual August-era fitters, model files (including null-space variants), initialization,
reconstruction/validation helpers, simulation code and results, and PBC2 source. Do not reconstruct them
from report tables. No new simulation study, tutorial rewrite, vignette, pkgdown, PBC2 revision, release,
Zenodo update, or merge is part of this phase.

## Known remaining package issues

No man-page documentation or formal release-ready package check exists. The old tutorial remains V1.
The fork-based parallel backend remains macOS/Linux-oriented; seed is not a guarantee of JAGS RNG
reproducibility. These inherited issues are documented, not redesigned here. Installation/short smoke
execution is not evidence of convergence, statistical correctness, numerical equivalence, or performance.

## Approved Bernoulli V2 completion (supersedes the historical hold above)

Bernoulli now supports observation-level irregular times, unequal visits and
baseline/time-varying predictors through both public fitters. Its production
spline prior is centered null-space with gamma ~ N(0,100),
theta[r] | tau.alpha ~ N(0,1/(tau.alpha*lambda.pen[r])), and
tau.alpha ~ Gamma(1,.001), shape/rate. Esra explicitly approved
sigma.b ~ Uniform(0,5), replacing the retained V1 Gamma(1,.005) precision prior.
New Bernoulli fits are not statistically equivalent to V1. Common-grid legacy
inputs and arguments still execute; saved historical alpha/basis reconstruction
is unchanged. Internal inputs$null.space records the actual decomposition;
model.settings$spline.prior identifies the backend. Users provide no matrices.
Default cubic degree 3/order 4/n_basis=8 and deprecated nknots behavior remain.
Gaussian/Poisson formulations and the existing missing-data behavior are unchanged.
See simulations/bernoulli-v2-validation.md for the final validation workflow.

## Task 6 public interface

Optional structured `control` and `priors` lists were added to both public
fitters without removing legacy arguments. Conflicting legacy/structured
computational settings fail explicitly. With neither list supplied, all
family models and computational defaults retain their previous values.
The JAGS files now read prior hyperparameters from the resolved family defaults
rather than literal constants; the default values are identical. New fits store
resolved prior settings in model.settings and show them in summary(). Older
saved objects without this field remain readable and plottable. The plot S3
method now supports plot(fit) using the saved fitted data; direct
plot.tdmm(data, fit) remains supported. tdmm.parallel() remains a separate
entry point using the existing fork backend. Only approved prior families may
be tuned: distribution changes require future statistical review.
