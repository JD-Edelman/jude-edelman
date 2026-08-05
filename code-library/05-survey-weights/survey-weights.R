# ==============================================================================
#  MODULE 5: SURVEY-WEIGHTED ANALYSIS
#  Dataset: CES 2020 (cleaned in Module 1)
#
#  Purpose: Produce nationally representative estimates using CES post-election
#  weights via the survey package. Covers weighted means, proportions,
#  tabulations, OLS, logit, and subpopulation analysis.
#
#  Key package: survey (Thomas Lumley) — the standard for complex survey
#  analysis in R, mirrors Stata's svy suite.
# ==============================================================================

library(tidyverse)
library(survey)
library(broom)
library(modelsummary)

ces <- readRDS("CES2020_clean.rds")


# ==============================================================================
# SECTION 1: DECLARE THE SURVEY DESIGN
# ==============================================================================

# svydesign() tells R the structure of the sampling design.
# CES does not release stratum or cluster variables publicly, so we
# declare only the weight. This gives correct weighted estimates;
# SEs are computed via Taylor linearization.
#
# ids    = ~1  means no clustering variable (treat each row as its own PSU)
# weights = ~wt_post  applies the post-election survey weight

ces_svy <- svydesign(
  ids     = ~1,
  weights = ~wt_post,
  data    = ces
)

# Confirm design
summary(ces_svy)


# ==============================================================================
# SECTION 2: WEIGHTED MEANS AND PROPORTIONS
# ==============================================================================

# svymean() — weighted means with design-based SEs
svymean(~ age + ideology5 + imm_restrict + econ_retro,
        design = ces_svy, na.rm = TRUE)

# Unweighted comparison
ces |>
  summarise(across(c(age, ideology5, imm_restrict, econ_retro),
                   ~ mean(.x, na.rm = TRUE)))

# svymean() for binary/proportion variables
svymean(~ college + voted + dem + rep,
        design = ces_svy, na.rm = TRUE)

# With confidence intervals
confint(svymean(~ age + ideology5, design = ces_svy, na.rm = TRUE))

# Weighted proportion by subgroup — over() equivalent in R
# Use svyby() for group-specific estimates
svyby(~ voted, by = ~ census_region, design = ces_svy,
      FUN = svymean, na.rm = TRUE)


# ==============================================================================
# SECTION 3: WEIGHTED FREQUENCY TABLES
# ==============================================================================

# svytable() produces a weighted cross-tabulation (counts scaled to population)
svytable(~ college, design = ces_svy)
svytable(~ voted, design = ces_svy)
svytable(~ party_id3, design = ces_svy)

# Two-way weighted cross-tab
svytable(~ party_id3 + biden_voter, design = ces_svy) |>
  prop.table(margin = 1) |>   # row proportions
  round(3)

# Chi-square test on weighted table — uses Rao-Scott correction
svychisq(~ party_id3 + biden_voter, design = ces_svy, statistic = "Chisq")
svychisq(~ college + voted, design = ces_svy, statistic = "Chisq")


# ==============================================================================
# SECTION 4: SURVEY-WEIGHTED OLS (LINEAR REGRESSION)
# ==============================================================================

# svyglm() with family = gaussian() gives weighted OLS.
# Always use svyglm() not glm() when you want design-based inference.

svy_ols <- svyglm(
  imm_restrict ~ education + age + factor(sex) + factor(census_region) +
    ideology5 + party_id7,
  design = ces_svy
)

summary(svy_ols)
tidy(svy_ols, conf.int = TRUE)


# ==============================================================================
# SECTION 5: SURVEY-WEIGHTED LOGIT
# ==============================================================================

# svyglm() with family = quasibinomial() gives weighted logistic regression.
# Use quasibinomial (not binomial) with svyglm to avoid a common warning
# about non-integer weights — it gives identical point estimates.

svy_logit_voted <- svyglm(
  voted ~ education + age + factor(sex) + factor(census_region) +
    ideology5 + party_id7,
  design = ces_svy,
  family = quasibinomial(link = "logit")
)

summary(svy_logit_voted)

# Odds ratios
tidy(svy_logit_voted, exponentiate = TRUE, conf.int = TRUE) |>
  mutate(across(where(is.numeric), ~ round(.x, 3)))

# Biden vote choice (voters only) — use subset() for subpopulations in survey pkg
# NEVER filter the dataframe first — it destroys the design.
# subset() is the correct approach (like Stata's subpop())

svy_logit_biden <- svyglm(
  biden_voter ~ education + age + factor(sex) + ideology5 +
    party_id7 + white_nh + college + imm_restrict,
  design = subset(ces_svy, voted == 1),
  family = quasibinomial(link = "logit")
)

tidy(svy_logit_biden, exponentiate = TRUE, conf.int = TRUE) |>
  mutate(across(where(is.numeric), ~ round(.x, 3)))


# ==============================================================================
# SECTION 6: SUBPOPULATION ANALYSIS (subset)
# ==============================================================================

# CORRECT: use subset() to restrict to a subpopulation
# This keeps all cases in the design but estimates for the subgroup only.
# WRONG: filter(ces, black == 1) then create a new svydesign — destroys SEs.

ces_svy_black  <- subset(ces_svy, race_eth == 2)   # Black respondents
ces_svy_college <- subset(ces_svy, college == 1)
ces_svy_women  <- subset(ces_svy, sex == 2)

# Mean ideology among Black respondents
svymean(~ ideology5 + imm_restrict + econ_retro,
        design = ces_svy_black, na.rm = TRUE)

# Biden vote among Black voters
svymean(~ biden_voter,
        design = subset(ces_svy_black, voted == 1), na.rm = TRUE)

# Mean restrictionism among college-educated
svymean(~ imm_restrict + ideology5,
        design = ces_svy_college, na.rm = TRUE)

# Mean restrictionism among women
svymean(~ imm_restrict + ideology5 + econ_retro,
        design = ces_svy_women, na.rm = TRUE)


# ==============================================================================
# SECTION 7: DESIGN EFFECT (DEFF)
# ==============================================================================

# deff option in svymean reports the design effect.
# DEFF > 1 means the survey design inflates variance vs. a simple random sample.

svymean(~ age + college + voted + ideology5,
        design = ces_svy, na.rm = TRUE, deff = TRUE)


# ==============================================================================
# SECTION 8: WEIGHTED VS. UNWEIGHTED COMPARISON
# ==============================================================================

# Unweighted logit
m_unweighted <- glm(
  biden_voter ~ education + age + factor(sex) + ideology5 + party_id7 +
    white_nh + college + imm_restrict,
  data   = filter(ces, voted == 1),
  family = binomial()
)

# Weighted logit
m_weighted <- svyglm(
  biden_voter ~ education + age + factor(sex) + ideology5 + party_id7 +
    white_nh + college + imm_restrict,
  design = subset(ces_svy, voted == 1),
  family = quasibinomial()
)

# Side-by-side table
modelsummary(
  list("Unweighted" = m_unweighted, "Weighted" = m_weighted),
  exponentiate = TRUE,
  stars        = c("*" = .05, "**" = .01, "***" = .001),
  title        = "Biden Vote Choice: Unweighted vs. Survey-Weighted Logit"
)


# ==============================================================================
# SECTION 9: WEIGHTED DESCRIPTIVE TABLE BY GROUP
# ==============================================================================

# Compute weighted means by party ID
svyby(
  ~ ideology5 + imm_restrict + age + econ_retro,
  by     = ~ party_id3,
  design = ces_svy,
  FUN    = svymean,
  na.rm  = TRUE
) |>
  as_tibble() |>
  mutate(across(where(is.numeric), ~ round(.x, 2)))


# ==============================================================================
# SECTION 10: NOTES ON WHEN TO WEIGHT
# ==============================================================================

# Always weight when making population-level descriptive claims.
# Consider weighting in causal models as a robustness check.
# If weighted and unweighted estimates diverge substantially, investigate.

message("Module 5 complete.")
