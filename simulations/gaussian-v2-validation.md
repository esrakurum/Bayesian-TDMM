# Single-dataset Gaussian V2 validation

This script uses the installed public TDMM package and the finalized effective
8-basis cubic default. It generates one dataset (seed 27181): 200 subjects,
5–10 irregular visits, a normal baseline covariate, a time-varying covariate,
random-intercept variance 0.5 and residual variance 0.1. Coefficient truth is
sin(2*pi*t), cos(2*pi*t), and 1.5*(t-0.5). Three chains use 8,000 iterations,
3,000 burn-in, thinning five, adaptation 5,000 and fit seed 77181. Priors and
model are unchanged. This is not a formal simulation study.

Run in Terminal:

```sh
cd '/Users/esrakurum/Library/CloudStorage/Dropbox/Work/Bayesian-VCM w:Makena/Bayesian-VCM/TDMM-development'
mkdir -p /private/tmp/tdmm-spline-library
R_LIBS=/private/tmp/tdmm-spline-library R CMD INSTALL --library=/private/tmp/tdmm-spline-library .
R_LIBS=/private/tmp/tdmm-spline-library Rscript simulations/gaussian-v2-validation.R --check
R_LIBS=/private/tmp/tdmm-spline-library Rscript simulations/gaussian-v2-validation.R
```

R2jags, rjags and coda must be installed (the existing pilot library contains
them), and JAGS must be available. No Dropbox source loading or JAGS path is
needed. Use Rscript, not source(), because the script locates its own file.
The --check option checks data preparation without MCMC or output files.

Return the small review files from `results/gaussian-v2-validation`:
`summary.txt`, `coefficient-metrics.csv`, `pointwise.csv`,
`parameter-diagnostics.csv`, `variance-recovery.csv`, `run-notes.txt`,
`sessionInfo.txt`, `package.txt`, and all three PDFs (`package-coefficients`,
`truth-comparison`, `traces`). Retain `fit.rds`, `data.rds` and `settings.rds`
locally for follow-up diagnostics. Return the console error if the run fails.
The script refuses to overwrite an existing output directory.

Metrics describe this dataset, not expected bias/MSE or repeated-sampling
coverage. No convergence threshold or statistical acceptance rule is changed.
Serial/parallel execution is separately exercised by package smoke tests;
this validation performs one serial fit to limit computation.
