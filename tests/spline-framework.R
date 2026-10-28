library(TDMM)
specification <- getFromNamespace('.make.spline.spec','TDMM')
evaluate <- getFromNamespace('.evaluate.spline','TDMM')
resolve <- getFromNamespace('.resolve.n_basis','TDMM')
signed.basis <- getFromNamespace('.legacy.bbase','TDMM')
fitted.spec <- getFromNamespace('.fitted.spline.spec','TDMM')
near <- function(a,b,tol=1e-10) stopifnot(isTRUE(all.equal(a,b,tolerance=tol,check.attributes=FALSE)))
error <- function(expr) stopifnot(inherits(tryCatch({force(expr);NULL},error=identity),'error'))
for(d in c(1,2,3,4)) for(q in c(6L,8L,15L,25L)) {
  for(domain in list(c(0,1),c(-7,9),c(1976,1982),c(1e6,1e6+.01))) {
    s <- specification(domain[1],domain[2],q,d)
    x <- seq(s$tlo,s$thi,length.out=401)
    b <- evaluate(x,s)
    stopifnot(identical(dim(b),c(401L,q)),length(s$knots)==q+d+1,
              s$intervals==q-d,all(b>=-1e-12),all(rowSums(b>1e-12)<=d+1))
    near(rowSums(b),rep(1,length(x)))
    near(b,splines::splineDesign(s$knots,x,ord=d+1,outer.ok=TRUE))
    for(j in seq_len(q)) stopifnot(all(b[x<s$knots[j] | x>s$knots[j+d+1],j]==0))
    # Endpoints, knots and points outside the entire support.
    edge <- c(s$tlo,s$thi,s$knots,min(s$knots)-1,max(s$knots)+1)
    near(evaluate(edge,s),splines::splineDesign(s$knots,edge,ord=d+1,outer.ok=TRUE))
  }
}
# Independent check against the cubic basis formula.
s <- specification(0,1,6,3);x <- seq(0,1,length.out=301)
near(evaluate(x,s),signed.basis(x,0,1,3,3))
# Affine transformations retain the basis shape on a well-resolved scale.
near(evaluate(x,s),evaluate(1976+6*x,specification(1976,1982,6,3)))
stopifnot(resolve()==8L,suppressWarnings(resolve(nknots=6,degree=3))==7L,
          suppressWarnings(resolve(nknots=6,degree=2))==6L)
warned <- FALSE
withCallingHandlers(resolve(nknots=6),warning=function(w){warned<<-TRUE;invokeRestart('muffleWarning')})
stopifnot(warned)
error(resolve(6,6));error(resolve(3));error(resolve(6.5));error(resolve(NA));error(specification(1,1,6))
for(f in list(tdmm,tdmm.parallel)) error(f(data.frame(),n_basis=6,nknots=6))
# Saved standard and signed quadratic fits: detect from stored basis and preserve.
for(convention in c('standard','legacy-signed')) {
  s <- specification(0,1,6,2);s$convention <- convention
  i <- list(tlo=0,thi=1,degree=2,basis=evaluate(x,s),nX=1,coef.names='beta0')
  obj <- structure(list(inputs=i,time.points=x),class='tdmm')
  near(evaluate(x,fitted.spec(obj)),i$basis)
  obj$inputs$basis.convention <- convention
  near(evaluate(x,fitted.spec(obj)),i$basis)
  pg <- make.tdmm.plot.grid(data.frame(time=c(-100,100)),grid=x,result=obj)
  near(pg$bases.grid,i$basis)
  error(make.tdmm.plot.grid(NULL,result=obj,degree=3))
  error(make.tdmm.plot.grid(NULL,result=obj,n_basis=7))
  # Actual plotting/reconstruction retains signed coefficients and fitted domain.
  obj$post.mat <- matrix(rep(seq_len(6),each=4),4,6,
                         dimnames=list(NULL,paste0("alpha[1,",1:6,"]")))
  grDevices::pdf(tempfile(fileext=".pdf"))
  plotted <- plot.tdmm(data.frame(time=c(-100,100)),obj,grid=x)
  grDevices::dev.off()
  near(plotted$summaries$beta.mean[[1]],as.vector(i$basis %*% seq_len(6)))
  near(evaluate(.5,s),evaluate(c(.5,.5),s)[1,,drop=FALSE])
  obj$inputs$degree <- NULL
  error(fitted.spec(obj))
}
# Fitted objects use exact stored knots, even when the plotting data range differs.
s <- specification(0,1,6,3)
obj <- structure(list(inputs=list(spline=s)),class='tdmm')
near(make.tdmm.plot.grid(data.frame(time=c(-9,9)),grid=x,result=obj)$bases.grid,evaluate(x,s))
error(make.tdmm.plot.grid(NULL,result=obj,n_basis=6,nknots=5))
cat('PASS spline properties, dimensions, public compatibility and saved-object reconstruction\n')

build <- getFromNamespace("build.tdmm.subject.inputs","TDMM")
dat <- data.frame(subject.ID=rep(1:2,each=3),time=rep(c(0,.4,1),2),y=1:6,x=1:6)
i <- build(dat,n_basis=6)
D2 <- diff(diag(6),differences=2)
near(i$Penalty.bases,crossprod(D2)+diag(1e-6,6))
stopifnot(i$n_basis==6L,ncol(i$bases.obs)==6L)
