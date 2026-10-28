# Technical documentation

**TDMM: Bayesian Time-Dynamic Models with Optional Mixed Effects**
models Gaussian, Bernoulli, and Poisson outcomes using coefficient
functions that vary smoothly over time. Repeated observations use a
subject-specific random intercept by default; `random_intercept = FALSE`
supports independent observations. The [reference
index](https://esrakurum.github.io/Bayesian-TDMM/reference/index.md)
documents fitting, priors, computational controls, plotting,
diagnostics, and data checks. The [Getting Started
guide](https://esrakurum.github.io/Bayesian-TDMM/articles/getting-started.md)
gives the introductory workflow.

For repeated observations, the model includes a subject-specific random
intercept:

\[g\{ E\lbrack Y_{i}(t) \mid b_{i}\rbrack\} = \beta_{0}(t) + \sum\limits_{k}X_{ik}(t)\beta_{k}(t) + b_{i}.\]

For independent observations, `random_intercept = FALSE` omits that
term:

\[g\{ E\lbrack Y_{i}(t)\rbrack\} = \beta_{0}(t) + \sum\limits_{k}X_{ik}(t)\beta_{k}(t).\]

Here \(g\) is the identity, logit, or log link for Gaussian, Bernoulli,
or Poisson outcomes, respectively. In independent-observation settings,
time may be age, time since an event, time relative to an event, or
another meaningful time scale. The curves describe how associations vary
across that time scale in the population; they do not by themselves
describe within-subject longitudinal change.

Cubic B-splines (degree 3, order 4), `n_basis = 8` by default, and a
second-order coefficient-difference penalty are used for both
specifications. `n_basis` directly specifies the number of basis
functions. The `nknots` argument remains available for existing calls;
use `n_basis` when specifying the basis dimension. Family-specific
priors can be inspected with `tdmm.priors()`.

The historical v0.1.0 source and documentation remain available through
the [v0.1.0 Git
tag](https://github.com/esrakurum/Bayesian-TDMM/tree/v0.1.0).
