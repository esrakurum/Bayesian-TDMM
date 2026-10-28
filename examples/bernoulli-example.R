# Reusable Bernoulli simulation design. No fitting, file writes, or basis construction.
# Coefficients are log-odds effects; the seed makes the example reproducible.
bernoulli_truth <- function(time) {
  cbind(beta0=-0.5+0.75*sin(2*pi*time),
        beta1=0.75*cos(2*pi*time), beta2=0.5+0.25*time)
}
simulate_bernoulli <- function(seed, n_subject=200L, visits=8:14,
                                sigma_b=sqrt(0.5)) {
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
    beta <- bernoulli_truth(time)
    eta <- beta[,1]+baseline[i]*beta[,2]+changing*beta[,3]+b[i]
    data.frame(id=i,time=time,y=rbinom(n,1,plogis(eta)),
      baseline=baseline[i],changing=changing,
      true_b=b[i],eta=eta,probability=plogis(eta))
  })
  all <- do.call(rbind,rows)
  list(data=all[,c('id','time','y','baseline','changing')],
    truth=bernoulli_truth(all$time),true_b=all$true_b,
    eta=all$eta,probability=all$probability,
    subjects=data.frame(id=seq_len(n_subject),baseline=baseline,
      subject_component=subject_component,b=b),
    settings=list(seed=seed,n_subject=n_subject,visits=visits,sigma_b=sigma_b,
      subject_component_sd=1,time_trend=0.5,observation_noise_sd=0.5,
      fit_n_basis=8L,fit_degree=3L,scenario='bernoulli-example'))
}

# Standalone user example: source(), then run_bernoulli_example().
# Sourcing does not run MCMC. Existing matching saved fits are reused.
run_bernoulli_example <- function(out="bernoulli-example-output") {
  library(TDMM)
  sim <- simulate_bernoulli(seed=20261021L)
  dat <- sim$data
  saved <- file.path(out,"fit.rds")
  if(file.exists(saved)) {
    fit <- readRDS(saved)
    stopifnot(identical(fit$inputs$data,dat),fit$family=="bernoulli",
      identical(fit$model.settings$spline.prior,"centered null-space"),
      fit$inputs$n_basis==8,fit$inputs$degree==3,
      fit$model.settings$n.chains==3,fit$model.settings$n.iter==20000,
      fit$model.settings$n.burn==10000,fit$model.settings$n.thin==5,
      fit$model.settings$n.adapt==5000)
    message("Reusing matching saved fit; no additional MCMC.")
  } else {
    dir.create(out,recursive=TRUE,showWarnings=FALSE)
    saveRDS(sim,file.path(out,"simulation.rds"))
    set.seed(87181L)
    fit <- tdmm(dat,family="bernoulli",subject.var="id",
      x.var=c("baseline","changing"),n_basis=8,degree=3,
      random_intercept=TRUE,
      n.chains=3,n.iter=20000,n.burn=10000,n.thin=5,n.adapt=5000)
    saveRDS(fit,saved)
  }
  summary(fit)
  plot.tdmm(dat,fit,grid=seq(.01,.99,length.out=100))
  plot.trace.tdmm(fit,c("sigma.b",paste0("tau.alpha[",1:3,"]")))
  invisible(list(data=dat,fit=fit,truth=bernoulli_truth,
    true_sigma_b=sim$settings$sigma_b))
}
