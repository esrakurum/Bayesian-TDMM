# Fit a time-dynamic mixed-effects model

Fit Gaussian, Bernoulli, or Poisson longitudinal outcomes with
time-varying coefficient functions and subject-specific random
intercepts.

## Usage

``` r
tdmm(data, family = c("gaussian", "bernoulli", "poisson"), nknots = NULL, subject.var = "subject.ID", 
    time.var = "time", y.var = "y", x.var = NULL, degree = 3, n.chains = 3, n.iter = 10000, n.burn = 3000, 
    n.thin = 5, n.adapt = 5000, jags.dir = NULL, quiet = FALSE, n_basis = NULL, control = NULL, priors = NULL)
```

## Arguments

  - data:
    
    Long-format data frame: one row per observed subject and time.

  - family:
    
    One of "gaussian", "bernoulli", or "poisson".

  - nknots:
    
    Deprecated compatibility argument with its historical interval-count
    interpretation. Do not supply with n\_basis.

  - subject.var:
    
    Name of the subject ID column.

  - time.var:
    
    Name of the numeric observation-time column.

  - y.var:
    
    Name of the response column.

  - x.var:
    
    Names of numeric covariates, in coefficient order; NULL selects all
    columns other than subject ID, time, and response.

  - degree:
    
    B-spline polynomial degree; default 3 (cubic).

  - n.chains:
    
    Legacy number of chains; prefer control.

  - n.iter:
    
    Legacy total iterations; prefer control.

  - n.burn:
    
    Legacy burn-in iterations; prefer control.

  - n.thin:
    
    Legacy thinning interval; prefer control.

  - n.adapt:
    
    Legacy adaptation iterations; prefer control.

  - jags.dir:
    
    Legacy model-directory override for compatibility; ordinary users
    should leave this NULL.

  - quiet:
    
    Suppress JAGS progress output when TRUE.

  - n\_basis:
    
    Actual number of B-spline basis functions. Omission resolves to 8.

  - control:
    
    Optional list from tdmm\_control() controlling chains, iterations,
    burn-in, thinning, adaptation, seed, parallel execution, and cores.

  - priors:
    
    Optional family-specific list, normally obtained from
    tdmm.priors(family) and modified by the user.

## Details

Rows may have irregular subject-specific times and unequal visit counts.
Numeric covariates may be constant or change within subject. Coefficient
functions use an extended uniform B-spline basis with a second-order
coefficient-difference penalty. The default is cubic with eight basis
functions. Use tdmm\_control(parallel = TRUE, cores = ...) for parallel
chains. The coefficient functions are on the identity, logit, or log
link scale for Gaussian, Bernoulli, or Poisson responses, respectively.

## Value

A fitted object of class "tdmm" containing posterior samples,
reconstructed coefficient functions, input metadata, variance summaries,
and fitting settings.

## See also

`tdmm.control`, `tdmm.priors`, `summary.tdmm`, `plot.tdmm`

## Examples

``` r
if (FALSE) { # \dontrun{
# Requires JAGS and runs MCMC.
set.seed(42)
my_long_data <- do.call(rbind, lapply(seq_len(20), function(id) {
  time <- sort(runif(5))
  baseline <- rnorm(1)
  changing <- rnorm(5)
  data.frame(id = id, time = time, baseline = baseline,
             changing = changing,
             y = 0.5 + baseline * sin(2*pi*time) +
                 changing * (time - 0.5) + rnorm(5, sd = 0.3))
}))
fit <- tdmm(my_long_data, family = "gaussian", subject.var = "id",
            time.var = "time", y.var = "y", x.var = c("baseline", "changing"),
            control = tdmm_control(seed = 42))
summary(fit)
plot(fit)
} # }
```
