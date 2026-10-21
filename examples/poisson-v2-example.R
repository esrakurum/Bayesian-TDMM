# Reusable Poisson V2 design. No fitting, file writes, or basis construction.
# Coefficients are log-rate effects. seed is explicit for repeated studies.
poisson_v2_truth <- function(time) {
  cbind(beta0=0.25+0.35*sin(2*pi*time),
        beta1=0.35*cos(2*pi*time), beta2=0.25+0.20*time)
}
simulate_poisson_v2 <- function(seed, n_subject=200L, visits=8:14,
                                sigma_b=0.5) {
  stopifnot(length(seed)==1L, is.finite(seed),
    length(n_subject)==1L, is.finite(n_subject), n_subject>=2,
    n_subject==as.integer(n_subject), length(visits)>=1L,
    all(is.finite(visits)), all(visits>=2), all(visits==as.integer(visits)),
    length(sigma_b)==1L, is.finite(sigma_b), sigma_b>0)
  # Preserve the caller's RNG state; data and fitting RNG are separate.
  had_seed <- exists('.Random.seed',envir=.GlobalEnv,inherits=FALSE)
  if(had_seed) old_seed <- get('.Random.seed',envir=.GlobalEnv)
  on.exit(if(had_seed) assign('.Random.seed',old_seed,envir=.GlobalEnv)
          else if(exists('.Random.seed',envir=.GlobalEnv,inherits=FALSE))
            rm('.Random.seed',envir=.GlobalEnv),add=TRUE)
  set.seed(seed)
  baseline <- rnorm(n_subject)
  subject_component <- rnorm(n_subject)
  b <- rnorm(n_subject,sd=sigma_b)
  rows <- lapply(seq_len(n_subject),function(i) {
    n <- visits[sample.int(length(visits),1)]
    time <- sort(runif(n))
    changing <- subject_component[i]+0.5*time+rnorm(n,sd=0.5)
    beta <- poisson_v2_truth(time)
    eta <- beta[,1]+baseline[i]*beta[,2]+changing*beta[,3]+b[i]
    data.frame(id=i,time=time,y=rpois(n,exp(eta)),
      baseline=baseline[i],changing=changing,
      true_b=b[i],eta=eta,lambda=exp(eta))
  })
  all <- do.call(rbind,rows)
  list(data=all[,c('id','time','y','baseline','changing')],
    truth=poisson_v2_truth(all$time),true_b=all$true_b,
    eta=all$eta,lambda=all$lambda,
    subjects=data.frame(id=seq_len(n_subject),baseline=baseline,
      subject_component=subject_component,b=b),
    settings=list(seed=seed,n_subject=n_subject,visits=visits,sigma_b=sigma_b,
      subject_component_sd=1,time_trend=0.5,observation_noise_sd=0.5,
      fit_n_basis=8L,fit_degree=3L,scenario='poisson-v2-final'))
}

# Source this standalone file, then call run_poisson_example().
# Requires installed TDMM V2, R2jags/rjags/coda and system JAGS.
# Uses one illustrative dataset; this is not a repeated simulation study.
run_poisson_example <- function(out='poisson-example-output') {
  library(TDMM)
  sim <- simulate_poisson_v2(seed=20261021L)
  dat <- sim$data
  saved <- file.path(out,'fit.rds')
  if(file.exists(saved)) {
    fit <- readRDS(saved)
    stopifnot(identical(fit$inputs$data,dat),fit$family=='poisson',
      fit$inputs$n_basis==8L,fit$inputs$degree==3,
      fit$model.settings$n.chains==3,fit$model.settings$n.iter==8000,
      fit$model.settings$n.burn==3000,fit$model.settings$n.thin==5,
      fit$model.settings$n.adapt==5000)
    message('Reusing saved matching fit; no additional MCMC.')
  } else {
    dir.create(out,recursive=TRUE,showWarnings=FALSE)
    saveRDS(sim,file.path(out,'simulation.rds'))
    set.seed(87181L) # Separate fitting seed; initialization uses package defaults.
    fit <- tdmm(dat,family='poisson',subject.var='id',
      x.var=c('baseline','changing'),n_basis=8,degree=3,
      n.chains=3,n.iter=8000,n.burn=3000,n.thin=5,n.adapt=5000)
    saveRDS(fit,saved)
  }
  summary(fit)
  # No JAGS paths, basis matrices or subject mappings are needed from the user.
  plot.tdmm(dat,fit)
  plot.trace.tdmm(fit,c('sigma.b','tau.alpha[1]','tau.alpha[2]','tau.alpha[3]'))
  invisible(list(data=dat,fit=fit,truth=poisson_v2_truth,
                 true_sigma_b=sim$settings$sigma_b))
}
