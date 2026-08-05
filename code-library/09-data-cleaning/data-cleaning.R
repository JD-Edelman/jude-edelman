# ==============================================================================
#  MODULE 9: DATA CLEANING & VALIDATION
#  Dataset: CES 2020 (raw, before Module 1 cleaning)
#
#  Purpose: Systematic data cleaning workflow — detecting and handling
#  missing data, outliers, inconsistent responses, duplicates, and
#  string-to-numeric conversions using dplyr and tidyr.
# ==============================================================================

library(tidyverse)
library(janitor)     # tabyl(), clean_names(), get_dupes() — install.packages("janitor")
library(visdat)      # visualize missing data patterns — install.packages("visdat")
library(naniar)      # tidy missing data tools — install.packages("naniar")

ces <- readRDS("CES2020_clean.rds")


# ==============================================================================
# SECTION 1: INITIAL AUDIT
# ==============================================================================

glimpse(ces)            # variable names, types, first few values
dim(ces)                # rows x columns
skimr::skim(ces)        # comprehensive univariate summary (install.packages("skimr"))


# ==============================================================================
# SECTION 2: MISSING DATA AUDIT
# ==============================================================================

# Count and proportion missing for every variable
missing_summary <- ces |>
  summarise(across(everything(),
                   list(n_miss = ~ sum(is.na(.x)),
                        pct    = ~ mean(is.na(.x)) * 100))) |>
  pivot_longer(everything(),
               names_to  = c("variable", ".value"),
               names_sep = "__") |>
  arrange(desc(pct)) |>
  filter(pct > 0)

print(missing_summary, n = 30)

# Which key analysis variables have the most missing?
ces |>
  select(age, education, ideology5, party_id3, imm_restrict,
         voted, biden_voter, white_nh, college) |>
  summarise(across(everything(), ~ mean(is.na(.x)) * 100)) |>
  pivot_longer(everything(), names_to = "var", values_to = "pct_missing") |>
  arrange(desc(pct_missing))

# Visualize missing data patterns
vis_miss(
  ces |> select(age, education, ideology5, party_id3, imm_restrict,
                voted, biden_voter, white_nh, college),
  sort_miss = TRUE
)

# Upset plot: which variables tend to be missing together?
gg_miss_upset(
  ces |> select(age, education, ideology5, party_id3, imm_restrict,
                voted, biden_voter)
)


# ==============================================================================
# SECTION 3: LOGICAL CONSISTENCY CHECKS
# ==============================================================================

# Impossible ages
ces |> filter(age < 18 | age > 110) |> nrow()
ces |> filter(age < 18 | age > 110) |> select(caseid, birth_year, age)

# biden_voter should be missing unless voted == 1
# Anyone with biden_voter coded but voted == 0?
ces |>
  filter(!is.na(biden_voter), voted == 0) |>
  nrow()

# College recode check: college==1 requires education >= 5
ces |>
  filter(college == 1 & education < 5) |>
  nrow()   # should be 0

ces |>
  filter(college == 0 & education >= 5) |>
  nrow()   # should be 0

# White non-Hispanic check: white_nh==1 requires race_eth==1 AND hispanic_id==2
ces |>
  filter(white_nh == 1 & (race_eth != 1 | hispanic_id != 2)) |>
  nrow()   # should be 0

# Party ID consistency: Strong Republican on pid7 but Democrat on pid3?
ces |>
  filter(party_id7 == 7 & party_id3 == 1) |>
  nrow()

ces |>
  filter(party_id7 == 1 & party_id3 == 2) |>
  nrow()

# Report all check results in one tidy block
checks <- tibble(
  check         = c("Age < 18 or > 110",
                    "Biden voter but voted == 0",
                    "College=1 but educ < 5",
                    "College=0 but educ >= 5",
                    "white_nh error",
                    "Strong Rep coded as Dem"),
  n_flagged     = c(
    sum((ces$age < 18 | ces$age > 110), na.rm = TRUE),
    sum(!is.na(ces$biden_voter) & ces$voted == 0, na.rm = TRUE),
    sum(ces$college == 1 & ces$education < 5, na.rm = TRUE),
    sum(ces$college == 0 & ces$education >= 5, na.rm = TRUE),
    sum(ces$white_nh == 1 & (ces$race_eth != 1 | ces$hispanic_id != 2), na.rm = TRUE),
    sum(ces$party_id7 == 7 & ces$party_id3 == 1, na.rm = TRUE)
  )
)

checks |> mutate(pass = n_flagged == 0)


# ==============================================================================
# SECTION 4: DUPLICATE ID CHECK
# ==============================================================================

# Check for duplicate caseids using janitor::get_dupes()
get_dupes(ces, caseid)   # returns only rows that are duplicates

# Manual approach
ces |>
  count(caseid) |>
  filter(n > 1) |>
  nrow()   # should be 0 for a cross-sectional survey


# ==============================================================================
# SECTION 5: OUTLIER DETECTION — CONTINUOUS VARIABLES
# ==============================================================================

# Z-score approach: flag |z| > 4 (appropriate for large N)
outlier_flags <- ces |>
  mutate(
    z_age = (age - mean(age, na.rm=TRUE)) / sd(age, na.rm=TRUE)
  ) |>
  filter(abs(z_age) > 4) |>
  select(caseid, age, z_age) |>
  arrange(desc(abs(z_age)))

outlier_flags |> head(20)

# IQR method (more robust to extreme values)
q <- quantile(ces$age, c(0.25, 0.75), na.rm = TRUE)
iqr <- q[2] - q[1]
lo  <- q[1] - 3 * iqr
hi  <- q[2] + 3 * iqr

ces |> filter(age < lo | age > hi) |> nrow()


# ==============================================================================
# SECTION 6: HANDLING MISSING DATA — STRATEGIES
# ==============================================================================

# STRATEGY 1: LISTWISE DELETION (default in lm/glm)
# R's lm() drops NA rows automatically — check model N vs total N
m <- lm(imm_restrict ~ education + age + ideology5, data = ces)
cat("Model N:", nobs(m), "| Total N:", nrow(ces), "\n")

# STRATEGY 2: SIMPLE MEAN IMPUTATION (demonstrating mechanics, not recommended)
ces_mean_imp <- ces |>
  mutate(
    ideology5_imp = if_else(
      is.na(ideology5),
      mean(ideology5, na.rm = TRUE),
      as.double(ideology5)
    )
  )

# Compare distributions
ces |> summarise(mean = mean(ideology5, na.rm=TRUE), sd = sd(ideology5, na.rm=TRUE))
ces_mean_imp |> summarise(mean = mean(ideology5_imp), sd = sd(ideology5_imp))
# SD is lower after mean imputation — underestimates variance

rm(ces_mean_imp)

# STRATEGY 3: MULTIPLE IMPUTATION — see Module 10


# ==============================================================================
# SECTION 7: RECODING VARIABLES
# ==============================================================================

# Replace specific values with NA (more targeted than across())
ces <- ces |>
  mutate(
    econ_retro = na_if(econ_retro, 6)   # 6 = "Not sure" → missing
  )

# Collapsing categories
ces <- ces |>
  mutate(
    # Age groups with meaningful sociological categories
    age_group = case_when(
      age < 30              ~ "18-29",
      age >= 30 & age < 45  ~ "30-44",
      age >= 45 & age < 60  ~ "45-59",
      age >= 60             ~ "60+",
      TRUE                  ~ NA_character_
    ) |> factor(levels = c("18-29", "30-44", "45-59", "60+")),

    # Ideology collapsed to 3 categories
    ideology3 = case_when(
      ideology5 %in% 1:2 ~ "Liberal",
      ideology5 == 3     ~ "Moderate",
      ideology5 %in% 4:5 ~ "Conservative",
      TRUE               ~ NA_character_
    ) |> factor(levels = c("Liberal", "Moderate", "Conservative")),

    # Education quartile
    educ_quartile = ntile(education, 4)
  )

ces |> count(age_group)
ces |> count(ideology3)
ces |> count(educ_quartile)


# ==============================================================================
# SECTION 8: STANDARDIZING VARIABLES (Z-SCORES)
# ==============================================================================

# scale() centers and divides by SD — creates a numeric matrix
# as.numeric() extracts the vector from the matrix wrapper

ces <- ces |>
  mutate(
    z_age       = as.numeric(scale(age)),
    z_education = as.numeric(scale(education)),
    z_ideology  = as.numeric(scale(ideology5)),
    z_restrict  = as.numeric(scale(imm_restrict)),
    z_econ      = as.numeric(scale(econ_retro))
  )

# Standardized regression
lm(z_restrict ~ z_education + z_age + z_ideology + factor(sex),
   data = ces) |>
  broom::tidy()

# Drop z-score columns after use (optional)
ces <- ces |> select(-starts_with("z_"))


# ==============================================================================
# SECTION 9: CLEAN VARIABLE NAMES WITH JANITOR
# ==============================================================================

# clean_names() converts all names to snake_case and handles special characters
# Useful after importing messy CSV headers

demo_messy <- tibble(
  `Respondent ID` = 1:5,
  `Age (Years)`   = c(35, 42, 28, 51, 67),
  `Party.ID`      = c(1, 2, 3, 1, 2),
  `VoteChoice2020` = c(1, 0, 1, 1, 0)
)

demo_clean <- demo_messy |> clean_names()
names(demo_clean)   # respondent_id, age_years, party_id, votechoice2020


# ==============================================================================
# SECTION 10: TABYL — JANITOR'S FREQUENCY TABLES
# ==============================================================================

# tabyl() is a tidyverse-friendly alternative to table()
# Handles NA explicitly and formats output cleanly

ces |> tabyl(sex) |> adorn_pct_formatting()
ces |> tabyl(voted) |> adorn_pct_formatting()
ces |> tabyl(college) |> adorn_pct_formatting()

# Two-way tabyl with chi-square test
ces |>
  tabyl(college, biden_voter) |>
  adorn_percentages("row") |>
  adorn_pct_formatting() |>
  adorn_ns()   # add raw counts in parentheses

ces |>
  tabyl(party_id3, biden_voter) |>
  chisq.test()


# ==============================================================================
# SECTION 11: FINAL SAVE
# ==============================================================================

# Add new variables and save the analysis-ready file
saveRDS(ces, "CES2020_analysis_ready.rds")
write_csv(ces, "CES2020_analysis_ready.csv")

message("Module 9 complete. Analysis-ready dataset saved.")
