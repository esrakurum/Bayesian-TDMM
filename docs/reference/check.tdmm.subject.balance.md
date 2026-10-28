# Inspect observations per subject

Inspect observation counts and observation-time balance across subjects.

## Usage

``` r
check.tdmm.subject.balance(data, subject.var = "subject.ID", time.var = "time")
```

## Arguments

  - data:

    Data frame with one row per observation.

  - subject.var:

    Subject ID column name.

  - time.var:

    Numeric observation-time column name.

## Value

A diagnostic list describing observation-count and observation-time
balance.

## Examples

``` r
d <- data.frame(subject.ID = rep(1:3, each = 3), time = rep(1:3, 3))
check.tdmm.subject.balance(d)
#> $n.subject
#> [1] 3
#>
#> $min.obs.per.subject
#> [1] 3
#>
#> $max.obs.per.subject
#> [1] 3
#>
#> $mean.obs.per.subject
#> [1] 3
#>
#> $obs.per.subject
#>
#> 1 2 3
#> 3 3 3
#>
#> $balanced
#> [1] TRUE
#>
#> $common.time.grid
#> [1] TRUE
#>
#> $time.grid
#> [1] 1 2 3
#>
#> $time.by.subject
#> $time.by.subject$`1`
#> [1] 1 2 3
#>
#> $time.by.subject$`2`
#> [1] 1 2 3
#>
#> $time.by.subject$`3`
#> [1] 1 2 3
#>
#>
```
