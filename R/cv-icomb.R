#' Performs rolling forecast origin cross-validation for information combination
#'
#' @param fitted A matrix of size nobs x nvars containing the fitted values.
#' @param actual A matrix containing the actual values.
#' @param train_size The size of the initial training window.
#' @param alpha The elasticnet mixing parameter, with \eqn{0 \leq \alpha \leq 1}. The penalty is defined as
#' \deqn{(1 - \alpha)/2\|B\|_2^2 + \alpha\|B\|_2}
#' `alpha = 1` is the group lasso penalty, and `alpha = 0` is the ridge penalty.
#' @param standardize Logical flag for `x` variable standardization, prior to fitting the model sequence.
#' The coefficients are always returned on the original scale. Default is `standardize = FALSE`.
#' @param standardize_response This allows the user to standardize the response variables.
#' Default is `standardize_response = FALSE`.
#' @param intercept Should intercepts be fitted (default = TRUE) or set to zero (FALSE).
#' @param lambda A user supplied `lambda` sequence. Typical usage is to have the program compute its own
#' `lambda` sequence based on `nlambda` and `lambda_min_ratio`. Supplying a value of `lambda` overrides this. Supply a decreasing
#' sequence of `lambda` values.
#' @param lambda_min_ratio The smallest value for `lambda`, as a fraction of `lambda_max`
#' (the data derived value for which all coefficients are zero). `lambda_min_ratio = "expand"` (default) sets the ratio as
#' \eqn{10^{-\lfloor \log_{10}(\lambda_{max})\rfloor-2}} whereas `lambda_min_ratio = "glmnet"` sets the ratio to the value used in the `glmnet` package.
#' If `nobs < nvars`, the default is `0.01`, otherwise `1e-04`.
#' @param nlambda The number of lambda values. Default is 100.
#' @param maxit Maximum number of passes over the data for all lambda values. Default is \eqn{10^7}.
#' @param exact A logical flag indicating whether to use a sequence of lambda values (from `lambda_max` to `lambda_best`)
#' when fitting the final model on the entire dataset.
#' The functions in the `glmnet` package are designed for efficiency by computing the entire regularization path
#' (a sequence of lambda values) using "warm starts", which is often faster than computing a single fit. The default is `TRUE`.
#' @importFrom glmnet glmnet
#' @importFrom future.apply future_sapply
#' @importFrom stats coef predict
#'
#' @returns A list containing
#' \item{fit}{An object of class `glmnet` fitted on the entire dataset.}
#' \item{info}{A vector containing `lambda_max`, `lambda_best`, and the index of `lambda_best` in the `lambda` sequence.}
#' \item{coefs}{Estimated coefficients corresponding to `lambda_best`.}
#' @export
#'
#' @examples
#' library(hts)
#' library(forecast)
#' set.seed(2024)
#' nodes <- list(2, c(2, 2))
#' bts <- matrix(, nrow = 100, ncol = 4)
#' for (i in 1:4) {
#'  bts[, i] <- arima.sim(list(order = c(1,0,0), ar = 0.7), n = 100)
#' }
#' eg_hts <- hts(bts, nodes)
#' ally <- allts(eg_hts)
#' fitted <- matrix(, nrow = 100, ncol = 7)
#' for (i in 1:7) {
#'  fit <- auto.arima(ally[, i])
#'  fitted[, i] <- fitted(fit)
#'}
#' out <- cv_icomb(fitted, ally, train_size = 70)
cv_icomb <- function (fitted, actual, train_size, alpha = 1, standardize = FALSE,
                      standardize_response = FALSE, intercept = TRUE, lambda = NULL,
                      lambda_min_ratio = "expand",
                      nlambda = 100, maxit = 1e+07, exact = TRUE) {
  dimx <- dim(fitted)
  if (is.null(dimx) | (dimx[2] <= 1))
    cli::cli_abort("{.var fitted} should be a matrix with 2 or more columns")
  if (any(is.na(fitted)))
    cli::cli_abort("{.var fitted} has missing values")
  nobs <- dimx[1]
  nvars <- dimx[2]

  dimy <- dim(actual)
  if (is.null(dimy) | (dimy[2] <= 1))
    cli::cli_abort("{.var actual} should be a matrix with 2 or more columns")
  if (any(is.na(actual)))
    cli::cli_abort("{.var actual} has missing values")

  if (dimy[1] != dimx[1])
    cli::cli_abort("number of observations in {.var actual} and {.var fitted} does not match")

  if (train_size > dimx[1])
    cli::cli_abort("number of training observations should be less than that for actual/fitted")

  if (lambda_min_ratio >= 1 & is.numeric(lambda_min_ratio))
    cli::cli_abort("lambda_min_ratio should be less than 1")

  if (alpha > 1) {
    cli::cli_warn("{.var alpha} > 1; set to 1")
    alpha <- 1
  }

  if (alpha < 0) {
    cli::cli_warn("{.var alpha} < 0; set to 0")
    alpha <- 0
  }

  if (is.null(lambda))
    lambda <- lambda_path(fitted, actual, alpha, standardize, standardize_response, intercept, lambda_min_ratio, nlambda)

  niter <- nobs - train_size
  test <- actual[(train_size + 1):nobs, ]
  ysd_all <- array(, dim = c(niter, dimy[2]))

  recon_list <- future_sapply(1:niter, function(i) {
    train_set <- 1:(train_size + i - 1)
    xdata <- fitted[train_set, ]
    ydata <- actual[train_set, ]

    xsd <- sqrt(colMeans(scale(xdata, center = TRUE, scale = FALSE)^2))
    xconst_var <- xsd < sqrt(.Machine$double.eps) # constant predictors

    ysd <- ysd_all[i, ] <- sqrt(colMeans(scale(ydata, center = TRUE, scale = FALSE)^2))
    yconst_var <- ysd < sqrt(.Machine$double.eps) # constant responses

    if (any(yconst_var)) {
      cli::cli_warn("There are constant responses.")

      if (standardize_response)
        ydata <- ydata[, !yconst_var]
    }

    fit <- glmnet(xdata[, !xconst_var], ydata, family = "mgaussian", standardize = standardize,
                  standardize.response = standardize_response, intercept = intercept, alpha = alpha, lambda = lambda, maxit = maxit)
    predict(fit, newx = fitted[train_size + i, !xconst_var, drop = FALSE])
  }, future.seed = TRUE)
  recon <- array(t(recon_list), dim = c(niter, dimy[2], length(lambda)))
  err <- sweep(recon, 1:2, test)

  mse <- colMeans(colMeans(err^2))
  mse_over_response <- apply(err^2, c(1, 3), mean)

  idx_min <- which.min(mse)
  lambda_best <- lambda[idx_min]

  lambda_info <- c(lambda_max = max(lambda), lambda_best = lambda_best,
                   lambda_best_idx = idx_min)

  xsd <- sqrt(colMeans(scale(fitted, center = TRUE, scale = FALSE)^2))
  xconst_var <- xsd < sqrt(.Machine$double.eps) # constant predictors

  ysd <- sqrt(colMeans(scale(actual, center = TRUE, scale = FALSE)^2))
  yconst_var <- ysd < sqrt(.Machine$double.eps) # constant responses

  if (any(yconst_var)) {
    cli::cli_warn("There are constant responses.")

    if (standardize_response)
      actual <- actual[, !yconst_var]
  }

  if (!exact) {
    fit <- glmnet(fitted[, !xconst_var], actual, family = "mgaussian", standardize = standardize,
                  standardize.response = standardize_response, intercept = intercept, alpha = alpha,
                  lambda = lambda_best, maxit = maxit)
    coefs <- coef(fit)
    best_coef <- sapply(coefs, function(x) x[, idx_min])
    list(fit = fit,
         info = list(lambda_info = lambda_info, mse_info = mse, nnzeros = fit$dfmat[1, 1]),
         coefs = best_coef)
  } else {
    lambda_subset <- lambda[lambda >= lambda_best]
    fit <- glmnet(fitted[, !xconst_var], actual, family = "mgaussian", standardize = standardize,
                  standardize.response = standardize_response, intercept = intercept, alpha = alpha,
                  lambda = lambda_subset, maxit = maxit)
    coefs <- coef(fit)
    best_coef <- sapply(coefs, function(x) x[, idx_min])
    list(fit = fit,
         info = list(lambda_info = lambda_info, mse_info = mse, nnzeros = fit$dfmat[1, idx_min]),
         coefs = best_coef)
  }
}
