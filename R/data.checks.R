############################################################
## data.checks.R
##
## Data checking functions for TDMM inputs.
##
## The checks make sure:
##   - required columns are present
##   - data are in long format
##   - the time variable is numeric
##   - covariates are numeric
##   - the response matches the selected family
##
## The updated checks allow:
##   - balanced measurement times
##   - irregular measurement times
##   - baseline covariates
##   - time-varying covariates
############################################################


############################################################
## Check repeated-measure structure
############################################################

check.tdmm.subject.balance <- function(data,
                                       subject.var = "subject.ID",
                                       time.var = "time") {

  ##########
  ## Check required columns
  ##########

  required.cols <- c(subject.var, time.var)
  missing.cols <- setdiff(required.cols, names(data))

  if (length(missing.cols) > 0) {
    stop(
      "data is missing required column(s): ",
      paste(missing.cols, collapse = ", "),
      call. = FALSE
    )
  }

  ##########
  ## Count observations per subject
  ##########

  obs.per.subject <- table(data[[subject.var]])

  ##########
  ## Store observed times by subject
  ##########

  time.by.subject <- split(data[[time.var]], data[[subject.var]])
  time.by.subject <- lapply(time.by.subject, sort)

  ##########
  ## Check balanced structure
  ##########

  reference.grid <- time.by.subject[[1]]

  common.time.grid <- all(
    sapply(time.by.subject, function(z) identical(z, reference.grid))
  )

  balanced <- length(unique(as.numeric(obs.per.subject))) == 1

  ##########
  ## Return structure summary
  ##########

  list(
    n.subject = length(obs.per.subject),
    min.obs.per.subject = min(obs.per.subject),
    max.obs.per.subject = max(obs.per.subject),
    mean.obs.per.subject = mean(obs.per.subject),
    obs.per.subject = obs.per.subject,
    balanced = balanced,
    common.time.grid = common.time.grid,
    time.grid = reference.grid,
    time.by.subject = time.by.subject
  )
}


############################################################
## Check covariate variation within subject
############################################################

check.tdmm.covariate.variation <- function(data,
                                           subject.var = "subject.ID",
                                           x.var) {

  ##########
  ## Count unique values within subject
  ##########

  x.unique.by.subject <- lapply(x.var, function(x.name) {
    tapply(
      data[[x.name]],
      data[[subject.var]],
      function(z) length(unique(z))
    )
  })

  names(x.unique.by.subject) <- x.var

  ##########
  ## Identify baseline and time-varying covariates
  ##########

  x.constant.by.variable <- sapply(
    x.unique.by.subject,
    function(z) all(z == 1)
  )

  baseline.covariates <- names(x.constant.by.variable)[x.constant.by.variable]
  time.varying.covariates <- names(x.constant.by.variable)[!x.constant.by.variable]

  ##########
  ## Return covariate summary
  ##########

  list(
    x.constant.by.variable = x.constant.by.variable,
    x.unique.by.subject = x.unique.by.subject,
    baseline.covariates = baseline.covariates,
    time.varying.covariates = time.varying.covariates,
    has.time.varying.covariates = length(time.varying.covariates) > 0
  )
}


############################################################
## Check general TDMM data structure
############################################################

check.tdmm.data.structure <- function(data,
                                      subject.var = "subject.ID",
                                      time.var = "time",
                                      y.var = "y",
                                      x.var = NULL,
                                      stop.on.fail = TRUE) {

  ##########
  ## Basic data check
  ##########

  if (!is.data.frame(data)) {
    stop("data must be a data frame.", call. = FALSE)
  }

  ##########
  ## Select covariates
  ##########

  if (is.null(x.var)) {
    x.var <- setdiff(names(data), c(subject.var, time.var, y.var))
  }

  if (length(x.var) == 0) {
    stop("No covariates were provided or detected.", call. = FALSE)
  }

  ##########
  ## Check required columns
  ##########

  required.cols <- c(subject.var, time.var, y.var, x.var)
  missing.cols <- setdiff(required.cols, names(data))

  if (length(missing.cols) > 0) {

    msg <- paste0(
      "data is missing required column(s): ",
      paste(missing.cols, collapse = ", ")
    )

    if (stop.on.fail) {
      stop(msg, call. = FALSE)
    } else {
      warning(msg, call. = FALSE)
    }
  }

  ##########
  ## Check missing values
  ##########

  missing.counts <- colSums(is.na(data[, required.cols, drop = FALSE]))
  has.missing <- any(missing.counts > 0)

  if (has.missing) {

    msg <- "Missing values were found in the required TDMM columns."

    if (stop.on.fail) {
      stop(msg, call. = FALSE)
    } else {
      warning(msg, call. = FALSE)
    }
  }

  ##########
  ## Check time variable
  ##########

  if (!is.numeric(data[[time.var]])) {

    msg <- "time.var must be numeric."

    if (stop.on.fail) {
      stop(msg, call. = FALSE)
    } else {
      warning(msg, call. = FALSE)
    }
  }

  ##########
  ## Check covariates
  ##########

  covariate.numeric <- sapply(data[, x.var, drop = FALSE], is.numeric)

  if (!all(covariate.numeric)) {

    bad.x <- names(covariate.numeric)[!covariate.numeric]

    msg <- paste0(
      "The following covariate(s) are not numeric: ",
      paste(bad.x, collapse = ", "),
      ". Convert factor or character covariates to numeric indicators before fitting."
    )

    if (stop.on.fail) {
      stop(msg, call. = FALSE)
    } else {
      warning(msg, call. = FALSE)
    }
  }

  ##########
  ## Summarize repeated-measure structure
  ##########

  subject.balance <- check.tdmm.subject.balance(
    data = data,
    subject.var = subject.var,
    time.var = time.var
  )

  ##########
  ## Summarize covariate variation
  ##########

  covariate.variation <- check.tdmm.covariate.variation(
    data = data,
    subject.var = subject.var,
    x.var = x.var
  )

  ##########
  ## Check row ordering
  ##########

  data.ordered <- data[order(data[[subject.var]], data[[time.var]]), ]

  ordered.by.subject.time <- identical(
    row.names(data),
    row.names(data.ordered)
  )

  if (!ordered.by.subject.time) {
    warning(
      "Rows are not ordered by subject and time. ",
      "The fitting function will reorder the data internally.",
      call. = FALSE
    )
  }

  ##########
  ## Return structure check
  ##########

  list(
    required.columns = required.cols,
    missing.counts = missing.counts,
    has.missing = has.missing,
    subject.balance = subject.balance,
    x.var = x.var,
    p = length(x.var),
    x.constant.within.subject = all(covariate.variation$x.constant.by.variable),
    covariate.numeric = covariate.numeric,
    covariate.variation = covariate.variation,
    x.constant.by.variable = covariate.variation$x.constant.by.variable,
    x.unique.by.subject = covariate.variation$x.unique.by.subject,
    baseline.covariates = covariate.variation$baseline.covariates,
    time.varying.covariates = covariate.variation$time.varying.covariates,
    has.time.varying.covariates = covariate.variation$has.time.varying.covariates,
    ordered.by.subject.time = ordered.by.subject.time
  )
}


############################################################
## Check Gaussian response
############################################################

check.gaussian.response <- function(data,
                                    y.var = "y",
                                    time.var = "time") {

  ##########
  ## Check required columns
  ##########

  required.cols <- c(y.var, time.var)
  missing.cols <- setdiff(required.cols, names(data))

  if (length(missing.cols) > 0) {
    stop(
      "data is missing required column(s): ",
      paste(missing.cols, collapse = ", "),
      call. = FALSE
    )
  }

  ##########
  ## Check response
  ##########

  y <- data[[y.var]]

  if (!is.numeric(y)) {
    warning("The Gaussian response variable is not numeric.", call. = FALSE)
  }

  ##########
  ## Overall response summaries
  ##########

  overall <- list(
    n = length(y),
    mean = mean(y, na.rm = TRUE),
    sd = stats::sd(y, na.rm = TRUE),
    min = min(y, na.rm = TRUE),
    max = max(y, na.rm = TRUE)
  )

  ##########
  ## Response summaries by observed time
  ##########

  by.time <- aggregate(
    y,
    by = list(time = data[[time.var]]),
    FUN = function(z) {
      c(
        n = length(z),
        mean = mean(z, na.rm = TRUE),
        sd = stats::sd(z, na.rm = TRUE),
        min = min(z, na.rm = TRUE),
        max = max(z, na.rm = TRUE)
      )
    }
  )

  by.time <- do.call(data.frame, by.time)
  names(by.time) <- c("time", "n", "mean", "sd", "min", "max")

  ##########
  ## Return response check
  ##########

  list(
    family = "gaussian",
    overall = overall,
    by.time = by.time
  )
}


############################################################
## Check Bernoulli response
############################################################

check.bernoulli.balance <- function(data,
                                    y.var = "y",
                                    time.var = "time") {

  ##########
  ## Check required columns
  ##########

  required.cols <- c(y.var, time.var)
  missing.cols <- setdiff(required.cols, names(data))

  if (length(missing.cols) > 0) {
    stop(
      "data is missing required column(s): ",
      paste(missing.cols, collapse = ", "),
      call. = FALSE
    )
  }

  ##########
  ## Check response
  ##########

  y <- data[[y.var]]
  y.values <- sort(unique(y))

  if (!all(y.values %in% c(0, 1))) {
    stop("For Bernoulli data, y must contain only 0 and 1 values.",
         call. = FALSE)
  }

  ##########
  ## Overall response summaries
  ##########

  overall.counts <- table(y)
  overall.proportions <- prop.table(overall.counts)

  ##########
  ## Response summaries by observed time
  ##########

  by.time <- aggregate(
    y,
    by = list(time = data[[time.var]]),
    FUN = function(z) {
      c(
        n = length(z),
        n0 = sum(z == 0),
        n1 = sum(z == 1),
        prop1 = mean(z == 1),
        prop0 = mean(z == 0)
      )
    }
  )

  by.time <- do.call(data.frame, by.time)
  names(by.time) <- c("time", "n", "n0", "n1", "prop1", "prop0")

  ##########
  ## Return response check
  ##########

  list(
    family = "bernoulli",
    overall.counts = overall.counts,
    overall.proportions = overall.proportions,
    by.time = by.time
  )
}


############################################################
## Check Poisson response
############################################################

check.poisson.counts <- function(data,
                                 y.var = "y",
                                 time.var = "time") {

  ##########
  ## Check required columns
  ##########

  required.cols <- c(y.var, time.var)
  missing.cols <- setdiff(required.cols, names(data))

  if (length(missing.cols) > 0) {
    stop(
      "data is missing required column(s): ",
      paste(missing.cols, collapse = ", "),
      call. = FALSE
    )
  }

  ##########
  ## Check response
  ##########

  y <- data[[y.var]]

  if (any(y < 0, na.rm = TRUE)) {
    stop("For Poisson data, y must be nonnegative.",
         call. = FALSE)
  }

  if (any(abs(y - round(y)) > .Machine$double.eps^0.5, na.rm = TRUE)) {
    stop("For Poisson data, y must contain integer counts.",
         call. = FALSE)
  }

  ##########
  ## Overall response summaries
  ##########

  overall <- list(
    n = length(y),
    mean = mean(y, na.rm = TRUE),
    variance = stats::var(y, na.rm = TRUE),
    min = min(y, na.rm = TRUE),
    max = max(y, na.rm = TRUE),
    zeros = sum(y == 0, na.rm = TRUE),
    zero.proportion = mean(y == 0, na.rm = TRUE)
  )

  ##########
  ## Response summaries by observed time
  ##########

  by.time <- aggregate(
    y,
    by = list(time = data[[time.var]]),
    FUN = function(z) {
      c(
        n = length(z),
        mean = mean(z, na.rm = TRUE),
        variance = stats::var(z, na.rm = TRUE),
        min = min(z, na.rm = TRUE),
        max = max(z, na.rm = TRUE),
        zeros = sum(z == 0),
        zero.proportion = mean(z == 0)
      )
    }
  )

  by.time <- do.call(data.frame, by.time)
  names(by.time) <- c(
    "time",
    "n",
    "mean",
    "variance",
    "min",
    "max",
    "zeros",
    "zero.proportion"
  )

  ##########
  ## Return response check
  ##########

  list(
    family = "poisson",
    overall = overall,
    by.time = by.time
  )
}


############################################################
## Combined family-specific TDMM check
############################################################

check.tdmm.family.data <- function(data,
                                   family = c("gaussian", "bernoulli", "poisson"),
                                   subject.var = "subject.ID",
                                   time.var = "time",
                                   y.var = "y",
                                   x.var = NULL,
                                   stop.on.fail = TRUE) {

  ##########
  ## Match family
  ##########

  family <- match.arg(family)

  ##########
  ## Select covariates
  ##########

  if (is.null(x.var)) {
    x.var <- setdiff(names(data), c(subject.var, time.var, y.var))
  }

  p <- length(x.var)

  ##########
  ## Check data structure
  ##########

  structure.check <- check.tdmm.data.structure(
    data = data,
    subject.var = subject.var,
    time.var = time.var,
    y.var = y.var,
    x.var = x.var,
    stop.on.fail = stop.on.fail
  )

  ##########
  ## Check response by family
  ##########

  response.check <- switch(
    family,
    gaussian = check.gaussian.response(
      data = data,
      y.var = y.var,
      time.var = time.var
    ),
    bernoulli = check.bernoulli.balance(
      data = data,
      y.var = y.var,
      time.var = time.var
    ),
    poisson = check.poisson.counts(
      data = data,
      y.var = y.var,
      time.var = time.var
    )
  )

  ##########
  ## Return full check
  ##########

  list(
    family = family,
    covariates = x.var,
    p = p,
    structure.check = structure.check,
    response.check = response.check
  )
}
