library(TDMM)

seed <- 431L
n.subject <- 5L
n.time <- 4L
set.seed(seed)
time <- rep(seq(0, 1, length.out = n.time), times = n.subject)
id <- rep(seq_len(n.subject), each = n.time)
x1 <- rep(rnorm(n.subject), each = n.time)
b <- rnorm(n.subject, sd = sqrt(.5))[id]
lambda <- exp(sin(2 * pi * time) + cos(2 * pi * time) * x1 + b)
y <- rpois(n.subject * n.time, lambda = lambda)
expected <- data.frame(subject.ID = id, time = time, y = y, x1 = x1)
stopifnot(identical(data.gen.tdmm.pois(n.subject, n.time, seed = seed),
                    expected),
          identical(data.gen.tdmm.pois(n.subject, n.time, seed = seed),
                    data.gen.tdmm.pois(n.subject, n.time, seed = seed,
                                       random_intercept = TRUE)))

default.repeated <- data.gen.tdmm.pois(seed = seed)
stopifnot(nrow(default.repeated) == 200L * 20L,
          length(unique(default.repeated$subject.ID)) == 200L,
          all(table(default.repeated$subject.ID) == 20L))

# Check the independent-observation generator and its draw sequence.
n <- 64L
set.seed(seed)
time <- runif(n)
x1 <- rnorm(n)
component <- rnorm(n)
x2 <- component + 0.5 * time + rnorm(n, sd = 0.5)
beta0 <- 0.25 + 0.35 * sin(2 * pi * time)
beta1 <- 0.35 * cos(2 * pi * time)
beta2 <- 0.25 + 0.20 * time
y <- rpois(n, lambda = exp(beta0 + x1 * beta1 + x2 * beta2))
expected <- data.frame(subject.ID = seq_len(n), time = time, y = y,
                       x1 = x1, x2 = x2)
independent <- data.gen.tdmm.pois(n.subject = n, seed = seed,
                                  random_intercept = FALSE)
stopifnot(identical(independent, expected),
          all(table(independent$subject.ID) == 1L),
          all(independent$time >= 0 & independent$time <= 1),
          identical(independent,
                    data.gen.tdmm.pois(n.subject = n, n.time = 99L,
                                       sigma2.b = 100, seed = seed,
                                       random_intercept = FALSE)))

default.independent <- data.gen.tdmm.pois(seed = seed,
                                          random_intercept = FALSE)
explicit.independent <- data.gen.tdmm.pois(n.subject = 2200L,
                                           seed = seed,
                                           random_intercept = FALSE)
stopifnot(identical(default.independent, explicit.independent),
          nrow(default.independent) == 2200L,
          all(table(default.independent$subject.ID) == 1L))

for (value in list(NA, c(TRUE, FALSE), 1, "FALSE")) {
  error <- tryCatch(data.gen.tdmm.pois(random_intercept = value),
                    error = identity)
  stopifnot(inherits(error, "error"))
}

fit <- tdmm(independent, family = "poisson", x.var = c("x1", "x2"),
            random_intercept = FALSE, n.chains = 2, n.iter = 150,
            n.burn = 75, n.thin = 1, n.adapt = 100, quiet = TRUE)
stopifnot(inherits(fit, "tdmm"),
          identical(fit$model.settings$random_intercept, FALSE),
          ncol(fit$beta.hat) == 3L,
          is.null(fit$sigma.b), is.null(fit$sigma2.b),
          all(is.finite(fit$beta.hat)))
cat("PASS Poisson simulation random_intercept TRUE/FALSE and FALSE fit\n")
