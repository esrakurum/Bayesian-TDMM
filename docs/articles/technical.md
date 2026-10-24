# Technical documentation

TDMM models longitudinal outcomes using time-varying coefficient
functions and a subject-specific random intercept. The [reference
index](https://esrakurum.github.io/Bayesian-TDMM/reference/index.md)
documents fitting, priors, computational controls, plotting,
diagnostics, and data checks. The [Getting Started
guide](https://esrakurum.github.io/Bayesian-TDMM/articles/getting-started.md)
gives the full introductory workflow.

New fits use cubic B-splines (degree 3, order 4), `n_basis = 8` by
default, and a second-order coefficient-difference penalty. `n_basis`
directly specifies the number of basis functions. The `nknots` argument
is retained for compatibility with older calls; use `n_basis` for new
work. Family-specific priors can be inspected with `tdmm.priors()`.

The historical v0.1.0 source and documentation remain available through
the [v0.1.0 Git
tag](https://github.com/esrakurum/Bayesian-TDMM/tree/v0.1.0).
