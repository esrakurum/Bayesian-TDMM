# Run from the TDMM repository root after installing TDMM and JAGS.
# Sourcing defines this function only; MCMC starts on an explicit call.
# This is an interface illustration, not a statistical validation study.
run_small_bernoulli_v2 <- function(out='results/bernoulli-v2-user-example',
                                   fit_model=TRUE) {
  source('examples/bernoulli-v2-example.R', local=TRUE)
  sim <- simulate_bernoulli_v2(seed=20261021L, n_subject=50L, visits=5:8)
  dat <- sim$data
  stopifnot(length(unique(dat$id))==50L,
            length(unique(as.numeric(table(dat$id))))>1L)
  if (!fit_model) return(invisible(dat))
  library(TDMM)
  dir.create(out, recursive=TRUE, showWarnings=FALSE)
  path <- file.path(out,'fit.rds')
  if (file.exists(path)) {
    fitted <- readRDS(path)
    if (!identical(fitted$inputs$data,dat) ||
        fitted$model.settings$family!='bernoulli' ||
        fitted$inputs$n_basis!=8L)
      stop('Saved fit does not match this example; use a new output directory.')
    message('Reusing saved fit; no MCMC rerun.')
  } else {
    fitted <- tdmm(dat, family='bernoulli', subject.var='id',
      time.var='time', y.var='y', x.var=c('baseline','changing'),
      n_basis=8, control=tdmm_control(chains=3, iterations=4000,
        burn_in=1500, thin=2, adapt=2000, seed=77181),
      priors=tdmm.priors('bernoulli'), quiet=TRUE)
    saveRDS(fitted,path)
    saveRDS(dat,file.path(out,'data.rds'))
  }
  writeLines(capture.output(summary(fitted)),file.path(out,'summary.txt'))
  grDevices::pdf(file.path(out,'coefficients.pdf'),width=10,height=4)
  plot(fitted)
  grDevices::dev.off()
  grDevices::pdf(file.path(out,'traces.pdf'),width=9,height=7)
  plot.trace.tdmm(fitted,c('sigma.b','tau.alpha[1]'))
  grDevices::dev.off()
  message('Inspect reconstructed curves and chain diagnostics before inference.')
  invisible(fitted)
}
