
## Gaussian TDMM parallel simulation example
devtools::install_github("esrakurum/Bayesian-TDMM")
library(TDMM)
library(coda)

## Generate Gaussian TDMM data

data.gauss <- data.gen.tdmm.gauss(n.subject = 200, n.time = 20,
                                  sigma2.b = 0.5, sigma2.e = 0.1, seed = 541)

head(data.gauss)
dim(data.gauss)

## Check data structure

check.gauss <- check.tdmm.family.data(data = data.gauss, family = "gaussian")

check.gauss$structure.check$subject.balance$n.subject
check.gauss$structure.check$subject.balance$balanced
check.gauss$structure.check$subject.balance$common.time.grid
check.gauss$structure.check$x.constant.within.subject

check.gauss$response.check$overall
head(check.gauss$response.check$by.time)

## Fit Gaussian TDMM using chain-level parallelization
fit.gauss.parallel <- tdmm.parallel(data = data.gauss, family = "gaussian", nknots = 15, 
                                    n.chains = 3, n.cores = 3, seed = 541)

## Check fitted object

summary.tdmm(fit.gauss.parallel)

fit.gauss.parallel$model.settings$family
fit.gauss.parallel$beta.names

fit.gauss.parallel$model.settings$parallel.method
fit.gauss.parallel$model.settings$n.cores
fit.gauss.parallel$model.settings$n.chains

head(fit.gauss.parallel$time.points)
head(fit.gauss.parallel$beta0.hat)
head(fit.gauss.parallel$beta1.hat)

fit.gauss.parallel$sigma2.b
fit.gauss.parallel$sigma2.e


## Save fitted coefficient summaries

gauss.parallel.beta.summary <- data.frame(
  time = fit.gauss.parallel$time.points,
  beta0.hat = fit.gauss.parallel$beta0.hat,
  beta1.hat = fit.gauss.parallel$beta1.hat,
  true.beta0 = sin(2 * pi * fit.gauss.parallel$time.points),
  true.beta1 = cos(2 * pi * fit.gauss.parallel$time.points)
)

head(gauss.parallel.beta.summary)

write.csv(gauss.parallel.beta.summary,
  file = "gaussian_parallel_beta_summary_for_handbook.csv",
  row.names = FALSE)

## Plot fitted coefficient functions

plot.tdmm(data = data.gauss, result = fit.gauss.parallel, sd = FALSE,
  level = 0.95, grid = NULL, n.grid = 100,
  file = "gaussian_parallel_tdmm_beta_plot_for_handbook.png")

## Trace plots for variance terms

params <- c("sigma2.b", "sigma2.e")
plot.trace.tdmm(result = fit.gauss.parallel,params = params,
  file = "gaussian_parallel_tdmm_trace_variance_for_handbook.png")
