tourism_gts <- tsibble::tourism |>
  fabletools::aggregate_key(Purpose,
                            Trips = sum(Trips))

fit <- tourism_gts |>
  fabletools::model(base = fable::SNAIVE(Trips)) |>
  broom::augment()

fitted <- fit |>
  tibble::as_tibble() |>
  dplyr::select(Quarter, Purpose, .fitted) |>
  tidyr::pivot_wider(names_from = "Purpose", values_from  = ".fitted") |>
  dplyr::select(-Quarter)

actual <- fit |>
  tibble::as_tibble() |>
  dplyr::select(Quarter, Purpose, Trips) |>
  tidyr::pivot_wider(names_from = "Purpose", values_from  = "Trips") |>
  dplyr::select(-Quarter)

mask <- complete.cases(fitted) & complete.cases(actual)

# Option 1
lambda_icomb <- lambda_path(x = fitted[mask, ], y = actual[mask, ],
                            alpha = 1, standardize = FALSE,
                            standardize_response = FALSE, intercept = FALSE)[1]

fit_glmnet <- glmnet::glmnet(x = as.matrix(fitted[mask, ]), y = as.matrix(actual[mask, ]),
                             alpha = 1, standardize = FALSE,
                             standardize.response = FALSE, intercept = FALSE, family = "mgaussian")
lambda_glmnet <- fit_glmnet$lambda[1]
expect_equal(lambda_icomb, lambda_glmnet)

# option 2
lambda_icomb <- lambda_path(x = fitted[mask, ], y = actual[mask, ],
                            alpha = 0, standardize = FALSE,
                            standardize_response = FALSE, intercept = FALSE)[1]

fit_glmnet <- glmnet::glmnet(x = as.matrix(fitted[mask, ]), y = as.matrix(actual[mask, ]),
                             alpha = 0, standardize = FALSE,
                             standardize.response = FALSE, intercept = FALSE, family = "mgaussian")
lambda_glmnet <- fit_glmnet$lambda[1]
expect_equal(lambda_icomb, lambda_glmnet)

# Option 3
lambda_icomb <- lambda_path(x = fitted[mask, ], y = actual[mask, ],
                            alpha = 1, standardize = FALSE,
                            standardize_response = TRUE, intercept = FALSE)[1]

fit_glmnet <- glmnet::glmnet(x = as.matrix(fitted[mask, ]), y = as.matrix(actual[mask, ]),
                             alpha = 1, standardize = FALSE,
                             standardize.response = TRUE, intercept = FALSE, family = "mgaussian")
lambda_glmnet <- fit_glmnet$lambda[1]
expect_equal(lambda_icomb, lambda_glmnet)

# Option 4
lambda_icomb <- lambda_path(x = fitted[mask, ], y = actual[mask, ],
                            alpha = 0, standardize = FALSE,
                            standardize_response = TRUE, intercept = FALSE)[1]

fit_glmnet <- glmnet::glmnet(x = as.matrix(fitted[mask, ]), y = as.matrix(actual[mask, ]),
                             alpha = 0, standardize = FALSE,
                             standardize.response = TRUE, intercept = FALSE, family = "mgaussian")
lambda_glmnet <- fit_glmnet$lambda[1]
expect_equal(lambda_icomb, lambda_glmnet)

# Option 5
lambda_icomb <- lambda_path(x = fitted[mask, ], y = actual[mask, ],
                            alpha = 1, standardize = TRUE,
                            standardize_response = FALSE, intercept = FALSE)[1]

fit_glmnet <- glmnet::glmnet(x = as.matrix(fitted[mask, ]), y = as.matrix(actual[mask, ]),
                             alpha = 1, standardize = TRUE,
                             standardize.response = FALSE, intercept = FALSE, family = "mgaussian")
lambda_glmnet <- fit_glmnet$lambda[1]
expect_equal(lambda_icomb, lambda_glmnet)

# Option 6
lambda_icomb <- lambda_path(x = fitted[mask, ], y = actual[mask, ],
                            alpha = 0, standardize = TRUE,
                            standardize_response = FALSE, intercept = FALSE)[1]

fit_glmnet <- glmnet::glmnet(x = as.matrix(fitted[mask, ]), y = as.matrix(actual[mask, ]),
                             alpha = 0, standardize = TRUE,
                             standardize.response = FALSE, intercept = FALSE, family = "mgaussian")
lambda_glmnet <- fit_glmnet$lambda[1]
expect_equal(lambda_icomb, lambda_glmnet)

# Option 7
lambda_icomb <- lambda_path(x = fitted[mask, ], y = actual[mask, ],
                            alpha = 1, standardize = FALSE,
                            standardize_response = FALSE, intercept = TRUE)[1]

fit_glmnet <- glmnet::glmnet(x = as.matrix(fitted[mask, ]), y = as.matrix(actual[mask, ]),
                             alpha = 1, standardize = FALSE,
                             standardize.response = FALSE, intercept = TRUE, family = "mgaussian")
lambda_glmnet <- fit_glmnet$lambda[1]
expect_equal(lambda_icomb, lambda_glmnet)

# Option 8
lambda_icomb <- lambda_path(x = fitted[mask, ], y = actual[mask, ],
                            alpha = 0, standardize = FALSE,
                            standardize_response = FALSE, intercept = TRUE)[1]

fit_glmnet <- glmnet::glmnet(x = as.matrix(fitted[mask, ]), y = as.matrix(actual[mask, ]),
                             alpha = 0, standardize = FALSE,
                             standardize.response = FALSE, intercept = TRUE, family = "mgaussian")
lambda_glmnet <- fit_glmnet$lambda[1]
expect_equal(lambda_icomb, lambda_glmnet)

# Option 9
lambda_icomb <- lambda_path(x = fitted[mask, ], y = actual[mask, ],
                            alpha = 1, standardize = TRUE,
                            standardize_response = TRUE, intercept = FALSE)[1]

fit_glmnet <- glmnet::glmnet(x = as.matrix(fitted[mask, ]), y = as.matrix(actual[mask, ]),
                             alpha = 1, standardize = TRUE,
                             standardize.response = TRUE, intercept = FALSE, family = "mgaussian")
lambda_glmnet <- fit_glmnet$lambda[1]
expect_equal(lambda_icomb, lambda_glmnet)

# Option 10
lambda_icomb <- lambda_path(x = fitted[mask, ], y = actual[mask, ],
                            alpha = 0, standardize = TRUE,
                            standardize_response = TRUE, intercept = FALSE)[1]

fit_glmnet <- glmnet::glmnet(x = as.matrix(fitted[mask, ]), y = as.matrix(actual[mask, ]),
                             alpha = 0, standardize = TRUE,
                             standardize.response = TRUE, intercept = FALSE, family = "mgaussian")
lambda_glmnet <- fit_glmnet$lambda[1]
expect_equal(lambda_icomb, lambda_glmnet)

# Option 11
lambda_icomb <- lambda_path(x = fitted[mask, ], y = actual[mask, ],
                            alpha = 1, standardize = FALSE,
                            standardize_response = TRUE, intercept = TRUE)[1]

fit_glmnet <- glmnet::glmnet(x = as.matrix(fitted[mask, ]), y = as.matrix(actual[mask, ]),
                             alpha = 1, standardize = FALSE,
                             standardize.response = TRUE, intercept = TRUE, family = "mgaussian")
lambda_glmnet <- fit_glmnet$lambda[1]
expect_equal(lambda_icomb, lambda_glmnet)

# Option 12
lambda_icomb <- lambda_path(x = fitted[mask, ], y = actual[mask, ],
                            alpha = 0, standardize = FALSE,
                            standardize_response = TRUE, intercept = TRUE)[1]

fit_glmnet <- glmnet::glmnet(x = as.matrix(fitted[mask, ]), y = as.matrix(actual[mask, ]),
                             alpha = 0, standardize = FALSE,
                             standardize.response = TRUE, intercept = TRUE, family = "mgaussian")
lambda_glmnet <- fit_glmnet$lambda[1]
expect_equal(lambda_icomb, lambda_glmnet)

# Option 13
lambda_icomb <- lambda_path(x = fitted[mask, ], y = actual[mask, ],
                            alpha = 1, standardize = TRUE,
                            standardize_response = FALSE, intercept = TRUE)[1]

fit_glmnet <- glmnet::glmnet(x = as.matrix(fitted[mask, ]), y = as.matrix(actual[mask, ]),
                             alpha = 1, standardize = TRUE,
                             standardize.response = FALSE, intercept = TRUE, family = "mgaussian")
lambda_glmnet <- fit_glmnet$lambda[1]
expect_equal(lambda_icomb, lambda_glmnet)


# Option 14
lambda_icomb <- lambda_path(x = fitted[mask, ], y = actual[mask, ],
                            alpha = 0, standardize = TRUE,
                            standardize_response = FALSE, intercept = TRUE)[1]

fit_glmnet <- glmnet::glmnet(x = as.matrix(fitted[mask, ]), y = as.matrix(actual[mask, ]),
                             alpha = 0, standardize = TRUE,
                             standardize.response = FALSE, intercept = TRUE, family = "mgaussian")
lambda_glmnet <- fit_glmnet$lambda[1]
expect_equal(lambda_icomb, lambda_glmnet)

# Option 15
lambda_icomb <- lambda_path(x = fitted[mask, ], y = actual[mask, ],
                            alpha = 1, standardize = TRUE,
                            standardize_response = TRUE, intercept = TRUE)[1]

fit_glmnet <- glmnet::glmnet(x = as.matrix(fitted[mask, ]), y = as.matrix(actual[mask, ]),
                             alpha = 1, standardize = TRUE,
                             standardize.response = TRUE, intercept = TRUE, family = "mgaussian")
lambda_glmnet <- fit_glmnet$lambda[1]
expect_equal(lambda_icomb, lambda_glmnet)


# Option 16
lambda_icomb <- lambda_path(x = fitted[mask, ], y = actual[mask, ],
                            alpha = 0, standardize = TRUE,
                            standardize_response = TRUE, intercept = TRUE)[1]

fit_glmnet <- glmnet::glmnet(x = as.matrix(fitted[mask, ]), y = as.matrix(actual[mask, ]),
                             alpha = 0, standardize = TRUE,
                             standardize.response = TRUE, intercept = TRUE, family = "mgaussian")
lambda_glmnet <- fit_glmnet$lambda[1]
expect_equal(lambda_icomb, lambda_glmnet)
