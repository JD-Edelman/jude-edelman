# =============================================================================
# MODULE 14: MULTILEVEL MODELS (MIXED-EFFECTS REGRESSION)
# CES 2020 Social Science Code Library
# =============================================================================
# Topics covered:
#   - Random intercept models (respondents nested in states)
#   - Random slope models (slopes vary by group)
#   - ICC via performance::icc()
#   - Cross-level interactions
#   - REML vs. full ML (lrtest for fixed effects requires ML)
#   - Comparison notes for fixed-effects via lfe or plm
#
# Data note: read_rds() assumes you saved the cleaned CES 2020 object from
# an earlier pipeline step. Alternatively, use arrow::read_parquet() to load
# directly from the .parquet source, then export with haven::write_dta() for
# Stata compatibility.
# =============================================================================

library(lme4)        # lmer(), random effects models
library(lmerTest)    # adds p-values to lmer() via Satterthwaite df
library(broom.mixed) # tidy() and glance() for lmer/glmer objects
library(performance) # icc(), model_performance()
library(tidyverse)   # data wrangling and plotting

# --- SECTION 1: DATA PREP AND xtset EQUIVALENT ---
# ces <- read_rds("path/to/ces2020_clean.rds")
# Inspect nesting: ces |> count(inputstate)
# Recode variables; use numeric codes, not string labels

# --- SECTION 2: NULL MODEL AND ICC ---
# null_mod <- lmer(outcome ~ 1 + (1 | inputstate), data = ces, REML = TRUE)
# summary(null_mod)
# performance::icc(null_mod)
# Interpret: tau2_00 / (tau2_00 + sigma2)

# --- SECTION 3: RANDOM INTERCEPT MODEL ---
# ri_mod <- lmer(outcome ~ predictor1 + predictor2 + (1 | inputstate),
#                data = ces, REML = TRUE)
# summary(ri_mod)
# tidy(ri_mod, effects = "fixed", conf.int = TRUE)
# tidy(ri_mod, effects = "ran_pars")

# --- SECTION 4: RANDOM SLOPE MODEL ---
# rs_mod <- lmer(outcome ~ predictor1 + (predictor1 | inputstate),
#                data = ces, REML = TRUE)
# anova(ri_mod, rs_mod)   # LRT; refit with REML=FALSE first for fixed-effect comparisons
# ranef(rs_mod)            # empirical Bayes estimates of u0j and u1j

# --- SECTION 5: CROSS-LEVEL INTERACTION ---
# cli_mod <- lmer(outcome ~ predictor1 * state_level_var + (predictor1 | inputstate),
#                 data = ces, REML = TRUE)
# summary(cli_mod)
# Marginal effects at representative values of state_level_var

# --- SECTION 6: HAUSMAN-STYLE COMPARISON TO FE ---
# library(fixest)
# fe_mod <- feols(outcome ~ predictor1 + predictor2 | inputstate, data = ces)
# Compare coefficients on within-state predictors between fe_mod and ri_mod
# Discuss: FE absorbs all between-state variance; MLM models it
