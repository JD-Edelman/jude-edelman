# ==============================================================================
#  MODULE 1: IMPORT, RENAME, RECODE & GENERATE NEW VARIABLES
#  Dataset: Cooperative Election Study (CES) 2020 Common Content
#
#  Download data (CSV, ~188MB):
#  https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi%3A10.7910/DVN/E9N6PH
#
#  Codebook/Questionnaire:
#  https://cces.gov.harvard.edu/pages/welcome-cooperative-congressional-election-study
#
#  Citation:
#  Schaffner, Brian; Ansolabehere, Stephen; Luks, Sam, 2021,
#  "Cooperative Election Study Common Content, 2020",
#  https://doi.org/10.7910/DVN/E9N6PH, Harvard Dataverse, V4.
#
#  Purpose: Import the CES CSV, rename variables, recode missing values using
#  dplyr's across() + named vectors as "dictionaries", and generate new variables.
# ==============================================================================


# ==============================================================================
# SECTION 0: SETUP
# ==============================================================================

# Install packages if you haven't already (run once, then comment out)
# install.packages(c("tidyverse", "haven", "labelled"))

library(tidyverse)   # dplyr, tidyr, readr, stringr, forcats, purrr
library(haven)       # read Stata/SPSS files if needed
library(labelled)    # work with value labels


# ==============================================================================
# SECTION 1: IMPORT CSV
# ==============================================================================

# read_csv() from readr (part of tidyverse) is faster than base read.csv()
# and auto-detects column types.

ces <- read_csv("CES20_Common_OUTPUT_vv.csv")

# Quick audit
glimpse(ces)          # variable names, types, first few values
dim(ces)              # rows × columns
names(ces)[1:20]      # first 20 variable names


# ==============================================================================
# SECTION 2: RENAME VARIABLES
# ==============================================================================

# rename(new_name = old_name)
# We chain multiple renames in one call using the pipe |> (native R 4.1+)
# or %>% (magrittr, loaded with tidyverse — same thing)

ces <- ces |>
  rename(
    # --- Demographics ---
    sex              = gender,
    birth_year       = birthyr,
    education        = educ,
    race_eth         = race,
    hispanic_id      = hispanic,
    voter_registered = votereg,
    census_region    = region,
    state_fips       = inputstate,

    # --- Party & ideology ---
    party_id3        = pid3,
    party_id7        = pid7,
    ideology5        = ideo5,

    # --- Survey weights ---
    wt_post          = weight,
    wt_cumulative    = weight_cumulative,

    # --- Presidential approval ---
    approve_trump    = CC20_320a,
    approve_congress = CC20_320b,
    approve_scotus   = CC20_320c,

    # --- Economy / wellbeing ---
    econ_retro       = CC20_302,
    hh_income_change = CC20_303,
    police_safety    = CC20_307,
    self_rated_health = CC20_309e,

    # --- Policy attitudes: healthcare ---
    pol_medicare_expand = CC20_327a,
    pol_drug_prices     = CC20_327b,
    pol_aca_repeal      = CC20_327c,
    pol_medicaid_work   = CC20_327d,
    pol_mandate_repeal  = CC20_327e,
    pol_public_option   = CC20_327f,

    # --- Policy attitudes: guns ---
    pol_assault_ban      = CC20_330a,
    pol_concealed_carry  = CC20_330b,
    pol_background_check = CC20_330c,

    # --- Policy attitudes: immigration ---
    pol_daca         = CC20_331a,
    pol_border_patrol = CC20_331b,
    pol_wall         = CC20_331c,
    pol_legal_status = CC20_331d,
    pol_deportation  = CC20_331e,

    # --- Policy attitudes: abortion ---
    pol_abort_always    = CC20_332a,
    pol_abort_rape      = CC20_332b,
    pol_abort_health    = CC20_332c,
    pol_abort_heartbeat = CC20_332d,
    pol_abort_20wk      = CC20_332e,
    pol_abort_fund      = CC20_332f,
    pol_abort_ban       = CC20_332g,

    # --- Policy attitudes: environment/climate ---
    pol_climate_epa        = CC20_333a,
    pol_climate_paris      = CC20_333b,
    pol_climate_renewables = CC20_333c,
    pol_climate_carbon_tax = CC20_333d,

    # --- Turnout & vote choice ---
    voted_2020 = CC20_401,
    pres_vote  = CC20_410
  )


# ==============================================================================
# SECTION 3: RECODE MISSING VALUES
# ==============================================================================

# Strategy: define named vectors as "dictionaries" — the equivalent of
# Stata's global macros. Then use dplyr's across() to apply recodes
# across multiple variables at once.
#
# Missing codes:
#   8 / 98  = Skipped
#   9 / 99  = Not Asked
#
# In R we convert these to NA (R's universal missing value).
# na_if(x, y) replaces y with NA in vector x.
# across(cols, fn) applies fn to each column in cols.

# --- 3A. Variables using codes 8 and 9 as missing ---

vars_8_9 <- c(
  "sex", "birth_year", "education", "race_eth", "hispanic_id",
  "voter_registered", "approve_trump", "approve_congress", "approve_scotus",
  "econ_retro", "hh_income_change", "police_safety", "self_rated_health",
  "pol_medicare_expand", "pol_drug_prices", "pol_aca_repeal",
  "pol_medicaid_work", "pol_mandate_repeal", "pol_public_option",
  "pol_assault_ban", "pol_concealed_carry", "pol_background_check",
  "pol_daca", "pol_border_patrol", "pol_wall", "pol_legal_status",
  "pol_deportation",
  "pol_abort_always", "pol_abort_rape", "pol_abort_health",
  "pol_abort_heartbeat", "pol_abort_20wk", "pol_abort_fund", "pol_abort_ban",
  "pol_climate_epa", "pol_climate_paris", "pol_climate_renewables",
  "pol_climate_carbon_tax"
)

ces <- ces |>
  mutate(across(
    all_of(vars_8_9),
    ~ na_if(na_if(.x, 8), 9)
    # na_if() can only replace one value at a time, so we chain two calls:
    # inner call replaces 8 with NA, outer call then replaces 9 with NA
  ))

# --- 3B. Variables using codes 98 and 99 as missing ---

vars_98_99 <- c("voted_2020", "pres_vote")

ces <- ces |>
  mutate(across(
    all_of(vars_98_99),
    ~ na_if(na_if(.x, 98), 99)
  ))

# --- 3C. Recode 6 = "Not sure" on econ_retro to NA ---
ces <- ces |>
  mutate(econ_retro = na_if(econ_retro, 6))

# Spot-check: confirm no 8/9/98/99 remain in key variables
ces |>
  select(sex, education, pres_vote, voted_2020) |>
  summarise(across(everything(), ~ sum(.x %in% c(8, 9, 98, 99), na.rm = TRUE)))


# ==============================================================================
# SECTION 4: GENERATE NEW VARIABLES
# ==============================================================================

# mutate() creates new variables (or overwrites existing ones).
# All new columns are added to the dataframe.
# case_when() is the dplyr equivalent of Stata's recode with multiple conditions.

ces <- ces |>
  mutate(

    # --- 4A. Age (continuous) ---
    # CES records birth year; derive age as of election day 2020
    age = 2020 - birth_year,

    # --- 4B. College degree binary ---
    # education: 1=No HS ... 5=4-year degree, 6=Postgrad
    # college = 1 if 4-year degree or higher
    college = case_when(
      education >= 5 ~ 1L,
      education <  5 ~ 0L,
      TRUE           ~ NA_integer_   # propagate NA when education is NA
    ),

    # --- 4C. Biden voter binary ---
    # pres_vote: 1=Biden, 2=Trump, 4=Other, 5=Not in race, 6=Didn't vote, 7=Not sure
    # Restrict to Biden (1) vs Trump (2) only; all others become NA
    biden_voter = case_when(
      pres_vote == 1 ~ 1L,
      pres_vote == 2 ~ 0L,
      TRUE           ~ NA_integer_
    ),

    # --- 4D. White non-Hispanic indicator ---
    # race_eth == 1 (White) AND hispanic_id == 2 (Not Hispanic)
    white_nh = case_when(
      race_eth == 1 & hispanic_id == 2 ~ 1L,
      !is.na(race_eth) & !is.na(hispanic_id) ~ 0L,
      TRUE ~ NA_integer_
    ),

    # --- 4E. Voted indicator ---
    # voted_2020: 5 = "I voted in the election"
    voted = case_when(
      voted_2020 == 5 ~ 1L,
      !is.na(voted_2020) ~ 0L,
      TRUE ~ NA_integer_
    ),

    # --- 4F. Party dummies ---
    # party_id3: 1=Democrat, 2=Republican, 3=Independent
    dem = case_when(
      party_id3 == 1 ~ 1L,
      !is.na(party_id3) ~ 0L,
      TRUE ~ NA_integer_
    ),
    rep = case_when(
      party_id3 == 2 ~ 1L,
      !is.na(party_id3) ~ 0L,
      TRUE ~ NA_integer_
    ),

    # --- 4G. Immigration restrictionism index (0-5 additive) ---
    # Each item: 1 if respondent takes the restrictionist position
    imm_item1 = if_else(pol_daca        == 2, 1L, 0L),   # oppose DACA
    imm_item2 = if_else(pol_border_patrol == 1, 1L, 0L), # support more patrol
    imm_item3 = if_else(pol_wall         == 1, 1L, 0L),  # support wall
    imm_item4 = if_else(pol_legal_status == 2, 1L, 0L),  # oppose legal path
    imm_item5 = if_else(pol_deportation  == 1, 1L, 0L)   # support deportation
  ) |>
  # Sum the five immigration items (rowSums handles NA: use na.rm to count
  # valid items; set scale to NA if all five items are missing)
  mutate(
    imm_n_valid  = rowSums(!is.na(pick(imm_item1:imm_item5))),
    imm_restrict = rowSums(pick(imm_item1:imm_item5), na.rm = TRUE),
    imm_restrict = if_else(imm_n_valid < 4, NA_integer_, imm_restrict)
  ) |>
  # Drop the temporary item and count columns
  select(-imm_item1, -imm_item2, -imm_item3, -imm_item4, -imm_item5,
         -imm_n_valid)


# ==============================================================================
# SECTION 5: SANITY CHECKS
# ==============================================================================

# Age range
ces |> summarise(min_age = min(age, na.rm=TRUE), max_age = max(age, na.rm=TRUE))
ces |> filter(age < 18 | age > 110) |> nrow()

# Verify college recode
ces |> count(education, college) |> print(n = 20)

# Verify biden_voter is only 0/1/NA
ces |> count(biden_voter)

# Verify voted logic: everyone with biden_voter should have voted==1
ces |> filter(!is.na(biden_voter)) |> count(voted)

# Missing data summary for key variables
ces |>
  select(age, education, ideology5, imm_restrict, voted, biden_voter,
         white_nh, college, dem, rep) |>
  summarise(across(everything(), ~ mean(is.na(.x)) * 100)) |>
  pivot_longer(everything(), names_to = "variable", values_to = "pct_missing") |>
  arrange(desc(pct_missing))


# ==============================================================================
# SECTION 6: CONVERT TO FACTORS (OPTIONAL)
# ==============================================================================

# Factors are R's equivalent of Stata value labels.
# Useful for ggplot legends and model output.
# Keep the underlying numeric version for regression; create factors for display.

ces <- ces |>
  mutate(
    sex_f      = factor(sex,      levels = 1:2,   labels = c("Male", "Female")),
    college_f  = factor(college,  levels = 0:1,   labels = c("No 4-yr degree", "College+")),
    voted_f    = factor(voted,    levels = 0:1,   labels = c("Did not vote", "Voted")),
    biden_f    = factor(biden_voter, levels = 0:1, labels = c("Trump", "Biden")),
    region_f   = factor(census_region, levels = 1:4,
                        labels = c("Northeast", "Midwest", "South", "West")),
    party3_f   = factor(party_id3, levels = 1:3,
                        labels = c("Democrat", "Republican", "Independent"))
  )


# ==============================================================================
# SECTION 7: SAVE CLEANED DATASET
# ==============================================================================

# saveRDS() saves as a compressed R binary (.rds) — fast to reload
# write_csv() saves as CSV if you want cross-software compatibility

saveRDS(ces, "CES2020_clean.rds")
write_csv(ces, "CES2020_clean.csv")

message("Module 1 complete. Cleaned dataset saved.")
