## This file contains data checking functions for TDMM inputs.
##
## The checks are used before fitting a model to make sure:
##   - required columns are present
##   - data are in long format
##   - subjects share a common time grid
##   - baseline covariates are constant within subject
##   - the response matches the selected family


##########
## Check repeated-measure structure
##########

check.tdmm.subject.balance <- function(data,
                                       subject.var = "subject.ID",
                                       time.var = "time") {
  
  ## Check that the subject ID and time columns are present.
  required.cols <- c(subject.var, time.var)
  missing.cols <- setdiff(required.cols, names(data))
  
  if (length(missing.cols) > 0) {
    stop(
      "data is missing required column(s): ",
      paste(missing.cols, collapse = ", "),
      call. = FALSE
    )
  }
  
  ## Count repeated observations per subject.
  obs.per.subject <- table(data[[subject.var]])
  
  ## Split and sort the observed time grid for each subject.
  time.by.subject <- split(data[[time.var]], data[[subject.var]])
  time.by.subject <- lapply(time.by.subject, sort)
  
  ## Use the first subject's time grid as the reference.
  reference.grid <- time.by.subject[[1]]
  
  ## Check if all subjects have the same time grid.
  common.time.grid <- all(
    sapply(time.by.subject, function(z) identical(z, reference.grid))
  )
  
  ## Check if all subjects have the same number of observations.
  balanced <- length(unique(as.numeric(obs.per.subject))) == 1
  
  list(
    n.subject = length(obs.per.subject),
    min.obs.per.subject = min(obs.per.subject),
    max.obs.per.subject = max(obs.per.subject),
    mean.obs.per.subject = mean(obs.per.subject),
    obs.per.subject = obs.per.subject,
    balanced = balanced,
    common.time.grid = common.time.grid,
    time.grid = reference.grid
  )
}


##########
## Check general TDMM data structure
##########

check.tdmm.data.structure <- function(data,
                                      subject.var = "subject.ID",
                                      time.var = "time",
                                      y.var = "y",
                                      x.var = NULL,
                                      stop.on.fail = TRUE) {
  
  ## If covariates are not supplied, use all columns except
  ## subject, time, and response.
  if (is.null(x.var)) {
    x.var <- setdiff(names(data), c(subject.var, time.var, y.var))
  }
  
  if (length(x.var) == 0) {
    stop("No baseline covariates were provided or detected.", call. = FALSE)
  }
  
  ## Check that all required columns are present.
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
  
  ## Check missing values in required columns.
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
  
  ## Check repeated-measure balance and common time grid.
  subject.balance <- check.tdmm.subject.balance(
    data = data,
    subject.var = subject.var,
    time.var = time.var
  )
  
  if (!subject.balance$balanced) {
    msg <- "Subjects do not all have the same number of repeated observations."
    
    if (stop.on.fail) {
      stop(msg, call. = FALSE)
    } else {
      warning(msg, call. = FALSE)
    }
  }
  
  if (!subject.balance$common.time.grid) {
    msg <- "Subjects do not all share the same time grid."
    
    if (stop.on.fail) {
      stop(msg, call. = FALSE)
    } else {
      warning(msg, call. = FALSE)
    }
  }
  
  ## Check that each baseline covariate is constant within subject.
  x.unique.by.subject <- lapply(x.var, function(x.name) {
    tapply(
      data[[x.name]],
      data[[subject.var]],
      function(z) length(unique(z))
    )
  })
  
  names(x.unique.by.subject) <- x.var
  
  x.constant.by.variable <- sapply(
    x.unique.by.subject,
    function(z) all(z == 1)
  )
  
  x.constant.within.subject <- all(x.constant.by.variable)
  
  if (!x.constant.within.subject) {
    bad.x <- names(x.constant.by.variable)[!x.constant.by.variable]
    
    msg <- paste0(
      "The following baseline covariate(s) are not constant within subject: ",
      paste(bad.x, collapse = ", "),
      ". Baseline covariates must be constant within subject for the current TDMM implementation."
    )
    
    if (stop.on.fail) {
      stop(msg, call. = FALSE)
    } else {
      warning(msg, call. = FALSE)
    }
  }
  
  ## Check whether rows are already ordered by subject and time.
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
  
  list(
    required.columns = required.cols,
    missing.counts = missing.counts,
    has.missing = has.missing,
    subject.balance = subject.balance,
    x.var = x.var,
    p = length(x.var),
    x.constant.within.subject = x.constant.within.subject,
    x.constant.by.variable = x.constant.by.variable,
    x.unique.by.subject = x.unique.by.subject,
    ordered.by.subject.time = ordered.by.subject.time
  )
}


##########
## Check Gaussian response
##########

check.gaussian.response <- function(data,
                                    y.var = "y",
                                    time.var = "time") {
  
  ## Check that the response and time variables are present.
  required.cols <- c(y.var, time.var)
  missing.cols <- setdiff(required.cols, names(data))
  
  if (length(missing.cols) > 0) {
    stop(
      "data is missing required column(s): ",
      paste(missing.cols, collapse = ", "),
      call. = FALSE
    )
  }
  
  y <- data[[y.var]]
  
  ## Gaussian responses should be numeric.
  if (!is.numeric(y)) {
    warning("The Gaussian response variable is not numeric.", call. = FALSE)
  }
  
  ## Overall response summaries.
  overall <- list(
    n = length(y),
    mean = mean(y, na.rm = TRUE),
    sd = stats::sd(y, na.rm = TRUE),
    min = min(y, na.rm = TRUE),
    max = max(y, na.rm = TRUE)
  )
  
  ## Response summaries by time point.
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
  
  list(
    family = "gaussian",
    overall = overall,
    by.time = by.time
  )
}


##########
## Check Bernoulli response
##########

check.bernoulli.balance <- function(data,
                                    y.var = "y",
                                    time.var = "time") {
  
  ## Check that the response and time variables are present.
  required.cols <- c(y.var, time.var)
  missing.cols <- setdiff(required.cols, names(data))
  
  if (length(missing.cols) > 0) {
    stop(
      "data is missing required column(s): ",
      paste(missing.cols, collapse = ", "),
      call. = FALSE
    )
  }
  
  y <- data[[y.var]]
  
  ## Bernoulli responses must contain only 0 and 1.
  y.values <- sort(unique(y))
  
  if (!all(y.values %in% c(0, 1))) {
    stop("For Bernoulli data, y must contain only 0 and 1 values.", call. = FALSE)
  }
  
  overall.counts <- table(y)
  overall.proportions <- prop.table(overall.counts)
  
  ## Response balance by time point.
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
  
  list(
    family = "bernoulli",
    overall.counts = overall.counts,
    overall.proportions = overall.proportions,
    by.time = by.time
  )
}


##########
## Check Poisson response
##########

check.poisson.counts <- function(data,
                                 y.var = "y",
                                 time.var = "time") {
  
  ## Check that the response and time variables are present.
  required.cols <- c(y.var, time.var)
  missing.cols <- setdiff(required.cols, names(data))
  
  if (length(missing.cols) > 0) {
    stop(
      "data is missing required column(s): ",
      paste(missing.cols, collapse = ", "),
      call. = FALSE
    )
  }
  
  y <- data[[y.var]]
  
  ## Poisson responses must be nonnegative integer counts.
  if (any(y < 0, na.rm = TRUE)) {
    stop("For Poisson data, y must be nonnegative.", call. = FALSE)
  }
  
  if (any(abs(y - round(y)) > .Machine$double.eps^0.5, na.rm = TRUE)) {
    stop("For Poisson data, y must contain integer counts.", call. = FALSE)
  }
  
  overall <- list(
    n = length(y),
    mean = mean(y, na.rm = TRUE),
    variance = stats::var(y, na.rm = TRUE),
    min = min(y, na.rm = TRUE),
    max = max(y, na.rm = TRUE),
    zeros = sum(y == 0, na.rm = TRUE),
    zero.proportion = mean(y == 0, na.rm = TRUE)
  )
  
  ## Count summaries by time point.
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
  
  list(
    family = "poisson",
    overall = overall,
    by.time = by.time
  )
}


##########
## Combined family-specific TDMM check
##########

check.tdmm.family.data <- function(data,
                                   family = c("gaussian", "bernoulli", "poisson"),
                                   subject.var = "subject.ID",
                                   time.var = "time",
                                   y.var = "y",
                                   x.var = NULL,
                                   stop.on.fail = TRUE) {
  
  ## This is the main checking function users can run before
  ## fitting a TDMM.
  ##
  ## It first checks the shared longitudinal data structure
  ## and then runs the response check for the selected family.
  
  family <- match.arg(family)
  
  ## If the user does not give covariate names, use all columns
  ## except the subject ID, time, and response columns.
  if (is.null(x.var)) {
    x.var <- setdiff(names(data), c(subject.var, time.var, y.var))
  }
  
  ## Count the number of baseline covariates.
  p <- length(x.var)
  
  ## Run the shared TDMM data structure check.
  structure.check <- check.tdmm.data.structure(
    data = data,
    subject.var = subject.var,
    time.var = time.var,
    y.var = y.var,
    x.var = x.var,
    stop.on.fail = stop.on.fail
  )
  
  ## Run the response check that matches the selected family.
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
  
  list(
    family = family,
    covariates = x.var,
    p = p,
    structure.check = structure.check,
    response.check = response.check
  )
}
