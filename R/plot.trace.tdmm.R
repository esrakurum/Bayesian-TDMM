## plot.trace.tdmm() makes traceplots for selected posterior
## parameters from a fitted TDMM object.
##
## This is useful for checking MCMC behavior before interpreting
## fitted coefficient curves.
##
## Examples of parameters:
##   ## Gaussian models include random-intercept and residual variance terms
##   params = c("sigma2.b", "sigma2.e")
##
##   ## Bernoulli and Poisson models include only the random-intercept variance
##   params = c("sigma2.b")
##
##   ## Spline coefficient traces can also be checked
##   params = paste0("alpha[1,", 1:5, "]")
##
## Note:
## For variance-component diagnostics, this function currently
## focuses on variance terms. If users pass sigma.b or sigma.e,
## those are automatically replaced with sigma2.b or sigma2.e.
############################################################

plot.trace.tdmm <- function(result,
                            params,
                            file = NULL,
                            ncol = 2,
                            width = 1800,
                            height = NULL,
                            res = 150,
                            lwd = 0.4,
                            col = NULL,
                            show.legend = FALSE) {
  
  ########
  ## Check fitted object
  ########
  
  if (!inherits(result, "tdmm")) {
    stop("result must be a fitted TDMM object.", call. = FALSE)
  }
  
  ########
  ## Extract posterior matrix for checking parameter names
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
  ## Keep variance terms only for sigma traces
  ########
  
  ## For now, trace diagnostics for variance components are shown
  ## using sigma2 terms. If users pass sigma.b or sigma.e, replace
  ## them with the corresponding variance terms.
  params <- gsub("^sigma\\.b$", "sigma2.b", params)
  params <- gsub("^sigma\\.e$", "sigma2.e", params)
  
  ## Remove duplicates that may result from replacement.
  params <- unique(params)
  
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
  ## Extract chain-specific samples
  ########
  
  chain.samples <- NULL
  
  ## Case 1: tdmm() fitted with R2jags.
  ## R2jags stores chain-specific samples in sims.array.
  if (!is.null(result$post.samples$BUGSoutput$sims.array)) {
    
    sims.array <- result$post.samples$BUGSoutput$sims.array
    
    chain.samples <- lapply(seq_len(dim(sims.array)[2]), function(chain.id) {
      sims.array[, chain.id, , drop = FALSE]
    })
    
    names(chain.samples) <- paste0("Chain ", seq_along(chain.samples))
  }
  
  ## Case 2: tdmm.parallel() fitted with coda::mcmc.list.
  if (is.null(chain.samples) && inherits(result$post.samples, "mcmc.list")) {
    
    chain.samples <- lapply(result$post.samples, function(x) {
      as.matrix(x)
    })
    
    names(chain.samples) <- paste0("Chain ", seq_along(chain.samples))
  }
  
  ## Fallback: if chain-specific samples are not available,
  ## plot the combined posterior matrix as one trace.
  if (is.null(chain.samples)) {
    chain.samples <- list("Combined chains" = post.mat)
  }
  
  n.chains <- length(chain.samples)
  
  ########
  ## Set chain colors
  ########
  
  if (is.null(col)) {
    if (n.chains == 1) {
      col <- "gray25"
    } else {
      nejm.cols <- c(
        "#0072B5FF",  # blue
        "#20854EFF",  # green
        "#BC3C29FF",  # red
        "#7876B1FF",  # purple
        "#E18727FF",  # orange
        "#6F99ADFF",  # light blue
        "#FFDC91FF",  # yellow
        "#EE4C97FF"   # pink
      )
      
      col <- rep(nejm.cols, length.out = n.chains)
    }
  } else {
    col <- rep(col, length.out = n.chains)
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
    mar = c(4.2, 4.4, 3.0, 1.2),
    mgp = c(2.5, 0.8, 0),
    cex.axis = 0.85,
    cex.lab = 0.9,
    cex.main = 1.0
  )
  
  ########
  ## Plot each parameter
  ########
  
  for (param in params) {
    
  y.list <- lapply(chain.samples, function(chain.mat) {
  
    if (length(dim(chain.mat)) == 3) {
      chain.mat[, 1, param]
    } else {
      chain.mat[, param]
    }
  })
    
    y.range <- range(unlist(y.list), na.rm = TRUE)
    
    graphics::plot(
      y.list[[1]],
      type = "l",
      lwd = lwd,
      col = col[1],
      ylim = y.range,
      main = paste("Trace of", param),
      xlab = "Iteration",
      ylab = param
    )
    
    if (n.chains > 1) {
      for (chain.id in 2:n.chains) {
        graphics::lines(
          y.list[[chain.id]],
          lwd = lwd,
          col = col[chain.id]
        )
      }
    }
    
    if (show.legend && n.chains > 1) {
      graphics::legend(
        "topright",
        legend = names(chain.samples),
        col = col,
        lwd = 1.2,
        bty = "n",
        cex = 0.75
      )
    }
  }
  
  invisible(NULL)
}
