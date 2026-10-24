# Check TDMM long-format input structure

Check required columns, data types, missingness, repeated measurements,
and covariate structure before model fitting.

## Usage

``` r
check.tdmm.data.structure(data, subject.var = "subject.ID", time.var = "time", y.var = "y", x.var = NULL, stop.on.fail = TRUE)
```

## Arguments

  - data:
    
    Long-format data frame.

  - subject.var:
    
    Subject ID column name.

  - time.var:
    
    Numeric observation-time column name.

  - y.var:
    
    Response column name.

  - x.var:
    
    Numeric covariate column names; NULL selects remaining columns.

  - stop.on.fail:
    
    If TRUE, stop on invalid data; otherwise return diagnostics.

## Value

A list of data-check diagnostics and selected covariates; invalid input
raises an error when stop.on.fail is TRUE.

## See also

`tdmm`

## Examples

``` r
d <- data.frame(subject.ID = rep(1:3, each = 3),
                time = rep(c(0, 0.5, 1), 3), y = rnorm(9), x = rnorm(9))
check.tdmm.data.structure(d, x.var = "x")
#> $required.columns
#> [1] "subject.ID" "time"       "y"          "x"         
#> 
#> $missing.counts
#> subject.ID       time          y          x 
#>          0          0          0          0 
#> 
#> $has.missing
#> [1] FALSE
#> 
#> $subject.balance
#> $subject.balance$n.subject
#> [1] 3
#> 
#> $subject.balance$min.obs.per.subject
#> [1] 3
#> 
#> $subject.balance$max.obs.per.subject
#> [1] 3
#> 
#> $subject.balance$mean.obs.per.subject
#> [1] 3
#> 
#> $subject.balance$obs.per.subject
#> 
#> 1 2 3 
#> 3 3 3 
#> 
#> $subject.balance$balanced
#> [1] TRUE
#> 
#> $subject.balance$common.time.grid
#> [1] TRUE
#> 
#> $subject.balance$time.grid
#> [1] 0.0 0.5 1.0
#> 
#> $subject.balance$time.by.subject
#> $subject.balance$time.by.subject$`1`
#> [1] 0.0 0.5 1.0
#> 
#> $subject.balance$time.by.subject$`2`
#> [1] 0.0 0.5 1.0
#> 
#> $subject.balance$time.by.subject$`3`
#> [1] 0.0 0.5 1.0
#> 
#> 
#> 
#> $x.var
#> [1] "x"
#> 
#> $p
#> [1] 1
#> 
#> $x.constant.within.subject
#> [1] FALSE
#> 
#> $covariate.numeric
#>    x 
#> TRUE 
#> 
#> $covariate.variation
#> $covariate.variation$x.constant.by.variable
#>     x 
#> FALSE 
#> 
#> $covariate.variation$x.unique.by.subject
#> $covariate.variation$x.unique.by.subject$x
#> 1 2 3 
#> 3 3 3 
#> 
#> 
#> $covariate.variation$baseline.covariates
#> character(0)
#> 
#> $covariate.variation$time.varying.covariates
#> [1] "x"
#> 
#> $covariate.variation$has.time.varying.covariates
#> [1] TRUE
#> 
#> 
#> $x.constant.by.variable
#>     x 
#> FALSE 
#> 
#> $x.unique.by.subject
#> $x.unique.by.subject$x
#> 1 2 3 
#> 3 3 3 
#> 
#> 
#> $baseline.covariates
#> character(0)
#> 
#> $time.varying.covariates
#> [1] "x"
#> 
#> $has.time.varying.covariates
#> [1] TRUE
#> 
#> $ordered.by.subject.time
#> [1] TRUE
#> 
```
