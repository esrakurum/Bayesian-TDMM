# Reusable Gaussian V2 design. No fitting, file writes, or basis construction.
# Coefficients are on the response scale; the seed makes data reproducible.
gaussian_v2_truth <- function(time) {
  cbind(beta0 = sin(2*pi*time), beta1 = cos(2*pi*time),
        beta2 = 1.5*(time - .5))
}

simulate_gaussian_v2 <- function(seed, n_subject = 200L, visits = 5:10,
                                 sigma_b = sqrt(.5), sigma_e = sqrt(.1)) {
  stopifnot(length(seed) == 1L, is.finite(seed),
            length(n_subject) == 1L, is.finite(n_subject), n_subject >= 2,
            n_subject == as.integer(n_subject), length(visits) >= 1L,
            all(is.finite(visits)), all(visits >= 2),
            all(visits == as.integer(visits)),
            length(sigma_b) == 1L, is.finite(sigma_b), sigma_b > 0,
            length(sigma_e) == 1L, is.finite(sigma_e), sigma_e > 0)
  # Preserve the caller's RNG state.
  had_seed <- exists('.Random.seed', envir = .GlobalEnv, inherits = FALSE)
  if (had_seed) old_seed <- get('.Random.seed', envir = .GlobalEnv)
  on.exit(if (had_seed) assign('.Random.seed', old_seed, envir = .GlobalEnv)
          else if (exists('.Random.seed', envir = .GlobalEnv, inherits = FALSE))
            rm('.Random.seed', envir = .GlobalEnv), add = TRUE)
  set.seed(seed)
  rows <- lapply(seq_len(n_subject), function(i) {
    n <- visits[sample.int(length(visits), 1L)]
    time <- sort(runif(n))
    baseline <- rnorm(1L)
    changing <- sin(2*pi*time) + rnorm(n, sd = .25)
    b <- rnorm(1L, sd = sigma_b)
    beta <- gaussian_v2_truth(time)
    eta <- beta[, 1] + baseline*beta[, 2] + changing*beta[, 3] + b
    data.frame(id = paste0('person-', i), time = time,
               y = rnorm(n, eta, sd = sigma_e), baseline = baseline,
               changing = changing, true_b = b, eta = eta)
  })
  all <- do.call(rbind, rows)
  list(data = all[, c('id', 'time', 'y', 'baseline', 'changing')],
       truth = gaussian_v2_truth(all$time), true_b = all$true_b,
       eta = all$eta,
       settings = list(seed = seed, n_subject = n_subject, visits = visits,
                       sigma_b = sigma_b, sigma_e = sigma_e,
                       observation_noise_sd = .25,
                       fit_n_basis = 8L, fit_degree = 3L))
}
