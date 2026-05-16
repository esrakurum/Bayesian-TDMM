## Poisson TDMM simulation example
devtools::install_github("esrakurum/Bayesian-TDMM")
library(TDMM)

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

## Fit Poisson TDMM

fit.pois <- tdmm(data = data.pois, family = "poisson", nknots = 15)

## Check fitted object
summary.tdmm(fit.pois)

fit.pois$data.check$family
fit.pois$beta.names

head(fit.pois$time.points)
head(fit.pois$beta0.hat)
head(fit.pois$beta1.hat)

fit.pois$sigma2.b

## Save fitted coefficient summaries

pois.beta.summary <- data.frame(
  time = fit.pois$time.points,
  beta0.hat = fit.pois$beta0.hat,
  beta1.hat = fit.pois$beta1.hat,
  true.beta0 = sin(2 * pi * fit.pois$time.points),
  true.beta1 = cos(2 * pi * fit.pois$time.points)
)

head(pois.beta.summary)

write.csv(
  pois.beta.summary,
  file = "poisson_beta_summary_for_handbook.csv",
  row.names = FALSE
)

## Plot fitted coefficient functions
plot.tdmm(data = data.pois, result = fit.pois, sd = FALSE,
  level = 0.95, grid = NULL, n.grid = 100,
  file = "poisson_tdmm_beta_plot_for_handbook.png")

## Trace plot for variance term
params <- c("sigma2.b")
plot.trace.tdmm(result = fit.pois, params = params,
  file = "poisson_tdmm_trace_variance_for_handbook.png")
