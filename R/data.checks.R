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
  ##
  ## The covariates are user specified through x.var.
  ## For example:
  ##   x.var = "x1"
  ##   x.var = c("x1", "x2")
  ##   x.var = c("age", "treatment", "baseline_score")
  ##
  ## If x.var is left as NULL, all columns except the subject,
  ## time, and response variables are treated as baseline
  ## covariates.
  
  family <- match.arg(family)
  
  ## If the user does not give covariate names, use all columns
  ## except the subject ID, time, and response columns.
  if (is.null(x.var)) {
    x.var <- setdiff(names(data), c(subject.var, time.var, y.var))
  }
  
  ## Count the number of baseline covariates.
  ## This is the p in x_1, ..., x_p.
  p <- length(x.var)
  
  ## Run the shared TDMM data structure check.
  ## This checks things like:
  ##   - required columns are present
  ##   - data are ordered by subject and time
  ##   - subjects share a common time grid
  ##   - baseline covariates are constant within subject
  structure.check <- check.tdmm.data.structure(data = data, subject.var = subject.var,
    time.var = time.var, y.var = y.var, x.var = x.var, stop.on.fail = stop.on.fail)
  
  ## Run the response check that matches the selected family.
  ## Gaussian responses should be numeric.
  ## Bernoulli responses should be coded as 0/1.
  ## Poisson responses should be nonnegative integer counts.
  response.check <- switch(
    family,
    
    gaussian = check.gaussian.response(
      data = data, y.var = y.var, time.var = time.var),
    
    bernoulli = check.bernoulli.balance(
      data = data, y.var = y.var, time.var = time.var),
    
    poisson = check.poisson.counts(
      data = data, y.var = y.var, time.var = time.var)
  )
  
  ## Return the selected family, covariate names, number of
  ## covariates, structure check, and response check.
  list(
    family = family, covariates = x.var, p = p, 
    structure.check = structure.check, response.check = response.check)
}
