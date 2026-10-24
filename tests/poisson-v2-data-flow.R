library(TDMM)
# No outcome generation, posterior performance or convergence checks.
build <- getFromNamespace("build.tdmm.subject.inputs", "TDMM")
jags.data <- getFromNamespace("build.tdmm.jags.data", "TDMM")
bbase <- getFromNamespace("bbase", "TDMM")
recover <- getFromNamespace("recover.tdmm.betas", "TDMM")
near <- function(a,b) stopifnot(isTRUE(all.equal(a,b,tolerance=1e-10,check.attributes=FALSE)))
base <- data.frame(person=c("z", "a", "z", "m", "a", "z"),
                   visit=c(.9,.15,.1,.45,.8,.6),
                   response=c(101,102,103,104,105,106),
                   baseline=c(30,10,30,20,10,30),
                   changing=c(11,22,33,44,55,66))
for (ids in list(base$person, c(90,10,90,40,10,90),
                 factor(base$person,levels=c("z","m","a","unused")))) {
  dat <- base; dat$person <- ids
  expected <- dat[order(dat$person,dat$visit),]
  z <- build(dat, n_basis=15, subject.var="person", time.var="visit",
             y.var="response", x.var=c("baseline","changing"))
  check <- suppressWarnings(check.tdmm.family.data(dat, family="poisson",
            subject.var="person",time.var="visit",y.var="response",
            x.var=c("baseline","changing")))
  stopifnot(check$structure.check$subject.balance$n.subject == 3L,
            !check$structure.check$subject.balance$balanced,
            !check$structure.check$subject.balance$common.time.grid,
            identical(check$structure.check$baseline.covariates,"baseline"),
            identical(check$structure.check$time.varying.covariates,"changing"),
            z$N == 6L, z$n.subject == 3L, z$nX == 3L,
            identical(sort(z$n.obs.subject),c(1,2,3)),
            all(z$subject.levels[z$subject.ID] == as.character(expected$person)),
            setequal(z$subject.ID,1:3),
            identical(z$y,expected$response), identical(z$time.obs,expected$visit),
            identical(dim(z$bases.obs), c(6L,15L)),
            identical(dim(z$X.obs), c(6L,3L)),
            identical(colnames(z$X.obs),c("Intercept","baseline","changing")),
            identical(z$X,z$X.obs), identical(z$N,z$n.total),
            identical(z$nbasis,z$n.basis))
  near(z$X.obs,cbind(1,expected$baseline,expected$changing))
  # Evaluate each expected observation independently, then restore input order.
  for (j in seq_len(nrow(expected))) {
    near(z$bases.obs[j,], bbase(c(expected$visit[j],expected$visit[j]),
                              min(base$visit),max(base$visit),12,3)[1,])
  }
  jd <- jags.data(z,"poisson")
  stopifnot(setequal(names(jd),c("smoothing.shape","smoothing.rate",
    "random.sd.max","N","n.subject","nX","n_basis","y",
                                "subject.ID","X","bases.obs","Penalty.bases")),
            identical(jd$y,z$y), identical(jd$subject.ID,z$subject.ID),
            identical(jd$X,z$X.obs), identical(jd$bases.obs,z$bases.obs),
            jd$n_basis == ncol(z$bases.obs))
  # Reordering the same observations must not change prepared model inputs.
  revz <- build(dat[6:1,],15,"person","visit","response",c("baseline","changing"))
  stopifnot(identical(jd,jags.data(revz,"poisson")))
}
# A common-grid fixture verifies basis reuse/alignment in the legacy Gaussian case.
common <- expand.grid(visit=c(.1,.45,.9),person=c("x","y"))
common$response <- 1:6; common$baseline <- rep(c(2,4),each=3)
z <- build(common,15,"person","visit","response","baseline")
near(z$bases.obs,z$basis[match(z$time.obs,z$time.points),,drop=FALSE])
# Shared time values across subjects must collapse only in the output grid.
dat <- base; dat$visit[5] <- .9
z <- build(dat,15,"person","visit","response",c("baseline","changing"))
stopifnot(nrow(z$bases.obs)==6L,nrow(z$basis)==5L,
          identical(z$time.points,sort(unique(dat$visit))))
# Synthetic coefficient draws test array/column reconstruction, not inference.
alpha.names <- unlist(lapply(1:3,function(k) paste0("alpha[",k,",",1:15,"]")))
post <- matrix(0,4,length(alpha.names),dimnames=list(NULL,alpha.names))
post[,"alpha[1,1]"] <- 1:4
post[,"alpha[2,7]"] <- 2*(1:4)
post[,"alpha[3,15]"] <- -(1:4)
post <- post[,rev(seq_len(ncol(post))),drop=FALSE]
b <- recover(post,z$basis,z$nX,z$coef.names)
stopifnot(identical(dim(b$beta.draws),c(4L,5L,3L)),
          identical(dim(b$beta.hat),c(5L,3L)),
          identical(colnames(b$beta.hat),z$coef.names))
near(b$beta.hat[,1],mean(1:4)*z$basis[,1])
near(b$beta.hat[,2],mean(2*(1:4))*z$basis[,7])
near(b$beta.hat[,3],mean(-(1:4))*z$basis[,15])
cat("PASS Poisson V2 row alignment, ID types, repeated times and reconstruction dimensions\n")
