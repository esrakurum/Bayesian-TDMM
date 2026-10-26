library(TDMM)

# Check the repeated-measures generator against its explicit draw sequence.
seed <- 271L
set.seed(seed)
n.subject <- 5L
n.time <- 4L
time <- rep(seq(0, 1, length.out = n.time), times = n.subject)
id <- rep(seq_len(n.subject), each = n.time)
x1 <- rep(rnorm(n.subject), each = n.time)
b <- rnorm(n.subject, sd = sqrt(.5))[id]
eps <- rnorm(n.subject * n.time, sd = sqrt(.1))
expected <- data.frame(subject.ID = id, time = time,
  y = sin(2 * pi * time) + cos(2 * pi * time) * x1 + b + eps,
  x1 = x1)
stopifnot(identical(data.gen.tdmm.gauss(n.subject, n.time, seed = seed),
  expected),
  identical(data.gen.tdmm.gauss(n.subject, n.time, seed = seed),
    data.gen.tdmm.gauss(n.subject, n.time, seed = seed,
      random_intercept = TRUE)))

default.repeated <- data.gen.tdmm.gauss(seed = seed)
stopifnot(nrow(default.repeated) == 200L * 20L,
  length(unique(default.repeated$subject.ID)) == 200L)

# Reproduce every RNG draw of the independent-observation branch.
n <- 48L
set.seed(seed)
t <- runif(n)
x1 <- rnorm(n)
u <- runif(n)
x2 <- sin(2 * pi * u) + rnorm(n, sd = .25)
mean_y <- sin(2 * pi * t) + cos(2 * pi * t) * x1 +
  1.5 * (t - .5) * x2
y <- mean_y + rnorm(n, sd = sqrt(.1))
independent <- data.gen.tdmm.gauss(n.subject = n, n.time = 99L,
  seed = seed, random_intercept = FALSE)
stopifnot(identical(independent,
  data.frame(subject.ID = seq_len(n), time = t, y = y,
    x1 = x1, x2 = x2)),
  nrow(independent) == n,
  all(table(independent$subject.ID) == 1L),
  all(independent$time >= 0 & independent$time <= 1),
  identical(independent,
    data.gen.tdmm.gauss(n.subject = n, n.time = 1L,
      sigma2.b = 100, seed = seed, random_intercept = FALSE)))

default.independent <- data.gen.tdmm.gauss(seed = seed,
  random_intercept = FALSE)
stopifnot(nrow(default.independent) == 300L,
  all(table(default.independent$subject.ID) == 1L),
  identical(default.independent,
    data.gen.tdmm.gauss(n.subject = 300L, seed = seed,
      random_intercept = FALSE)))

large <- data.gen.tdmm.gauss(n.subject = 5000L, seed = 431L,
  random_intercept = FALSE)
stopifnot(abs(cor(large$x2, large$time)) < .05,
  abs(mean(large$x2)) < .05,
  abs(sd(large$x2) - sqrt(.5 + .25^2)) < .05)

for (value in list(NA, c(TRUE, FALSE), 1, "FALSE")) {
  err <- tryCatch(data.gen.tdmm.gauss(random_intercept = value),
    error = identity)
  stopifnot(inherits(err, "error"))
}

fit <- tdmm(independent, family = "gaussian", x.var = c("x1", "x2"),
  random_intercept = FALSE, n.chains = 2, n.iter = 150,
  n.burn = 75, n.thin = 1, n.adapt = 100, quiet = TRUE)
stopifnot(inherits(fit, "tdmm"),
  identical(fit$model.settings$random_intercept, FALSE),
  ncol(fit$beta.hat) == 3L,
  is.null(fit$sigma.b), is.null(fit$sigma2.b),
  all(is.finite(fit$beta.hat)))
cat("PASS Gaussian simulation random_intercept TRUE/FALSE and FALSE fit\n")
