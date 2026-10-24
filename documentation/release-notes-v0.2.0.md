# TDMM v0.2.0 release notes

TDMM v0.2.0 supports Gaussian, Bernoulli, and Poisson longitudinal outcomes with subject-specific irregular observation times, unequal visit counts, baseline covariates, and time-varying covariates. New fits use cubic B-splines with a second-order coefficient-difference penalty and eight basis functions by default. The number of basis functions is controlled directly with `n_basis`.

The recommended workflow is `tdmm()` followed by `summary()`, coefficient plots, and chain diagnostics. Serial and parallel fitting are selected with `tdmm_control()`; `tdmm.parallel()` remains available for compatibility. The package includes a Getting Started vignette, short examples for all three families, and a reproducible PBC2 application. Users should assess convergence and model fit for each analysis.

Version 0.1.0 remains preserved as the historical V1 release. Its Zenodo DOI, 10.5281/zenodo.20617705, should not be cited as an archive of v0.2.0. Add a version-specific DOI to release metadata only after the v0.2.0 archive is created.
