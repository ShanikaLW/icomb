
<!-- README.md is generated from README.Rmd. Please edit that file -->

# icomb

<!-- badges: start -->

<!-- badges: end -->

The R package *icomb* provides tools for implementing the information
combination approach to forecasting hierarchical time series proposed by
Nguyen, Vahid and Wickramasuriya (2025).

It offers tools to construct and combine forecasts based on different
information sets, enabling improved forecast accuracy within
hierarchical and grouped time series structures.

## Installation

You can install the **development** version from
[GitHub](https://github.com/ShanikaLW/icomb)

``` r
# install.packages("pak")
pak::pak("ShanikaLW/icomb")
```

## Example

``` r
library(fable)
library(fabletools)
library(tsibble)
library(dplyr)
library(lubridate)
library(icomb)
library(ggtime)

tourism_hts <- tourism |>  
  aggregate_key(State * Purpose,
                Trips = sum(Trips)) 

tourism_hts |>  
  model(base = ETS(Trips)) |>  
  reconcile(ols = min_trace(base, method = "ols"),
            icomb = icomb(base, train_size = 75)) |>  
  forecast(h = "3 years") |>  
  filter(Purpose == "Holiday", State == "Victoria") |>  
  autoplot(filter(tourism_hts, Purpose == "Holiday", 
                  State == "Victoria", year(Quarter) > 2010), level = NULL)
```

<img src="man/figures/README-example-1.png" alt="" width="100%" />

This workflow can be parallelized to improve performance using the
`future` package. By specifying a parallelization plan via
`future::plan()` (e.g., `multisession` or `multicore`), users can
control how computations are distributed across available workers. This
allows the cross-validation procedure in the information combination
approach to run in parallel without modifying the core code, while
remaining flexible to different computing environments. If no plan is
set, the default sequential strategy is used, meaning computations are
performed one after another with no parallelization.

``` r
library(future)
plan(multisession, workers = 2)

tourism_hts |>  
  model(base = ETS(Trips)) |>  
  reconcile(ols = min_trace(base, method = "ols"),
            icomb = icomb(base, train_size = 75))  |>  
  forecast(h = "3 years") 
#> # A fable: 1,620 x 6 [1Q]
#> # Key:     State, Purpose, .model [135]
#> Loading required namespace: crayon
#>    State  Purpose  .model Quarter
#>    <chr*> <chr*>   <chr>    <qtr>
#>  1 ACT    Business base   2018 Q1
#>  2 ACT    Business base   2018 Q2
#>  3 ACT    Business base   2018 Q3
#>  4 ACT    Business base   2018 Q4
#>  5 ACT    Business base   2019 Q1
#>  6 ACT    Business base   2019 Q2
#>  7 ACT    Business base   2019 Q3
#>  8 ACT    Business base   2019 Q4
#>  9 ACT    Business base   2020 Q1
#> 10 ACT    Business base   2020 Q2
#> # ℹ 1,610 more rows
#> # ℹ 2 more variables: Trips <dist>, .mean <dbl>
plan(sequential)
```

## References

- Nguyen, M., Vahid, F., & Wickramasuriya, S. L. (2025). Hierarchical
  Forecasting: The Role of Information Combination (Working Paper
  No. 11/25). Department of Econometrics and Business Statistics, Monash
  University. URL:
  <https://www.monash.edu/business/ebs/research/publications/ebs/2025/wp11-2025.pdf>
