# ==============================================================================
#  MODULE 2: DESCRIPTIVE STATISTICS & TABULATIONS
#  Dataset: CES 2020 (cleaned in Module 1)
#
#  Purpose: Summarize continuous and categorical variables, cross-tabulate,
#  compare group means, and examine missing data patterns.
# ==============================================================================

library(tidyverse)
library(scales)      # percent formatting in tables


ces <- readRDS("CES2020_clean.rds")


# ==============================================================================
# SECTION 1: UNIVARIATE SUMMARIES — CONTINUOUS VARIABLES
# ==============================================================================

# summary() gives the five-number summary + mean for every column
ces |>
  select(age, education, ideology5, party_id7, imm_restrict,
         econ_retro, hh_income_change, self_rated_health) |>
  summary()

# More controlled output with summarise + across
# Creates a clean "Table 1" style dataframe you can export
ces |>
  select(age, education, ideology5, party_id7, imm_restrict,
         econ_retro, self_rated_health) |>
  summarise(across(
    everything(),
    list(
      mean   = ~ mean(.x, na.rm = TRUE),
      sd     = ~ sd(.x,   na.rm = TRUE),
      median = ~ median(.x, na.rm = TRUE),
      min    = ~ min(.x,  na.rm = TRUE),
      max    = ~ max(.x,  na.rm = TRUE),
      n      = ~ sum(!is.na(.x))
    ),
    .names = "{.col}__{.fn}"
  )) |>
  pivot_longer(
    everything(),
    names_to  = c("variable", "stat"),
    names_sep = "__"
  ) |>
  pivot_wider(names_from = stat, values_from = value) |>
  mutate(across(where(is.numeric), ~ round(.x, 2)))

# Detailed distribution check — skewness and percentiles
ces |>
  summarise(
    mean   = mean(age, na.rm = TRUE),
    sd     = sd(age, na.rm = TRUE),
    p10    = quantile(age, .10, na.rm = TRUE),
    p25    = quantile(age, .25, na.rm = TRUE),
    median = median(age, na.rm = TRUE),
    p75    = quantile(age, .75, na.rm = TRUE),
    p90    = quantile(age, .90, na.rm = TRUE)
  )


# ==============================================================================
# SECTION 2: FREQUENCY TABLES — CATEGORICAL VARIABLES
# ==============================================================================

# count() produces frequency tables; mutate adds proportions
freq_table <- function(df, var) {
  df |>
    count({{ var }}, .drop = FALSE) |>
    mutate(pct = n / sum(n) * 100) |>
    mutate(pct = round(pct, 1))
}

freq_table(ces, sex)
freq_table(ces, census_region)
freq_table(ces, college)
freq_table(ces, voted)
freq_table(ces, biden_voter)
freq_table(ces, party_id3)
freq_table(ces, party_id7)
freq_table(ces, approve_trump)

# Including NA in counts — always show how much is missing
ces |> count(biden_voter, useNA = "always")
ces |> count(ideology5,   useNA = "always")


# ==============================================================================
# SECTION 3: CROSS-TABULATIONS (TWO-WAY TABLES)
# ==============================================================================

# count(var1, var2) gives raw cell counts
# pivot_wider turns it into a proper crosstab layout

crosstab <- function(df, row_var, col_var) {
  df |>
    count({{ row_var }}, {{ col_var }}) |>
    group_by({{ row_var }}) |>
    mutate(row_pct = round(n / sum(n) * 100, 1)) |>
    ungroup() |>
    pivot_wider(
      names_from  = {{ col_var }},
      values_from = c(n, row_pct),
      names_glue  = "{.value}_{col_var}"
    )
}

# Biden vote by college degree
ces |>
  filter(!is.na(biden_voter), !is.na(college)) |>
  count(college, biden_voter) |>
  group_by(college) |>
  mutate(row_pct = round(n / sum(n) * 100, 1)) |>
  ungroup()

# Biden vote by party ID
ces |>
  filter(!is.na(biden_voter), !is.na(party_id3)) |>
  count(party_id3, biden_voter) |>
  group_by(party_id3) |>
  mutate(row_pct = round(n / sum(n) * 100, 1))

# Biden vote by census region
ces |>
  filter(!is.na(biden_voter), !is.na(census_region)) |>
  count(census_region, biden_voter) |>
  group_by(census_region) |>
  mutate(row_pct = round(n / sum(n) * 100, 1))

# Chi-square test of independence
tbl <- table(ces$college, ces$biden_voter)
chisq.test(tbl)

tbl_region <- table(ces$census_region, ces$voted)
chisq.test(tbl_region)


# ==============================================================================
# SECTION 4: GROUP MEANS
# ==============================================================================

# group_by() + summarise() is the dplyr equivalent of Stata's tabstat by()

# Mean age, ideology, restrictionism by Biden vs Trump voter
ces |>
  filter(!is.na(biden_voter)) |>
  group_by(biden_voter) |>
  summarise(
    mean_age         = round(mean(age, na.rm = TRUE), 2),
    mean_ideology    = round(mean(ideology5, na.rm = TRUE), 2),
    mean_imm_restrict = round(mean(imm_restrict, na.rm = TRUE), 2),
    mean_econ_retro  = round(mean(econ_retro, na.rm = TRUE), 2),
    n                = n()
  )

# Same by party ID (3-category)
ces |>
  filter(!is.na(party_id3)) |>
  group_by(party_id3) |>
  summarise(
    mean_ideology     = round(mean(ideology5, na.rm = TRUE), 2),
    mean_imm_restrict = round(mean(imm_restrict, na.rm = TRUE), 2),
    n                 = n()
  )

# Mean restrictionism by college degree
ces |>
  filter(!is.na(college)) |>
  group_by(college) |>
  summarise(
    mean_restrict = round(mean(imm_restrict, na.rm = TRUE), 2),
    sd_restrict   = round(sd(imm_restrict, na.rm = TRUE), 2),
    n             = sum(!is.na(imm_restrict))
  )


# ==============================================================================
# SECTION 5: T-TESTS — MEAN COMPARISONS
# ==============================================================================

# t.test(y ~ group, data, var.equal = FALSE) — Welch's t-test (default)
# var.equal = FALSE means Welch (unequal variances) — preferred

# Does immigration restrictionism differ by college degree?
t.test(imm_restrict ~ college, data = ces, var.equal = FALSE)

# Does ideology differ between Biden and Trump voters?
t.test(ideology5 ~ biden_voter, data = ces, var.equal = FALSE)

# Does age differ between voters and non-voters?
t.test(age ~ voted, data = ces, var.equal = FALSE)

# Dem vs. Rep only (drop independents for this test)
ces_partisans <- ces |> filter(party_id3 %in% c(1, 2))
t.test(econ_retro ~ party_id3, data = ces_partisans, var.equal = FALSE)


# ==============================================================================
# SECTION 6: CORRELATION MATRIX
# ==============================================================================

# cor() computes Pearson r; use = "pairwise.complete.obs" for pairwise deletion
cor_vars <- ces |>
  select(age, education, ideology5, imm_restrict, econ_retro,
         self_rated_health, biden_voter)

cor_matrix <- cor(cor_vars, use = "pairwise.complete.obs")
round(cor_matrix, 3)

# With p-values using Hmisc (install if needed)
# install.packages("Hmisc")
# library(Hmisc)
# rcorr(as.matrix(cor_vars))

# Or using corrr (tidyverse-adjacent)
# install.packages("corrr")
# library(corrr)
# cor_vars |> correlate() |> shave() |> fashion()


# ==============================================================================
# SECTION 7: MISSING DATA PATTERNS
# ==============================================================================

# Proportion missing for each key variable
ces |>
  select(age, education, ideology5, imm_restrict, voted, biden_voter,
         party_id3, econ_retro) |>
  summarise(across(everything(), ~ mean(is.na(.x)) * 100)) |>
  pivot_longer(everything(),
               names_to = "variable",
               values_to = "pct_missing") |>
  mutate(pct_missing = round(pct_missing, 2)) |>
  arrange(desc(pct_missing))

# Is missingness on ideology5 associated with party?
ces |>
  mutate(miss_ideo = is.na(ideology5)) |>
  group_by(party_id3) |>
  summarise(pct_missing_ideo = mean(miss_ideo, na.rm = TRUE) * 100,
            n = n())


# ==============================================================================
# SECTION 8: WEIGHTED DESCRIPTIVES
# ==============================================================================

# The survey package handles complex survey design properly.
# install.packages("survey")
library(survey)

# Declare survey design (CES post-election weight, no public strata/cluster)
ces_svy <- svydesign(
  ids     = ~1,             # no clustering variable publicly available
  weights = ~wt_post,
  data    = ces
)

# Weighted means
svymean(~ age + college + voted + ideology5, design = ces_svy, na.rm = TRUE)

# Unweighted for comparison
ces |>
  summarise(
    mean_age     = mean(age, na.rm = TRUE),
    mean_college = mean(college, na.rm = TRUE),
    mean_voted   = mean(voted, na.rm = TRUE),
    mean_ideo    = mean(ideology5, na.rm = TRUE)
  )

message("Module 2 complete.")
