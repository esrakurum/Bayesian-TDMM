## Poisson TDMM parallel simulation example
devtools::install_github("esrakurum/Bayesian-TDMM")
library(TDMM)
library(coda)

## Generate Poisson TDMM data

data.pois <- data.gen.tdmm.pois(n.subject = 200, n.time = 20,
                                sigma2.b = 0.5, seed = 541)

head(data.pois)
dim(data.pois)
summary(data.pois$y)
table(data.pois$y)

## Check data structure

check.pois <- check.tdmm.family.data(data = data.pois, family = "poisson")

check.pois$structure.check$subject.balance$n.subject
check.pois$structure.check$subject.balance$balanced
check.pois$structure.check$subject.balance$common.time.grid
check.pois$structure.check$x.constant.within.subject

check.pois$response.check$overall
head(check.pois$response.check$by.time)

## Fit Poisson TDMM using chain-level parallelization

fit.pois.parallel <- tdmm.parallel(data = data.pois, family = "poisson", nknots = 15,
                                   n.chains = 3, n.cores = 3, seed = 541)

## Check fitted object

summary.tdmm(fit.pois.parallel)

fit.pois.parallel$model.settings$family
fit.pois.parallel$beta.names

fit.pois.parallel$model.settings$parallel.method
fit.pois.parallel$model.settings$n.cores
fit.pois.parallel$model.settings$n.chains

head(fit.pois.parallel$time.points)
head(fit.pois.parallel$beta0.hat)
head(fit.pois.parallel$beta1.hat)

fit.pois.parallel$sigma2.b

## Save fitted coefficient summaries

pois.parallel.beta.summary <- data.frame(
  time = fit.pois.parallel$time.points,
  beta0.hat = fit.pois.parallel$beta0.hat,
  beta1.hat = fit.pois.parallel$beta1.hat,
  true.beta0 = sin(2 * pi * fit.pois.parallel$time.points),
  true.beta1 = cos(2 * pi * fit.pois.parallel$time.points)
)

head(pois.parallel.beta.summary)

write.csv(pois.parallel.beta.summary,
  file = "poisson_parallel_beta_summary_for_handbook.csv",
  row.names = FALSE)

## Plot fitted coefficient functions

plot.tdmm(data = data.pois, result = fit.pois.parallel, sd = FALSE,
  level = 0.95, grid = NULL, n.grid = 100,
  file = "poisson_parallel_tdmm_beta_plot_for_handbook.png")

## Trace plot for variance term

params <- "sigma2.b"
plot.trace.tdmm(result = fit.pois.parallel, params = params,
  file = "poisson_parallel_tdmm_trace_variance_for_handbook.png")
