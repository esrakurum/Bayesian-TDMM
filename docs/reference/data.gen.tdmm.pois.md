# Generate Poisson TDMM simulation data



Generate Poisson counts for TDMM examples. The default uses repeated

measurements and a subject-specific random intercept; `random_intercept

= FALSE` generates independent observations with two predictors.



## Usage



``` r

data.gen.tdmm.pois(n.subject = 200, n.time = 20, sigma2.b = 0.5,

  seed = NULL, random_intercept = TRUE)

```



## Arguments



  - n.subject:



    Number of subjects. If omitted, the default is 200 with a random

    intercept and 2200 without one. An explicitly supplied value is used

    in either case.



  - n.time:



    Number of observations per subject when `random_intercept = TRUE`;

    unused otherwise.



  - sigma2.b:



    Random-intercept variance when `random_intercept = TRUE`; unused

    otherwise.



  - seed:



    Optional random seed.



  - random\_intercept:



    A single logical value. `TRUE` generates repeated observations on a

    common time grid with a subject-specific random intercept. `FALSE`

    generates one independent observation per subject with time drawn

    uniformly from 0 to 1.



## Details



With `random_intercept = FALSE`, `x1` is standard Normal and `x2 = u

+ 0.5*time + e`, where `u` is standard Normal and `e` is Normal with

standard deviation 0.5, independently drawn for each subject. The log

mean is `beta0(time) + x1*beta1(time) + x2*beta2(time)`, where `beta0(t)

= 0.25 + 0.35*sin(2*pi*t)`, `beta1(t) = 0.35*cos(2*pi*t)`, and `beta2(t)

= 0.25 + 0.20*t`.



## Value



A data frame with `subject.ID`, `time`, `y`, and `x1`; the

independent-observation design also has `x2`.



## Examples



``` r

d <- data.gen.tdmm.pois(n.subject = 5, n.time = 4, seed = 1)

d.independent <- data.gen.tdmm.pois(n.subject = 10,

  random_intercept = FALSE, seed = 1)

```
