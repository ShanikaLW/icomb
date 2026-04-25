# Calculate a sequence of penalty parameters

Generates a decreasing sequence of regularization parameters for
penalized multivariate regression by estimating the maximum lambda from
the data and constructing a log-spaced path to a minimum value, with
options for standardization and handling of zero-variance predictors and
responses.

## Usage

``` r
lambda_path(
  x,
  y,
  alpha = 1,
  standardize = FALSE,
  standardize_response = FALSE,
  intercept = TRUE,
  lambda_min_ratio = "expand",
  nlambda = 100
)
```

## Arguments

- x:

  Input matrix, of dimension nobs x nvars; each row is an observation
  vector. `nvars` should be greater than one. In other words `x` should
  have 2 or more columns. `x` can be in the sparse matrix format
  (inherit from class "`sparseMatrix`" as in package `Matrix`).

- y:

  A matrix of quantitative responses.

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

## Value

A sequence of penalty parameters

## Author

Shanika L Wickramasuriya

## Examples

``` r
set.seed(2024)
n <- 100
p <- 50
k <- 2
x <- matrix(rnorm(n * p), ncol = p)
y <- matrix(rnorm(n * k), ncol = k)
glmnet::glmnet(x, y, family = "mgaussian", standardize = FALSE,
               standardize.response = FALSE, intercept = TRUE)$lambda
#>  [1] 0.2509154454 0.2286248088 0.2083144109 0.1898083328 0.1729462836
#>  [6] 0.1575822125 0.1435830430 0.1308275212 0.1192051648 0.1086153065
#> [11] 0.0989662220 0.0901743356 0.0821634962 0.0748643176 0.0682135780
#> [16] 0.0621536717 0.0566321108 0.0516010702 0.0470169733 0.0428401150
#> [21] 0.0390343173 0.0355666161 0.0324069759 0.0295280295 0.0269048408
#> [26] 0.0245146889 0.0223368715 0.0203525254 0.0185444631 0.0168970241
#> [31] 0.0153959391 0.0140282063 0.0127819791 0.0116464633 0.0106118236
#> [36] 0.0096690984 0.0088101224 0.0080274554 0.0073143184 0.0066645345
#> [41] 0.0060724756 0.0055330136 0.0050414759 0.0045936051 0.0041855219
#> [46] 0.0038136917 0.0034748938 0.0031661938 0.0028849179 0.0026286297
#> [51] 0.0023951095 0.0021823346 0.0019884620 0.0018118125 0.0016508561
#> [56] 0.0015041986 0.0013705697 0.0012488121 0.0011378711 0.0010367857
#> [61] 0.0009446805 0.0008607577 0.0007842904 0.0007146162 0.0006511317
#> [66] 0.0005932869 0.0005405809 0.0004925572
lambda_path(x, y, lambda_min_ratio = "glmnet")
#>   [1] 2.509154e-01 2.286248e-01 2.083144e-01 1.898083e-01 1.729463e-01
#>   [6] 1.575822e-01 1.435830e-01 1.308275e-01 1.192052e-01 1.086153e-01
#>  [11] 9.896622e-02 9.017434e-02 8.216350e-02 7.486432e-02 6.821358e-02
#>  [16] 6.215367e-02 5.663211e-02 5.160107e-02 4.701697e-02 4.284012e-02
#>  [21] 3.903432e-02 3.556662e-02 3.240698e-02 2.952803e-02 2.690484e-02
#>  [26] 2.451469e-02 2.233687e-02 2.035253e-02 1.854446e-02 1.689702e-02
#>  [31] 1.539594e-02 1.402821e-02 1.278198e-02 1.164646e-02 1.061182e-02
#>  [36] 9.669098e-03 8.810122e-03 8.027455e-03 7.314318e-03 6.664534e-03
#>  [41] 6.072476e-03 5.533014e-03 5.041476e-03 4.593605e-03 4.185522e-03
#>  [46] 3.813692e-03 3.474894e-03 3.166194e-03 2.884918e-03 2.628630e-03
#>  [51] 2.395110e-03 2.182335e-03 1.988462e-03 1.811813e-03 1.650856e-03
#>  [56] 1.504199e-03 1.370570e-03 1.248812e-03 1.137871e-03 1.036786e-03
#>  [61] 9.446805e-04 8.607577e-04 7.842904e-04 7.146162e-04 6.511317e-04
#>  [66] 5.932869e-04 5.405809e-04 4.925572e-04 4.487998e-04 4.089297e-04
#>  [71] 3.726015e-04 3.395006e-04 3.093403e-04 2.818594e-04 2.568197e-04
#>  [76] 2.340046e-04 2.132163e-04 1.942747e-04 1.770159e-04 1.612903e-04
#>  [81] 1.469617e-04 1.339060e-04 1.220102e-04 1.111711e-04 1.012950e-04
#>  [86] 9.229623e-05 8.409689e-05 7.662595e-05 6.981871e-05 6.361621e-05
#>  [91] 5.796472e-05 5.281530e-05 4.812333e-05 4.384819e-05 3.995283e-05
#>  [96] 3.640353e-05 3.316955e-05 3.022285e-05 2.753794e-05 2.509154e-05
```
