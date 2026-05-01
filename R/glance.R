node_present <- function(x) {
  betas <- attr(x, "icombfit")$coefs
  vals <- rowSums(abs(betas)) > sqrt(.Machine$double.eps)

  if ("intercept" %in% rownames(betas))
    vals[-1]
  else vals
}

#' Glance a mable which contains an information combination reconciliation method
#'
#' It uses the models within a mable to produce a one row summary statistics of their fits.
#'
#' @param x A mable
#' @param ... Arguments for model methods
#'
#' @returns The tibble contains the output of \code{glance()} for that model,
#' with an added logical column \code{.included} indicating whether the corresponding node is present
#' in the reconciliation process when the information combination method is used.
#'
#' @examples
#' \donttest{
#' library(fable)
#' library(fabletools)
#' library(tsibble)
#' library(dplyr)
#'
#' tourism_gts <- tourism |>
#'   aggregate_key(State * Purpose,
#'                 Trips = sum(Trips))
#'
#' fit <- tourism_gts |>
#'   model(base = ETS(Trips)) |>
#'   reconcile(ols = min_trace(base, method = "ols"),
#'             icomb = icomb(base, train_size = 75))
#'
#' fit |>
#'   glance()
#' }
#'
#' @export
#' @importFrom dplyr mutate
glance.mdl_icomb_lst <- function(x, ...) {
  map(x, glance, ...) |>
    map2(node_present(x),
         ~mutate(.x, .included = .y))
}
