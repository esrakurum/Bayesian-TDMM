# Phase 2A validation

Environment: R 4.5.0, JAGS 4.3.2, R2jags 0.8.9, rjags 4.17, coda 0.19.4.1.
Package: TDMM 0.1.0.9000. Dependencies/installation were isolated in
`/private/tmp/tdmm-phase2a-library`; no Dropbox source file was edited.
R2jags was missing and installed there. The unused mcmcplots import was removed;
no package R code calls it, and CRAN did not provide it for this R version.

## Results

| Check | Result |
|---|---|
| R source parsing and DESCRIPTION DCF | Passed |
| R CMD INSTALL | Passed, including temporary/final-location loading |
| library(TDMM) | Passed |
| Gaussian common-grid baseline, serial and parallel | Passed |
| Bernoulli common-grid baseline, serial and parallel | Passed (unchanged V1 model) |
| Poisson common-grid baseline, serial and parallel | Passed (unchanged V1 model) |
| Gaussian irregular/unequal visits with time-varying predictor, serial and parallel | Passed |
| Bernoulli/Poisson V2, both entry points | Intentionally blocked with review-pending error |
| Summary and coefficient/SD/variance trace plots | Passed for all eight successful fits |
| SD-only object | SD plots; absent variance errors without transformation |
| Shuffled rows, character IDs, custom time column | Alignment and plotting checks passed |
| Missing values | Public fitter rejects; direct V2 helper deletes incomplete rows, as documented |
| codetools::checkUsagePackage | No findings |
| git diff --check | Passed |
| V1 non-Gaussian models, spline utilities, generators and tutorial | Byte-identical to main |
| Gaussian prior block | Identical after whitespace normalization |
| v0.1.0 tag | Remains 8d54f178b837253606e480257c144dd83ac142c7 |

The deterministic execution fixtures use 30 common-grid rows or 25 irregular rows, two chains,
100 iterations, 50 burn-in, thinning 1 and adaptation 100. They retain the package's default
nknots=15 and degree=2. These are short execution tests, not simulations, convergence tests,
coverage studies, or statistical validation. No posterior estimates are treated as findings.
The fixture script is tests/phase2a-smoke.R and may be run against an installed package with:

```sh
Rscript --vanilla tests/phase2a-smoke.R
```

The tests generate only temporary plots. Installation reports the inherited absence of man pages.
R startup reports host locale warnings; neither prevented execution. A full release/package check,
statistical equivalence comparison and cross-platform parallel validation were not performed.
No release, merge, tag modification, Zenodo update, tutorial rewrite, or new analysis was performed.
