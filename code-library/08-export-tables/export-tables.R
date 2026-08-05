# ==============================================================================
#  MODULE 8: EXPORTING TABLES TO WORD, LATEX, AND EXCEL
#  Dataset: CES 2020 (cleaned in Module 1)
#
#  Purpose: Automate production of publication-ready tables from R output.
#  Primary tool: modelsummary (regression + descriptive tables to any format)
#  Also covers: gt, flextable, writexl for additional output types.
#
#  install.packages(c("modelsummary", "gt", "flextable", "writexl", "officer"))
# ==============================================================================

library(tidyverse)
library(modelsummary)   # regression tables to Word/LaTeX/HTML/Excel
library(gt)             # elegant HTML/Word tables from tibbles
library(flextable)      # Word-friendly tables
library(writexl)        # write Excel without Java dependency
library(broom)
library(sandwich)

ces <- readRDS("CES2020_clean.rds")


# ==============================================================================
# SECTION 1: REGRESSION TABLES WITH MODELSUMMARY
# ==============================================================================

# Workflow:
#   1. Fit models and put them in a named list
#   2. Call modelsummary() — output format is controlled by the output= argument
#      "default"       → console
#      "table.docx"    → Word
#      "table.tex"     → LaTeX
#      "table.html"    → HTML
#      "table.xlsx"    → Excel

m1 <- lm(imm_restrict ~ education, data = ces)
m2 <- lm(imm_restrict ~ education + age + factor(sex) + factor(census_region), data = ces)
m3 <- lm(imm_restrict ~ education + age + factor(sex) + factor(census_region) +
            ideology5 + party_id7, data = ces)

models <- list(
  "Bivariate"    = m1,
  "Demographics" = m2,
  "Full"         = m3
)

# Console display
modelsummary(
  models,
  stars   = c("*" = .05, "**" = .01, "***" = .001),
  gof_map = c("nobs", "r.squared", "adj.r.squared", "AIC", "BIC"),
  title   = "OLS Regression: Predictors of Immigration Restrictionism"
)

# Export to Word
modelsummary(
  models,
  output  = "table_ols_restrict.docx",
  stars   = c("*" = .05, "**" = .01, "***" = .001),
  gof_map = c("nobs", "r.squared", "adj.r.squared"),
  title   = "OLS Regression: Predictors of Immigration Restrictionism"
)

# Export to LaTeX (booktabs format for academic journals)
modelsummary(
  models,
  output   = "table_ols_restrict.tex",
  stars    = c("*" = .05, "**" = .01, "***" = .001),
  booktabs = TRUE,
  gof_map  = c("nobs", "r.squared", "adj.r.squared"),
  title    = "OLS Regression: Predictors of Immigration Restrictionism"
)


# ==============================================================================
# SECTION 2: LOGIT TABLE WITH ODDS RATIOS
# ==============================================================================

l1 <- glm(voted ~ education + age + factor(sex) + ideology5,
          data = ces, family = binomial())
l2 <- glm(voted ~ education + age + factor(sex) + ideology5 + party_id7 + college,
          data = ces, family = binomial())
l3 <- glm(voted ~ education + age + factor(sex) + ideology5 + party_id7 +
            college + white_nh + imm_restrict,
          data = ces, family = binomial())

logit_models <- list("Model 1" = l1, "Model 2" = l2, "Model 3" = l3)

modelsummary(
  logit_models,
  exponentiate = TRUE,   # display ORs instead of log-odds
  stars        = c("*" = .05, "**" = .01, "***" = .001),
  gof_map      = c("nobs", "logLik", "AIC"),
  title        = "Logistic Regression (Odds Ratios): Voter Turnout 2020"
)

modelsummary(
  logit_models,
  output       = "table_logit_turnout.docx",
  exponentiate = TRUE,
  stars        = c("*" = .05, "**" = .01, "***" = .001),
  gof_map      = c("nobs", "AIC"),
  title        = "Logistic Regression (Odds Ratios): Voter Turnout 2020"
)


# ==============================================================================
# SECTION 3: REGRESSION TABLE WITH ROBUST SEs
# ==============================================================================

# Pass a vcov argument to apply robust SEs to all models automatically
modelsummary(
  models,
  vcov    = "HC3",
  stars   = c("*" = .05, "**" = .01, "***" = .001),
  gof_map = c("nobs", "r.squared", "adj.r.squared"),
  title   = "OLS with HC3 Robust Standard Errors"
)

# Clustered SEs by state
modelsummary(
  list("Clustered" = m3),
  vcov    = ~ state_fips,   # cluster on state_fips variable
  stars   = c("*" = .05, "**" = .01, "***" = .001),
  title   = "OLS with State-Clustered Standard Errors"
)


# ==============================================================================
# SECTION 4: DESCRIPTIVE STATISTICS TABLE (TABLE 1)
# ==============================================================================

# datasummary_skim() from modelsummary gives a quick descriptive table
datasummary_skim(
  ces |> select(age, education, ideology5, imm_restrict, econ_retro,
                self_rated_health, college, voted, biden_voter, white_nh),
  title = "Table 1. Descriptive Statistics — CES 2020"
)

# Export to Word
datasummary_skim(
  ces |> select(age, education, ideology5, imm_restrict, econ_retro,
                college, voted, white_nh),
  output = "table1_descriptives.docx",
  title  = "Table 1. Descriptive Statistics"
)

# Custom Table 1 with specific statistics using datasummary()
datasummary(
  age + education + ideology5 + imm_restrict + econ_retro ~
    Mean + SD + Median + Min + Max + N,
  data  = ces,
  title = "Table 1. Descriptive Statistics"
)


# ==============================================================================
# SECTION 5: CROSSTAB TABLE WITH DATASUMMARY_CROSSTAB
# ==============================================================================

# datasummary_crosstab() produces a formatted two-way table
datasummary_crosstab(
  party_id3 ~ biden_voter,
  data  = filter(ces, voted == 1, !is.na(party_id3), !is.na(biden_voter)),
  title = "Vote Choice by Party Identification (Voters Only)"
)


# ==============================================================================
# SECTION 6: MEAN COMPARISON TABLE (T-TEST STYLE TABLE 2)
# ==============================================================================

# Build a group comparison table manually using dplyr, then format with gt

compare_df <- ces |>
  filter(!is.na(biden_voter)) |>
  group_by(biden_voter) |>
  summarise(
    mean_age       = mean(age, na.rm = TRUE),
    mean_education = mean(education, na.rm = TRUE),
    mean_ideology  = mean(ideology5, na.rm = TRUE),
    mean_restrict  = mean(imm_restrict, na.rm = TRUE),
    mean_econ      = mean(econ_retro, na.rm = TRUE),
    n              = n(),
    .groups = "drop"
  ) |>
  mutate(biden_voter = if_else(biden_voter == 1, "Biden Voters", "Trump Voters")) |>
  pivot_longer(-c(biden_voter, n),
               names_to  = "variable",
               values_to = "mean") |>
  pivot_wider(names_from = biden_voter, values_from = mean)

compare_df |>
  gt() |>
  tab_header(title = "Table 2. Mean Differences by Presidential Vote Choice") |>
  fmt_number(columns = where(is.numeric), decimals = 2) |>
  cols_label(variable = "Variable")


# ==============================================================================
# SECTION 7: FORMATTED TABLES WITH GT
# ==============================================================================

# gt produces high-quality HTML and Word tables from any tibble

summary_stats <- ces |>
  select(age, education, ideology5, imm_restrict, econ_retro) |>
  summarise(across(everything(),
                   list(Mean = ~ round(mean(.x, na.rm=TRUE), 2),
                        SD   = ~ round(sd(.x,   na.rm=TRUE), 2),
                        N    = ~ sum(!is.na(.x))),
                   .names = "{.col}__{.fn}")) |>
  pivot_longer(everything(),
               names_to  = c("Variable", ".value"),
               names_sep = "__")

summary_stats |>
  gt() |>
  tab_header(
    title    = "Descriptive Statistics",
    subtitle = "CES 2020 Common Content"
  ) |>
  tab_spanner(label = "Statistics", columns = c(Mean, SD, N)) |>
  fmt_number(columns = c(Mean, SD), decimals = 2) |>
  fmt_integer(columns = N) |>
  cols_align(align = "center", columns = c(Mean, SD, N)) |>
  tab_source_note("Source: CES 2020 (Schaffner, Ansolabehere, Luks 2021)")

# Save gt table as Word document
# summary_stats |> gt() |> ... |> gtsave("gt_descriptives.docx")


# ==============================================================================
# SECTION 8: EXPORT TO EXCEL WITH WRITEXL
# ==============================================================================

# writexl::write_xlsx() exports a list of dataframes as separate sheets

coef_table <- tidy(m3, conf.int = TRUE) |>
  mutate(across(where(is.numeric), ~ round(.x, 4)))

desc_table <- ces |>
  select(age, education, ideology5, imm_restrict, econ_retro) |>
  summarise(across(everything(),
                   list(mean = ~ mean(.x, na.rm=TRUE),
                        sd   = ~ sd(.x, na.rm=TRUE)),
                   .names = "{.col}_{.fn}"))

write_xlsx(
  list(
    "Regression Coefficients" = coef_table,
    "Descriptive Statistics"  = as.data.frame(desc_table)
  ),
  path = "ces_analysis_output.xlsx"
)

message("Excel file written: ces_analysis_output.xlsx")


# ==============================================================================
# SECTION 9: CUSTOM COEFFICIENT RENAME MAP
# ==============================================================================

# modelsummary lets you rename coefficient labels for cleaner table display

coef_labels <- c(
  "(Intercept)"           = "Intercept",
  "education"             = "Education (1–6)",
  "age"                   = "Age",
  "factor(sex)2"          = "Female (ref: Male)",
  "factor(census_region)2" = "Midwest (ref: Northeast)",
  "factor(census_region)3" = "South",
  "factor(census_region)4" = "West",
  "ideology5"             = "Ideology (1=Lib, 5=Con)",
  "party_id7"             = "Party ID (1=Strong Dem, 7=Strong Rep)"
)

modelsummary(
  list("Full OLS" = m3),
  coef_map = coef_labels,
  stars    = c("*" = .05, "**" = .01, "***" = .001),
  gof_map  = c("nobs", "r.squared"),
  title    = "OLS Regression with Custom Coefficient Labels"
)


# ==============================================================================
# SECTION 10: ADDING NOTES AND FORMATTING FOOTNOTES
# ==============================================================================

# modelsummary supports notes= for table footnotes

modelsummary(
  logit_models,
  exponentiate = TRUE,
  stars        = c("*" = .05, "**" = .01, "***" = .001),
  gof_map      = c("nobs", "AIC"),
  notes        = list(
    "Robust (HC3) standard errors in parentheses.",
    "Source: CES 2020 (Schaffner, Ansolabehere & Luks 2021).",
    "Reference categories: Female=Male, Region=Northeast."
  ),
  title = "Table 3. Logistic Regression: Voter Turnout"
)

message("Module 8 complete.")
