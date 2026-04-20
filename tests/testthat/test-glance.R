tourism_gts <- tsibble::tourism |>
  fabletools::aggregate_key(State * Purpose,
                            Trips = sum(Trips))

fit <- tourism_gts |>
  fabletools::model(base = fable::ETS(Trips))

fit_recon <- fit |>
  fabletools::reconcile(ols = fabletools::min_trace(base, method = "ols"),
                        icomb = icomb(base, train_size = 55))

fit_recon_glance <- fit_recon |>
  glance()

expect_true(".included" %in% colnames(fit_recon_glance))

glance_base <- fit_recon_glance |>
  dplyr::filter(.model == "base") |>
  dplyr::pull(.included)
expect_equal(glance_base, rep(NA, 45))


glance_ols <- fit_recon_glance |>
  dplyr::filter(.model == "ols") |>
  dplyr::pull(.included)
expect_equal(glance_ols, rep(NA, 45))

fit_glance <- fit_recon |>
  dplyr::select(base, ols) |>
  glance()

expect_false(".included" %in% colnames(fit_glance))

fitted <- fit |>
  broom::augment() |>
  tibble::as_tibble() |>
  dplyr::select(Quarter, State, Purpose, .fitted) |>
  tidyr::pivot_wider(names_from = c("State", "Purpose"), values_from  = ".fitted") |>
  dplyr::select(-Quarter) |>
  as.matrix()

actual <- fit |>
  broom::augment() |>
  tibble::as_tibble() |>
  dplyr::select(Quarter, State, Purpose, Trips) |>
  tidyr::pivot_wider(names_from = c("State", "Purpose"), values_from  = "Trips") |>
  dplyr::select(-Quarter) |>
  as.matrix()


idx <- as.vector((rowMeans(abs(icomb:::cv_icomb(fitted, actual, train_size = 55)$coefs)) > sqrt(.Machine$double.eps))[-1])
glance_included <- fit_recon_glance |>
  dplyr::filter(.model == "icomb") |>
  dplyr::pull(.included)
expect_equal(idx, glance_included)
