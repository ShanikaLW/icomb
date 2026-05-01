# Glance a mable which contains an information combination reconciliation method

It uses the models within a mable to produce a one row summary
statistics of their fits.

## Usage

``` r
# S3 method for class 'mdl_icomb_lst'
glance(x, ...)
```

## Arguments

- x:

  A mable

- ...:

  Arguments for model methods

## Value

The tibble contains the output of
[`glance()`](https://generics.r-lib.org/reference/glance.html) for that
model, with an added logical column `.included` indicating whether the
corresponding node is present in the reconciliation process when the
information combination method is used.

## Examples

``` r
# \donttest{
library(fable)
library(fabletools)
library(tsibble)
library(dplyr)
#> 
#> Attaching package: ‘dplyr’
#> The following objects are masked from ‘package:stats’:
#> 
#>     filter, lag
#> The following objects are masked from ‘package:base’:
#> 
#>     intersect, setdiff, setequal, union

tourism_gts <- tourism |>
  aggregate_key(State * Purpose,
                Trips = sum(Trips))

fit <- tourism_gts |>
  model(base = ETS(Trips)) |>
  reconcile(ols = min_trace(base, method = "ols"),
            icomb = icomb(base, train_size = 75))

fit |>
  glance()
#> # A tibble: 135 × 12
#>    State  Purpose  .model sigma2 log_lik   AIC  AICc   BIC   MSE  AMSE
#>    <chr*> <chr*>   <chr>   <dbl>   <dbl> <dbl> <dbl> <dbl> <dbl> <dbl>
#>  1 ACT    Business base   0.0540   -453.  919.  921.  936. 1069. 1071.
#>  2 ACT    Business ols    0.0540   -453.  919.  921.  936. 1069. 1071.
#>  3 ACT    Business icomb  0.0540   -453.  919.  921.  936. 1069. 1071.
#>  4 ACT    Holiday  base   0.0680   -463.  940.  941.  956. 1509. 1538.
#>  5 ACT    Holiday  ols    0.0680   -463.  940.  941.  956. 1509. 1538.
#>  6 ACT    Holiday  icomb  0.0680   -463.  940.  941.  956. 1509. 1538.
#>  7 ACT    Other    base   0.202    -376.  759.  759.  766.  154.  156.
#>  8 ACT    Other    ols    0.202    -376.  759.  759.  766.  154.  156.
#>  9 ACT    Other    icomb  0.202    -376.  759.  759.  766.  154.  156.
#> 10 ACT    Visiting base   0.0305   -450.  905.  905.  912.  965. 1038.
#> # ℹ 125 more rows
#> # ℹ 2 more variables: MAE <dbl>, .included <lgl>
# }
```
