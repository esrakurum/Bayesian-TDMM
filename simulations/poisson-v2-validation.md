# Poisson V2 single-dataset validation

Restart R in RStudio first to avoid retaining an older loaded TDMM namespace.
Run these commands in the R console (also compatible with ordinary R):

    setwd("/Users/esrakurum/Library/CloudStorage/Dropbox/Work/Bayesian-VCM w:Makena/Bayesian-VCM/TDMM-development")
    lib <- "/private/tmp/tdmm-spline-library"
    dir.create(lib, recursive=TRUE, showWarnings=FALSE)
    .libPaths(c(lib, .libPaths()))
    status <- system2(file.path(R.home("bin"), "R"),
      c("CMD", "INSTALL", paste0("--library=", shQuote(lib)), shQuote(getwd())))
    stopifnot(status == 0)
    source("simulations/poisson-v2-validation.R")
    run_poisson_validation(check_only=TRUE) # No MCMC or files
    run_poisson_validation()

JAGS and the existing R2jags/rjags/coda dependencies must be available.
Sourcing defines a function only; the final command starts the fit.
After installation, the equivalent Terminal command from this directory is:

    R_LIBS=/private/tmp/tdmm-spline-library Rscript -e 'source("simulations/poisson-v2-validation.R"); run_poisson_validation()'

The single dataset has 200 subjects, 5–10 irregular visits, a baseline N(0,1)
covariate and a time-varying sin(2*pi*t)+N(0,0.25^2) covariate. True coefficient
functions on the log-rate scale are sin(2*pi*t), cos(2*pi*t), 1.5*(t-0.5).
Random-intercept variance is 0.5. The count mean is exp(X beta(t)+b).
Data seed is 37181, fit seed 87181, predictive simulation seed 97181.
The default-eight cubic framework and supplied Poisson V2 priors are used.
The fit uses three chains, 8,000 iterations, 3,000 burn-in, thinning five,
5,000 adaptation. These settings are a starting point, not a convergence claim.

Return the CSV/TXT/PDF files in results/poisson-v2-validation:

- coefficient-metrics.csv, pointwise.csv: curve recovery and chain-resolved R-hat/ESS;
- parameter-diagnostics.csv: SD, variance, precision and every tau.alpha R-hat/ESS;
- variance-recovery.csv: random-intercept SD/variance versus truth;
- count-checks.csv and count-fitted.csv: observed count summaries, conditional
  posterior predictive summaries and posterior mean intensity at each observation;
- summary.txt, warnings.txt, run-notes.txt, sessionInfo.txt, package.txt;
- package-coefficients.pdf, truth-comparison.pdf, traces.pdf.

Retain fit.rds, data.rds, settings.rds and count-replicates.rds locally.
fit.rds contains chain-resolved alpha, tau.alpha, b, sigma.b, sigma2.b and tau.b.
Count checks use up to 500 retained draws and subject-specific intercept draws;
they assess conditional replicated counts on the observed design, not
out-of-sample prediction. Zero fraction, mean, variance and maximum are compared.
Curve diagnostics use post-burn-in draws without discarding a second burn-in.
Posterior mean SD is not the square root of posterior mean variance; both
summaries are computed on their proper scales.

The script refuses to overwrite an existing output directory. If the fit fails,
return the console error and whatever files were written. Review warning logs
and all diagnostics; finite R-hat/ESS alone do not establish convergence.
One-dataset interval coverage fraction is not repeated-sampling coverage.
No formal repeated simulation or PBC2 analysis is run.
