# Produce coherent forecasts using the information combination method

The forecast function allows you to generate coherent future predictions
for hierarchical or grouped time series based on fitted models.

## Usage

``` r
# S3 method for class 'mdl_icomb_lst'
forecast(
  object,
  new_data = NULL,
  h = NULL,
  point_forecast = list(.mean = mean),
  ...
)
```

## Arguments

- object:

  The time series models used to produce the forecasts.

- new_data:

  A `tsibble` containing future information used to forecast.

- h:

  The forecast horizon (can be used instead of `new_data` for regular
  time series with no exogenous regressors).

- point_forecast:

  The point forecast measure(s) which should be returned in the
  resulting fable. Specify as a named list of functions which accept a
  distribution and return a vector.

- ...:

  Additional arguments for forecast model methods.

## Value

A fable containing the following columns:

- `.model`: The name of the model used to obtain the forecast. Taken
  from the column names of models in the provided mable.

- The forecast distribution. The name of this column will be the same as
  the dependent variable in the model(s). If multiple dependent
  variables exist, it will be named `.distribution`.

- Point forecasts computed from the distribution using the functions in
  the `point_forecast` argument. If `bootstrap = TRUE`, point forecasts
  are generated using bootstrapped sample paths.

## Details

The forecasts returned contain both point forecasts and their
distribution. A specific forecast interval can be extracted from the
distribution using the
[`distributional::hilo()`](https://pkg.mitchelloharawild.com/distributional/reference/hilo.html)
function. These intervals are stored in a single column using the `hilo`
class, to extract the numerical upper and lower bounds you can use
[`fabletools::unpack_hilo()`](https://fabletools.tidyverts.org/reference/unpack_hilo.html).

## Examples

``` r

library(fable)
#> Loading required package: fabletools
library(fabletools)
library(tsibble)
#> 
#> Attaching package: ‘tsibble’
#> The following objects are masked from ‘package:base’:
#> 
#>     intersect, setdiff, union
library(distributional)

tourism_hts <- tourism |>
  aggregate_key(State,
                Trips = sum(Trips))

fit <- tourism_hts |>
  model(base = ETS(Trips)) |>
  reconcile(ols = min_trace(base, method = "ols"),
            icomb = icomb(base, train_size = 75))
#> Warning: There were 2 warnings in `mutate()`.
#> The first warning was:
#> ℹ In argument: `icomb = icomb(base, train_size = 75)`.
#> Caused by warning in `.resolve_control()`:
#> ! Passing 'thresh' to glmnet() is deprecated. Use control = list(thresh = ...) instead.
#> ℹ Run `dplyr::last_dplyr_warnings()` to see the 1 remaining warning.

# \donttest{
fit |>
  forecast(bootstrap = TRUE, times = 1000) |>
  hilo(level = c(80, 95))
#> # A tsibble: 216 x 7 [1Q]
#> # Key:       State, .model [27]
#> Loading required namespace: crayon
#>    State  .model Quarter        Trips .mean                  `80%`
#>    <chr*> <chr>    <qtr>       <dist> <dbl>                 <hilo>
#>  1 ACT    base   2018 Q1 sample[1000]  703. [599.5647, 813.1174]80
#>  2 ACT    base   2018 Q2 sample[1000]  720. [609.7173, 835.1879]80
#>  3 ACT    base   2018 Q3 sample[1000]  737. [621.1969, 859.2365]80
#>  4 ACT    base   2018 Q4 sample[1000]  753. [638.0372, 869.9488]80
#>  5 ACT    base   2019 Q1 sample[1000]  765. [642.7770, 890.6511]80
#>  6 ACT    base   2019 Q2 sample[1000]  789. [667.6355, 908.2969]80
#>  7 ACT    base   2019 Q3 sample[1000]  802. [675.2354, 934.7294]80
#>  8 ACT    base   2019 Q4 sample[1000]  813. [679.5546, 943.1796]80
#>  9 ACT    ols    2018 Q1 sample[1000]  714. [537.2034, 887.3422]80
#> 10 ACT    ols    2018 Q2 sample[1000]  814. [629.9566, 991.8888]80
#> # ℹ 206 more rows
#> # ℹ 1 more variable: `95%` <hilo>
# }
```
