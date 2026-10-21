# Gaussian cubic basis pilot — completed by Esra

Compare 6, 8 and 10 actual cubic B-spline columns on the **same 10 datasets**
(seeds 2001–2010). Esra completed all 10 matched datasets and selected eight
bases for the final V2 default. The pilot itself used explicit dimensions and
did not select or change the default automatically. The script is preserved
unchanged as provenance; do not resume its old checkpoints after package
source changes. The saved manifest intentionally rejects changed source.

Mean fit times were 57.1165, 77.2051 and 129.7991 seconds for 6, 8 and 10.
For the nonlinear beta1 curve, mean pointwise MSE was 0.0024450, 0.0019016
and 0.0019135. Eight did not minimize every coefficient's MSE. Esra chose it
as the overall recovery/shape/runtime compromise. This 10-dataset pilot is
preliminary evidence, not a formal simulation study.
The script sources the local development checkout and explicitly supplies the
Gaussian JAGS path, avoiding an accidentally stale installed TDMM package.

## Design and MCMC

The generator reproduces Makena's Gaussian V2 design: 200 subjects, 5–10
observations per subject, sorted Uniform(0,1) times, a standard-normal baseline
covariate, a time-varying covariate sin(2*pi*time) + N(0,0.25^2), independent
normal random intercepts with variance 0.5, and residual variance 0.1.
True coefficients are sin(2*pi*time), cos(2*pi*time), and 1.5*(time-0.5).
Each dataset is generated once per seed and reused for all basis sizes.

All fits explicitly use degree 3; the existing second-difference penalty,
ridge and all Gaussian priors remain unchanged. Use the existing study's
3 chains, 8,000 iterations, 3,000 burn-in, thinning 5 and 5,000 adaptation.
This is **30 fits**, not 100 replications. Fit RNG seeds are separate from data
seeds (data seed + 50,000). Exact sampling reproducibility also depends on the
recorded R/JAGS/package versions.

## Exact local commands (Terminal)

```sh
cd '/Users/esrakurum/Library/CloudStorage/Dropbox/Work/Bayesian-VCM w:Makena/Bayesian-VCM/TDMM-development'
Rscript --vanilla simulations/gaussian-cubic-pilot.R --check
```

The no-fit check verifies matched data generation, all 30 design matrices, and
common-grid support. It creates no output files and does not require R2jags.

The temporary dependency library below was used for the package checks. If it
has been removed, this setup command reinstalls only missing dependencies there:

```sh
Rscript --vanilla -e 'lib <- "/private/tmp/tdmm-spline-library"; dir.create(lib, recursive=TRUE, showWarnings=FALSE); .libPaths(c(lib, .libPaths())); needed <- c("R2jags", "rjags", "coda"); missing <- needed[!vapply(needed, requireNamespace, logical(1), quietly=TRUE)]; if(length(missing)) install.packages(missing, lib=lib, repos="https://cloud.r-project.org")'
```

JAGS must be installed; it was available during preparation. Start the pilot:

```sh
mkdir -p results/gaussian-cubic-pilot
R_LIBS='/private/tmp/tdmm-spline-library' Rscript --vanilla simulations/gaussian-cubic-pilot.R > results/gaussian-cubic-pilot/run.log 2>&1
```

To watch progress from another Terminal:

```sh
tail -f '/Users/esrakurum/Library/CloudStorage/Dropbox/Work/Bayesian-VCM w:Makena/Bayesian-VCM/TDMM-development/results/gaussian-cubic-pilot/run.log'
```

If interrupted, rerun the same pilot command. Saved fits are reused, retaining
their original fit runtimes; summaries and plots are regenerated. Source,
settings and software fingerprints prevent accidental reuse after changes.
For a deliberately different run, preserve and rename the existing results
folder first. A failed fit is recorded and retried on the next run; a saved fit
with a diagnostic error remains available for investigation.

## Outputs to return

From `results/gaussian-cubic-pilot/`, return:

- `coefficient-summary.csv`: mean signed pointwise bias, MSE, 95% coverage,
  maximum curve R-hat and minimum curve ESS, separately for all three curves.
- `variance-runtime-summary.csv`: mean, bias and MSE for both variances;
  mean and total fit runtimes, counted once per fit.
- `replication-metrics.csv` and `paired-comparisons.csv`: dataset-level metrics,
  roughness/turning counts, and paired differences relative to six bases.
- `smoothing-variance-diagnostics.csv`: all smoothing and variance R-hat/ESS.
- `coefficient-curves.pdf`: ten pages of matched curves, truth and pointwise
  intervals, with consistent vertical scales across basis sizes.
- `fit-status.csv`, `matched-seeds.txt`, `interpretation.txt`, `sessionInfo.txt`,
  `manifest.rds`, and `run.log`.

Keep `fits/` and `datasets/` locally. The full posterior chain arrays are saved
so additional diagnostics can be recovered without refitting.

## Interpretation

Evaluate curves directly from each fitted spline on the common 100-point grid
0.01–0.99; do not interpolate coefficients from the observation grid. Bias,
MSE and coverage average equally over times and matched datasets. Diagnostics
use actual reconstructed curve draws, preserving chain identity. R-hat is
coda's univariate Gelman–Rubin point estimate with autoburnin=FALSE because
burn-in was already removed; ESS is coda's effectiveSize. These are not
rank-normalized R-hat or bulk/tail ESS. Smoothing diagnostics are also saved.

Comparative summaries use only datasets successful at all three sizes, and
report the matched count. Fits are not removed merely for poor convergence.
Inspect failed statuses and excluded seeds before interpreting comparisons.

Visual review should look for extra oscillations relative to truth, edge
excursions, and unusually wide intervals. Integrated squared second-derivative
approximations and turning-point counts supplement the plots; neither is an
automatic verdict that a curve is overly wiggly. In particular, beta2 is linear
and has zero true curvature. Statistical performance and instability cannot be
reported until the actual pilot is run and inspected. Ten datasets provide
preliminary evidence, not precise coverage estimates or a final default choice.
