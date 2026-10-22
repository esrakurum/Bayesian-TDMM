library(TDMM)
build <- getFromNamespace('build.tdmm.subject.inputs','TDMM')
jags <- getFromNamespace('build.tdmm.jags.data','TDMM')
d <- data.frame(subject.ID=c('z','a','z','a','z'), time=c(.9,.2,.4,.8,.1),
 y=c(1,0,1,1,0), baseline=c(1,-1,1,-1,1),changing=c(2,1,-1,3,.5))
for(nb in c(4,6,8,10)) {
 i <- build(d,n_basis=nb,x.var=c('baseline','changing'))
 j <- jags(i,'bernoulli')
 D <- diff(diag(nb),differences=2)
 U <- cbind(j$U.null,j$U.pen)
 stopifnot(j$n.null==2,j$n.pen==nb-2,
  max(abs(crossprod(U)-diag(nb)))<1e-12,
  max(abs(D %*% j$U.null))<1e-12,
  max(abs(j$U.pen %*% diag(j$lambda.pen) %*% t(j$U.pen)-crossprod(D)))<1e-12,
  identical(j$y,i$data$y), identical(j$X[,3],i$data$changing),
  all(i$subject.levels[j$subject.ID]==i$data$subject.ID),
  identical(j$bases.obs,splines::splineDesign(i$spline$knots,i$time.obs,ord=4)))
 # Match the approved diagnostic coordinates and conditional covariance exactly.
 e<-eigen(i$Penalty.bases,symmetric=TRUE);pen<-which(e$values-1e-6>1e-8)
 stopifnot(identical(j$U.pen,e$vectors[,pen,drop=FALSE]),
  identical(j$lambda.pen,e$values[pen]-1e-6))
}
cat('PASS Bernoulli null-space dimensions, prior decomposition and alignment\n')
