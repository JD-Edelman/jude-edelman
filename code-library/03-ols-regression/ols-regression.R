# ==============================================================================
#  MODULE 3: OLS LINEAR REGRESSION
#  Dataset: CES 2020 (cleaned in Module 1)
#
#  Purpose: Run OLS from bivariate through full models with interaction terms,
#  robust SEs, post-estimation diagnostics, and formatted output tables.
# ==============================================================================

library(tidyverse)
library(sandwich)    # robust/clustered standard errors (vcovHC, vcovCL)
library(lmtest)      # coeftest() — apply robust SEs to model output
library(modelsummary) # publication-quality regression tables
library(broom)       # tidy(), glance(), augment() — tidy model output

# install.packages(c("sandwich", "lmtest", "modelsummary", "broom"))

ces <- readRDS("CES2020_clean.rds")

# Complete-case subset spanning all variables used in the comparison table
# (Sections 1–3) so modelsummary sees the same N across nested models
ces_cc <- ces |>
  tidyr::drop_na(imm_restrict, education, age, sex, census_region,
                 ideology5, party_id7, college)


# ==============================================================================
# SECTION 1: SIMPLE (BIVARIATE) OLS
# ==============================================================================

# lm(outcome ~ predictor(s), data)
# R's formula interface: ~ separates outcome from predictors
# + adds predictors; * adds an interaction AND both main effects

m_simple <- lm(imm_restrict ~ education, data = ces_cc)

summary(m_simple)

# tidy() from broom gives a clean tibble of coefficients
tidy(m_simple, conf.int = TRUE)

# glance() gives model-level stats (R², F-stat, df, etc.)
glance(m_simple)

# Interpretation: the "estimate" for education is the slope —
# each additional unit of education is associated with that many
# fewer/more units of immigration restrictionism, on average.


# ==============================================================================
# SECTION 2: MULTIPLE REGRESSION (ADDITIVE CONTROLS)
# ==============================================================================

# factor() converts a numeric variable to a categorical dummy set in the model
# R automatically omits the lowest-level category as the reference group
# (equivalent to Stata's i. prefix)

m_demog <- lm(
  imm_restrict ~ education + age + factor(sex) + factor(census_region),
  data = ces_cc
)

summary(m_demog)
tidy(m_demog, conf.int = TRUE)


# ==============================================================================
# SECTION 3: FULL MODEL
# ==============================================================================

m_full <- lm(
  imm_restrict ~ education + age + factor(sex) + factor(census_region) +
    ideology5 + party_id7 + college,
  data = ces_cc
)

summary(m_full)
tidy(m_full, conf.int = TRUE)
glance(m_full)


# ==============================================================================
# SECTION 4: COMPARING NESTED MODELS
# ==============================================================================

# anova(restricted_model, full_model) runs an F-test comparing nested models
# (the R equivalent of Stata's "test ideology5 party_id7" after regress)

anova(m_demog, m_full)

# The F-statistic tests H0: all newly added coefficients == 0 simultaneously.
# Significant p-value → the full model fits significantly better.


# ==============================================================================
# SECTION 5: INTERACTION TERMS
# ==============================================================================

# In R formulas:
#   a:b    = interaction of a and b (no main effects)
#   a*b    = a + b + a:b (main effects + interaction)
# Always use * when you want the interaction — it includes main effects.

# Does education's effect on restrictionism vary by party?
m_interact <- lm(
  imm_restrict ~ education * factor(party_id3) + age + factor(sex),
  data = ces
)

summary(m_interact)

# Visualize the interaction with predicted values
# Create a prediction grid covering education × party combinations
pred_grid <- expand.grid(
  education  = 1:6,
  party_id3  = 1:3,
  age        = mean(ces$age, na.rm = TRUE),
  sex        = 1   # hold sex constant at Male (reference)
)

pred_grid$predicted <- predict(m_interact, newdata = pred_grid)

ggplot(pred_grid, aes(x = education, y = predicted,
                      color = factor(party_id3),
                      group = factor(party_id3))) +
  geom_line(linewidth = 1) +
  geom_point(size = 2) +
  scale_color_manual(
    values = c("blue", "red", "darkgreen"),
    labels = c("Democrat", "Republican", "Independent")
  ) +
  scale_x_continuous(
    breaks = 1:6,
    labels = c("No HS", "HS grad", "Some coll.", "Assoc.", "Bach.", "Postgrad")
  ) +
  labs(
    title   = "Predicted Immigration Restrictionism by Education & Party",
    x       = "Education Level",
    y       = "Predicted Restrictionism (0–5)",
    color   = "Party ID"
  ) +
  theme_minimal()


# ==============================================================================
# SECTION 6: ROBUST STANDARD ERRORS (HETEROSKEDASTICITY-ROBUST)
# ==============================================================================

# OLS standard errors assume homoskedasticity. When violated, use
# Huber-White robust SEs via sandwich::vcovHC() and lmtest::coeftest().
#
# type = "HC3" is the most common; "HC1" matches Stata's default robust

m_robust <- lm(
  imm_restrict ~ education + age + ideology5 + factor(sex) + factor(census_region),
  data = ces
)

# Display with robust SEs
coeftest(m_robust, vcov = vcovHC(m_robust, type = "HC3"))

# Tidy output with robust SEs — use tidy(coeftest(...))
tidy(coeftest(m_robust, vcov = vcovHC(m_robust, type = "HC3")), conf.int = TRUE)


# ==============================================================================
# SECTION 7: CLUSTERED STANDARD ERRORS
# ==============================================================================

# Cluster SEs by state when observations within states are correlated.
# vcovCL() from sandwich handles clustering.

m_cluster <- lm(
  imm_restrict ~ education + age + ideology5 + factor(sex),
  data = ces
)

coeftest(m_cluster, vcov = vcovCL(m_cluster, cluster = ~state_fips))


# ==============================================================================
# SECTION 8: STANDARDIZED (BETA) COEFFICIENTS
# ==============================================================================

# Standardize predictors to SD units before regressing.
# scale() centers and divides by SD (z-score).
# Resulting coefficients are directly comparable in magnitude.

ces_scaled <- ces |>
  mutate(across(
    c(education, age, ideology5, party_id7, imm_restrict),
    ~ as.numeric(scale(.x))
  ))

m_std <- lm(
  imm_restrict ~ education + age + ideology5 + party_id7 + factor(sex),
  data = ces_scaled
)

tidy(m_std, conf.int = TRUE)

# All coefficients are now in SD units — compare magnitude across predictors.
# factor(sex) is a dummy so its standardized coefficient is less interpretable.


# ==============================================================================
# SECTION 9: POST-ESTIMATION DIAGNOSTICS
# ==============================================================================

# augment() from broom adds fitted values, residuals, leverage, Cook's D
# to the original data as new columns

diag_df <- augment(m_full)

# --- Residual vs. Fitted ---
ggplot(diag_df, aes(x = .fitted, y = .resid)) +
  geom_point(alpha = 0.2, color = "navy", size = .5) +
  geom_hline(yintercept = 0, color = "red", linetype = "dashed") +
  geom_smooth(method = "loess", se = FALSE, color = "orange", linewidth = .8) +
  labs(title = "Residuals vs. Fitted Values",
       x = "Fitted Values", y = "Residuals") +
  theme_minimal()

# --- Q-Q Plot (normality of residuals) ---
ggplot(diag_df, aes(sample = .std.resid)) +
  stat_qq(alpha = 0.3, color = "navy") +
  stat_qq_line(color = "red") +
  labs(title = "Normal Q-Q Plot of Standardized Residuals",
       x = "Theoretical Quantiles", y = "Standardized Residuals") +
  theme_minimal()

# --- Cook's D — influential observations ---
diag_df |>
  mutate(obs = row_number()) |>
  ggplot(aes(x = obs, y = .cooksd)) +
  geom_point(alpha = 0.3, size = .5) +
  geom_hline(yintercept = 4 / nrow(ces), color = "red", linetype = "dashed") +
  labs(title = "Cook's Distance",
       subtitle = "Red line = 4/N threshold",
       x = "Observation", y = "Cook's D") +
  theme_minimal()

# Count high-influence observations
n <- nrow(m_full$model)
sum(diag_df$.cooksd > 4 / n, na.rm = TRUE)

# --- VIF (multicollinearity) ---
# install.packages("car")
library(car)
vif(m_full)
# VIF > 10 (or > 5 conservatively) signals problematic multicollinearity

# --- Breusch-Pagan test (heteroskedasticity) ---
# lmtest::bptest()
bptest(m_full)
# Significant → heteroskedasticity present → use robust SEs


# ==============================================================================
# SECTION 10: PUBLICATION TABLE WITH MODELSUMMARY
# ==============================================================================

# modelsummary() produces Word, LaTeX, or HTML regression tables.
# Pass a named list of models for side-by-side columns.

models <- list(
  "Bivariate"    = m_simple,
  "Demographics" = m_demog,
  "Full Model"   = m_full
)

# Console display
modelsummary(
  models,
  stars   = c("*" = .05, "**" = .01, "***" = .001),
  gof_map = c("nobs", "r.squared", "adj.r.squared", "AIC", "BIC"),
  title   = "OLS Regression: Predictors of Immigration Restrictionism"
)

# Export to Word
# modelsummary(models, output = "table_ols.docx",
#   stars = c("*" = .05, "**" = .01, "***" = .001))

# Export to LaTeX
# modelsummary(models, output = "table_ols.tex",
#   stars = c("*" = .05, "**" = .01, "***" = .001))

# With robust SEs
modelsummary(
  models,
  vcov  = "HC3",   # applies robust SEs to all models automatically
  stars = c("*" = .05, "**" = .01, "***" = .001),
  title = "OLS Regression: Robust SEs"
)

message("Module 3 complete.")
