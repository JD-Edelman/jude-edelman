# ==============================================================================
#  MODULE 10: MULTIPLE IMPUTATION WITH MICE
#  Dataset: CES 2020 (cleaned in Module 1)
#
#  Purpose: Handle missing covariate data using MICE (Multivariate Imputation
#  by Chained Equations). R's mice package is the gold standard for MI
#  and mirrors Stata's mi impute chained in approach.
#
#  install.packages(c("mice", "miceadds", "mitml"))
# ==============================================================================

library(tidyverse)
library(mice)        # MICE imputation
library(broom)
library(modelsummary)

ces <- readRDS("CES2020_clean.rds")


# ==============================================================================
# SECTION 1: ASSESS MISSING DATA BEFORE IMPUTING
# ==============================================================================

# Select variables for the analysis + imputation model
analysis_vars <- ces |>
  select(
    caseid, age, sex, education, race_eth, college, white_nh,
    census_region, state_fips,
    ideology5, party_id3, party_id7, dem, rep,
    imm_restrict, econ_retro, hh_income_change, approve_trump,
    self_rated_health,
    voted, voted_2020, pres_vote, biden_voter,
    wt_post
  )

# Summary of missingness
md.pattern(
  analysis_vars |> select(-caseid, -wt_post),
  rotate.names = TRUE
)

# How much is missing on key variables?
analysis_vars |>
  summarise(across(everything(), ~ mean(is.na(.x)) * 100)) |>
  pivot_longer(everything(), names_to = "variable", values_to = "pct_missing") |>
  filter(pct_missing > 0) |>
  arrange(desc(pct_missing))

# Is missingness on ideology5 predicted by observed vars? (MAR plausibility)
glm(is.na(ideology5) ~ sex + age + college + white_nh + census_region,
    data = analysis_vars,
    family = binomial()) |>
  broom::tidy() |>
  filter(term != "(Intercept)")
# Significant predictors → data are MAR (not MCAR) — imputation is appropriate


# ==============================================================================
# SECTION 2: SET UP THE MICE IMPUTATION
# ==============================================================================

# Select only the imputation dataset (drop variables you won't impute or analyze)
# Never impute outcome variables — include them as predictors in the imputation
# model but do not impute their missing values.

imp_data <- analysis_vars |>
  select(-caseid, -wt_post, -voted_2020, -pres_vote)

# mice() creates m imputed datasets using chained equations.
# Each variable is imputed using a model conditional on all others.
#
# Method choices per variable:
#   "pmm"    = predictive mean matching (continuous; robust to non-normality)
#   "logreg" = logistic regression (binary 0/1)
#   "polyreg" = multinomial logit (unordered categorical)
#   "polr"   = proportional odds / ordered logit (ordinal)
#   ""       = don't impute this variable (complete or outcome)

# Inspect what mice would default to for each variable
init <- mice(imp_data, maxit = 0)
meth <- init$method
pred <- init$predictorMatrix

# View default methods
meth

# Override methods for specific variables
meth["ideology5"]      <- "polr"    # ordinal (1-5)
meth["party_id3"]      <- "polyreg" # nominal (1-3)
meth["party_id7"]      <- "polr"    # ordinal (1-7)
meth["econ_retro"]     <- "polr"    # ordinal (1-5)
meth["hh_income_change"] <- "polr"
meth["approve_trump"]  <- "polr"
meth["self_rated_health"] <- "polr"

# Don't impute outcome variables or derived vars
meth["voted"]       <- ""
meth["biden_voter"] <- ""
meth["dem"]         <- ""
meth["rep"]         <- ""

# Remove caseid and weight from predictor matrix (if present)
# They aren't in imp_data so this is already handled

# Run imputation
set.seed(20240101)

mi_out <- mice(
  imp_data,
  m       = 20,        # number of imputed datasets
  method  = meth,
  maxit   = 10,        # iterations per imputation
  printFlag = FALSE    # suppress verbose output
)

message("Imputation complete. m = ", mi_out$m, " datasets created.")


# ==============================================================================
# SECTION 3: DIAGNOSTICS — DID IMPUTATION WORK?
# ==============================================================================

# Trace plots: check convergence (should look like "hairy caterpillar" — no trend)
plot(mi_out, c("ideology5", "party_id7", "econ_retro"))

# Density plots: compare imputed vs. observed distributions
densityplot(mi_out, ~ ideology5 + party_id7 + econ_retro)
# Blue = observed, red = imputed. Should overlap substantially.

# Strip plots for binary/categorical
stripplot(mi_out, ideology5 ~ .imp, pch = 20, cex = .4)

# Compare means across imputed datasets
mi_out$imp$ideology5 |> colMeans()
# Values should be similar across m = 1 to 20; large spread = convergence problem


# ==============================================================================
# SECTION 4: ANALYZE — RUN MODELS ON ALL IMPUTED DATASETS
# ==============================================================================

# with() runs a model on each of the m imputed datasets
# pool() combines the m sets of results using Rubin's rules

# OLS on imputed data
mi_ols <- with(
  mi_out,
  lm(imm_restrict ~ education + age + ideology5 + party_id7 +
       factor(sex) + factor(census_region) + college + white_nh)
)

pooled_ols <- pool(mi_ols)
summary(pooled_ols)

# pool.r.squared() — pooled R-squared
pool.r.squared(mi_ols)

# Logit on imputed data (voted)
mi_logit <- with(
  mi_out,
  glm(voted ~ education + age + ideology5 + party_id7 +
        factor(sex) + factor(census_region) + college + white_nh,
      family = binomial())
)

pooled_logit <- pool(mi_logit)
summary(pooled_logit, exponentiate = TRUE, conf.int = TRUE)

# Fraction of missing information (FMI) — shown in pool summary
# FMI close to 0 = imputation didn't change much (variable had little missing)
# FMI > 0.3 = substantial missing-data uncertainty


# ==============================================================================
# SECTION 5: TIDY POOLED RESULTS WITH BROOM
# ==============================================================================

# tidy.mipo() from broom works on pooled mice objects
tidy(pooled_ols, conf.int = TRUE) |>
  mutate(across(where(is.numeric), ~ round(.x, 4)))

tidy(pooled_logit, exponentiate = TRUE, conf.int = TRUE) |>
  mutate(across(where(is.numeric), ~ round(.x, 4)))


# ==============================================================================
# SECTION 6: COMPARE MI TO COMPLETE-CASE (SENSITIVITY CHECK)
# ==============================================================================

# Complete-case OLS
cc_ols <- lm(
  imm_restrict ~ education + age + ideology5 + party_id7 +
    factor(sex) + factor(census_region) + college + white_nh,
  data = ces
)

# MI OLS (tidy the pooled result into the same format)
mi_ols_tidy <- tidy(pooled_ols, conf.int = TRUE) |>
  mutate(model = "MI (m=20)")

cc_tidy <- tidy(cc_ols, conf.int = TRUE) |>
  mutate(model = "Complete Case")

# Side-by-side coefficient comparison
bind_rows(cc_tidy, mi_ols_tidy) |>
  select(model, term, estimate, std.error, p.value) |>
  pivot_wider(
    names_from  = model,
    values_from = c(estimate, std.error, p.value)
  ) |>
  mutate(across(where(is.numeric), ~ round(.x, 4))) |>
  print(n = 30)


# ==============================================================================
# SECTION 7: WORKING WITH COMPLETED DATASETS
# ==============================================================================

# complete() extracts one or all imputed datasets from the mids object

# Extract a single imputed dataset (dataset #1)
imp1 <- complete(mi_out, 1)
glimpse(imp1)

# Extract all m imputed datasets stacked with .imp indicator
all_imp <- complete(mi_out, action = "long", include = TRUE)
# .imp == 0 = original data; .imp == 1:20 = imputed datasets
all_imp |> count(.imp)

# Convert to data frame for custom analysis
# (You can run models on each and pool manually if needed)
models_by_imp <- map(1:mi_out$m, function(i) {
  d <- complete(mi_out, i)
  lm(imm_restrict ~ education + age + ideology5, data = d)
})

# Pool manually with Rubin's rules (for custom estimators not supported by with())
estimates <- map_dbl(models_by_imp, ~ coef(.x)["education"])
variances  <- map_dbl(models_by_imp, ~ vcov(.x)["education", "education"])

m   <- length(estimates)
q_bar <- mean(estimates)                        # pooled estimate
u_bar <- mean(variances)                        # within-imputation variance
b     <- var(estimates)                         # between-imputation variance
t_var <- u_bar + (1 + 1/m) * b                 # total variance (Rubin's rules)

cat("Pooled education coefficient:", round(q_bar, 4), "\n")
cat("Pooled SE:", round(sqrt(t_var), 4), "\n")


# ==============================================================================
# SECTION 8: PASSIVE IMPUTATION — DERIVED VARIABLES
# ==============================================================================

# Variables derived from imputed variables must be recomputed in each
# imputed dataset AFTER imputation. In mice, use the passive method or
# recompute manually with complete().

# Example: recompute dem and rep from the imputed party_id3
all_imp_updated <- all_imp |>
  mutate(
    dem = if_else(.imp > 0, as.integer(party_id3 == 1), dem),
    rep = if_else(.imp > 0, as.integer(party_id3 == 2), rep)
  )

# Verify: dem should be 1 everywhere party_id3 == 1 in imputed datasets
all_imp_updated |>
  filter(.imp > 0) |>
  summarise(consistency = mean(dem == (party_id3 == 1), na.rm = TRUE))


# ==============================================================================
# SECTION 9: SAVE THE IMPUTED OBJECT
# ==============================================================================

# Save the mids object — it contains all imputed datasets
saveRDS(mi_out, "CES2020_mice.rds")

# To reload in another script:
#   mi_out <- readRDS("CES2020_mice.rds")
#   pooled <- with(mi_out, lm(...)) |> pool()

message("Module 10 complete. MICE object saved as CES2020_mice.rds.")
