# Produce coherent forecasts using the information combination method

The forecast function allows you to generate coherent future predictions
for hierarchical or grouped time series based on fitted models.

## Usage

``` r
# S3 method for class 'lst_icomb_mdl'
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

tourism_gts <- tourism |>
  aggregate_key(State * Purpose,
                Trips = sum(Trips))

fit <- tourism_gts |>
  model(base = ETS(Trips)) |>
  reconcile(ols = min_trace(base, method = "ols"),
            icomb = icomb(base, train_size = 75))
fit |>
  forecast(bootstrap = TRUE, times = 1000) |>
  hilo(level = c(80, 95))
#> # A tsibble: 1,080 x 8 [1Q]
#> # Key:       State, Purpose, .model [135]
#> Loading required namespace: crayon
#>    State  Purpose  .model Quarter        Trips .mean
#>    <chr*> <chr*>   <chr>    <qtr>       <dist> <dbl>
#>  1 ACT    Business base   2018 Q1 sample[1000]  145.
#>  2 ACT    Business base   2018 Q2 sample[1000]  203.
#>  3 ACT    Business base   2018 Q3 sample[1000]  197.
#>  4 ACT    Business base   2018 Q4 sample[1000]  191.
#>  5 ACT    Business base   2019 Q1 sample[1000]  142.
#>  6 ACT    Business base   2019 Q2 sample[1000]  204.
#>  7 ACT    Business base   2019 Q3 sample[1000]  197.
#>  8 ACT    Business base   2019 Q4 sample[1000]  189.
#>  9 ACT    Business ols    2018 Q1 sample[1000]  173.
#> 10 ACT    Business ols    2018 Q2 sample[1000]  237.
#> # ℹ 1,070 more rows
#> # ℹ 2 more variables: `80%` <hilo>, `95%` <hilo>
```
