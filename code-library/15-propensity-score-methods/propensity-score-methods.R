# =============================================================================
# MODULE 15: PROPENSITY SCORE METHODS
# CES 2020 Social Science Code Library
# =============================================================================
# Topics covered:
#   - Propensity score estimation via logistic regression
#   - Nearest-neighbor matching with MatchIt
#   - IPTW (ATE and ATT) with WeightIt
#   - Balance diagnostics with cobalt (love.plot, bal.tab)
#   - Outcome analysis on matched/weighted samples
#
# Unconfoundedness assumption:
#   All methods assume Y(0),Y(1) are independent of treatment D given observed
#   covariates X. This is untestable; consider sensitivity analysis
#   (e.g., sensemakr or RosenbaumBounds) after main results.
# =============================================================================

library(MatchIt)   # matching: matchit(), match.data(), match_arg()
library(WeightIt)  # IPTW: weightit()
library(cobalt)    # balance: bal.tab(), love.plot()
library(tidyverse) # data wrangling
library(broom)     # tidy() for regression objects

# --- SECTION 1: ESTIMATE PROPENSITY SCORES (logit) ---
# ces <- read_rds("path/to/ces2020_clean.rds")
# ps_mod <- glm(treatment_var ~ covariate1 + covariate2 + covariate3,
#               data = ces, family = binomial(link = "logit"))
# ces$pscore <- predict(ps_mod, type = "response")
# summary(ces$pscore)

# --- SECTION 2: COMMON SUPPORT AND OVERLAP ---
# ggplot(ces, aes(x = pscore, fill = factor(treatment_var))) +
#   geom_density(alpha = 0.5) +
#   labs(title = "Propensity score distributions by treatment",
#        x = "Estimated propensity score", fill = "Treatment") +
#   theme_minimal()
# Trim units outside common support before matching/weighting

# --- SECTION 3: NEAREST-NEIGHBOR MATCHING ---
# m_out <- matchit(treatment_var ~ covariate1 + covariate2 + covariate3,
#                  data = ces, method = "nearest", distance = "glm",
#                  link = "logit", ratio = 1, replace = FALSE)
# summary(m_out)
# matched_data <- match.data(m_out)

# --- SECTION 4: IPTW WEIGHTS ---
# ATE weights
# w_ate <- weightit(treatment_var ~ covariate1 + covariate2 + covariate3,
#                   data = ces, method = "ps", estimand = "ATE")
# ATT weights
# w_att <- weightit(treatment_var ~ covariate1 + covariate2 + covariate3,
#                   data = ces, method = "ps", estimand = "ATT")
# ces$ate_weight <- w_ate$weights
# ces$att_weight <- w_att$weights

# --- SECTION 5: BALANCE DIAGNOSTICS (standardized differences) ---
# Pre-weighting balance
# bal.tab(treatment_var ~ covariate1 + covariate2 + covariate3, data = ces,
#         thresholds = c(m = 0.1))
# Post-weighting balance (IPTW)
# bal.tab(w_att, thresholds = c(m = 0.1))
# love.plot(w_att, thresholds = 0.1,
#           title = "Covariate balance before and after IPTW (ATT)")

# --- SECTION 6: OUTCOME ANALYSIS ---
# Naive (unadjusted)
# lm(outcome_var ~ treatment_var, data = ces) |> tidy(conf.int = TRUE)
# IPTW-weighted ATE
# lm(outcome_var ~ treatment_var, data = ces, weights = ate_weight) |> tidy(conf.int = TRUE)
# IPTW-weighted ATT
# lm(outcome_var ~ treatment_var, data = ces, weights = att_weight) |> tidy(conf.int = TRUE)
# Doubly robust (add covariates to weighted regression)
# lm(outcome_var ~ treatment_var + covariate1 + covariate2,
#    data = ces, weights = att_weight) |> tidy(conf.int = TRUE)
