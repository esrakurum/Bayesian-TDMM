\name{check.tdmm.subject.balance}
\alias{check.tdmm.subject.balance}
\title{Inspect subject visit counts}
\description{Inspect repeated-measure visit counts and observation-time balance across subjects.}
\usage{
check.tdmm.subject.balance(data, subject.var = "subject.ID", time.var = "time") 
}
\arguments{
\item{data}{Long-format data frame.}
\item{subject.var}{Subject ID column name.}
\item{time.var}{Numeric observation-time column name.}
}
\value{A diagnostic list describing visit-count and observation-time balance.}
\examples{
d <- data.frame(subject.ID = rep(1:3, each = 3), time = rep(1:3, 3))
check.tdmm.subject.balance(d)
}
