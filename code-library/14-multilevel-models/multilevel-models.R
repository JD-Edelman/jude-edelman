# =============================================================================
# MODULE 14: MULTILEVEL MODELS (MIXED-EFFECTS REGRESSION)
# CES 2020 Social Science Code Library
# =============================================================================
# Topics covered:
#   1. Null model / ICC — how much variance lives at the state level
#   2. Random intercept model — level-1 predictors with varying intercepts
#   3. Random slope model — one slope allowed to vary across states
#   4. Model comparison via LRT — REML=FALSE is REQUIRED for this
#   5. Cross-level interaction — state-level variable moderates individual slope
#   6. Extract & plot random effects
#   7. Note on multiply-imputed data (mice::pool)
#   8. Fixed-effects alternative via fixest::feols()
#
# Key concept — REML vs ML:
#   REML=TRUE  gives better variance estimates; use for final parameter tables.
#   REML=FALSE is mandatory for likelihood ratio tests comparing fixed effects.
#   anova() on two lmer objects automatically refits with ML — but being
#   explicit is clearer and safer (see Section 4).
#
# Nesting structure: ~2,200 respondents per state on average (n=51 groups).
# With only 51 groups the random-slope correlation is estimated with noise;
# treat those estimates as descriptive, not causal.
# =============================================================================

library(haven)       # read_dta()
library(tidyverse)   # data wrangling + ggplot2
library(lme4)        # lmer(), ranef(), VarCorr()
library(lmerTest)    # Satterthwaite df -> p-values on fixed effects
library(performance) # icc() — returns both adjusted and unadjusted ICC
library(broom.mixed) # tidy() and glance() for lmer/glmer objects
library(fixest)      # feols() — fast fixed-effects alternative


# =============================================================================
# 0. LOAD DATA
# =============================================================================

ces <- haven::read_dta("ces2020.dta")

# Quick look at nesting: how many respondents per state?
ces |> count(inputstate) |> summary()
# Expect: 51 states/DC, medians ~700-1200 depending on trimmed sample


# =============================================================================
# 1. PREPARE VARIABLES
# =============================================================================
# approval_pres is the outcome: presidential approval (numeric scale)
# inputstate    is the grouping variable (state FIPS code)
# ideo5         is ideology: 1=Very liberal, 3=Moderate, 5=Very conservative
# pid7          is party ID: 1=Strong Dem ... 7=Strong Rep
# faminc_new    is family income (categorical ordinal, 1-16)
# gender        is 1=Male, 2=Female (numeric code, not label)
# educ          is 1-6 (no HS through postgrad)

ces_clean <- ces |>
  # Drop rows missing on any model variable
  filter(
    !is.na(approval_pres),
    !is.na(inputstate),
    !is.na(ideo5),
    !is.na(pid7),
    !is.na(faminc_new),
    !is.na(gender),
    !is.na(educ)
  ) |>
  mutate(
    # Center continuous predictors for interpretability
    # Centering ideo5 at 3 (moderate) makes the intercept = predicted value
    # for a moderate respondent
    ideo5_c      = ideo5 - 3,
    pid7_c       = pid7 - 4,          # center at 4 (Independent-leaning)
    faminc_c     = faminc_new - 8,    # center near midpoint
    female       = as.integer(gender == 2),
    college_plus = as.integer(educ >= 5)
  )

# State-level aggregate: mean ideology per state (the level-2 predictor)
state_means <- ces_clean |>
  group_by(inputstate) |>
  summarise(state_mean_ideo = mean(ideo5, na.rm = TRUE), .groups = "drop")

ces_clean <- ces_clean |>
  left_join(state_means, by = "inputstate") |>
  mutate(state_mean_ideo_c = state_mean_ideo - 3)


# =============================================================================
# 2. NULL MODEL (random intercept only, no predictors)
# =============================================================================
# Purpose: partition variance into within-state (level 1) vs. between-state
# (level 2) components before adding any predictors.

null_mod <- lmer(
  approval_pres ~ 1 + (1 | inputstate),
  data = ces_clean,
  REML = TRUE
)

summary(null_mod)
# Read the output:
#   Random effects:
#     Groups     Name        Variance  Std.Dev.
#     inputstate (Intercept) tau2_00   ...    <- between-state variance
#     Residual               sigma2    ...    <- within-state variance
#   Fixed effects:
#     (Intercept)  <- grand mean of approval_pres across all respondents

# --- ICC via performance::icc() ---
# icc() returns TWO versions:
#   Conditional ICC: variance explained by the grouping structure alone
#   Adjusted ICC:    same (for simple 2-level models these are equal)
icc_result <- performance::icc(null_mod)
print(icc_result)

# Manual verification — should match the ICC output above
vc <- as.data.frame(VarCorr(null_mod))
tau2 <- vc$vcov[vc$grp == "inputstate"]   # between-state variance
sig2 <- vc$vcov[vc$grp == "Residual"]     # within-state variance
icc_manual <- tau2 / (tau2 + sig2)
cat("Manual ICC check:", round(icc_manual, 4), "\n")

# Interpretation guide:
#   ICC < 0.05  -> very little clustering; OLS with state FE might suffice
#   ICC 0.05-0.15 -> modest clustering; MLM adds precision
#   ICC > 0.15  -> strong clustering; MLM is clearly warranted


# =============================================================================
# 3. RANDOM INTERCEPT MODEL (level-1 predictors, fixed state slope)
# =============================================================================
# Each state gets its own intercept, but all predictors have the same slope
# regardless of state. This is the most common starting model in sociology.

ri_mod <- lmer(
  approval_pres ~ ideo5_c + pid7_c + faminc_c + female + college_plus +
    (1 | inputstate),
  data = ces_clean,
  REML = TRUE
)

summary(ri_mod)

# --- Tidy fixed effects table ---
tidy(ri_mod, effects = "fixed", conf.int = TRUE) |>
  select(term, estimate, std.error, statistic, conf.low, conf.high) |>
  mutate(across(where(is.numeric), \(x) round(x, 3)))

# --- Tidy random effects (variance components) ---
tidy(ri_mod, effects = "ran_pars")
# Look at "sd__(Intercept)" for inputstate: this is sqrt(tau2_00)

# --- Model fit ---
glance(ri_mod)
# AIC, BIC, logLik, sigma, nobs, ngrps


# =============================================================================
# 4. RANDOM SLOPE MODEL
# =============================================================================
# Allow the effect of ideology (ideo5_c) to vary across states.
# Syntax: (1 + ideo5_c | inputstate)
#   = random intercept AND random slope for ideo5_c, with correlation
# This estimates: tau2_00, tau2_11, tau_01

rs_mod <- lmer(
  approval_pres ~ ideo5_c + pid7_c + faminc_c + female + college_plus +
    (1 + ideo5_c | inputstate),
  data = ces_clean,
  REML = TRUE
)

summary(rs_mod)
# Random effects section now shows:
#   Groups     Name        Variance Std.Dev. Corr
#   inputstate (Intercept) ...
#              ideo5_c     ...      ...      rho
# rho is the correlation between states' intercepts and their ideo slopes.
# A negative rho means states with higher average approval have a flatter
# ideology gradient (or vice versa).

# If the model fails to converge, try:
#   (1 + ideo5_c || inputstate)   <- forces tau_01 = 0 (uncorrelated)


# =============================================================================
# 5. MODEL COMPARISON VIA LIKELIHOOD RATIO TEST
# =============================================================================
# CRITICAL: anova() comparing fixed effects requires REML=FALSE (full ML).
# lme4's anova() will warn you and refit automatically, but explicit is better.
#
# Rule of thumb:
#   Comparing RANDOM EFFECTS structures -> can use REML
#   Comparing FIXED EFFECTS structures  -> MUST use ML (REML=FALSE)

# Refit both models with REML=FALSE for honest LRT
ri_ml <- update(ri_mod, REML = FALSE)
rs_ml <- update(rs_mod, REML = FALSE)

# LRT: does adding a random slope for ideology significantly improve fit?
anova(ri_ml, rs_ml)
# Output includes: Df, AIC, BIC, logLik, deviance, Chisq, Chi Df, Pr(>Chisq)
# If Pr < 0.05, the random slope is warranted.
# Note: the chi-squared test for variance components is conservative
# (boundary problem); p-values are upper bounds.

# You can also pass the REML=TRUE models and lme4 will refit them:
# anova(ri_mod, rs_mod)   # lme4 warns "refitting model(s) with ML"
# Both approaches give the same result; explicit ML refit is cleaner in papers.


# =============================================================================
# 6. CROSS-LEVEL INTERACTION
# =============================================================================
# A cross-level interaction multiplies a level-1 predictor (ideo5_c, which
# varies by respondent) by a level-2 predictor (state_mean_ideo_c, which
# varies by state). This tests whether the individual-level ideology slope
# is steeper in conservative vs. liberal states.
#
# Requirement: the level-1 predictor must be in the random part too, otherwise
# you're modeling a cross-level interaction on a fixed slope — which is
# conceptually odd and can cause convergence issues.

cli_mod <- lmer(
  approval_pres ~ ideo5_c * state_mean_ideo_c + pid7_c + faminc_c +
    female + college_plus +
    (1 + ideo5_c | inputstate),
  data = ces_clean,
  REML = TRUE
)

summary(cli_mod)
# Key coefficient: ideo5_c:state_mean_ideo_c
# Positive -> individual ideology effect is amplified in conservative states
# Negative -> ideology matters less (convergence) in homogeneous states

# Compare to random slope model (no cross-level interaction)
cli_ml  <- update(cli_mod, REML = FALSE)
anova(rs_ml, cli_ml)


# =============================================================================
# 7. EXTRACT AND PLOT RANDOM EFFECTS
# =============================================================================

# ranef() returns a list; one element per grouping variable
re <- ranef(ri_mod)
str(re)           # re$inputstate is a data frame of BLUPs (u0j estimates)

# Convert to data frame for plotting
re_df <- re$inputstate |>
  rownames_to_column("inputstate") |>
  rename(u0j = `(Intercept)`) |>
  mutate(inputstate = as.integer(inputstate)) |>
  arrange(u0j)

# Caterpillar plot: each state's random intercept with 95% CI
# Standard error of BLUPs
se_re <- sqrt(attr(re$inputstate, "postVar")[1, 1, ])
re_df <- re_df |>
  mutate(
    se   = se_re,
    lo95 = u0j - 1.96 * se,
    hi95 = u0j + 1.96 * se,
    rank = row_number()
  )

ggplot(re_df, aes(x = rank, y = u0j, ymin = lo95, ymax = hi95)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
  geom_errorbar(width = 0.3, color = "steelblue", alpha = 0.7) +
  geom_point(size = 1.5, color = "steelblue") +
  labs(
    title    = "State random intercepts (u0j) from random intercept model",
    subtitle = "Points are BLUP estimates; bars are 95% CIs",
    x        = "States ranked by random intercept",
    y        = "Deviation from grand mean approval (u0j)"
  ) +
  theme_minimal(base_size = 12)

# Tip: to label specific states, left_join re_df to a FIPS lookup table.


# =============================================================================
# 8. NOTE ON MULTIPLY-IMPUTED DATA
# =============================================================================
# If you imputed missing values with mice, do NOT run lmer on a single
# completed dataset. Instead:
#
#   library(mice)
#   imp <- mice(ces_raw, m = 20, method = "pmm", seed = 42)
#
#   # Fit the model on each imputed dataset
#   models <- with(imp, lmer(
#     approval_pres ~ ideo5_c + pid7_c + (1 | inputstate),
#     REML = FALSE   # MI pooling requires ML
#   ))
#
#   # Pool fixed effects using Rubin's rules
#   pooled <- pool(models)
#   summary(pooled)
#
# Caveat: mice::pool() handles fixed effects well via Rubin's rules.
# Pooling variance components (tau, sigma) is harder; lme4 does not support
# this natively. The mitml package offers pool.fixef() and pool.anova()
# specifically for mixed models.


# =============================================================================
# 9. FIXED-EFFECTS ALTERNATIVE VIA fixest::feols()
# =============================================================================
# feols() absorbs state fixed effects without estimating them explicitly.
# This eliminates all between-state confounding but discards between-state
# information and cannot estimate time-invariant variables (like state region).
#
# Use feols() when:
#   - You only care about within-state variation
#   - You suspect omitted state-level confounders
#   - You have many groups (states) and want computational speed
#
# Use lmer() when:
#   - You want to model and interpret between-state variance
#   - You have level-2 predictors or cross-level interactions
#   - Your ICC shows meaningful between-group variance

fe_mod <- fixest::feols(
  approval_pres ~ ideo5_c + pid7_c + faminc_c + female + college_plus |
    inputstate,        # <- this absorbs state FE
  data    = ces_clean,
  cluster = ~inputstate   # cluster SEs by state
)

summary(fe_mod)
etable(fe_mod)   # fixest's clean coefficient table

# Compare fixed-effect coefficients from lmer vs. feols
# If they differ substantially, there is omitted between-state confounding
# that the random intercept model is not fully accounting for.

tidy(ri_mod, effects = "fixed") |>
  select(term, estimate) |>
  rename(lmer_est = estimate)
# vs. tidy(fe_mod) for feols coefficients


# =============================================================================
# END OF MODULE 14
# =============================================================================
