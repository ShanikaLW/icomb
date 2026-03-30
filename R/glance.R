#' @importFrom tidyr pivot_longer
node_present <- function(x) {
  if (!inherits(x, "lst_icomb_mdl"))
    return(rep(TRUE, length(x)))

  betas <- attr(x, "icombfit")$coefs
  vals <- rowSums(abs(betas)) > sqrt(.Machine$double.eps)

  if ("(Intercept)" %in% rownames(betas))
    vals[-1]
  else vals
}

series_included <- function(x) {
  mbl_vars <- mable_vars(x)
  as_tibble(x) |>
    mutate(across(all_of(mbl_vars), node_present)) |>
    pivot_longer(mbl_vars, names_to = ".model", values_to = ".included")
}

#' @export
inspect_reconciliation <- function(x, ...){
  mbl_vars <- mable_vars(x)
  glance(x, ...) |>
    full_join(series_included(x), by = c(".model", key_vars(x)))
}
