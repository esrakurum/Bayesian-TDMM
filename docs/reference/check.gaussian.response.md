# Check a numeric Gaussian response.

Check a numeric Gaussian response.

## Usage

``` r
check.gaussian.response(data, y.var = "y", time.var = "time")
```

## Arguments

  - data:
    
    Long-format data frame.

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
