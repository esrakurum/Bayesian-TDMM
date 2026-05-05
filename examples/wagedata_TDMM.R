## Real data example: Gaussian TDMM with WageData

devtools::install_github("esrakurum/Bayesian-TDMM")
library(TDMM)

library(panelr)
library(dplyr)
library(tidyr)
library(ggplot2)

## Load and inspect the WageData

data("WageData")

head(WageData)
glimpse(WageData)
summary(WageData)
names(WageData)

## Create analysis dataset
##
## WageData contains seven survey waves. The survey waves correspond
## to annual observations from 1976 through 1982.
##
## We use t directly in the model because it is the numeric time
## variable. For interpretation and plotting, t = 1, ..., 7 is
## relabeled as years 1976, ..., 1982.

wage_analysis <- WageData %>%
  select(id, t, lwage, fem, ed) %>%
  mutate(
    id = as.factor(id), t = as.numeric(t), year = 1975 + t,
    lwage = as.numeric(lwage), fem = as.numeric(fem), ed = as.numeric(ed),
    gender = factor(
      fem,
      levels = c(0, 1),
      labels = c("Male", "Female")
    ),
    ## Center education so the intercept is easier to interpret.
    ## With this centering, beta0(t) represents the baseline
    ## log wage for males with average education.
    ed_c = ed - mean(ed, na.rm = TRUE))

head(wage_analysis)
summary(wage_analysis)

## EDA 1: Check missingness

colSums(is.na(wage_analysis))

missing_summary <- data.frame(
  variable = names(wage_analysis), n_missing = colSums(is.na(wage_analysis)),
  pct_missing = round(100 * colSums(is.na(wage_analysis)) / nrow(wage_analysis), 2))

missing_summary

model.vars <- c("id", "t", "year", "lwage", "fem", "ed", "ed_c", "gender")

sum(complete.cases(wage_analysis[, model.vars]))
nrow(wage_analysis)

wage_analysis[!complete.cases(wage_analysis[, model.vars]), ]

## EDA 2: Check longitudinal structure

length(unique(wage_analysis$id))
sort(unique(wage_analysis$t))
sort(unique(wage_analysis$year))

table(table(wage_analysis$id))
table(wage_analysis$t)
table(wage_analysis$year)

## EDA 3: Check gender balance

gender_balance <- wage_analysis %>%
  group_by(gender) %>%
  summarize(
    n_subjects = n_distinct(id), n_obs = n(),
    pct_subjects = round(100 * n_subjects / n_distinct(wage_analysis$id), 2),
    pct_obs = round(100 * n_obs / nrow(wage_analysis), 2), mean_lwage = mean(lwage),
    sd_lwage = sd(lwage), mean_ed = mean(ed), sd_ed = sd(ed), .groups = "drop")

gender_balance

## EDA 4: Average log wage by gender and year

wage_summary_gender <- wage_analysis %>%
  group_by(year, gender) %>%
  summarize(
    n = n(), mean_lwage = mean(lwage), sd_lwage = sd(lwage), se_lwage = sd_lwage / sqrt(n),
    lower = mean_lwage - 1.96 * se_lwage, upper = mean_lwage + 1.96 * se_lwage, .groups = "drop")

wage_summary_gender

wage_mean_plot <- ggplot(wage_summary_gender, aes(x = year, y = mean_lwage, color = gender)) +
  geom_line(linewidth = 1) +
  geom_point(size = 2) +
  geom_errorbar(aes(ymin = lower, ymax = upper), width = 0.15) +
  scale_x_continuous(breaks = sort(unique(wage_analysis$year))) +
  labs(
    title = "Average Log Wage Over Time by Gender",
    x = "Year",
    y = "Average log wage",
    color = "Gender"
  ) +
  theme_minimal()

wage_mean_plot

ggsave(
  filename = "wage_eda_average_log_wage_by_gender.png",
  plot = wage_mean_plot,
  width = 7,
  height = 5,
  dpi = 300
)

## EDA 5: Check education

summary(wage_analysis$ed)
summary(wage_analysis$ed_c)

table(wage_analysis$ed)

wage_education_boxplot <- ggplot(wage_analysis, aes(x = gender, y = ed)) +
  geom_boxplot() +
  labs(
    title = "Education by Gender",
    x = "Gender",
    y = "Years of education"
  ) +
  theme_minimal()

wage_education_boxplot

ggsave(
  filename = "wage_eda_education_by_gender_boxplot.png",
  plot = wage_education_boxplot,
  width = 7,
  height = 5,
  dpi = 300
)

## EDA 6: Distribution of log wage

wage_histogram <- ggplot(wage_analysis, aes(x = lwage)) +
  geom_histogram(bins = 30, color = "white") +
  labs(
    title = "Distribution of Log Wage",
    x = "Log wage",
    y = "Count"
  ) +
  theme_minimal()

wage_histogram

ggsave(
  filename = "wage_eda_log_wage_histogram.png",
  plot = wage_histogram,
  width = 7,
  height = 5,
  dpi = 300
)

## EDA 7: Log wage density by gender

wage_density_plot <- ggplot(wage_analysis, aes(x = lwage, color = gender)) +
  geom_density(linewidth = 1) +
  labs(
    title = "Log Wage Distribution by Gender",
    x = "Log wage",
    y = "Density",
    color = "Gender"
  ) +
  theme_minimal()

wage_density_plot

ggsave(
  filename = "wage_eda_log_wage_density_by_gender.png",
  plot = wage_density_plot,
  width = 7,
  height = 5,
  dpi = 300
)

## Create TDMM-ready dataset
##
## x1 = female indicator
## x2 = centered education
##
## The current TDMM package expects baseline covariates to be
## constant within subject. Education is constant within subject
## in this dataset, so it is compatible with the current TDMM
## implementation.

data.wage <- wage_analysis %>%
  transmute(
    subject.ID = id, time = t, y = lwage, x1 = fem, x2 = ed_c) %>%
  arrange(subject.ID, time)

head(data.wage)
summary(data.wage)

## Check TDMM-ready data

colSums(is.na(data.wage))

sum(complete.cases(data.wage))
nrow(data.wage)

length(unique(data.wage$subject.ID))
sort(unique(data.wage$time))

table(table(data.wage$subject.ID))
table(data.wage$time)

## Run TDMM data checks

check.wage <- check.tdmm.family.data(data = data.wage, family = "gaussian", x.var = c("x1", "x2"))

check.wage$structure.check$subject.balance$n.subject
check.wage$structure.check$subject.balance$balanced
check.wage$structure.check$subject.balance$common.time.grid
check.wage$structure.check$x.constant.within.subject
check.wage$structure.check$x.constant.by.variable

check.wage$response.check$overall
head(check.wage$response.check$by.time)

## Fit Gaussian TDMM to WageData
fit.wage <- tdmm(data = data.wage, family = "gaussian", nknots = 5)

## Check spline knot spacing for WageData
nknots <- 5

time.points <- sort(unique(data.wage$time))
year.labels <- 1975 + time.points

tlo <- min(time.points)
thi <- max(time.points)

nseg <- nknots - 2
dx <- (thi - tlo) / nseg

segment.knots <- seq(tlo, thi, by = dx)
segment.years <- 1975 + segment.knots

knot.check <- data.frame(
  model_time = segment.knots,
  calendar_year = segment.years
)
knot.check

## Check fitted object
summary.tdmm(fit.wage)

fit.wage$beta.names
names(fit.wage)[grepl("beta", names(fit.wage), ignore.case = TRUE)]
colnames(fit.wage$post.mat)[grepl("alpha", colnames(fit.wage$post.mat))]

## Interpretation:
## beta0(t): baseline log wage for males with average education
## beta_x1(t): female-minus-male log wage difference
## beta_x2(t): effect of one additional year of education

## Save fitted coefficient summaries

wage.beta.summary <- data.frame(
  time = fit.wage$time.points,
  year = 1975 + fit.wage$time.points,
  beta0.hat = fit.wage$beta.hat[, "beta0"],
  beta_x1.hat = fit.wage$beta.hat[, "beta_x1"],
  beta_x2.hat = fit.wage$beta.hat[, "beta_x2"]
)

head(wage.beta.summary)

write.csv(
  wage.beta.summary,
  file = "wage_gaussian_tdmm_beta_summary_for_handbook.csv",
  row.names = FALSE
)

## Plot fitted TDMM coefficient curves

plot.tdmm(
  data = data.wage,
  result = fit.wage,
  sd = FALSE,
  level = 0.95,
  file = "wage_gaussian_tdmm_coefficient_curves_years.png",
  x.axis.values = 1:7,
  x.axis.labels = 1976:1982,
  xlab = "t (Year)",
  ylim = list(
    NULL,
    c(-0.65, 0.05),
    c(0, 0.09)
  ),
  width = 3000,
  height = 850,
  res = 180
)

## Trace plots for Gaussian variance terms
params <- c("sigma2.b", "sigma2.e")
plot.trace.tdmm(
  result = fit.wage,
  params = params,
  file = "wage_gaussian_tdmm_trace_variance_terms.png")
