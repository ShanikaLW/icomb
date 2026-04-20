tourism_gts <- tsibble::tourism |>
  fabletools::aggregate_key(Purpose,
                            Trips = sum(Trips))

reconciled_fc <- tourism_gts |>
  fabletools::model(base = fable::SNAIVE(Trips)) |>
  fabletools::reconcile(icomb = icomb(base, train_size = 75)) |>
  forecast()

agg_fc <- reconciled_fc |>
  dplyr::filter(.model == "icomb", fabletools::is_aggregated(Purpose))

bottom_fc <- reconciled_fc |>
  dplyr::filter(.model == "icomb", !fabletools::is_aggregated(Purpose)) |>
  dplyr::summarise(.mean = sum(.mean))

expect_equal(agg_fc$.mean, bottom_fc$.mean)

reconciled_fc <- tourism_gts |>
  fabletools::model(base = fable::ETS(Trips)) |>
  fabletools::reconcile(icomb = icomb(base, train_size = 75)) |>
  forecast()

agg_fc <- reconciled_fc |>
  dplyr::filter(.model == "icomb", fabletools::is_aggregated(Purpose))

bottom_fc <- reconciled_fc |>
  dplyr::filter(.model == "icomb", !fabletools::is_aggregated(Purpose)) |>
  dplyr::summarise(.mean = sum(.mean))

expect_equal(agg_fc$.mean, bottom_fc$.mean)

reconciled_fc <- tourism_gts |>
  fabletools::model(base = fable::ETS(Trips)) |>
  fabletools::reconcile(icomb = icomb(base, train_size = 75)) |>
  forecast(bootstrap = TRUE, times = 500)

agg_fc <- reconciled_fc |>
  dplyr::filter(.model == "icomb", fabletools::is_aggregated(Purpose))

bottom_fc <- reconciled_fc |>
  dplyr::filter(.model == "icomb", !fabletools::is_aggregated(Purpose)) |>
  dplyr::summarise(.mean = sum(mean(Trips)))

expect_equal(mean(agg_fc$Trips), bottom_fc$.mean)
