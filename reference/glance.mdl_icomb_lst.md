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

tourism_hts <- tourism |>
  aggregate_key(State,
                Trips = sum(Trips))

fit <- tourism_hts |>
  model(base = ETS(Trips)) |>
  reconcile(ols = min_trace(base, method = "ols"),
            icomb = icomb(base, train_size = 75))

fit |>
  glance()
#> # A tibble: 27 × 11
#>    State          .model  sigma2 log_lik   AIC  AICc   BIC    MSE   AMSE     MAE
#>    <chr*>         <chr>    <dbl>   <dbl> <dbl> <dbl> <dbl>  <dbl>  <dbl>   <dbl>
#>  1 ACT          … base   1.56e-2   -504. 1019. 1020. 1031.  3704. 3.75e3 9.78e-2
#>  2 ACT          … ols    1.56e-2   -504. 1019. 1020. 1031.  3704. 3.75e3 9.78e-2
#>  3 ACT          … icomb  1.56e-2   -504. 1019. 1020. 1031.  3704. 3.75e3 9.78e-2
#>  4 New South Wal… base   9.70e+4   -631. 1277. 1278. 1294. 89711. 1.09e5 2.43e+2
#>  5 New South Wal… ols    9.70e+4   -631. 1277. 1278. 1294. 89711. 1.09e5 2.43e+2
#>  6 New South Wal… icomb  9.70e+4   -631. 1277. 1278. 1294. 89711. 1.09e5 2.43e+2
#>  7 Northern Terr… base   2.77e-2   -492.  999. 1000. 1016.  3327. 3.78e3 1.17e-1
#>  8 Northern Terr… ols    2.77e-2   -492.  999. 1000. 1016.  3327. 3.78e3 1.17e-1
#>  9 Northern Terr… icomb  2.77e-2   -492.  999. 1000. 1016.  3327. 3.78e3 1.17e-1
#> 10 Queensland   … base   9.81e+4   -632. 1278. 1279. 1294. 90738. 9.98e4 2.37e+2
#> # ℹ 17 more rows
#> # ℹ 1 more variable: .included <lgl>
```
