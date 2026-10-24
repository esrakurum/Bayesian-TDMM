#!/usr/bin/env Rscript
# Gaussian-only pilot. Run with --check for deterministic checks without MCMC.
argv <- commandArgs(trailingOnly = TRUE)
script <- sub('^--file=', '', grep('^--file=', commandArgs(), value = TRUE)[1])
root <- normalizePath(file.path(dirname(script), '..'), mustWork = TRUE)
out <- file.path(root, 'results', 'gaussian-cubic-pilot')
seeds <- 2001:2010
sizes <- c(6L, 8L, 10L)
grid <- seq(.01, .99, length.out = 100)
settings <- list(seeds=seeds, n_basis=sizes, degree=3L, n_subject=200L,
                 n_chains=3L, n_iter=8000L, n_burn=3000L, n_thin=5L,
                 n_adapt=5000L, grid=grid, variance_b=.5, variance_e=.1)
api <- new.env(parent = globalenv())
for (f in list.files(file.path(root, 'R'), pattern='\\.R$', full.names=TRUE))
  sys.source(f, envir=api)
truth <- function(t) cbind(beta0=sin(2*pi*t), beta1=cos(2*pi*t), beta2=1.5*(t-.5))
simulate_data <- function(seed) {
  set.seed(seed)
  rows <- lapply(seq_len(settings$n_subject), function(id) {
    n <- sample(5:10, 1)
    t <- sort(runif(n))
    baseline <- rnorm(1)
    tv <- sin(2*pi*t) + rnorm(n, sd=.25)
    b <- rnorm(1, sd=sqrt(.5))
    beta <- truth(t)
    y <- rnorm(n, beta[,1] + beta[,2]*baseline + beta[,3]*tv + b, sqrt(.1))
    data.frame(id=id, time=t, y=y, x.baseline=baseline, x.tv=tv)
  })
  do.call(rbind, rows)
}
# --check never fits models or writes output files.
self_check <- function() {
  stopifnot(identical(formals(api$tdmm)$degree, 3),
            'n_basis' %in% names(formals(api$tdmm)))
  for (seed in seeds) {
    dat <- simulate_data(seed)
    stopifnot(identical(dat,simulate_data(seed)),length(unique(dat$id))==200L,
              all(table(dat$id)>=5),all(table(dat$id)<=10),
              min(dat$time)<min(grid),max(dat$time)>max(grid))
    for (q in sizes) {
      i <- api$build.tdmm.subject.inputs(dat,n_basis=q,subject.var='id',
             time.var='time',y.var='y',x.var=c('x.baseline','x.tv'),degree=3)
      stopifnot(ncol(i$bases.obs)==q,i$spline$intervals==q-3,
                i$spline$convention=='standard',i$degree==3)
    }
  }
  cat('PASS: 10 reproducible datasets, 30 cubic design matrices, common grid in range. No fits run.\n')
}
self_check()
if ('--check' %in% argv) quit(status=0)
if (length(argv)) stop('Only optional argument is --check.')
for (p in c('R2jags','rjags','coda'))
  if (!requireNamespace(p,quietly=TRUE)) stop('Install missing package: ',p)

# Bind checkpoints to exact source/model/script bytes and settings. No stale reuse.
source_files <- c(list.files(file.path(root,'R'),full.names=TRUE,pattern='\\.R$'),
                  file.path(root,'inst/jags/TDMM_Gaussian_JAGS.txt'),normalizePath(script))
manifest <- list(settings=settings, md5=tools::md5sum(source_files),
                 R=R.version.string,
                 packages=vapply(c('R2jags','rjags','coda'),function(p)
                   as.character(utils::packageVersion(p)),character(1)),
                 JAGS=as.character(rjags::jags.version()))
dir.create(out,recursive=TRUE,showWarnings=FALSE)
manifest_file <- file.path(out,'manifest.rds')
if (file.exists(manifest_file)) {
  if (!identical(readRDS(manifest_file),manifest))
    stop('Source, settings or software changed. Preserve/rename the existing output directory before a new run.')
} else saveRDS(manifest,manifest_file)
writeLines(capture.output(sessionInfo()),file.path(out,'sessionInfo.txt'))
for (d in c('datasets','fits')) dir.create(file.path(out,d),showWarnings=FALSE)

# Chain-resolved curve draws on exactly the same grid; no interpolation.
curve_chains <- function(fit) {
  B <- api$make.tdmm.plot.grid(NULL,grid=grid,result=fit)$bases.grid
  a <- fit$post.samples$BUGSoutput$sims.array
  lapply(seq_len(dim(a)[2]),function(chain) {
    lapply(seq_len(3),function(k) {
      cols <- paste0('alpha[',k,',',seq_len(ncol(B)),']')
      a[,chain,cols,drop=FALSE][,1,] %*% t(B)
    })
  })
}
chain_stats <- function(chains) {
  m <- coda::mcmc.list(lapply(chains,coda::mcmc))
  # These are already retained post-burn-in draws: do not discard half again.
  r <- coda::gelman.diag(m,multivariate=FALSE,autoburnin=FALSE)$psrf[,1]
  e <- coda::effectiveSize(m)
  list(rhat=r,ess=e)
}
roughness <- function(y) {
  h <- grid[2]-grid[1]
  sum((diff(y,differences=2)/h^2)^2)*h
}
turns <- function(y) {
  s <- sign(diff(y)); s <- s[s!=0]
  if(length(s)<2) return(0L)
  sum(diff(s)!=0)
}

summary_rows <- point_rows <- diagnostic_rows <- list()
status <- list()
for(seed in seeds) {
  dat <- simulate_data(seed) # One identical dataset reused for every basis size.
  df <- file.path(out,'datasets',paste0('seed-',seed,'.rds'))
  if(file.exists(df)) stopifnot(identical(readRDS(df),dat)) else saveRDS(dat,df)
  for(q in sizes) {
    tag <- paste0('seed-',seed,'-basis-',q)
    cp <- file.path(out,'fits',paste0(tag,'.rds'))
    cat('\n',tag, if(file.exists(cp)) ' [checkpoint]' else ' [fitting]', '\n',sep='')
    ans <- tryCatch({
      if(file.exists(cp)) rec <- readRDS(cp) else {
        # Separate data and fitting RNG. Same starting R seed across basis choices.
        set.seed(seed+50000L)
        elapsed <- system.time(fit <- api$tdmm(dat,family='gaussian',n_basis=q,
          degree=3,subject.var='id',time.var='time',y.var='y',
          x.var=c('x.baseline','x.tv'),n.chains=settings$n_chains,
          n.iter=settings$n_iter,n.burn=settings$n_burn,n.thin=settings$n_thin,
          n.adapt=settings$n_adapt,jags.dir=file.path(root,'inst/jags'),quiet=TRUE))
        rec <- list(fit=fit,fit_seconds=unname(elapsed['elapsed']),
                    data_seed=seed,fit_seed=seed+50000L)
        saveRDS(rec,cp) # Retain raw chain draws for later diagnostics.
      }
      fit <- rec$fit
      stopifnot(fit$inputs$n_basis==q,fit$inputs$degree==3)
      chains <- curve_chains(fit)
      pw <- sr <- list()
      for(k in 1:3) {
        draws <- do.call(rbind,lapply(chains,`[[`,k))
        mu <- colMeans(draws)
        lo <- apply(draws,2,quantile,.025); hi <- apply(draws,2,quantile,.975)
        target <- truth(grid)[,k]
        dg <- chain_stats(lapply(chains,`[[`,k))
        pw[[k]] <- data.frame(seed=seed,n_basis=q,coefficient=paste0('beta',k-1),
          time=grid,true=target,estimate=mu,lower=lo,upper=hi,bias=mu-target,
          squared_error=(mu-target)^2,covered=lo<=target & target<=hi,
          rhat=dg$rhat,ess=dg$ess)
        sr[[k]] <- data.frame(seed=seed,n_basis=q,coefficient=paste0('beta',k-1),
          mean_bias=mean(mu-target),mean_mse=mean((mu-target)^2),
          coverage=mean(lo<=target & target<=hi),max_curve_rhat=max(dg$rhat),
          min_curve_ess=min(dg$ess),roughness=roughness(mu),
          truth_roughness=roughness(target),turning_points=turns(mu),
          truth_turning_points=turns(target),sigma2_b=fit$sigma2.b,
          sigma2_e=fit$sigma2.e,fit_seconds=rec$fit_seconds)
      }
      a <- fit$post.samples$BUGSoutput$sims.array
      cols <- c(paste0('tau.alpha[',1:3,']'),'sigma2.b','sigma2.e')
      dg <- chain_stats(lapply(seq_len(dim(a)[2]),function(ch)a[,ch,cols]))
      list(pointwise=do.call(rbind,pw),summary=do.call(rbind,sr),
           diagnostic=data.frame(seed=seed,n_basis=q,parameter=cols,
                                  rhat=dg$rhat,ess=dg$ess))
    },error=function(e) e)
    ok <- !inherits(ans,'error')
    status[[tag]] <- data.frame(seed=seed,n_basis=q,ok=ok,
                                message=if(ok) '' else conditionMessage(ans))
    if(ok) {
      summary_rows[[tag]] <- ans$summary;point_rows[[tag]] <- ans$pointwise
      diagnostic_rows[[tag]] <- ans$diagnostic
    } else message('Failed: ',conditionMessage(ans))
    write.csv(do.call(rbind,status),file.path(out,'fit-status.csv'),row.names=FALSE)
  }
}
if(!length(summary_rows)) stop('No fits with complete diagnostics; see fit-status.csv.')
s <- do.call(rbind,summary_rows);p <- do.call(rbind,point_rows)
d <- do.call(rbind,diagnostic_rows)
write.csv(s,file.path(out,'replication-metrics.csv'),row.names=FALSE)
write.csv(p,file.path(out,'pointwise-results.csv'),row.names=FALSE)
write.csv(d,file.path(out,'smoothing-variance-diagnostics.csv'),row.names=FALSE)
# Compare only datasets successful at ALL three sizes; disclose every failure.
matched <- seeds[vapply(seeds,function(seed)
  all(sizes %in% s$n_basis[s$seed==seed]),logical(1))]
writeLines(paste('Matched seeds:',paste(matched,collapse=', ')),file.path(out,'matched-seeds.txt'))
if(!length(matched)) stop('No complete matched datasets. Raw outputs retained.')
s <- s[s$seed %in% matched,];p <- p[p$seed %in% matched,]
cs <- do.call(rbind,lapply(split(s,list(s$n_basis,s$coefficient),drop=TRUE),function(z)
  data.frame(n_basis=z$n_basis[1],coefficient=z$coefficient[1],n_matched=nrow(z),
    mean_pointwise_bias=mean(z$mean_bias),mean_pointwise_mse=mean(z$mean_mse),
    mean_pointwise_95_coverage=mean(z$coverage),max_curve_rhat=max(z$max_curve_rhat),
    min_curve_ess=min(z$min_curve_ess),mean_roughness=mean(z$roughness),
    mean_turning_points=mean(z$turning_points))))
vs <- do.call(rbind,lapply(split(s[s$coefficient=='beta0',],s$n_basis[s$coefficient=='beta0']),function(z)
  data.frame(n_basis=z$n_basis[1],n_matched=nrow(z),mean_sigma2_b=mean(z$sigma2_b),
    bias_sigma2_b=mean(z$sigma2_b)-.5,mse_sigma2_b=mean((z$sigma2_b-.5)^2),
    mean_sigma2_e=mean(z$sigma2_e),bias_sigma2_e=mean(z$sigma2_e)-.1,
    mse_sigma2_e=mean((z$sigma2_e-.1)^2),mean_fit_seconds=mean(z$fit_seconds),
    total_fit_seconds=sum(z$fit_seconds))))
write.csv(cs,file.path(out,'coefficient-summary.csv'),row.names=FALSE)
write.csv(vs,file.path(out,'variance-runtime-summary.csv'),row.names=FALSE)
# Matched differences in MSE/coverage: paired by seed and coefficient.
base <- s[s$n_basis==6,c('seed','coefficient','mean_mse','coverage')]
paired <- merge(s,base,by=c('seed','coefficient'),suffixes=c('','_basis6'))
paired$delta_mse_vs6 <- paired$mean_mse-paired$mean_mse_basis6
paired$delta_coverage_vs6 <- paired$coverage-paired$coverage_basis6
write.csv(paired,file.path(out,'paired-comparisons.csv'),row.names=FALSE)

# One page per dataset: columns=basis sizes, rows=coefficient functions.
# Common y limits within a coefficient allow honest visual comparison.
grDevices::pdf(file.path(out,'coefficient-curves.pdf'),width=12,height=9)
for(seed in matched) {
  par(mfrow=c(3,3),mar=c(3,3,2,1),oma=c(0,0,2,0))
  for(k in 0:2) {
    z <- p[p$seed==seed & p$coefficient==paste0('beta',k),]
    ylim <- range(z$true,z$lower,z$upper)
    for(q in sizes) {
      a <- z[z$n_basis==q,];a <- a[order(a$time),]
      plot(a$time,a$estimate,type='n',ylim=ylim,xlab='Time',ylab=paste0('beta',k),main=paste('n_basis =',q))
      polygon(c(a$time,rev(a$time)),c(a$lower,rev(a$upper)),col='grey90',border=NA)
      lines(a$time,a$estimate,col='blue',lwd=2);lines(a$time,a$true,lty=2,lwd=2)
      if(k==0 && q==6) legend('topright',c('Posterior mean','Truth','95% interval'),
                              col=c('blue','black','grey70'),lty=c(1,2,1),bty='n',cex=.7)
    }
  }
  mtext(paste('Matched dataset',seed),outer=TRUE)
}
grDevices::dev.off()
writeLines(c('Gaussian cubic pilot only; no default selection is automatic.',
 'Bias is signed estimate minus truth; MSE and pointwise coverage average equally over 100 times and matched datasets.',
 'Curve R-hat/ESS are computed on retained chain-resolved coefficient-function draws, with autoburnin=FALSE.',
 'Reported extrema span all grid points and matched replications, separately by coefficient.',
 'Smoothing and variance R-hat/ESS are also saved. Failed fits are never silently counted as successful.',
 'Roughness is an integrated squared second-derivative finite-difference diagnostic; turning points count slope sign changes.',
 'Inspect coefficient-curves.pdf for excess oscillation, edge excursions and intervals. Roughness is not an automatic instability verdict.',
 'Runtime measures each fit, including preparation and output construction, but excludes pilot diagnostics/plotting.',
 'Ten datasets provide preliminary comparisons, not precise coverage estimates or final validation.'),
 file.path(out,'interpretation.txt'))
print(cs);print(vs)
cat('\nCompleted matched datasets:',length(matched),'of',length(seeds),'\nResults:',out,'\n')
