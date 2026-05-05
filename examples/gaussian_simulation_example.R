
## Gaussian TDMM simulation example
devtools::install_github("esrakurum/Bayesian-Varying-Coefficient-Models")
library(TDMM)

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

## Fit Gaussian TDMM

fit.gauss <- tdmm(data = data.gauss, family = "gaussian", nknots = 15)

## Check fitted object
summary.tdmm(fit.gauss)

fit.gauss$family
fit.gauss$beta.names

head(fit.gauss$time.points)
head(fit.gauss$beta0.hat)
head(fit.gauss$beta1.hat)

fit.gauss$sigma2.b
fit.gauss$sigma2.e

## Save fitted coefficient summaries

gauss.beta.summary <- data.frame(
  time = fit.gauss$time.points,
  beta0.hat = fit.gauss$beta0.hat,
  beta1.hat = fit.gauss$beta1.hat,
  true.beta0 = sin(2 * pi * fit.gauss$time.points),
  true.beta1 = cos(2 * pi * fit.gauss$time.points)
)

head(gauss.beta.summary)

write.csv(
  gauss.beta.summary,
  file = "gaussian_beta_summary_for_handbook.csv",
  row.names = FALSE
)

## Plot fitted coefficient functions
plot.tdmm(data = data.gauss, result = fit.gauss, sd = FALSE,
  level = 0.95, grid = NULL, n.grid = 100,
  file = "gaussian_tdmm_beta_plot_for_handbook.png")

## Trace plots for variance terms
params <- c("sigma2.e", "sigma2.b")
plot.trace.tdmm(result = fit.gauss, params = params,
  file = "gaussian_tdmm_trace_variance_for_handbook.png")

