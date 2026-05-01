## This file contains plotting helpers for fitted TDMM objects.
##
## Main user-facing function:
##   plot.tdmm()
##
## Main helper functions:
##   make.tdmm.plot.grid()
##   recover.tdmm.betas.ci()
##
## The plotting workflow:
##   1. build a time grid for plotting
##   2. evaluate the spline basis on that grid
##   3. recover posterior draws of the coefficient functions
##   4. plot posterior mean curves with uncertainty bands
##
## The main plot function is designed for observed data settings.
## It does not require known true coefficient functions.
############################################################


#########
## Build plotting grid and spline basis
#########

make.tdmm.plot.grid <- function(data,
                                grid = NULL,
                                n.grid = 100,
                                time.var = "time",
                                nknots = 15,
                                degree = 2) {
  
  ## Check that the time variable is present.
  if (!time.var %in% names(data)) {
    stop("The time variable was not found in data.", call. = FALSE)
  }
  
  ## Determine the observed time range.
  tlo <- min(data[[time.var]], na.rm = TRUE)
  thi <- max(data[[time.var]], na.rm = TRUE)
  
  ## If the user does not provide a grid, create one over
  ## the observed time range.
  if (is.null(grid)) {
    grid <- seq(tlo, thi, length.out = n.grid)
  }
  
  ## If the user provides one numeric value, treat it as the
  ## number of plotting grid points.
  if (length(grid) == 1 && is.numeric(grid)) {
    grid <- seq(tlo, thi, length.out = grid)
  }
  
  ## Build the spline basis on the plotting grid.
  ## This uses the same spline basis construction as the model.
  nseg <- nknots - 2
  
  bases.grid <- bbase(x = grid, xl = tlo, xr = thi, ndx = nseg, deg = degree)
  
  list(
    grid = grid,
    bases.grid = bases.grid,
    tlo = tlo,
    thi = thi,
    nseg = nseg,
    nknots = nknots,
    degree = degree
  )
}


#########
## Recover posterior summaries of coefficient functions
#########

recover.tdmm.betas.ci <- function(post.mat,
                                  bases.grid,
                                  p,
                                  x.var = NULL,
                                  level = 0.95) {
  
  ## This function recovers posterior mean curves and uncertainty
  ## summaries for beta_0(t), beta_1(t), ..., beta_p(t).
  ##
  ## It uses posterior samples of the spline coefficients alpha.
  ##
  ## The number of baseline covariates is p, so the total number
  ## of coefficient functions is p + 1 because the model also has
  ## the time-varying intercept beta_0(t).
  
  #########
  ## Basic dimensions
  #########
  
  nbasis <- ncol(bases.grid)
  ncoef <- p + 1
  
 #########
  ## Extract alpha draws
  #########
  ## This uses the internal helper from tdmm.helpers.R.
  ## It supports matrix-style alpha[k,l] names and separate
  ## alpha0, alpha1, ..., alphap naming.
  
  alpha.draws <- .extract.alpha.draws(post.mat = post.mat, p = p, nbasis = nbasis)
  
  #########
  ## Set credible interval probabilities
  #########
  
  probs <- c((1 - level) / 2, 1 - (1 - level) / 2)
  
  #########
  ## Recover beta draws and summaries
  #########
  
  beta.draws <- vector("list", ncoef)
  beta.mean <- vector("list", ncoef)
  beta.lower <- vector("list", ncoef)
  beta.upper <- vector("list", ncoef)
  beta.sd <- vector("list", ncoef)
  
  for (k in seq_len(ncoef)) {
    
    ## Extract posterior draws for the kth coefficient function.
    alpha.k.draws <- alpha.draws[, k, , drop = FALSE][, 1, ]
    
    ## Convert spline coefficient draws into beta_k(t) draws
    ## on the plotting grid.
    beta.k.draws <- alpha.k.draws %*% t(bases.grid)
    
    beta.draws[[k]] <- beta.k.draws
    beta.mean[[k]] <- colMeans(beta.k.draws)
    beta.lower[[k]] <- apply(beta.k.draws, 2, quantile, probs = probs[1])
    beta.upper[[k]] <- apply(beta.k.draws, 2, quantile, probs = probs[2])
    beta.sd[[k]] <- apply(beta.k.draws, 2, stats::sd)
  }
  
  #########
  ## Name coefficient function outputs
  #########
  
  if (is.null(x.var)) {
    beta.names <- c("beta0", paste0("beta", seq_len(p)))
  } else {
    beta.names <- c("beta0", paste0("beta_", x.var))
  }
  
  names(beta.draws) <- paste0(beta.names, ".draws")
  names(beta.mean) <- paste0(beta.names, ".mean")
  names(beta.lower) <- paste0(beta.names, ".lower")
  names(beta.upper) <- paste0(beta.names, ".upper")
  names(beta.sd) <- paste0(beta.names, ".sd")
  
  list(
    beta.draws = beta.draws,
    beta.mean = beta.mean,
    beta.lower = beta.lower,
    beta.upper = beta.upper,
    beta.sd = beta.sd,
    beta.names = beta.names,
    ncoef = ncoef,
    p = p,
    level = level
  )
}


#########
## Main TDMM plot function
#########

plot.tdmm <- function(data,
                      result,
                      sd = FALSE,
                      level = 0.95,
                      grid = NULL,
                      n.grid = 100,
                      time.var = "time",
                      nknots = NULL,
                      degree = NULL,
                      file = NULL,
                      lwd.mean = 2,
                      lty.band = 3,
                      show.band = TRUE,
                      x.axis.values = NULL,
                      x.axis.labels = NULL,
                      xlab = "time",
                      coef.labels = NULL,
                      width = 2200,
                      height = 700,
                      res = 150) {
  
  ## This is the main plotting function for fitted TDMM objects.
  ##
  ## It plots posterior mean coefficient functions with either:
  ##   - pointwise credible intervals, if sd = FALSE
  ##   - posterior standard deviation bands, if sd = TRUE
  ##
  ## The fitted curves are shown on the model's linear predictor scale.
  ## For Gaussian models this is the response scale.
  ## For Bernoulli models this is the log-odds scale.
  ## For Poisson models this is the log-mean scale.
  ##
  ## The main arguments are:
  ##   data   = original data frame used to fit the model
  ##   result = fitted TDMM object from tdmm() or tdmm.parallel()
  ##   sd     = whether to use posterior SD bands instead of CIs
  ##   level  = credible interval level
  ##   grid   = optional plotting grid
  ##   n.grid = number of plotting grid points if grid is NULL
  
  #########
  ## Check fitted object
  #########
  
  if (!inherits(result, "tdmm")) {
    stop("result must be a fitted TDMM object.", call. = FALSE)
  }
  
  #########
  ## Check optional x-axis labels
  #########
  
  if (is.null(x.axis.values) != is.null(x.axis.labels)) {
    stop("x.axis.values and x.axis.labels must either both be NULL or both be provided.", call. = FALSE)
  }
  
  if (!is.null(x.axis.values) &&
      length(x.axis.values) != length(x.axis.labels)) {
    stop("x.axis.values and x.axis.labels must have the same length.", call. = FALSE)
  }
  
  #########
  ## Extract posterior samples
  #########
  
  if (!is.null(result$post.mat)) {
    post.mat <- result$post.mat
  } else if (!is.null(result$post.samples)) {
    post.mat <- as.matrix(result$post.samples)
  } else {
    stop("Could not find posterior samples in result.", call. = FALSE)
  }
  
  #########
  ## Extract model settings
  #########
  
  if (is.null(nknots)) {
    if (!is.null(result$model.settings$nknots)) {
      nknots <- result$model.settings$nknots
    } else if (!is.null(result$inputs$nknots)) {
      nknots <- result$inputs$nknots
    } else {
      stop("nknots was not found in result. Please supply nknots manually.", call. = FALSE)
    }
  }
  
  if (is.null(degree)) {
    if (!is.null(result$model.settings$degree)) {
      degree <- result$model.settings$degree
    } else if (!is.null(result$inputs$degree)) {
      degree <- result$inputs$degree
    } else {
      degree <- 2
    }
  }
  
  ## Extract covariate information.
  p <- result$inputs$p
  x.var <- result$inputs$x.var
  
  #########
  ## Build plotting grid
  #########
  
  plot.grid <- make.tdmm.plot.grid(
    data = data, grid = grid, n.grid = n.grid, time.var = time.var, nknots = nknots, degree = degree)
  
  #########
  ## Recover coefficient summaries
  #########
  
  beta.out <- recover.tdmm.betas.ci(
    post.mat = post.mat, bases.grid = plot.grid$bases.grid, p = p, x.var = x.var, level = level)
  
  ncoef <- beta.out$ncoef
  
  #########
  ## Check coefficient labels
  #########
  
  if (!is.null(coef.labels) && length(coef.labels) != ncoef) {
    stop(
      "coef.labels must have the same length as the number of coefficient functions.",
      call. = FALSE
    )
  }
  
  #########
  ## Open file device if requested
  #########
  
  if (!is.null(file)) {
    grDevices::png(filename = file, width = width, height = height, res = res)
    on.exit(grDevices::dev.off(), add = TRUE)
  }
  
  #########
  ## Set plot layout
  #########
  
  old.par <- graphics::par(no.readonly = TRUE)
  on.exit(graphics::par(old.par), add = TRUE)
  
  if (ncoef <= 3) {
    graphics::par(
      mfrow = c(1, ncoef),
      mar = c(4.2, 4.2, 3.2, 1.2),
      oma = c(0, 0, 1, 0),
      mgp = c(2.4, 0.8, 0),
      cex.axis = 0.85,
      cex.lab = 0.95,
      cex.main = 0.95
    )
  } else {
    graphics::par(
      mfrow = c(ceiling(ncoef / 2), 2),
      mar = c(4.2, 4.2, 3.2, 1.2),
      oma = c(0, 0, 1, 0),
      mgp = c(2.4, 0.8, 0),
      cex.axis = 0.85,
      cex.lab = 0.95,
      cex.main = 0.95
    )
  }
  
  #########
  ## Plot each coefficient function
  #########
  
  for (k in seq_len(ncoef)) {
    beta.label <- paste0("beta[", k - 1, "](t)")
    if (!is.null(coef.labels)) {
      main.label <- coef.labels[k]
    } else {
      main.label <- beta.label
    }
    
    ## Choose uncertainty bands.
    if (sd) {
      lower.band <- beta.out$beta.mean[[k]] - beta.out$beta.sd[[k]]
      upper.band <- beta.out$beta.mean[[k]] + beta.out$beta.sd[[k]]
    } else {
      lower.band <- beta.out$beta.lower[[k]]
      upper.band <- beta.out$beta.upper[[k]]
    }
    
    y.range <- range(beta.out$beta.mean[[k]], lower.band, upper.band, na.rm = TRUE)
    
    graphics::plot(
      plot.grid$grid,
      beta.out$beta.mean[[k]],
      type = "l",
      lwd = lwd.mean,
      ylim = y.range,
      xaxt = "n",
      xlab = xlab,
      ylab = beta.label,
      main = main.label
    )
    
    ## Add either the default numeric time axis or the custom axis.
    if (!is.null(x.axis.values) && !is.null(x.axis.labels)) {
      graphics::axis(1, at = x.axis.values, labels = x.axis.labels)
    } else {
      graphics::axis(1)
    }
    
    if (show.band) {
      graphics::lines(plot.grid$grid, lower.band, lty = lty.band)
      graphics::lines(plot.grid$grid, upper.band, lty = lty.band)
    }
    
    graphics::abline(h = 0, lty = 2)
  }
  
  #########
  ## Return plotting summaries invisibly
  #########
  
  invisible(list(grid = plot.grid$grid, bases.grid = plot.grid$bases.grid, summaries = beta.out))
}
