## Bernoulli TDMM parallel simulation example
devtools::install_github("esrakurum/Bayesian-TDMMM")
library(TDMM)
library(coda)
library(rjags)

## Generate Bernoulli TDMM data

data.bern <- data.gen.tdmm.bern(n.subject = 200, n.time = 20,
                                sigma2.b = 0.5, seed = 541)

head(data.bern)
dim(data.bern)
table(data.bern$y)

## Check data structure

check.bern <- check.tdmm.family.data(data = data.bern, family = "bernoulli")

check.bern$structure.check$subject.balance$n.subject
check.bern$structure.check$subject.balance$balanced
check.bern$structure.check$subject.balance$common.time.grid
check.bern$structure.check$x.constant.within.subject

check.bern$response.check$overall.counts
check.bern$response.check$overall.proportions
head(check.bern$response.check$by.time)

## Fit Bernoulli TDMM using chain-level parallelization

fit.bern.parallel <- tdmm.parallel(data = data.bern, family = "bernoulli", nknots = 15,
                                   n.chains = 3, n.cores = 3, seed = 541)

## Check fitted object

summary.tdmm(fit.bern.parallel)

fit.bern.parallel$model.settings$family
fit.bern.parallel$beta.names

fit.bern.parallel$model.settings$parallel.method
fit.bern.parallel$model.settings$n.cores
fit.bern.parallel$model.settings$n.chains

head(fit.bern.parallel$time.points)
head(fit.bern.parallel$beta0.hat)
head(fit.bern.parallel$beta1.hat)

fit.bern.parallel$sigma2.b

## Save fitted coefficient summaries

bern.parallel.beta.summary <- data.frame(
  time = fit.bern.parallel$time.points,
  beta0.hat = fit.bern.parallel$beta0.hat,
  beta1.hat = fit.bern.parallel$beta1.hat,
  true.beta0 = sin(2 * pi * fit.bern.parallel$time.points),
  true.beta1 = cos(2 * pi * fit.bern.parallel$time.points)
)

head(bern.parallel.beta.summary)

write.csv(bern.parallel.beta.summary,
  file = "bernoulli_parallel_beta_summary_for_handbook.csv",
  row.names = FALSE)

## Plot fitted coefficient functions

plot.tdmm(data = data.bern, result = fit.bern.parallel, sd = FALSE,
  level = 0.95, grid = NULL, n.grid = 100,
  file = "bernoulli_parallel_tdmm_beta_plot_for_handbook.png")

## Trace plot for variance term

params <- "sigma2.b"
plot.trace.tdmm(result = fit.bern.parallel, params = params,
  file = "bernoulli_parallel_tdmm_trace_variance_for_handbook.png")

