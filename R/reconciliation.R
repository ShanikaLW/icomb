#' Information combination reconciliation
#'
#' @param models A column of models in a mable.
#' @param train_size  The size of the initial training window.
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
#' @importFrom tsibble index_var interval
#' @importFrom purrr map map2 exec reduce
#' @importFrom dplyr full_join
#' @importFrom fabletools response distribution_var
#'
#' @returns A 'global' model which is icomb coherent
#' @export
#'
icomb <- function(models, train_size, alpha = 1, standardize = FALSE,
                  standardize_response = FALSE, intercept = TRUE, lambda = NULL,
                  lambda_min_ratio = "expand",
                  nlambda = 100, maxit = 1e+07, exact = TRUE){

  # gets univariate fitted and actual values
  fitted <- map(models, function(x) fitted(x))
  fitted <- unname(as.matrix(reduce(fitted, full_join, by = index_var(fitted[[1]]))[, -1]))
  actual <- map(models, function(x) response(x))
  actual <- unname(as.matrix(reduce(actual, full_join, by = index_var(actual[[1]]))[, -1]))

  # fit icomb
  icomb_fit <- cv_icomb(fitted = fitted, actual = actual, train_size = train_size, alpha = alpha,
                        standardize = standardize, standardize_response = standardize_response,
                        intercept = intercept, lambda = lambda, lambda_min_ratio = lambda_min_ratio,
                        nlambda = nlambda, maxit = maxit)

  # return a 'global' model which is icomb coherent
  structure(models, class = c("lst_icomb_mdl", "lst_mdl", "list"),
            alpha = alpha, standardize = standardize, standardize_response = standardize_response,
            intercept = intercept, lambda = lambda, lambda_min_ratio = lambda_min_ratio,
            nlambda = nlambda, maxit = maxit, icombfit = icomb_fit, exact = exact)
}

#' @export
forecast.lst_icomb_mdl <- function(object, new_data = NULL, h = NULL,
                                   point_forecast = list(.mean = mean), ...){

  fc <- NextMethod()
  point_method <- point_forecast

  reconcile_icomb_list(fc, object, point_forecast = point_method)
}

# from the fabletools package (internal function)
compute_point_forecasts <- function(distribution, measures){
  map(measures, calc, distribution)
}

calc <- function(f, ...){
  f(...)
}

reconcile_icomb_list <- function (fc, object, point_forecast)
{
  if (length(unique(map(fc, interval))) > 1) {
    cli::cli_abort("Reconciliation of temporal hierarchies is not yet supported.")
  }
  fc_dist <- map(fc, function(x) x[[distribution_var(x)]])
  fc_mean <- as.matrix(exec(cbind, !!!map(fc_dist, mean)))

  models <- object
  fitted <- map(models, function(x) fitted(x))
  fitted <- unname(as.matrix(reduce(fitted, full_join, by = index_var(fitted[[1]]))[, -1]))
  xsd <- sqrt(colMeans(scale(fitted, center = TRUE, scale = FALSE)^2))
  xconst_var <- xsd < sqrt(.Machine$double.eps) # constant predictors
  exact <- attr(object, "exact")
  icomb_fit <- attr(object, "icombfit")
  fit <- icomb_fit$fit
  lambda_best <- icomb_fit$info$lambda_info["lambda_best"]

  fc_mean <- t(as.matrix(predict(fit, newx = fc_mean[, !xconst_var, drop = FALSE],
                                 s = lambda_best,
                                 exact = exact)[, , 1]))

  fc_mean <- split(fc_mean, row(fc_mean))
  # The 'distribution' is degenerate (no variance): use distributional::dist_degenerate(<means>)
  fc_dist <- map(fc_mean, distributional::dist_degenerate)

  map2(fc, fc_dist, function(fc, dist) {
    dimnames(dist) <- dimnames(fc[[distribution_var(fc)]])
    fc[[distribution_var(fc)]] <- dist
    point_fc <- compute_point_forecasts(dist, point_forecast)
    fc[names(point_fc)] <- point_fc
    fc
  })
}
