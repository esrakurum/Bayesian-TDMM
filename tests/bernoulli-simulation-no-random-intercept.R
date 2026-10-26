library(TDMM)

seed <- 271L
n.subject <- 5L
n.time <- 4L
set.seed(seed)
time <- rep(seq(0, 1, length.out = n.time), times = n.subject)
id <- rep(seq_len(n.subject), each = n.time)
x1 <- rep(rnorm(n.subject), each = n.time)
b <- rnorm(n.subject, sd = sqrt(.5))[id]
p <- plogis(sin(2 * pi * time) + cos(2 * pi * time) * x1 + b)
y <- rbinom(n.subject * n.time, size = 1, prob = p)
expected <- data.frame(subject.ID = id, time = time, y = y, x1 = x1)
stopifnot(identical(data.gen.tdmm.bern(n.subject, n.time, seed = seed),
                    expected),
          identical(data.gen.tdmm.bern(n.subject, n.time, seed = seed),
                    data.gen.tdmm.bern(n.subject, n.time, seed = seed,
                                       random_intercept = TRUE)))

default.repeated <- data.gen.tdmm.bern(seed = seed)
stopifnot(nrow(default.repeated) == 200L * 20L,
          length(unique(default.repeated$subject.ID)) == 200L,
          all(table(default.repeated$subject.ID) == 20L))

# Reproduce the independent design, including its random-number draw order.
n <- 48L
set.seed(seed)
time <- runif(n)
x1 <- rnorm(n)
p <- plogis(sin(2 * pi * time) + x1 * cos(2 * pi * time))
y <- rbinom(n, size = 1L, prob = p)
expected <- data.frame(subject.ID = seq_len(n), time = time,
                       y = y, x1 = x1)
independent <- data.gen.tdmm.bern(n.subject = n, seed = seed,
                                  random_intercept = FALSE)
stopifnot(identical(independent, expected),
          all(table(independent$subject.ID) == 1L),
          all(independent$time >= 0 & independent$time <= 1),
          identical(independent,
                    data.gen.tdmm.bern(n.subject = n, n.time = 99L,
                                       sigma2.b = 100, seed = seed,
                                       random_intercept = FALSE)))

default.independent <- data.gen.tdmm.bern(seed = seed,
                                          random_intercept = FALSE)
explicit.independent <- data.gen.tdmm.bern(n.subject = 2500L,
                                           seed = seed,
                                           random_intercept = FALSE)
stopifnot(identical(default.independent, explicit.independent),
          nrow(default.independent) == 2500L,
          all(table(default.independent$subject.ID) == 1L))

for (value in list(NA, c(TRUE, FALSE), 1, "FALSE")) {
  error <- tryCatch(data.gen.tdmm.bern(random_intercept = value),
                    error = identity)
  stopifnot(inherits(error, "error"))
}

fit <- tdmm(independent, family = "bernoulli", x.var = "x1",
            random_intercept = FALSE, n.chains = 2, n.iter = 150,
            n.burn = 75, n.thin = 1, n.adapt = 100, quiet = TRUE)
stopifnot(inherits(fit, "tdmm"),
          identical(fit$model.settings$random_intercept, FALSE),
          ncol(fit$beta.hat) == 2L,
          is.null(fit$sigma.b), is.null(fit$sigma2.b),
          all(is.finite(fit$beta.hat)))
cat("PASS Bernoulli simulation random_intercept TRUE/FALSE and FALSE fit\n")
