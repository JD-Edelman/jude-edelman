# =============================================================================
# MODULE 15: PROPENSITY SCORE METHODS
# CES 2020 Social Science Code Library
# =============================================================================
# Topics covered:
#   1. Create binary treatment (college-educated vs. not)
#   2. Propensity score matching with MatchIt (distance="logit")
#   3. Balance diagnostics: summary(), bal.tab(), love.plot()
#   4. Outcome model on matched data with cluster-robust SEs (lm_robust)
#   5. IPTW (ATE) with WeightIt
#   6. Trim extreme weights
#   7. Manual SMD check with pooled SD formula
#   8. Doubly robust estimation concept (entropy balancing + outcome model)
#   9. Note on combining IPTW weights with CES survey weights
#
# Causal identification assumption (unconfoundedness / ignorability):
#   Conditional on observed covariates X, potential outcomes Y(0) and Y(1)
#   are independent of treatment D.  This is UNTESTABLE from data alone.
#   Always discuss plausibility and consider sensitivity analysis
#   (e.g., sensemakr, RosenbaumbBounds, E-values) in your write-up.
#
# Estimand clarity — know which quantity you are targeting:
#   ATE  = average treatment effect for the full population
#   ATT  = average treatment effect for the treated (college-educated here)
#   ATU  = average treatment effect for the untreated
#   Matching typically targets ATT; IPTW can target any.
# =============================================================================

library(haven)      # read_dta()
library(tidyverse)  # data wrangling + ggplot2
library(MatchIt)    # matchit(), match.data(), summary.matchit()
library(WeightIt)   # weightit(), trim()
library(cobalt)     # bal.tab(), love.plot()
library(broom)      # tidy() for lm objects
library(estimatr)   # lm_robust() — cluster-robust SEs without pain


# =============================================================================
# 0. LOAD DATA
# =============================================================================

ces <- haven::read_dta("ces2020.dta")


# =============================================================================
# 1. CREATE TREATMENT VARIABLE AND CLEAN DATA
# =============================================================================
# Treatment: college = 1 if respondent has a 4-year degree or more (educ >= 5)
#            college = 0 if respondent has some college or less (educ <= 4)
#
# educ coding in CES 2020:
#   1 = No HS diploma
#   2 = High school graduate
#   3 = Some college
#   4 = 2-year degree (Associate's)
#   5 = 4-year degree (Bachelor's)
#   6 = Post-graduate degree

ces <- ces |>
  mutate(
    college = as.integer(educ >= 5)   # 1=college+, 0=less than college
  )

# Check: treatment prevalence
ces |> count(college) |> mutate(pct = round(n / sum(n) * 100, 1))

# Covariates used throughout (pre-treatment confounders):
#   ideo5      : political ideology (1=very liberal to 5=very conservative)
#   faminc_new : family income category (1-16)
#   race       : 1=White, 2=Black, 3=Hispanic, 4=Asian, 5=Other (numeric)
#   gender     : 1=Male, 2=Female (numeric)
#   birthyr    : birth year (use as proxy for age)
#   pid7       : party ID (1-7)

# Drop rows missing on treatment, outcome, or any covariate
ces_ps <- ces |>
  filter(
    !is.na(college),
    !is.na(approval_pres),
    !is.na(ideo5),
    !is.na(faminc_new),
    !is.na(race),
    !is.na(gender),
    !is.na(birthyr),
    !is.na(pid7)
  ) |>
  mutate(age = 2020 - birthyr)

cat("Analytic sample N =", nrow(ces_ps), "\n")
cat("Treated (college) N =", sum(ces_ps$college), "\n")
cat("Control (no college) N =", sum(1 - ces_ps$college), "\n")


# =============================================================================
# 2. PROPENSITY SCORE MATCHING WITH MatchIt
# =============================================================================
# distance = "logit" tells MatchIt to estimate a logistic regression PS and
# then match on the log-odds (logit) of that score.
#
# COMMON MISTAKE TO AVOID:
#   WRONG:  matchit(..., distance = "glm", link = "logit")
#   RIGHT:  matchit(..., distance = "logit")
# The "logit" shorthand is MatchIt's preferred syntax as of v4.x.
# Using distance="glm" with link="logit" also works in v4 but is verbose
# and was sometimes confused with the pre-v4 API.

m_out <- matchit(
  college ~ ideo5 + faminc_new + race + gender + age + pid7,
  data     = ces_ps,
  method   = "nearest",    # nearest-neighbor matching (greedy, 1:1)
  distance = "logit",      # logistic PS, match on log-odds
  ratio    = 1,            # 1 control per treated
  replace  = FALSE         # without replacement (default)
)

# --- Matching summary ---
summary(m_out)
# Key rows to check:
#   "Std. Mean Diff." before and after matching
#   "Var. Ratio"      should be near 1 after matching
#   "eCDF Stat."      overall distributional balance
#   n.matched: should equal number of treated units (or fewer if caliper used)

# --- Standardized mean differences and love plot ---
love.plot(
  m_out,
  thresholds = c(m = 0.1),   # standard 0.1 SMD threshold line
  abs        = TRUE,
  stars      = "raw",
  title      = "Covariate balance: before and after nearest-neighbor matching"
)
# Dots to the LEFT of the 0.1 line = good balance after matching.
# If several covariates remain above 0.1, consider:
#   - Adding a caliper: matchit(..., caliper = 0.1, std.caliper = TRUE)
#   - Optimal matching: method = "optimal"
#   - Full matching:    method = "full"
#   - Genetic matching: method = "genetic"

# --- Extract matched dataset ---
matched_data <- match.data(m_out)
# matched_data is a data frame with columns:
#   subclass  : matched pair ID
#   distance  : estimated propensity score for each unit
#   weights   : 1 for all matched units (or fractional if full matching)
# It contains ONLY the matched units (treated + their matched controls)

cat("Matched sample N =", nrow(matched_data), "\n")
cat("Matched pairs =", n_distinct(matched_data$subclass), "\n")

# --- Density overlap check (visual) ---
ggplot(ces_ps, aes(x = distance, fill = factor(college))) +
  geom_density(alpha = 0.5) +
  labs(
    title = "Propensity score overlap (full sample)",
    x     = "Estimated propensity score (logit scale)",
    fill  = "College"
  ) +
  theme_minimal()
# After matching, this overlap should be much tighter.
# Lack of overlap in tails = common support violation; consider trimming.


# =============================================================================
# 3. OUTCOME MODEL ON MATCHED DATA
# =============================================================================
# Run the outcome regression on matched_data, NOT on the original ces_ps.
# This is the most common matching mistake in applied work.
#
# Why cluster SEs by subclass?
#   Each matched pair (subclass) shares a counterfactual — the control unit
#   was selected specifically to resemble the treated unit. Observations
#   within a pair are not independent; clustering accounts for this.

outcome_matched <- estimatr::lm_robust(
  approval_pres ~ college,
  data     = matched_data,
  clusters = subclass,       # cluster by matched pair
  se_type  = "CR2"           # CR2 = bias-corrected cluster-robust (HC3 analog)
)

summary(outcome_matched)
tidy(outcome_matched, conf.int = TRUE)
# Coefficient on college = ATT estimate from matching
# (because nearest-neighbor matching without replacement targets ATT)

# --- Covariate-adjusted outcome model (optional but recommended) ---
# Adding covariates to the outcome model ("regression adjustment") can
# remove residual imbalance and improve efficiency. This is safe here
# because matching already handled most confounding.
outcome_adj <- estimatr::lm_robust(
  approval_pres ~ college + ideo5 + faminc_new + pid7 + age,
  data     = matched_data,
  clusters = subclass,
  se_type  = "CR2"
)

tidy(outcome_adj, conf.int = TRUE) |>
  filter(term == "college")
# Compare to unadjusted estimate above; should be similar if matching worked.


# =============================================================================
# 4. IPTW WITH WeightIt
# =============================================================================
# IPTW (inverse probability of treatment weighting) keeps the full sample and
# re-weights it to create a pseudo-population where treatment is unconfounded.
#
# method = "ps"   : logistic regression propensity score (same as MatchIt)
# estimand = "ATE": weights target the average treatment effect for everyone

w_ate <- WeightIt::weightit(
  college ~ ideo5 + faminc_new + race + gender + age + pid7,
  data     = ces_ps,
  method   = "ps",
  estimand = "ATE"
)

summary(w_ate)
# Key output:
#   Weight summary: min, max, mean, effective sample size (ESS)
#   ESS drop indicates how much variance is lost to weighting
#   Effective sample size < n/4 suggests extreme weights need trimming

# Add weights to the data frame for later use
ces_ps <- ces_ps |>
  mutate(iptw_ate = w_ate$weights)


# =============================================================================
# 5. TRIM EXTREME WEIGHTS
# =============================================================================
# Extreme weights inflate variance. Trimming caps weights at the 99th percentile
# (or absolute upper bound) to improve stability at some cost to consistency.
# Always report both trimmed and untrimmed results.

w_ate_trimmed <- WeightIt::trim(w_ate, at = 0.99)   # trim at 99th percentile
summary(w_ate_trimmed)

ces_ps <- ces_ps |>
  mutate(iptw_ate_trim = w_ate_trimmed$weights)

# Visual: weight distribution before and after trimming
tibble(
  raw     = w_ate$weights,
  trimmed = w_ate_trimmed$weights
) |>
  pivot_longer(everything(), names_to = "version", values_to = "weight") |>
  ggplot(aes(x = weight, fill = version)) +
  geom_histogram(position = "dodge", bins = 50, alpha = 0.7) +
  scale_x_log10() +
  labs(
    title = "IPTW weight distributions: raw vs. trimmed (99th percentile)",
    x     = "Weight (log scale)",
    y     = "Count"
  ) +
  theme_minimal()


# =============================================================================
# 6. BALANCE DIAGNOSTICS FOR IPTW
# =============================================================================
# bal.tab() and love.plot() work directly on WeightIt objects.

bal.tab(
  w_ate,
  thresholds = c(m = 0.1, v = 2),   # SMD < 0.1, variance ratio < 2
  stats      = c("m", "v")          # report mean diffs and variance ratios
)

love.plot(
  w_ate,
  thresholds = 0.1,
  abs        = TRUE,
  title      = "Covariate balance: unadjusted vs. IPTW (ATE)"
)
# Compare to the matching love.plot from Section 2.
# IPTW often achieves slightly better balance across all covariates.


# =============================================================================
# 7. MANUAL SMD CHECK (pooled SD formula)
# =============================================================================
# SMD = (mean_treated - mean_control) / pooled_SD
# Pooled SD uses the UNWEIGHTED pre-matching variances by convention
# (using Austin & Stuart 2015 recommendation).
#
# Formula: pooled_SD = sqrt( ((n1-1)*var1 + (n0-1)*var0) / (n1+n0-2) )

check_smd <- function(var, treatment, data) {
  d1  <- data[[var]][data[[treatment]] == 1]
  d0  <- data[[var]][data[[treatment]] == 0]
  n1  <- length(d1);  n0  <- length(d0)
  m1  <- mean(d1, na.rm = TRUE); m0 <- mean(d0, na.rm = TRUE)
  v1  <- var(d1, na.rm = TRUE);  v0 <- var(d0, na.rm = TRUE)
  pooled_sd <- sqrt(((n1 - 1) * v1 + (n0 - 1) * v0) / (n1 + n0 - 2))
  smd <- (m1 - m0) / pooled_sd
  tibble(variable = var, mean_treated = m1, mean_control = m0,
         pooled_sd = pooled_sd, smd = smd)
}

covars <- c("ideo5", "faminc_new", "age", "pid7")

# Unadjusted SMDs
map_dfr(covars, check_smd, treatment = "college", data = ces_ps)

# Post-IPTW SMDs (using weighted means)
smd_iptw <- function(var, treatment, data, wt_col) {
  d   <- data[[var]]; trt <- data[[treatment]]; wt <- data[[wt_col]]
  # Weighted means
  m1w <- weighted.mean(d[trt == 1], wt[trt == 1], na.rm = TRUE)
  m0w <- weighted.mean(d[trt == 0], wt[trt == 0], na.rm = TRUE)
  # Unweighted pooled SD (by convention, use pre-weighting variances)
  n1  <- sum(trt == 1); n0 <- sum(trt == 0)
  v1  <- var(d[trt == 1], na.rm = TRUE); v0 <- var(d[trt == 0], na.rm = TRUE)
  pooled_sd <- sqrt(((n1 - 1) * v1 + (n0 - 1) * v0) / (n1 + n0 - 2))
  tibble(variable = var, smd_iptw = (m1w - m0w) / pooled_sd)
}

map_dfr(covars, smd_iptw, treatment = "college", data = ces_ps,
        wt_col = "iptw_ate_trim")
# SMDs below 0.10 in absolute value = good balance by the standard threshold.


# =============================================================================
# 8. DOUBLY ROBUST ESTIMATION
# =============================================================================
# Doubly robust (DR) estimators combine a propensity score model AND an
# outcome model. The estimator is consistent if EITHER model is correctly
# specified (but not necessarily both). This provides extra insurance.
#
# Approach A: Entropy balancing (ebal) via WeightIt
#   Entropy balancing finds weights that exactly balance covariate means
#   without a PS model, making balance a constraint rather than a goal.

w_ebal <- WeightIt::weightit(
  college ~ ideo5 + faminc_new + race + gender + age + pid7,
  data     = ces_ps,
  method   = "ebal",      # entropy balancing — no propensity model needed
  estimand = "ATE"
)

summary(w_ebal)
bal.tab(w_ebal, thresholds = c(m = 0.1))
# Entropy balancing EXACTLY zeroes out mean differences by construction.
# Check variance ratios too — ebal only balances means by default.

ces_ps <- ces_ps |> mutate(ebal_wt = w_ebal$weights)

# DR outcome model: entropy balancing weights + regression adjustment
outcome_ebal <- lm(
  approval_pres ~ college + ideo5 + faminc_new + pid7 + age,
  data    = ces_ps,
  weights = ebal_wt
)
tidy(outcome_ebal, conf.int = TRUE) |> filter(term == "college")
# This is the augmented IPW (AIPW / DR) estimate.
# It is consistent if either the weighting model or the outcome model is right.

# Approach B: AIPW concept manually
#   mu1_hat = predicted outcome under treatment=1 from an outcome model
#   mu0_hat = predicted outcome under treatment=0
#   DR_ATE = mean(mu1_hat - mu0_hat)
#             + mean( (Y - mu1_hat) * D / pscore )
#             - mean( (Y - mu0_hat) * (1-D) / (1-pscore) )
# This is computationally identical to what WeightIt + lm does above.
# The tmle or AIPW packages implement this with efficient standard errors.


# =============================================================================
# 9. COMBINING IPTW WITH CES SURVEY WEIGHTS
# =============================================================================
# CES 2020 provides commonpostweight (post-stratification survey weights)
# for population-representative estimates. If your research question is about
# the general US population (not just CES respondents), you need BOTH the
# IPTW weights (for causal identification) and the survey weights (for
# representativeness).
#
# How to combine:
#   combined_weight = iptw_weight * survey_weight
#
# Then normalize so weights sum to N (optional but keeps scale interpretable):
#   combined_weight_norm = combined_weight / mean(combined_weight)
#
# Implementation:

ces_ps <- ces_ps |>
  mutate(
    combined_wt      = iptw_ate_trim * commonpostweight,
    combined_wt_norm = combined_wt / mean(combined_wt, na.rm = TRUE)
  )

# Use combined_wt_norm in the outcome model
outcome_combined <- lm(
  approval_pres ~ college,
  data    = ces_ps,
  weights = combined_wt_norm
)
tidy(outcome_combined, conf.int = TRUE)

# Important caveats:
#   1. Standard errors from lm() do not account for survey design.
#      Use the survey package (svyglm) or estimatr::lm_robust with
#      weights = combined_wt_norm for approximately correct inference.
#   2. Multiplying weights can amplify extreme values. After combining,
#      inspect the weight distribution and consider trimming again.
#   3. Methodological consensus on combining PS and survey weights is still
#      evolving. Cite Dugoff et al. (2014) or Ridgeway et al. (2015)
#      if you use this approach in a paper.

# Survey-design-aware outcome model with combined weights:
outcome_survey_robust <- estimatr::lm_robust(
  approval_pres ~ college + ideo5 + pid7,
  data    = ces_ps,
  weights = combined_wt_norm,
  se_type = "HC2"    # heteroskedasticity-robust; no clustering here
)
tidy(outcome_survey_robust, conf.int = TRUE) |> filter(term == "college")


# =============================================================================
# END OF MODULE 15
# =============================================================================
