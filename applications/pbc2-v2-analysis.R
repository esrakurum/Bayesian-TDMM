
# PBC2 application. 


pbc2_v2_data <- function() {
  if(!nzchar(system.file(package='JMbayes2')))
    stop("Install JMbayes2 first: install.packages('JMbayes2').")
  e <- new.env(parent=emptyenv())
  utils::data('pbc2',package='JMbayes2',envir=e)
  raw <- e$pbc2
  required <- c('id','year','serBilir','drug','albumin')
  if(!all(required %in% names(raw))) stop('JMbayes2::pbc2 column names changed.')
  if(anyNA(raw[,required])) stop('Missing values in analysis columns; review before changing the historical inclusion rule.')
  if(any(raw$serBilir<=0)) stop('Nonpositive bilirubin prevents the historical log transform.')
  if(!identical(levels(raw$drug),c('placebo','D-penicil')))
    stop('Treatment levels changed; review coding before fitting.')
  albumin_center <- mean(raw$albumin,na.rm=TRUE) # all source observations
  dat <- data.frame(id=as.numeric(raw$id),time=raw$year,
    y=log(raw$serBilir),drug=as.integer(raw$drug==levels(raw$drug)[2]),
    albumin=raw$albumin-albumin_center)
  if(nrow(dat)!=nrow(raw) || anyNA(dat) || anyDuplicated(dat[,c('id','time')]))
    stop('Unexpected PBC2 preprocessing structure; review source data.')
  by_id <- split(dat$drug,dat$id)
  if(!all(vapply(by_id,function(x) length(unique(x))==1L,logical(1))))
    stop('Treatment varies within subject; review source data.')
  structure <- list(source='JMbayes2::pbc2',
    source_version=as.character(utils::packageVersion('JMbayes2')),
    source_rows=nrow(raw),included_rows=nrow(dat),excluded_rows=0L,
    n_subjects=length(unique(dat$id)),visit_range=range(as.numeric(table(dat$id))),
    time_range=range(dat$time),treatment_subjects=table(dat$drug[!duplicated(dat$id)]),
    albumin_center=albumin_center,albumin_center_type='overall observation-level mean',
    albumin_unit='g/dL', bilirubin_unit='mg/dL')
  list(data=dat,metadata=structure)
}

.pbc2_settings <- function() list(family='gaussian',degree=3L,
  bases=c(6L,8L,10L),chains=3L,iterations=8000L,burn_in=3000L,
  thin=5L,adapt=5000L,seed=541L,grid_points=100L)
.pbc2_dir <- function(out) normalizePath(out,mustWork=FALSE)
.pbc2_fit_path <- function(out,n_basis) file.path(out,'fits',paste0('n-basis-',n_basis,'.rds'))
.pbc2_atomic_rds <- function(x,path) {
  tmp <- tempfile('checkpoint-',tmpdir=dirname(path))
  on.exit(unlink(tmp))
  saveRDS(x,tmp)
  if(!file.rename(tmp,path)) stop('Could not install saved fit: ',path)
}
.pbc2_manifest <- function(prep,s) {
  if(!requireNamespace('TDMM',quietly=TRUE)) stop('Install TDMM first.')
  if(!'control' %in% names(formals(TDMM::tdmm)))
    stop('Loaded TDMM is outdated: restart R and reinstall TDMM.')
  model <- system.file('jags','TDMM_Gaussian_JAGS.txt',package='TDMM')
  if(!nzchar(model)) stop('Installed Gaussian JAGS model is missing.')
  list(settings=s,source=prep$metadata,
    package_version=as.character(utils::packageVersion('TDMM')),
    gaussian_default_priors=TDMM::tdmm.priors('gaussian'),
    tdmm_body=deparse(body(TDMM::tdmm)),model_md5=unname(tools::md5sum(model)))
}
.pbc2_check_or_create <- function(out,prep,s,create=FALSE) {
  manifest <- .pbc2_manifest(prep,s)
  path <- file.path(out,'manifest.rds')
  if(file.exists(path)) {
    if(!identical(manifest,readRDS(path)) ||
       !identical(prep$data,readRDS(file.path(out,'analysis-data.rds'))))
      stop('Saved PBC2 inputs or installed TDMM differ; preserve this output and use a new directory.')
  } else if(create) {
    if(dir.exists(out) && length(list.files(out,all.files=TRUE,no..=TRUE)))
      stop('Nonempty output directory has no manifest: ',out)
    dir.create(file.path(out,'fits'),recursive=TRUE,showWarnings=FALSE)
    .pbc2_atomic_rds(manifest,path)
    .pbc2_atomic_rds(prep$data,file.path(out,'analysis-data.rds'))
    writeLines(capture.output(sessionInfo()),file.path(out,'sessionInfo.txt'))
    writeLines(c(paste0('Exact albumin center (g/dL): ',
      sprintf('%.16f',prep$metadata$albumin_center)),
      capture.output(str(prep$metadata))),file.path(out,'data-preparation.txt'))
  } else stop('No PBC2 manifest found: ',path)
  invisible(manifest)
}

check_pbc2_v2 <- function() {
  prep <- pbc2_v2_data()
  s <- .pbc2_settings()
  .pbc2_manifest(prep,s)
  checked <- TDMM::check.tdmm.family.data(prep$data,family='gaussian',
    subject.var='id',time.var='time',y.var='y',x.var=c('drug','albumin'))
  stopifnot(checked$structure.check$subject.balance$n.subject==312L,
    identical(checked$structure.check$baseline.covariates,'drug'),
    identical(checked$structure.check$time.varying.covariates,'albumin'))
  cat('PASS: JMbayes2::pbc2 loaded; 1,945 visits, 312 subjects, no exclusions; no fit.\n')
  print(prep$metadata)
  invisible(prep)
}

.pbc2_fit <- function(n_basis,out) {
  if(!n_basis %in% c(6L,8L,10L)) stop('Use n_basis 6, 8 or 10.')
  prep <- check_pbc2_v2(); s <- .pbc2_settings(); out <- .pbc2_dir(out)
  .pbc2_check_or_create(out,prep,s,create=TRUE)
  path <- .pbc2_fit_path(out,n_basis)
  if(file.exists(path)) {message('Reusing saved n_basis=',n_basis,' fit.');return(invisible(readRDS(path)))}
  warnings <- character()
  elapsed <- system.time(ans <- tryCatch(withCallingHandlers(
    TDMM::tdmm(prep$data,family='gaussian',subject.var='id',
      time.var='time',y.var='y',x.var=c('drug','albumin'),
      n_basis=n_basis,degree=s$degree,
      control=TDMM::tdmm_control(chains=s$chains,iterations=s$iterations,
        burn_in=s$burn_in,thin=s$thin,adapt=s$adapt,seed=s$seed),
      priors=TDMM::tdmm.priors('gaussian'),quiet=TRUE),
    warning=function(w) {warnings <<- c(warnings,conditionMessage(w));
      invokeRestart('muffleWarning')}),error=function(e)e))['elapsed']
  if(inherits(ans,'error')) {
    writeLines(c(conditionMessage(ans),warnings),
      file.path(out,'fits',paste0('n-basis-',n_basis,'-error.txt')))
    stop('PBC2 fit n_basis=',n_basis,' failed: ',conditionMessage(ans))
  }
  stopifnot(ans$inputs$n_basis==n_basis,ans$inputs$spline$degree==3L,
    ncol(ans$beta.hat)==3L)
  item <- list(n_basis=n_basis,fit=ans,elapsed_seconds=unname(elapsed),
    warnings=unique(warnings))
  .pbc2_atomic_rds(item,path)
  message('Saved n_basis=',n_basis,' in ',round(elapsed,1),' seconds.')
  invisible(item)
}

run_pbc2_v2_primary <- function(out='results/pbc2-v2-application') {
  .pbc2_fit(8L,out)
  summarize_pbc2_v2(out)
}
run_pbc2_v2_sensitivity <- function(out='results/pbc2-v2-application') {
  for(n_basis in c(6L,8L,10L)) .pbc2_fit(n_basis,out)
  summarize_pbc2_v2(out)
}
.pbc2_chain_stats <- function(chains) {
  m <- coda::mcmc.list(lapply(chains,coda::mcmc))
  list(rhat=unname(coda::gelman.diag(m,multivariate=FALSE,
    autoburnin=FALSE)$psrf[,1]),ess=unname(coda::effectiveSize(m)))
}
.pbc2_one <- function(item,grid) {
  fit <- item$fit; n_basis <- item$n_basis
  basis <- TDMM::make.tdmm.plot.grid(NULL,grid=grid,result=fit)$bases.grid
  a <- fit$post.samples$BUGSoutput$sims.array
  stopifnot(ncol(basis)==n_basis,dim(a)[2]==3L)
  curve <- do.call(rbind,lapply(seq_len(3L),function(k) {
    cols <- paste0('alpha[',k,',',seq_len(n_basis),']')
    chains <- lapply(seq_len(3L),function(ch)
      matrix(a[,ch,cols],ncol=n_basis) %*% t(basis))
    draws <- do.call(rbind,chains)
    ci <- apply(draws,2,quantile,probs=c(.025,.975))
    dg <- .pbc2_chain_stats(chains)
    data.frame(n_basis=n_basis,coefficient=c('intercept','treatment','albumin')[k],
      time=grid,estimate=colMeans(draws),lower=ci[1,],upper=ci[2,],
      rhat=dg$rhat,ess=dg$ess)
  }))
  params <- c('sigma.b','sigma2.b','sigma2.e',paste0('tau.alpha[',1:3,']'))
  pd <- .pbc2_chain_stats(lapply(seq_len(dim(a)[2]),function(ch)
    matrix(a[,ch,params],ncol=length(params),dimnames=list(NULL,params))))
  parameter <- data.frame(n_basis=n_basis,parameter=params,
    posterior_mean=colMeans(fit$post.mat[,params,drop=FALSE]),
    rhat=pd$rhat,ess=pd$ess)
  list(curve=curve,parameter=parameter)
}
.pbc2_plot_curve <- function(d,title,ylim=NULL) {
  if(is.null(ylim)) ylim <- range(d$lower,d$upper)
  plot(d$time,d$estimate,type='n',ylim=ylim,xlab='Years since baseline',
    ylab='Log serum bilirubin coefficient',main=title)
  polygon(c(d$time,rev(d$time)),c(d$lower,rev(d$upper)),
    col='grey85',border=NA)
  lines(d$time,d$estimate,col='navy',lwd=2)
  abline(h=0,lty=3)
}

summarize_pbc2_v2 <- function(out='results/pbc2-v2-application') {
  prep <- pbc2_v2_data();s <- .pbc2_settings();out <- .pbc2_dir(out)
  .pbc2_check_or_create(out,prep,s)
  writeLines(c(paste0('Exact albumin center (g/dL): ',
    sprintf('%.16f',prep$metadata$albumin_center)),
    capture.output(str(prep$metadata))),file.path(out,'data-preparation.txt'))
  bases <- s$bases[file.exists(vapply(s$bases,function(q) .pbc2_fit_path(out,q),''))]
  if(!length(bases)) stop('No saved PBC2 fits yet.')
  grid <- seq(min(prep$data$time),max(prep$data$time),length.out=s$grid_points)
  items <- lapply(bases,function(q)readRDS(.pbc2_fit_path(out,q)))
  pieces <- lapply(items,.pbc2_one,grid=grid)
  curves <- do.call(rbind,lapply(pieces,`[[`,'curve'))
  params <- do.call(rbind,lapply(pieces,`[[`,'parameter'))
  by_curve <- do.call(rbind,lapply(split(curves,list(curves$n_basis,curves$coefficient),drop=TRUE),function(z)
    data.frame(n_basis=z$n_basis[1],coefficient=z$coefficient[1],
      mean_estimate=mean(z$estimate),fraction_95_above_zero=mean(z$lower>0),
      fraction_95_below_zero=mean(z$upper<0),
      max_curve_rhat=max(z$rhat),min_curve_ess=min(z$ess))))
  selected <- do.call(rbind,lapply(split(curves,list(curves$n_basis,curves$coefficient),drop=TRUE),function(z) {
    ix <- unique(sapply(c(0,2,4,6,8,10,12,14),function(t)which.min(abs(z$time-t))))
    z[ix,c('n_basis','coefficient','time','estimate','lower','upper')]
  }))
  write.csv(curves,file.path(out,'coefficient-curves.csv'),row.names=FALSE)
  write.csv(params,file.path(out,'parameter-diagnostics.csv'),row.names=FALSE)
  write.csv(by_curve,file.path(out,'curve-diagnostics.csv'),row.names=FALSE)
  write.csv(selected,file.path(out,'selected-time-coefficients.csv'),row.names=FALSE)
  model_summary <- do.call(rbind,lapply(bases,function(q) {
    pp <- params[params$n_basis==q,]
    cc <- by_curve[by_curve$n_basis==q,]
    data.frame(n_basis=q,
      sigma_b=pp$posterior_mean[pp$parameter=='sigma.b'],
      sigma2_b=pp$posterior_mean[pp$parameter=='sigma2.b'],
      sigma2_e=pp$posterior_mean[pp$parameter=='sigma2.e'],
      max_curve_rhat=max(cc$max_curve_rhat),
      min_curve_ess=min(cc$min_curve_ess),
      fit_seconds=items[[which(bases==q)]]$elapsed_seconds)
  }))
  write.csv(model_summary,file.path(out,'model-summary.csv'),row.names=FALSE)
  breaks <- seq(0,ceiling(max(prep$data$time)))
  support <- data.frame(year_start=head(breaks,-1L),
    observations=vapply(head(breaks,-1L),function(t)
      sum(prep$data$time>=t & prep$data$time<t+1),integer(1)))
  write.csv(support,file.path(out,'time-support.csv'),row.names=FALSE)
  write.csv(data.frame(n_basis=bases,fit_seconds=vapply(items,`[[`,numeric(1),'elapsed_seconds'),
    warnings=vapply(items,function(x)paste(x$warnings,collapse=' | '),'')),
    file.path(out,'runtime-warnings.csv'),row.names=FALSE)
  writeLines(unlist(lapply(items,function(x)c(paste('n_basis=',x$n_basis),
    capture.output(summary(x$fit))))),file.path(out,'model-summaries.txt'))
  if(8L %in% bases) {
    fit <- items[[which(bases==8L)]]$fit
    grDevices::pdf(file.path(out,'primary-package-plot.pdf'),width=12,height=4)
    TDMM::plot.tdmm(prep$data,fit,grid=grid)
    grDevices::dev.off()
    grDevices::pdf(file.path(out,'primary-coefficients.pdf'),width=12,height=4)
    par(mfrow=c(1,3),mar=c(4,4,3,1))
    for(k in c('intercept','treatment','albumin'))
      .pbc2_plot_curve(curves[curves$n_basis==8L & curves$coefficient==k,],k)
    grDevices::dev.off()
  }
  if(length(bases)==3L) {
    grDevices::pdf(file.path(out,'basis-sensitivity.pdf'),width=12,height=4)
    par(mfrow=c(1,3),mar=c(4,4,3,1))
    for(k in c('intercept','treatment','albumin')) {
      z <- curves[curves$coefficient==k,]
      plot(range(z$time),range(z$lower,z$upper),type='n',xlab='Years since baseline',
        ylab='Log serum bilirubin coefficient',main=k)
      abline(h=0,lty=3)
      for(i in seq_along(bases)) {
        d <- z[z$n_basis==bases[i],]
        lines(d$time,d$estimate,col=c('steelblue','black','firebrick')[i],lwd=2)
        lines(d$time,d$lower,col=c('steelblue','black','firebrick')[i],lty=3)
        lines(d$time,d$upper,col=c('steelblue','black','firebrick')[i],lty=3)
      }
      legend('topright',paste0('n_basis=',bases),
        col=c('steelblue','black','firebrick'),lty=1,bty='n',cex=.7)
    }
    grDevices::dev.off()
  }
  print(prep$metadata);print(by_curve);print(params)
  invisible(list(metadata=prep$metadata,curves=curves,parameters=params,
    curve_diagnostics=by_curve))
}

if(sys.nframe()==0L) {
  args <- commandArgs(trailingOnly=TRUE)
  if(length(args)!=1L || !args %in% c('check','primary','sensitivity','summarize'))
    stop('Use check, primary, sensitivity, or summarize')
  if(args=='check') check_pbc2_v2()
  else if(args=='primary') run_pbc2_v2_primary()
  else if(args=='sensitivity') run_pbc2_v2_sensitivity()
  else summarize_pbc2_v2()
}
