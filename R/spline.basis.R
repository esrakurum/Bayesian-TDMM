# Shared spline specification, uses eight cubic bases.
.resolve.n_basis <- function(n_basis = NULL, nknots = NULL, degree = 3) {
  integer.scalar <- function(x) is.numeric(x) && length(x) == 1L &&
    is.finite(x) && x == floor(x)
  if (!integer.scalar(degree) || degree < 0)
    stop("degree must be a nonnegative integer.", call. = FALSE)
  if (!is.null(n_basis) && !is.null(nknots))
    stop("Supply only one of n_basis and nknots.", call. = FALSE)
  if (!is.null(nknots)) {
    if (!integer.scalar(nknots) || nknots < 3)
      stop("Legacy nknots must be an integer >= 3.", call. = FALSE)
    warning("nknots is deprecated: intervals = nknots - 2; use n_basis = nknots + degree - 2. The default degree is now 3.", call. = FALSE)
    n_basis <- nknots + degree - 2
  }
  if (is.null(n_basis)) n_basis <- 8L
  if (!integer.scalar(n_basis) || n_basis < max(3, degree + 1))
    stop("n_basis must be an integer >= max(3, degree + 1).", call. = FALSE)
  as.integer(n_basis)
}

.make.spline.spec <- function(tlo, thi, n_basis, degree = 3) {
  n_basis <- .resolve.n_basis(n_basis, degree = degree)
  if (length(tlo) != 1L || length(thi) != 1L ||
      !is.finite(tlo) || !is.finite(thi) || thi <= tlo)
    stop("Spline boundaries must be finite and increasing.", call. = FALSE)
  intervals <- n_basis - degree
  knots <- tlo + (-degree:(intervals + degree)) * ((thi - tlo) / intervals)
  if (any(diff(knots) <= 0)) stop("Time scale cannot resolve distinct knots.", call. = FALSE)
  list(n_basis = n_basis, degree = degree, order = degree + 1,
       intervals = intervals, tlo = tlo, thi = thi, knots = knots,
       convention = "standard", evaluator = "splineDesign", version = 1L)
}

.evaluate.spline <- function(x, spec) {
  if (!is.numeric(x) || any(!is.finite(x)))
    stop("Evaluation times must be finite numeric values.", call. = FALSE)
  if (identical(spec$convention, "legacy-signed")) {
    if (length(x) == 1L)
      return(.legacy.bbase(rep(x, 2), spec$tlo, spec$thi,
                           spec$intervals, spec$degree)[1, , drop = FALSE])
    return(.legacy.bbase(x, spec$tlo, spec$thi, spec$intervals, spec$degree))
  }
  if (!identical(spec$convention, "standard"))
    stop("Unknown fitted basis convention.", call. = FALSE)
  splines::splineDesign(spec$knots, x, ord = spec$order, outer.ok = TRUE)
}

# Internal compatibility for code using the interval-based constructor.
bbase <- function(x, xl, xr, ndx, deg) {
  .evaluate.spline(x, .make.spline.spec(xl, xr, ndx + deg, deg))
}

# Never infer a legacy object's degree from the new default. Unversioned objects
# must contain enough stored basis information to identify their convention.
.fitted.spline.spec <- function(result) {
  i <- result$inputs
  if (!is.null(i$spline)) return(i$spline)
  d <- i$degree
  if (is.null(d)) d <- result$model.settings$degree
  if (is.null(d) || is.null(i$basis) || is.null(result$time.points))
    stop("Legacy fit lacks degree/basis metadata; reconstruction is ambiguous.", call. = FALSE)
  spec <- .make.spline.spec(i$tlo, i$thi, ncol(i$basis), d)
  convention <- i$basis.convention
  if (is.null(convention)) convention <- result$model.settings$basis.convention
  if (!is.null(convention)) {
    spec$convention <- convention
  } else {
    same <- function(b) isTRUE(all.equal(unname(b), unname(i$basis),
                                        tolerance = 1e-7, check.attributes = FALSE))
    if (same(.evaluate.spline(result$time.points, spec))) return(spec)
    spec$convention <- "legacy-signed"
    if (!same(.evaluate.spline(result$time.points, spec)))
      stop("Cannot identify legacy fitted basis convention.", call. = FALSE)
  }
  spec
}

tpower <- function(x, t, p) {
  (x - t)^p * (x > t)
}


############################################################
## Construct the spline basis matrix
############################################################

## This function builds the spline basis matrix over a chosen
## time grid.
##
## The basis is used to represent the time-varying coefficient
## functions beta0(t), beta1(t), and any additional beta functions.

.legacy.bbase <- function(x, xl, xr, ndx, deg) {
  
  ## create equally spaced knots
  dx <- (xr - xl) / ndx
  knots <- seq(xl - deg * dx, xr + deg * dx, by = dx)
  
  ## number of basis functions
  n.basis <- length(knots) - deg - 1
  
  ## initialize the basis matrix
  B <- matrix(0, nrow = length(x), ncol = n.basis)
  
  ## build each basis function
  for (j in 1:n.basis) {
    
    B[, j] <- (-1)^(deg + 1) / (factorial(deg) * dx^deg) *
      rowSums(
        sapply(0:(deg + 1), function(k) {
          choose(deg + 1, k) *
            (-1)^k *
            tpower(x, knots[j + k], deg)
        })
      )
  }
  
  ## return the spline basis matrix
  B
}
