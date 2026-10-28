# Check a nonnegative integer Poisson response.

Check a nonnegative integer Poisson response.

## Usage

``` r
check.poisson.counts(data, y.var = "y", time.var = "time")
```

## Arguments

  - data:

    Data frame with one row per observation.

  - y.var:

    Response column name.

  - time.var:

    Numeric observation-time column name.

## Value

A family-specific response diagnostic list.

## See also

`check.tdmm.family.data`

## Examples

``` r
if (FALSE) { # \dontrun{
# For full input checking, use check.tdmm.family.data(data, family = "gaussian").
} # }
```
