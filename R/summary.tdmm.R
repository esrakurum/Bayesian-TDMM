## summary.tdmm() gives a compact summary of a fitted TDMM
## object returned by tdmm() or tdmm.parallel().
##
## It reports:
##   - response family
##   - number of subjects
##   - number of repeated time points
##   - number of baseline covariates
##   - covariate names
##   - MCMC settings
##   - variance summaries
##   - coefficient function names
############################################################

summary.tdmm <- function(object, ...) {
  
  ########
  ## Check object class
  ########
  
  if (!inherits(object, "tdmm")) {
    stop("object must be a fitted TDMM object.", call. = FALSE)
  }
  
  ########
  ## Extract basic pieces
  ########
  
  inputs <- object$inputs
  settings <- object$model.settings
  
  ########
  ## Print model summary
  ########
  
  cat("\nTDMM fit summary\n")
  cat("----------------\n")
  
  cat("Family: ", object$family, "\n", sep = "")
  cat("Number of subjects: ", inputs$n.subject, "\n", sep = "")
  cat("Number of time points: ", inputs$n.time, "\n", sep = "")
  cat("Total observations: ", inputs$n.total, "\n", sep = "")
  cat("Number of covariates: ", length(inputs$x.var), "\n", sep = "")
  cat("Number of coefficient functions: ", inputs$nX, "\n", sep = "")
  cat("Covariates: ", paste(inputs$x.var, collapse = ", "), "\n", sep = "")
  
  cat("\nMCMC settings\n")
  cat("-------------\n")
  cat("Chains: ", settings$n.chains, "\n", sep = "")
  cat("Iterations: ", settings$n.iter, "\n", sep = "")
  cat("Burn-in: ", settings$n.burn, "\n", sep = "")
  cat("Thinning: ", settings$n.thin, "\n", sep = "")
  cat("Adaptation: ", settings$n.adapt, "\n", sep = "")
  
  if (!is.null(settings$n.cores)) {
    cat("Cores: ", settings$n.cores, "\n", sep = "")
  }
  
  cat("\nVariance summaries\n")
  cat("------------------\n")
  cat("sigma2.b: ", object$sigma2.b, "\n", sep = "")
  cat("sigma.b: ", object$sigma.b, "\n", sep = "")
  
  if (object$family == "gaussian") {
    cat("sigma2.e: ", object$sigma2.e, "\n", sep = "")
    cat("sigma.e: ", object$sigma.e, "\n", sep = "")
  }
  
  cat("\nCoefficient functions\n")
  cat("---------------------\n")
  cat(paste(object$beta.names, collapse = ", "), "\n")
  
  ########
  ## Return an invisible summary list
  ########
  
  invisible(
    list(
      family = object$family,
      n.subject = inputs$n.subject,
      n.time = inputs$n.time,
      n.total = inputs$n.total,
      nX = inputs$nX,
      covariates = inputs$x.var,
      beta.names = object$beta.names,
      sigma2.b = object$sigma2.b,
      sigma.b = object$sigma.b,
      sigma2.e = if (object$family == "gaussian") object$sigma2.e else NULL,
      sigma.e = if (object$family == "gaussian") object$sigma.e else NULL,
      model.settings = settings
    )
  )
}
