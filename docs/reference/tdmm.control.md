# Computational controls for TDMM fits

Construct a named computational control list for `tdmm()`.
`tdmm.control()` is retained as an alias of `tdmm_control()`. A partial
named list can also be passed directly.

## Usage

``` r
tdmm.control(chains = 3L, iterations = 10000L, burn_in = 3000L,
  thin = 5L, adapt = 5000L, seed = NULL, cores = NULL,
  parallel = FALSE)
tdmm_control(chains = 3L, iterations = 10000L, burn_in = 3000L,
  thin = 5L, adapt = 5000L, seed = NULL, cores = NULL,
  parallel = FALSE)
```

## Arguments

  - chains:

    Number of independent MCMC chains.

  - iterations:

    Total iterations per chain, including burn-in.

  - burn\_in:

    Burn-in iterations per chain. Must be less than iterations.

  - thin:

    Posterior thinning interval.

  - adapt:

    JAGS adaptation iterations.

  - seed:

    Optional nonnegative integer seed for the fitter.

  - cores:

    Optional positive integer core count when parallel execution is
    enabled.

  - parallel:

    Use separate chains on forked workers when `TRUE`.

## Details

Individual MCMC arguments remain available. Supplying the same setting
in both places is an error. An omitted control list retains the serial
defaults; the `tdmm.parallel()` compatibility wrapper retains its
existing adaptation default. Parallel execution uses macOS/Linux forked
workers. Evaluation and plotting grids are selected by `plot()` or
`plot.tdmm()`, rather than by fitting control. Setting a seed affects
the R random-number generator.

## Value

A named list of computational settings.

## Examples

``` r
tdmm.control(chains = 3, iterations = 10000, burn_in = 3000,
  seed = 218)
#> $chains
#> [1] 3
#>
#> $iterations
#> [1] 10000
#>
#> $burn_in
#> [1] 3000
#>
#> $thin
#> [1] 5
#>
#> $adapt
#> [1] 5000
#>
#> $seed
#> [1] 218
#>
#> $cores
#> NULL
#>
#> $parallel
#> [1] FALSE
#>
```
