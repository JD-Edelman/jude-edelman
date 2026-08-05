# ==============================================================================
#  MODULE 4: LOGISTIC REGRESSION
#  Dataset: CES 2020 (cleaned in Module 1)
#
#  Purpose: Predict binary outcomes (voted, biden_voter) using logistic
#  regression. Covers model estimation, odds ratios, average marginal effects,
#  goodness of fit, predicted probabilities, and ROC/AUC.
# ==============================================================================

library(tidyverse)
library(broom)
library(modelsummary)
library(sandwich)
library(lmtest)
library(marginaleffects)  # average marginal effects (install.packages("marginaleffects"))
library(pROC)             # ROC curves and AUC (install.packages("pROC"))

ces <- readRDS("CES2020_clean.rds")


# ==============================================================================
# SECTION 1: SIMPLE LOGIT — DID RESPONDENT VOTE?
# ==============================================================================

# glm(outcome ~ predictors, data, family = binomial(link = "logit"))
# family = binomial gives logistic regression
# family = binomial(link = "probit") gives probit
#
# Output coefficients are in LOG-ODDS units — not directly interpretable
# as probabilities. Use exp() for odds ratios, or margins for probability scale.

m_voted_simple <- glm(
  voted ~ education,
  data   = ces,
  family = binomial(link = "logit")
)

summary(m_voted_simple)
tidy(m_voted_simple, conf.int = TRUE)


# ==============================================================================
# SECTION 2: ODDS RATIOS
# ==============================================================================

# Exponentiate coefficients and confidence intervals to get odds ratios.
# exp(coef) > 1 = predictor increases odds of Y=1
# exp(coef) < 1 = predictor decreases odds of Y=1

tidy(m_voted_simple, exponentiate = TRUE, conf.int = TRUE)

# Example interpretation:
# OR for education = 1.35 means each additional unit of education
# multiplies the odds of voting by 1.35 (35% increase in odds).


# ==============================================================================
# SECTION 3: FULL TURNOUT MODEL
# ==============================================================================

m_voted_full <- glm(
  voted ~ education + age + factor(sex) + factor(census_region) +
    ideology5 + party_id7 + college + white_nh + imm_restrict + econ_retro,
  data   = ces,
  family = binomial(link = "logit")
)

summary(m_voted_full)

# Odds ratio table
tidy(m_voted_full, exponentiate = TRUE, conf.int = TRUE) |>
  mutate(across(where(is.numeric), ~ round(.x, 3))) |>
  print(n = 30)

# With robust SEs
coeftest(m_voted_full, vcov = vcovHC(m_voted_full, type = "HC3"))


# ==============================================================================
# SECTION 4: PREDICTING BIDEN VOTE CHOICE
# ==============================================================================

# Restrict to voters who chose between Biden and Trump
ces_voters <- ces |> filter(voted == 1, !is.na(biden_voter))

m_biden <- glm(
  biden_voter ~ education + age + factor(sex) + factor(census_region) +
    ideology5 + party_id7 + college + white_nh + imm_restrict + econ_retro,
  data   = ces_voters,
  family = binomial(link = "logit")
)

tidy(m_biden, exponentiate = TRUE, conf.int = TRUE) |>
  mutate(across(where(is.numeric), ~ round(.x, 3)))


# ==============================================================================
# SECTION 5: AVERAGE MARGINAL EFFECTS (AME)
# ==============================================================================

# Marginal effects convert log-odds to probability scale:
# dP/dX = average change in Pr(Y=1) for a 1-unit change in X,
#         averaged across all observations.
#
# marginaleffects::avg_slopes() computes AMEs for all predictors.
# This is what most applied social scientists report in place of log-odds.

ame_voted <- avg_slopes(m_voted_full)
ame_voted

# Round and display cleanly
ame_voted |>
  as_tibble() |>
  select(term, contrast, estimate, std.error, p.value, conf.low, conf.high) |>
  mutate(across(where(is.numeric), ~ round(.x, 4))) |>
  arrange(p.value)

# Interpretation: the estimate for education means "on average across
# respondents, a 1-unit increase in education is associated with a
# [estimate] change in Pr(voted=1)."


# ==============================================================================
# SECTION 6: PREDICTED PROBABILITIES AT SPECIFIC VALUES
# ==============================================================================

# predictions() computes Pr(Y=1) at specified covariate values.
# datagrid() creates a grid of combinations to evaluate at.

# Predicted Pr(voted) across education levels, holding others at mean
pred_educ <- predictions(
  m_voted_full,
  newdata = datagrid(
    education = 1:6,
    sex = 1,
    census_region = 1
  )
)

pred_educ |>
  as_tibble() |>
  select(education, estimate, conf.low, conf.high)

# Plot
pred_educ |>
  ggplot(aes(x = education, y = estimate)) +
  geom_line(color = "navy", linewidth = 1) +
  geom_ribbon(aes(ymin = conf.low, ymax = conf.high), alpha = 0.2, fill = "navy") +
  scale_x_continuous(
    breaks = 1:6,
    labels = c("No HS", "HS grad", "Some coll.", "Assoc.", "Bach.", "Postgrad")
  ) +
  labs(
    title  = "Predicted Probability of Voting by Education",
    x      = "Education Level",
    y      = "Pr(Voted)"
  ) +
  ylim(0, 1) +
  theme_minimal()


# ==============================================================================
# SECTION 7: PREDICTED PROBABILITY BY SEX AND EDUCATION (INTERACTION)
# ==============================================================================

m_interact <- glm(
  voted ~ education * factor(sex) + age + ideology5,
  data   = ces,
  family = binomial()
)

pred_sex_educ <- predictions(
  m_interact,
  newdata = datagrid(
    education = 1:6,
    sex       = 1:2
  )
)

ggplot(pred_sex_educ, aes(x = education, y = estimate,
                          color = factor(sex), fill = factor(sex))) +
  geom_line(linewidth = 1) +
  geom_ribbon(aes(ymin = conf.low, ymax = conf.high), alpha = 0.15) +
  scale_color_manual(values = c("navy", "firebrick"),
                     labels = c("Male", "Female")) +
  scale_fill_manual(values  = c("navy", "firebrick"),
                    labels = c("Male", "Female")) +
  scale_x_continuous(breaks = 1:6,
                     labels = c("No HS","HS","Some coll.","Assoc.","Bach.","Postgrad"),
                     guide  = guide_axis(angle = 45)) +
  labs(title  = "Predicted Pr(Voted) by Education and Sex",
       x      = "Education Level", y = "Pr(Voted)",
       color  = "Sex", fill = "Sex") +
  ylim(0, 1) +
  theme_minimal()


# ==============================================================================
# SECTION 8: GOODNESS OF FIT
# ==============================================================================

# McFadden's pseudo R-squared
# = 1 - (log-likelihood of full model / log-likelihood of intercept-only model)

null_model <- glm(voted ~ 1, data = ces, family = binomial())

pseudo_r2 <- 1 - (logLik(m_voted_full) / logLik(null_model))
cat("McFadden pseudo R2:", round(as.numeric(pseudo_r2), 3), "\n")

# Hosmer-Lemeshow test (from ResourceSelection package)
# install.packages("ResourceSelection")
library(ResourceSelection)

pred_probs <- predict(m_voted_full, type = "response")
hl_test    <- hoslem.test(m_voted_full$y, pred_probs, g = 10)
hl_test
# Non-significant p-value = adequate fit.

# Classification table at 0.5 threshold
ces_complete <- ces |>
  filter(!is.na(voted), !is.na(education), !is.na(age), !is.na(sex),
         !is.na(census_region), !is.na(ideology5), !is.na(party_id7),
         !is.na(college), !is.na(white_nh), !is.na(imm_restrict),
         !is.na(econ_retro))

pred_class <- if_else(fitted(m_voted_full) > 0.5, 1, 0)
table(Predicted = pred_class, Actual = m_voted_full$y)

accuracy <- mean(pred_class == m_voted_full$y)
cat("Accuracy:", round(accuracy, 3), "\n")


# ==============================================================================
# SECTION 9: ROC CURVE AND AUC
# ==============================================================================

roc_obj <- roc(m_voted_full$y, fitted(m_voted_full))

cat("AUC:", round(auc(roc_obj), 3), "\n")
# AUC > 0.7 = acceptable; > 0.8 = excellent; 0.5 = no better than chance

# Plot ROC curve using ggplot via pROC
ggroc(roc_obj, color = "navy", linewidth = 1) +
  geom_segment(aes(x = 1, xend = 0, y = 0, yend = 1),
               color = "gray50", linetype = "dashed") +
  labs(
    title    = paste("ROC Curve — AUC =", round(auc(roc_obj), 3)),
    x        = "Specificity",
    y        = "Sensitivity"
  ) +
  theme_minimal()


# ==============================================================================
# SECTION 10: PROBIT AS ALTERNATIVE
# ==============================================================================

m_probit <- glm(
  voted ~ education + age + factor(sex) + ideology5 + party_id7,
  data   = ces,
  family = binomial(link = "probit")
)

# AMEs from probit should be very similar to logit AMEs
avg_slopes(m_probit) |>
  as_tibble() |>
  select(term, estimate, std.error, p.value) |>
  mutate(across(where(is.numeric), ~ round(.x, 4)))


# ==============================================================================
# SECTION 11: PUBLICATION TABLE
# ==============================================================================

m_l1 <- glm(voted ~ education + age + factor(sex) + ideology5,
             data = ces, family = binomial())

m_l2 <- glm(voted ~ education + age + factor(sex) + ideology5 + party_id7 + college,
             data = ces, family = binomial())

m_l3 <- glm(voted ~ education + age + factor(sex) + ideology5 + party_id7 +
               college + white_nh + imm_restrict,
             data = ces, family = binomial())

# Logit table with ORs (exponentiate = TRUE)
modelsummary(
  list("Model 1" = m_l1, "Model 2" = m_l2, "Model 3" = m_l3),
  exponentiate = TRUE,
  stars   = c("*" = .05, "**" = .01, "***" = .001),
  gof_map = c("nobs", "logLik", "AIC"),
  title   = "Logistic Regression (Odds Ratios): Voter Turnout 2020"
)

message("Module 4 complete.")
