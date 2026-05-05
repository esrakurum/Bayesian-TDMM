## Bernoulli TDMM simulation example
devtools::install_github("esrakurum/Bayesian-TDMM")
library(TDMM)

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

## Fit Bernoulli TDMM

fit.bern <- tdmm(data = data.bern, family = "bernoulli", nknots = 15)

## Check fitted object
summary.tdmm(fit.bern)

fit.bern$family
fit.bern$beta.names

head(fit.bern$time.points)
head(fit.bern$beta0.hat)
head(fit.bern$beta1.hat)

fit.bern$sigma2.b

## Save fitted coefficient summaries

bern.beta.summary <- data.frame(
  time = fit.bern$time.points,
  beta0.hat = fit.bern$beta0.hat,
  beta1.hat = fit.bern$beta1.hat,
  true.beta0 = sin(2 * pi * fit.bern$time.points),
  true.beta1 = cos(2 * pi * fit.bern$time.points)
)

head(bern.beta.summary)

write.csv(
  bern.beta.summary,
  file = "bernoulli_beta_summary_for_handbook.csv",
  row.names = FALSE
)

## Plot fitted coefficient functions
plot.tdmm(data = data.bern, result = fit.bern, sd = FALSE,
  level = 0.95, grid = NULL, n.grid = 100,
  file = "bernoulli_tdmm_beta_plot_for_handbook.png")

## Trace plot for variance term
params <- "sigma2.b"
plot.trace.tdmm(result = fit.bern, params = params,
  file = "bernoulli_tdmm_trace_variance_for_handbook.png")

