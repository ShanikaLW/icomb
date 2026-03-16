lambda_path <- function(x, y, alpha = 1, standardize = FALSE,
                        standardize_response = FALSE,
                        intercept = TRUE,
                        lambda_min_ratio = "expand",
                        nlambda = 100) {
  dimx <- dim(x)
  if (is.null(dimx) | (dimx[2] <= 1))
    stop("x should be a matrix with 2 or more columns")
  if (any(is.na(x)))
    stop("x has missing values")
  nobs <- dimx[1]
  nvars <- dimx[2]

  dimy <- dim(y)
  if (is.null(dimy) | (dimy[2] <= 1))
    stop("y should be a matrix with 2 or more columns")
  if (any(is.na(y)))
    stop("y has missing values")
  if (dimy[1] != dimx[1])
    stop("number of observations in actual and fitted does not match")

  if (lambda_min_ratio >= 1 & is.numeric(lambda_min_ratio))
    stop("lambda_min_ratio should be less than 1")

  if (alpha > 1) {
    warning("alpha > 1; set to 1")
    alpha <- 1
  }
  if (alpha < 0) {
    warning("alpha < 0; set to 0")
    alpha <- 0
  }

  if (intercept) {
    xm <- colMeans(x)
    ym <- colMeans(y)
  } else {
    xm <- rep(0, times = nvars)
    ym <- rep(0, times = dimy[2])
  }

  ysd <- sqrt(colMeans(scale(y, center = TRUE, scale = FALSE)^2))
  yconst_var <- ysd < sqrt(.Machine$double.eps) # identify constant responses

  if (!standardize_response)
    ysd <- rep(1, times = dimy[2])

  y <- scale(y, center = ym, scale = ysd)

  if (standardize_response) {
    if (length(which(yconst_var)) == dimy[2])
      stop("All used responses have zero variance")
    y <- y[, !yconst_var]
  }

  xsd <- sqrt(colMeans(scale(x, center = TRUE, scale = FALSE)^2))
  xconst_var <- xsd < sqrt(.Machine$double.eps) # identify constant predictors

  if (!standardize)
    xsd <- rep(1, times = nvars)

  if (length(which(xconst_var)) == nvars)
    stop("All used predictors have zero variance")

  x <- scale(x, center = xm, scale = xsd)
  x <- x[, !xconst_var]

  lambda_max <- max(sqrt(rowSums(crossprod(x, y)^2))/nobs) / pmax(alpha, 0.001)

  if (lambda_min_ratio == "expand")
    lambda_min_ratio <- 10^(-floor(log10(lambda_max))-2)
  else if (lambda_min_ratio == "glmnet")
    lambda_min_ratio <- ifelse(nobs < nvars, 0.01, 1e-04)
  lambda_min <- lambda_min_ratio * lambda_max
  exp(seq(log(lambda_max), log(lambda_min), length.out = nlambda))
}
