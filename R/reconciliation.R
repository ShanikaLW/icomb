#' Information combination reconciliation
#'
#' Implements the Information Combination (IComb) method for forecast reconciliation,
#' combining information from multiple base forecasts through a regression-based framework
#' that can be estimated using penalized regression techniques. The penalty parameter is estimated
#' using the rolling forecast origin cross-validation.
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
#'
#' @seealso [`reconcile()`], [`aggregate_key()`]
#' @importFrom tsibble index_var interval
#' @importFrom purrr map map2 exec reduce map_chr
#' @importFrom dplyr full_join
#' @importFrom fabletools response distribution_var
#' @importFrom vctrs vec_data
#'
#' @returns A 'global' model which is icomb coherent
#' @author Shanika L Wickramasuriya
#' @references Nguyen, M., Vahid, F., & Wickramasuriya, S. L. (2025).
#' Hierarchical Forecasting: The Role of Information Combination (Working Paper No. 11/25).
#' Department of Econometrics and Business Statistics, Monash University.
#' URL: \url{https://www.monash.edu/business/ebs/research/publications/ebs/2025/wp11-2025.pdf}
#' @export
#'
#' @examples
#' library(fable)
#' library(fabletools)
#' library(tsibble)
#' library(dplyr)
#' library(lubridate)
#' library(ggtime)
#'
#' tourism_hts <- tourism |>
#'   aggregate_key(State * Purpose,
#'                 Trips = sum(Trips))
#'
#' fit <- tourism_hts |>
#'   model(base = ETS(Trips)) |>
#'   reconcile(ols = min_trace(base, method = "ols"),
#'             icomb = icomb(base, train_size = 75))
#' fit |>
#'   forecast(h = "3 years")
#'
#' # extracting results from cross-validation
#' fit |>
#'   pull(icomb) |>
#'   attr("icombfit")
#'
#' # Parallelizing cross-validation
#' library(future)
#' plan(multisession, workers = 2)
#'
#' tourism_hts |>
#'   model(base = ETS(Trips)) |>
#'   reconcile(ols = min_trace(base, method = "ols"),
#'             icomb = icomb(base, train_size = 75)) |>
#'   forecast(h = "3 years")
#' plan(sequential)
#'
#'# Extracting probabilistic forecasts
#' fit |>
#'   forecast(h = "3 years", bootstrap = TRUE, times = 1000) |>
#'   filter(Purpose == "Holiday", State == "Victoria") |>
#'   autoplot(filter(tourism_hts, Purpose == "Holiday",
#'                   State == "Victoria", year(Quarter) > 2010))
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

dist_types <- function (dist) {
  map_chr(vec_data(dist), function(x) class(x)[1])
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

  actual <- map(models, function(x) response(x))
  actual <- unname(as.matrix(reduce(actual, full_join, by = index_var(actual[[1]]))[, -1]))
  mask <- complete.cases(fitted) & complete.cases(actual)

  xsd <- sqrt(colMeans(scale(fitted[mask, ], center = TRUE, scale = FALSE)^2))
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
  # fc_dist <- map(fc_mean, distributional::dist_degenerate) # uncomment this if below doesn't work

  fc_dist <- map(fc, function(x) x[[distribution_var(x)]])
  dist_type <- lapply(fc_dist, function(x) dist_types(x))
  dist_type <- unique(unlist(dist_type))
  reconcile_icomb_paths <- function(x) {
    t(as.matrix(predict(fit, newx = x[, !xconst_var, drop = FALSE],
                        s = lambda_best,
                        exact = exact)[, , 1]))
  }

  if (identical(dist_type, "dist_sample")) {
    sample_size <- unique(unlist(lapply(fc_dist, function(x) unique(lengths(distributional::parameters(x)$x)))))
    if (length(sample_size) != 1L)
      cli::cli_abort("Cannot reconcile sample paths with different replication sizes.")

    sample_horizon <- unique(lengths(fc_dist))
    if (length(sample_horizon) != 1L)
      cli::cli_abort("Cannot reconcile sample paths with different forecast horizon lengths.")

    # Extract sample paths
    # TO do: At the moment fabletools performs univariate block bootstrapping
    # To do: This needs to be changed when Mitch fixes fabletoools
    samples <- lapply(fc_dist, function(x) distributional::parameters(x)$x)
    # Convert to array [samples,horizon,nodes]
    samples <- array(unlist(samples, use.names = FALSE), dim = c(sample_size, sample_horizon, length(fc_dist)))

    # Reconcile
    samples <- apply(samples, 1, reconcile_icomb_paths, simplify = FALSE)
    # Convert to array [nodes, horizon, samples]
    samples <- array(unlist(samples), dim = c(length(fc_dist), sample_horizon, sample_size))

    # Convert to distributions
    fc_dist <- apply(
      samples, 1L, simplify = FALSE,
      function(x) unname(distributional::dist_sample(split(x, row(x))))
    )
  } else {
    fc_dist <- map(fc_mean, distributional::dist_degenerate)
  }

  map2(fc, fc_dist, function(fc, dist) {
    dimnames(dist) <- dimnames(fc[[distribution_var(fc)]])
    fc[[distribution_var(fc)]] <- dist
    point_fc <- compute_point_forecasts(dist, point_forecast)
    fc[names(point_fc)] <- point_fc
    fc
  })
}
