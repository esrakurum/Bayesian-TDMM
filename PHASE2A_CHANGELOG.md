# Phase 2A working change log

| File | Issue | Change made | Mechanical or statistical | Needs Esra K review? |
|---|---|---|---|---|
| DESCRIPTION | Malformed DCF; development metadata; unused dependency | Fix Description indentation and Suggests colon; use 0.1.0.9000; describe partial scope; remove unused mcmcplots import | Mechanical | No |
| CITATION.cff | Release metadata on development branch | Set 0.1.0.9000; omit historical date-released on unreleased snapshot | Mechanical | No |
| NAMESPACE | Unqualified stats functions | Import aggregate and generator distribution/link functions | Mechanical | No |
| R/data.checks.R | V1 rejects intended V2 structure | Integrate candidate structural/numeric checks and covariate classification; retain legacy boolean; trim whitespace | Mechanical integration | Yes: missing-data contract remains unresolved |
| R/tdmm.helpers.R | Common-grid preparation | Integrate candidate row-aligned inputs and integer IDs; preserve X.subject layout and legacy aliases | Mechanical integration | Yes: documented internal missing-data behavior |
| R/tdmm.helpers.R | Family routing and output consistency | Route Gaussian to observation-level data; keep V1 non-Gaussian data/monitors; gate V2; handle coda classes; add family | Mechanical integration | Yes: held models |
| R/tdmm.R | Serial integration | Use shared V2 preparation/scope guard and record implementation/size metadata; preserve automatic initialization | Mechanical integration | No |
| R/tdmm.parallel.R | Parallel integration and missing function lookup | Same routing/metadata; qualify stats::update and rjags::coda.samples; preserve initialization and backend | Mechanical integration | No |
| R/summary.tdmm.R | Time-count/output compatibility | Label unique observed times; add N/SD fields; retain n.total and variance fields | Mechanical | No |
| R/plot.trace.tdmm.R | SD silently rewritten as variance | Use exact parameter names and existing samples; reject unavailable names | Mechanical | No |
| R/plot.tdmm.R | Custom time column forgotten | Infer time.var from fit when omitted; leave basis/interval calculations unchanged | Mechanical | No |
| inst/jags/TDMM_Gaussian_JAGS.txt | Common-grid indexing and candidate filename mismatch | Integrate Gaussian observation-level likelihood at loader-expected filename; preserve prior block | Mechanical integration | No |
| inst/jags/TDMM_Bernoulli_JAGS.txt (unchanged) | V2 prior/parameterization conflict | No change; retain V1 compatibility path; block V2 data | Statistical — NOT implemented | Yes |
| inst/jags/TDMM_Poisson_JAGS.txt (unchanged) | V2 prior conflict | No change; retain V1 compatibility path; block V2 data | Statistical — NOT implemented | Yes |
| README.md | Stale paths and scope | Correct paths; document partial development scope and branch installation | Mechanical | No |
| .Rbuildignore | Development-only reports in package root | Exclude Phase 2A reports and citation metadata/tools from built package | Mechanical | No |
| tests/phase2a-smoke.R | No executable integration checks | Add deterministic small execution fixtures; no new simulation study or statistical thresholds | Mechanical validation | No |
| PHASE2A_COMPATIBILITY.md | Compatibility/deferred choices unrecorded | Record preserved interfaces, differences, held decisions and upload dependencies | Mechanical documentation | Yes: unresolved decisions |
| PHASE2A_CHANGELOG.md | No integration audit | Record file-level changes and candidate hashes | Mechanical documentation | No |
| PHASE2A_VALIDATION.md | Execution status unrecorded | Record environment, install/load and workflow smoke outcomes/limits | Mechanical documentation | No |
| examples/tdmm()/WageData_TDMM.R | Stale/default-main installation call | Use Bayesian-TDMM at ref v0.2-development; no analysis logic/results changed | Mechanical | No |
| examples/tdmm()/bernoulli_simulation.R | Stale/default-main installation call | Use Bayesian-TDMM at ref v0.2-development; no analysis logic/results changed | Mechanical | No |
| examples/tdmm()/gaussian_simulation.R | Stale/default-main installation call | Use Bayesian-TDMM at ref v0.2-development; no analysis logic/results changed | Mechanical | No |
| examples/tdmm()/poisson_simulation.R | Stale/default-main installation call | Use Bayesian-TDMM at ref v0.2-development; no analysis logic/results changed | Mechanical | No |
| examples/tdmm.parallel()/bernoulli_parallel.R | Stale/default-main installation call | Use Bayesian-TDMM at ref v0.2-development; no analysis logic/results changed | Mechanical | No |
| examples/tdmm.parallel()/gaussian_parallel.R | Stale/default-main installation call | Use Bayesian-TDMM at ref v0.2-development; no analysis logic/results changed | Mechanical | No |
| examples/tdmm.parallel()/poisson_parallel.R | Stale/default-main installation call | Use Bayesian-TDMM at ref v0.2-development; no analysis logic/results changed | Mechanical | No |

## Candidate provenance (SHA-256)

Each candidate was compared individually. The Gaussian model, structural checks and input builder were integrated; wrappers and output/summary methods were selectively reconciled. Non-Gaussian model/monitor/initialization changes were deferred. Spline utilities and simulation generators remain identical to main.

- `Updates/Update.pdf`: `74b7d5b5325d43790a420081dc52e4b3a861e47df1c29bddfde0454d5401b6b9`
- `Updates/Update_TDMM (2).pdf`: `86970e63df3cb5f780e69a9207236fd645d90ea1eb45176a76025096e1a8c5c1`
- `Updates/Updates_read this one.pdf`: `045ec17e571380b11d80241052416301935a8f1328e71492add4c05efa062ef4`
- `Updates/code/data.checks.R`: `c97c9e5cd048384d7a7e09f63e4a0845163c9e211ea76e0215b9ed58e203819b`
- `Updates/code/summary.tdmm.R`: `ac6f359ea465988e9fd60c6a00ea700c5d694fead7b62d2e7265f6be353c96ef`
- `Updates/code/tdmm.R`: `f1582e71759a2cfd242459810a8560979ecf0cb162d99243551850b17387a66b`
- `Updates/code/tdmm.helpers.R`: `27d4605d79069803e494ec0aa2e5a9eacd8366d8ecaffaa379ae71ba3b9da46d`
- `Updates/code/tdmm.parallel.R`: `495533d1e70fe8a34f9e7b83a94119902b94f3b35eb7f69e1d2fb190cbd41477`
- `Updates/jags/bernoulli.txt`: `6d196fcd6eaaea054b1781cc6fae1c8f1911de0fc94db4d13fe71fdeb7407f04`
- `Updates/jags/gaussian.txt`: `e8849daf0d48453654a07da238caace7f8f9daa04f5cbee2173d4cd784d7454c`
- `Updates/jags/poisson.txt`: `a451c8dc057ae51fabd9e393739b7db33014015031bf625e42c6d79e12f6094b`

## Approved centered null-space Bernoulli V2 integration

| File | Issue | Change made | Mechanical or statistical | Needs Esra K review? |
|---|---|---|---|---|
| inst/jags/TDMM_Bernoulli_JAGS.txt | Bernoulli V2 held on V1 model | Exact approved centered null-space observation-level model; Uniform(0,5) SD prior | Statistical, explicitly approved | Prior choice approved in this session |
| R/tdmm.helpers.R | Old balanced-grid Bernoulli input path | Internal eigen decomposition and observation-level JAGS data; monitor alpha, theta, gamma, tau.alpha and b | Implementation of approved specification | No |
| R/tdmm.R; R/tdmm.parallel.R | Public Bernoulli V2 blocked | Enable both fitters; save decomposition/prior metadata | Mechanical integration | No |
| tests/bernoulli-v2-*.R; tests/phase2a-smoke.R | Need regression coverage | Serial/parallel, prior reconstruction, alignment and legacy workflow checks | Software tests | No |
| simulations/bernoulli-v2-generator.R; simulations/bernoulli-v2-validation.* | Final public validation needed | Separate identifiable generator and one-dataset validation, with secondary tau diagnostics | Validation design | Review single-dataset results |
| README.md; DESCRIPTION; PHASE2A_COMPATIBILITY.md | Stale Bernoulli hold | Update current status and document intentional V1 prior differences | Documentation | No |
| examples/bernoulli-v2-example.R | Need a standalone user example after validation | Same generator and public fit/summary/plot workflow; reuse matching saved fits | Example | Single-dataset validation completed |

## Task 6 public controls and workflow

| File | Issue | Change made | Mechanical or statistical | Needs Esra K review? |
|---|---|---|---|---|
| R/interface.controls.R; NAMESPACE; man/tdmm.*.Rd | Priors and computation scattered or fixed in low-level files | Export structured controls and family-specific prior defaults, validate partial lists, document fields | Interface only; defaults unchanged | No |
| R/tdmm.R; R/tdmm.parallel.R; R/tdmm.helpers.R | Fitters lacked shared controls/prior data flow | Resolve lists, preserve legacy arguments, pass named hyperparameters, store prior metadata | Interface only | No |
| inst/jags/TDMM_*_JAGS.txt | Prior constants could not be tuned | Replace literals with validated named hyperparameters; same defaults | Parameterization of approved defaults | No |
| R/plot.tdmm.R; R/summary.tdmm.R | Generic plot(fit) unavailable and priors not visible | Register S3 plot using stored data; show resolved priors when present | Interface only | No |
| tests/structured-interface.R; existing family tests | Missing structured-control regression tests | Test defaults, invalid controls, serial/parallel workflows, plots, and saved-object compatibility | Software tests | No |
| README.md; PHASE2A_COMPATIBILITY.md | Stale V1 scope and undocumented public controls | Document workflow, sensitivity parameters, and compatibility | Documentation | No |

## Unified V2 fitter

| File | Issue | Change made | Mechanical or statistical | Needs Esra K review? |
|---|---|---|---|---|
| R/tdmm.R; R/tdmm.parallel.R | Separate public fitting paths | tdmm() selects serial or parallel by control; tdmm.parallel() delegates as a legacy wrapper | Interface only | No |
| R/interface.controls.R; NAMESPACE; man/tdmm.control.Rd | Parallel setting lacked unified control | Add tdmm_control() alias and validated parallel/cores settings | Interface only | No |
| README.md; PHASE2A_COMPATIBILITY.md; tests/structured-interface.R | Guidance and regression checks targeted separate fitter | Recommend unified workflow and test both new and legacy calls | Documentation/software tests | No |
