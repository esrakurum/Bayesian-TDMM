## plot.trace.tdmm() makes traceplots for selected posterior
## parameters from a fitted TDMM object.
##
## This is useful for checking MCMC behavior before interpreting
## fitted coefficient curves.
##
## Examples of parameters:
##   params = c("sigma2.b", "sigma2.e")
##   params = c("sigma.b", "sigma2.b", "sigma.e", "sigma2.e")
##   params = paste0("alpha[1,", 1:5, "]")
############################################################

plot.trace.tdmm <- function(result,
                            params,
                            file = NULL,
                            ncol = 2,
                            width = 1800,
                            height = NULL,
                            res = 150,
                            lwd = 0.3,
                            col = "gray25") {
  
  ########
  ## Check fitted object
  ########
  
  if (!inherits(result, "tdmm")) {
    stop("result must be a fitted TDMM object.", call. = FALSE)
  }
  
  ########
  ## Extract posterior matrix
  ########
  
  if (!is.null(result$post.mat)) {
    post.mat <- result$post.mat
  } else if (!is.null(result$post.samples$BUGSoutput$sims.matrix)) {
    post.mat <- result$post.samples$BUGSoutput$sims.matrix
  } else if (!is.null(result$post.samples)) {
    post.mat <- as.matrix(result$post.samples)
  } else {
    stop("Could not find posterior samples in result.", call. = FALSE)
  }
  
  ########
  ## Check requested parameters
  ########
  
  missing.params <- params[!params %in% colnames(post.mat)]
  
  if (length(missing.params) > 0) {
    stop(
      "The following parameters were not found in the posterior samples: ",
      paste(missing.params, collapse = ", "),
      call. = FALSE
    )
  }
  
  ########
  ## Set layout
  ########
  
  n.params <- length(params)
  nrow <- ceiling(n.params / ncol)
  
  if (is.null(height)) {
    height <- 450 * nrow
  }
  
  ########
  ## Open file device if requested
  ########
  
  if (!is.null(file)) {
    grDevices::png(
      filename = file,
      width = width,
      height = height,
      res = res
    )
    on.exit(grDevices::dev.off(), add = TRUE)
  }
  
  old.par <- graphics::par(no.readonly = TRUE)
  on.exit(graphics::par(old.par), add = TRUE)
  
  graphics::par(
    mfrow = c(nrow, ncol),
    mar = c(4, 4, 3, 1),
    mgp = c(2.4, 0.8, 0)
  )
  
  ########
  ## Plot each parameter
  ########
  
  for (param in params) {
    
    graphics::plot(
      post.mat[, param],
      type = "l",
      lwd = lwd,
      col = col,
      main = paste("Trace of", param),
      xlab = "Iteration",
      ylab = param
    )
  }
  
  invisible(NULL)
}
