# Check TDMM data for an outcome family

Apply structural and family-specific response checks to long-format TDMM
data.

## Usage

``` r
check.tdmm.family.data(data, family = c("gaussian", "bernoulli", "poisson"), subject.var = "subject.ID", time.var = "time", 
    y.var = "y", x.var = NULL, stop.on.fail = TRUE)
```

## Arguments

  - data:
    
    Long-format data frame.

  - family:
    
    One of "gaussian", "bernoulli", or "poisson".

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
check.tdmm.family.data(d, family = "gaussian", x.var = "x")
#> $family
#> [1] "gaussian"
#> 
#> $covariates
#> [1] "x"
#> 
#> $p
#> [1] 1
#> 
#> $structure.check
#> $structure.check$required.columns
#> [1] "subject.ID" "time"       "y"          "x"         
#> 
#> $structure.check$missing.counts
#> subject.ID       time          y          x 
#>          0          0          0          0 
#> 
#> $structure.check$has.missing
#> [1] FALSE
#> 
#> $structure.check$subject.balance
#> $structure.check$subject.balance$n.subject
#> [1] 3
#> 
#> $structure.check$subject.balance$min.obs.per.subject
#> [1] 3
#> 
#> $structure.check$subject.balance$max.obs.per.subject
#> [1] 3
#> 
#> $structure.check$subject.balance$mean.obs.per.subject
#> [1] 3
#> 
#> $structure.check$subject.balance$obs.per.subject
#> 
#> 1 2 3 
#> 3 3 3 
#> 
#> $structure.check$subject.balance$balanced
#> [1] TRUE
#> 
#> $structure.check$subject.balance$common.time.grid
#> [1] TRUE
#> 
#> $structure.check$subject.balance$time.grid
#> [1] 0.0 0.5 1.0
#> 
#> $structure.check$subject.balance$time.by.subject
#> $structure.check$subject.balance$time.by.subject$`1`
#> [1] 0.0 0.5 1.0
#> 
#> $structure.check$subject.balance$time.by.subject$`2`
#> [1] 0.0 0.5 1.0
#> 
#> $structure.check$subject.balance$time.by.subject$`3`
#> [1] 0.0 0.5 1.0
#> 
#> 
#> 
#> $structure.check$x.var
#> [1] "x"
#> 
#> $structure.check$p
#> [1] 1
#> 
#> $structure.check$x.constant.within.subject
#> [1] FALSE
#> 
#> $structure.check$covariate.numeric
#>    x 
#> TRUE 
#> 
#> $structure.check$covariate.variation
#> $structure.check$covariate.variation$x.constant.by.variable
#>     x 
#> FALSE 
#> 
#> $structure.check$covariate.variation$x.unique.by.subject
#> $structure.check$covariate.variation$x.unique.by.subject$x
#> 1 2 3 
#> 3 3 3 
#> 
#> 
#> $structure.check$covariate.variation$baseline.covariates
#> character(0)
#> 
#> $structure.check$covariate.variation$time.varying.covariates
#> [1] "x"
#> 
#> $structure.check$covariate.variation$has.time.varying.covariates
#> [1] TRUE
#> 
#> 
#> $structure.check$x.constant.by.variable
#>     x 
#> FALSE 
#> 
#> $structure.check$x.unique.by.subject
#> $structure.check$x.unique.by.subject$x
#> 1 2 3 
#> 3 3 3 
#> 
#> 
#> $structure.check$baseline.covariates
#> character(0)
#> 
#> $structure.check$time.varying.covariates
#> [1] "x"
#> 
#> $structure.check$has.time.varying.covariates
#> [1] TRUE
#> 
#> $structure.check$ordered.by.subject.time
#> [1] TRUE
#> 
#> 
#> $response.check
#> $response.check$family
#> [1] "gaussian"
#> 
#> $response.check$overall
#> $response.check$overall$n
#> [1] 9
#> 
#> $response.check$overall$mean
#> [1] 0.0831636
#> 
#> $response.check$overall$sd
#> [1] 1.007282
#> 
#> $response.check$overall$min
#> [1] -1.304544
#> 
#> $response.check$overall$max
#> [1] 1.888505
#> 
#> 
#> $response.check$by.time
#>   time n       mean        sd        min        max
#> 1  0.0 3  0.9314842 0.8336790  0.3629513  1.8885049
#> 2  0.5 3 -0.7720212 0.6159595 -1.3045435 -0.0974451
#> 3  1.0 3  0.0900278 0.8986038 -0.9358474  0.7377763
#> 
#> 
```
