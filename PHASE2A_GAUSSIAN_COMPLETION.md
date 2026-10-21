# Gaussian V2 implementation completion

Approved by Esra: eight cubic bases, polynomial degree 3, order 4,
second-order coefficient-difference penalty. No model/prior changes.
The effective default is resolved from NULL to preserve deprecated nknots.
For q bases and degree d: intervals=q-d, h=(max(time)-min(time))/intervals,
knots=min(time)+(-d:(intervals+d))*h. For q=8,d=3 there are five intervals,
12 extended uniform knots, and eight columns per coefficient in JAGS.
The unchanged penalty is crossprod(diff(diag(q),differences=2))+1e-6*diag(q).
Legacy nknots maps to q=nknots+d-2, warns, and cannot accompany n_basis.
Stored fitted spline metadata and legacy convention detection are unchanged.

## Change record

| File | Change |
| --- | --- |
| R/spline.basis.R | Effective default 8; pilot rationale comment |
| R/data.checks.R | Ignore unused subject-factor levels; reject nonnumeric Gaussian response and infinite response/time/covariate values before JAGS |
| R/tdmm.helpers.R | Qualify stats::complete.cases |
| tests/spline-framework.R | Default-eight assertion and q=8 property tests |
| tests/gaussian-v2-data-flow.R | Unused ID levels and true subject count regression |
| tests/phase2a-smoke.R | Default-eight Gaussian irregular serial fit, legacy nknots=7 parallel fit, summaries, grid/curve equality, smoothing/variance/alpha traces, invalid input checks |
| README.md | Final default, pilot rationale, public long-format workflow and platform limits |
| simulations/gaussian-cubic-pilot.R | Track previously prepared, unchanged pilot source as provenance |
| simulations/gaussian-cubic-pilot.md | Track pilot instructions and record Esra's completed selection |
| simulations/gaussian-v2-validation.R | Single dataset using installed public package, truth recovery, chain diagnostics and saved review outputs |
| simulations/gaussian-v2-validation.md | Exact local commands and review file list |
| PHASE2A_GAUSSIAN_COMPLETION.md | This completion record |

Public workflow: tdmm(data,family="gaussian",subject.var="id",
x.var=c("baseline","changing")), summary(fit), plot.tdmm(data,fit),
plot.trace.tdmm(fit,params). tdmm.parallel accepts the same inputs plus
n.cores and seed. Neither workflow needs external source files, basis matrices,
ID mapping or JAGS filenames. Numeric covariates are required; encode factors.
Public fitting still rejects missing required values. Direct internal preparation
still drops incomplete rows; direct response summaries still allow missing
values. No missing-data policy is changed.

## Validation and limits

Installed-package Gaussian irregular serial/parallel and legacy common-grid
Gaussian/Bernoulli/Poisson execution pass. No Bernoulli/Poisson V2 fits ran.
All three package test scripts pass, including spline properties and legacy
saved-object reconstruction. Plotting on fitted time.points reproduces the
coefficient means and basis exactly. Default and deprecated-argument paths
are exercised. Priors/model files were not edited.

R CMD check --no-manual: 0 errors, 1 warning, 2 notes. Warning: pre-existing
missing help pages for exported functions. Notes: pre-existing MIT LICENSE
metadata mismatch. Suggested panelr is unavailable; force-suggests was disabled.
Installation/loading and code checks pass. These packaging issues remain before
public release. No remaining execution blocker was found for complete numeric
Gaussian data on macOS/Linux; Windows multicore support remains unavailable
(the existing parallel fitter uses mclapply). Statistical adequacy is not
established by smoke tests. Esra's final single-dataset review is pending.

The new script's --check passes; a separate temporary copy with 200 iterations,
100 burn-in/adaptation and thinning one ran end-to-end and produced all 14
files. Its statistical results are not validation evidence. The full requested
8,000-iteration validation is prepared for Esra, not run here. Formal studies,
PBC2 and family-specific V2 work were not run. Main and v0.1.0 are untouched.
