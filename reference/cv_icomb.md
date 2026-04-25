# Performs rolling forecast origin cross-validation for information combination

Implements rolling-origin cross-validation for penalized multivariate
regression within the Information Combination (IComb) framework,
selecting the optimal lambda based on out-of-sample 1-step-ahead
prediction error and returning the fitted model, coefficients, and
performance metrics.

## Usage

``` r
cv_icomb(
  fitted,
  actual,
  train_size,
  alpha = 1,
  standardize = FALSE,
  standardize_response = FALSE,
  intercept = TRUE,
  lambda = NULL,
  lambda_min_ratio = "expand",
  nlambda = 100,
  maxit = 1e+07,
  thresh = 1e-07,
  exact = TRUE
)
```

## Arguments

- fitted:

  A matrix of size nobs x nvars containing the fitted values.

- actual:

  A matrix containing the actual values.

- train_size:

  The size of the initial training window.

- alpha:

  The elasticnet mixing parameter, with \\0 \leq \alpha \leq 1\\. The
  penalty is defined as \$\$(1 - \alpha)/2\\B\\\_2^2 +
  \alpha\\B\\\_2\$\$ `alpha = 1` is the group lasso penalty, and
  `alpha = 0` is the ridge penalty.

- standardize:

  Logical flag for `x` variable standardization, prior to fitting the
  model sequence. The coefficients are always returned on the original
  scale. Default is `standardize = FALSE`.

- standardize_response:

  This allows the user to standardize the response variables. Default is
  `standardize_response = FALSE`.

- intercept:

  Should intercepts be fitted (default = TRUE) or set to zero (FALSE).

- lambda:

  A user supplied `lambda` sequence. Typical usage is to have the
  program compute its own `lambda` sequence based on `nlambda` and
  `lambda_min_ratio`. Supplying a value of `lambda` overrides this.
  Supply a decreasing sequence of `lambda` values.

- lambda_min_ratio:

  The smallest value for `lambda`, as a fraction of `lambda_max` (the
  data derived value for which all coefficients are zero).
  `lambda_min_ratio = "expand"` (default) sets the ratio as
  \\10^{-\lfloor \log\_{10}(\lambda\_{max})\rfloor-2}\\ whereas
  `lambda_min_ratio = "glmnet"` sets the ratio to the value used in the
  `glmnet` package. If `nobs < nvars`, the default is `0.01`, otherwise
  `1e-04`.

- nlambda:

  The number of lambda values. Default is 100.

- maxit:

  Maximum number of passes over the data for all lambda values. Default
  is \\10^7\\.

- thresh:

  Convergence threshold for coordinate descent. Each inner
  coordinate-descent loop continues until the maximum change in the
  objective after any coefficient update is less than thresh times the
  null deviance. Defaults value is 1e-07.

- exact:

  A logical flag indicating whether to use a sequence of lambda values
  (from `lambda_max` to `lambda_best`) when fitting the final model on
  the entire dataset. The functions in the `glmnet` package are designed
  for efficiency by computing the entire regularization path (a sequence
  of lambda values) using "warm starts", which is often faster than
  computing a single fit. The default is `TRUE`.

## Value

A list containing

- fit:

  An object of class `glmnet` fitted on the entire dataset.

- info:

  A vector containing `lambda_max`, `lambda_best`, and the index of
  `lambda_best` in the `lambda` sequence.

- coefs:

  Estimated coefficients corresponding to `lambda_best`.

## References

Nguyen, M., Vahid, F., & Wickramasuriya, S. L. (2025). Hierarchical
Forecasting: The Role of Information Combination (Working Paper No.
11/25). Department of Econometrics and Business Statistics, Monash
University. URL:
<https://www.monash.edu/business/ebs/research/publications/ebs/2025/wp11-2025.pdf>

## Author

Shanika L Wickramasuriya

## Examples

``` r
if (FALSE) { # \dontrun{
library(hts)
library(forecast)
set.seed(2024)
nodes <- list(2, c(2, 2))
bts <- matrix(, nrow = 100, ncol = 4)
for (i in 1:4) {
 bts[, i] <- arima.sim(list(order = c(1,0,0), ar = 0.7), n = 100)
}
eg_hts <- hts(bts, nodes)
ally <- allts(eg_hts)
fitted <- matrix(, nrow = 100, ncol = 7)
for (i in 1:7) {
 fit <- auto.arima(ally[, i])
 fitted[, i] <- fitted(fit)
}
out <- cv_icomb(fitted, ally, train_size = 70)
} # }
```
