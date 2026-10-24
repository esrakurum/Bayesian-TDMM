# PBC2 application with TDMM

Run from the TDMM repository root. Source data are the `pbc2`
dataset distributed with **JMbayes2** (tested with version 0.6-5), loaded by
`data('pbc2', package='JMbayes2')`. The preparation uses all 1,945 source
observations from 312 subjects, with 1–16 visits per subject; there are no
missing analysis values and no exclusions. The script prepares the analysis
data from the source dataset on each run.

Preprocessing, in source order: `id = as.numeric(id)`, `time = year` (years
since baseline), `y = log(serBilir)`, `drug = 0` for placebo and `1` for
D-penicillamine, and `albumin = albumin - 3.3898868894601542`. That constant is the
overall **observation-level** mean of all source albumin values, not the mean
of subject-specific means. There is no centering of treatment. Thus the
intercept is the fitted log serum bilirubin trajectory for placebo at albumin
3.3898868894601542 g/dL and zero random intercept. The albumin coefficient describes
an association per 1 g/dL higher albumin at the same follow-up time; the
constant centering changes the intercept interpretation but not that slope.
The treatment coefficient is the modeled D-penicillamine-versus-placebo
association, not a causal effect established by this analysis.

The primary and sensitivity fits use `TDMM::tdmm()` with the
Gaussian model, cubic degree 3 and `n_basis` 8, 6, or 10, with unchanged
family-default Gaussian priors and 3 chains, 8,000 iterations, 3,000 burn-in,
thinning 5, adaptation 5,000 and fixed seed 541. The source package, data,
prior defaults, model file checksum, package version and settings are recorded
in the output. A saved fit is reused, and mismatched data/code are
rejected.

In RStudio, set the working directory to the TDMM repository and use a fresh R
session. Install packages if needed:

```r
install.packages('JMbayes2', repos='https://cloud.r-project.org') # data source
install.packages('R2jags', repos='https://cloud.r-project.org')   # if missing
install.packages('.', repos=NULL, type='source')                 # current TDMM
library(TDMM)
source('applications/pbc2-v2-analysis.R')
check_pbc2_v2()                  # optional: data checks, no fitting
run_pbc2_v2_primary()            # fit n_basis=8; save fit
summarize_pbc2_v2()              # inspect/regenerate tables and plots; no MCMC
run_pbc2_v2_sensitivity()        # fit 6 and 10; reuse saved 8
summarize_pbc2_v2()              # regenerate all comparison outputs; no MCMC
```

Terminal equivalents from the TDMM repository:

```sh
Rscript applications/pbc2-v2-analysis.R check
Rscript applications/pbc2-v2-analysis.R primary
Rscript applications/pbc2-v2-analysis.R summarize
Rscript applications/pbc2-v2-analysis.R sensitivity
```

Output is separate under `results/pbc2-v2-application/`: `analysis-data.rds`,
`manifest.rds`, `data-preparation.txt`, `sessionInfo.txt`, saved fits
`fits/n-basis-{6,8,10}.rds`, `coefficient-curves.csv`,
`selected-time-coefficients.csv`, `time-support.csv`, `curve-diagnostics.csv`,
`parameter-diagnostics.csv`, `model-summary.csv`, `runtime-warnings.csv`, `model-summaries.txt`,
`primary-package-plot.pdf`, `primary-coefficients.pdf`, and
`basis-sensitivity.pdf`. Fit-error text files appear only if needed. All plots
and tables can be regenerated from the saved fits with `summarize_pbc2_v2()`.

The basis sensitivity analysis compares coefficient means and 95% credible
bands on the same 100-point time grid, random-effect and residual variance,
curve R-hat/ESS and runtime. Scientific interpretation should focus on broad
patterns and regions with substantial follow-up support; the far-right tail
is sparse. Basis count is varied to assess robustness, not to choose whichever
fit gives the strongest treatment association.
