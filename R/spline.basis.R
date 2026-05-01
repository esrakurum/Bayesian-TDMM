############################################################
## Spline basis functions
############################################################

## truncated power basis function
## this is used as a building block for the spline basis

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

bbase <- function(x, xl, xr, ndx, deg) {
  
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
