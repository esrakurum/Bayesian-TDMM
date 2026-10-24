# Gaussian example

This example shows how to fit a Gaussian TDMM when subjects have
irregular observation times, unequal visit counts, one baseline
covariate, and one covariate measured at each visit. The coefficient
functions are known because the data are simulated.

``` r
set.seed(27181)
truth <- function(t) cbind(beta0 = sin(2*pi*t),
                           beta1 = cos(2*pi*t),
                           beta2 = 1.5*(t-0.5))
dat <- do.call(rbind, lapply(seq_len(40), function(i) {
  n <- sample(5:8, 1)
  time <- sort(runif(n))
  baseline <- rnorm(1)
  changing <- rnorm(n)
  b <- rnorm(1, sd=sqrt(0.5))
  beta <- truth(time)
  y <- rnorm(n, beta[,1] + baseline*beta[,2] + changing*beta[,3] + b,
             sd=sqrt(0.1))
  data.frame(id=paste0("person-",i), time=time, y=y,
             baseline=baseline, changing=changing)
}))
```

``` r
library(TDMM)
fit <- tdmm(dat, family="gaussian", subject.var="id",
            time.var="time", y.var="y",
            x.var=c("baseline","changing"), n_basis=8,
            control=tdmm_control(chains=3, iterations=4000,
              burn_in=1500, thin=2, adapt=2000, seed=77181),
            priors=tdmm.priors("gaussian"))
summary(fit)
plot(fit)
plot.trace.tdmm(fit,c("sigma.b","sigma2.e","tau.alpha[1]"))
```

Compare the reconstructed curves with `truth()` and examine the
pointwise credible bands. The [Getting Started
article](https://esrakurum.github.io/Bayesian-TDMM/articles/getting-started.md)
explains the scales and diagnostics. The package’s [Sweave
vignette](https://github.com/esrakurum/Bayesian-TDMM/blob/main/vignettes/getting-started.Rnw)
includes an illustration from a larger Gaussian dataset.
