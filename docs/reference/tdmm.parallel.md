# Legacy parallel TDMM fitting wrapper

Compatibility wrapper that delegates to tdmm() with parallel execution
selected.

## Usage

``` r
tdmm.parallel(data, family = c("gaussian", "bernoulli", "poisson"), nknots = NULL, subject.var = "subject.ID", 
    time.var = "time", y.var = "y", x.var = NULL, degree = 3, n.chains = 3, n.iter = 10000, n.burn = 3000, 
    n.thin = 5, n.adapt = 10000, n.cores = min(n.chains, parallel::detectCores()), jags.dir = NULL, quiet = FALSE, 
    seed = NULL, n_basis = NULL, control = NULL, priors = NULL)
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

  - n.cores:
    
    Legacy number of parallel cores; prefer control.

  - jags.dir:
    
    Legacy model-directory override for compatibility; ordinary users
    should leave this NULL.

  - quiet:
    
    Suppress JAGS progress output when TRUE.

  - seed:
    
    Legacy random seed; prefer control.

  - n\_basis:
    
    Actual number of B-spline basis functions. Omission resolves to 8.

  - control:
    
    Optional list from tdmm\_control() controlling chains, iterations,
    burn-in, thinning, adaptation, seed, parallel execution, and cores.

  - priors:
    
    Optional family-specific list, normally obtained from
    tdmm.priors(family) and modified by the user.

## Details

For new analyses, call tdmm() with control = tdmm\_control(parallel =
TRUE, cores = ...). This wrapper retains legacy arguments and delegates
data checking, model fitting, and output construction to tdmm().

## Value

A fitted object of class "tdmm".

## See also

`tdmm`

## Examples

``` r
if (FALSE) { # \dontrun{
## my_long_data is a long-format data frame; see the tdmm() example.
fit <- tdmm.parallel(my_long_data, family = "gaussian",
                     subject.var = "id", time.var = "time", y.var = "y",
                     x.var = "baseline", n.cores = 2)
} # }
```
