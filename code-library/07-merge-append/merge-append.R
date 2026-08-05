# ==============================================================================
#  MODULE 7: MERGE AND APPEND (JOIN AND BIND)
#  Dataset: CES 2020 (cleaned in Module 1)
#
#  Purpose: Combine datasets horizontally (merge/join) and vertically
#  (append/bind). dplyr uses SQL-style join vocabulary.
#
#  JOINS (merge = add columns):
#    left_join()  — all rows from left, matched from right (most common)
#    inner_join() — only rows present in BOTH datasets
#    full_join()  — all rows from both datasets
#    right_join() — all rows from right, matched from left
#    anti_join()  — rows in left that have NO match in right (find mismatches)
#
#  BIND (append = add rows):
#    bind_rows()  — stack datasets vertically (equivalent to Stata's append)
# ==============================================================================

library(tidyverse)

ces <- readRDS("CES2020_clean.rds")


# ==============================================================================
# SECTION 1: SPLIT THE FULL DATASET INTO THEMATIC FILES
# ==============================================================================

# Demographics file
ces_demographics <- ces |>
  select(caseid, age, sex, education, race_eth, hispanic_id, white_nh,
         college, birth_year, census_region, state_fips, wt_post)

saveRDS(ces_demographics, "ces_demographics.rds")

# Policy attitudes file
ces_attitudes <- ces |>
  select(caseid, ideology5, party_id3, party_id7, dem, rep,
         imm_restrict, pol_daca, pol_border_patrol, pol_wall,
         pol_legal_status, pol_deportation,
         pol_assault_ban, pol_concealed_carry, pol_background_check,
         pol_climate_epa, pol_climate_paris, pol_climate_renewables,
         pol_climate_carbon_tax,
         econ_retro, hh_income_change, approve_trump, approve_congress,
         approve_scotus)

saveRDS(ces_attitudes, "ces_attitudes.rds")

# Vote behavior file
ces_vote <- ces |>
  select(caseid, voted, voted_2020, pres_vote, biden_voter)

saveRDS(ces_vote, "ces_vote.rds")

# Regional subsets for append demo
saveRDS(filter(ces, census_region == 1), "ces_northeast.rds")
saveRDS(filter(ces, census_region == 2), "ces_midwest.rds")
saveRDS(filter(ces, census_region == 3), "ces_south.rds")
saveRDS(filter(ces, census_region == 4), "ces_west.rds")

message("Split files created.")


# ==============================================================================
# SECTION 2: UNDERSTANDING JOIN TYPES
# ==============================================================================

#  left_join(x, y, by = "key")
#  - All rows from x are kept
#  - Matched rows from y are joined
#  - Non-matched rows in x get NA for y's columns
#  - Rows in y with no match in x are dropped
#
#  This is the equivalent of Stata's merge 1:1 with _merge == 3 or 1.
#  Use left_join when x is your "master" dataset and y is your "using" file.


# ==============================================================================
# SECTION 3: JOIN DEMOGRAPHICS + ATTITUDES
# ==============================================================================

ces_dem <- readRDS("ces_demographics.rds")
ces_att <- readRDS("ces_attitudes.rds")

# join on the shared key variable: caseid
ces_dem_att <- left_join(ces_dem, ces_att, by = "caseid")

dim(ces_dem_att)
names(ces_dem_att)

# Quick check: no rows should be lost (all caseids should match)
nrow(ces_dem_att) == nrow(ces_dem)   # TRUE if perfectly matched

saveRDS(ces_dem_att, "ces_dem_att.rds")


# ==============================================================================
# SECTION 4: JOIN VOTE DATA — BUILD FULL DATASET FROM PARTS
# ==============================================================================

ces_vote_df <- readRDS("ces_vote.rds")

ces_rebuilt <- ces_dem_att |>
  left_join(ces_vote_df, by = "caseid")

nrow(ces_rebuilt) == nrow(ces)   # should be TRUE
message("Full dataset rebuilt from thematic files.")

saveRDS(ces_rebuilt, "ces_full_rebuilt.rds")


# ==============================================================================
# SECTION 5: INNER JOIN — KEEP ONLY MATCHED ROWS
# ==============================================================================

# inner_join() drops any row in EITHER dataset that doesn't have a match.
# Equivalent to Stata's keep if _merge == 3.

# Demonstrate with a subset of attitudes (drop some caseids to simulate mismatch)
ces_att_partial <- ces_att |> slice_sample(prop = 0.95)   # randomly drop 5%

merged_inner <- inner_join(ces_dem, ces_att_partial, by = "caseid")
merged_left  <- left_join(ces_dem,  ces_att_partial, by = "caseid")

nrow(merged_inner)   # fewer rows — only matched
nrow(merged_left)    # same as ces_dem — unmatched get NA for attitude vars

# Check how many were unmatched in the left join
merged_left |> filter(is.na(ideology5)) |> nrow()


# ==============================================================================
# SECTION 6: FULL JOIN — KEEP ALL ROWS FROM BOTH FILES
# ==============================================================================

# full_join() keeps every row from both datasets; non-matched get NA.
# Use when you don't know which file is the "master" and don't want to lose data.

merged_full <- full_join(ces_dem, ces_att_partial, by = "caseid")
nrow(merged_full)   # could be larger than either input if there are extra caseids


# ==============================================================================
# SECTION 7: ANTI JOIN — FIND MISMATCHES
# ==============================================================================

# anti_join(x, y) returns rows in x with NO match in y.
# This is the diagnostic tool — equivalent to Stata's tab _merge to see
# what didn't match, but faster.

unmatched <- anti_join(ces_dem, ces_att_partial, by = "caseid")
nrow(unmatched)   # how many demographics records have no attitude match?

# Check from the other side
anti_join(ces_att_partial, ces_dem, by = "caseid") |> nrow()


# ==============================================================================
# SECTION 8: MANY-TO-ONE JOIN (m:1 EQUIVALENT)
# ==============================================================================

# When you join individual-level data to a state-level file,
# many respondents share one state — this is m:1 in Stata.
# dplyr handles this automatically: the state row is duplicated for each match.

# Create a state-level characteristic (mean ideology by state)
state_chars <- ces |>
  group_by(state_fips) |>
  summarise(
    state_mean_ideo  = mean(ideology5, na.rm = TRUE),
    n_respondents    = n(),
    .groups = "drop"
  )

# Join state characteristics to individual-level data
ces_with_state <- ces_dem |>
  left_join(state_chars, by = "state_fips")

# Every respondent now has their state's mean ideology
ces_with_state |>
  select(caseid, state_fips, state_mean_ideo) |>
  head(10)

# Many respondents share the same state_mean_ideo — this is correct
cor(ces_with_state$state_mean_ideo, ces_rebuilt$ideology5, use = "pairwise")


# ==============================================================================
# SECTION 9: REALISTIC MERGE WITH MISMATCHES — EXTERNAL DATA
# ==============================================================================

# Simulate a fake state-level economic file that is missing some states
state_econ <- tibble(
  state_fips = c(1, 4, 6, 8, 9, 10, 12, 13, 17, 18),
  state_unemp = c(3.5, 5.2, 7.1, 3.9, 4.4, 4.1, 4.7, 3.8, 4.5, 3.3)
)

# Join to individual data — some respondents won't match (state not in econ file)
ces_with_econ <- ces_dem |>
  left_join(state_econ, by = "state_fips")

# Check missingness on the new variable
ces_with_econ |>
  summarise(
    n_total    = n(),
    n_matched  = sum(!is.na(state_unemp)),
    n_missing  = sum(is.na(state_unemp)),
    pct_missing = mean(is.na(state_unemp)) * 100
  )

# Which states had no match?
ces_with_econ |>
  filter(is.na(state_unemp)) |>
  distinct(state_fips) |>
  arrange(state_fips)


# ==============================================================================
# SECTION 10: APPEND WITH BIND_ROWS
# ==============================================================================

# bind_rows() stacks datasets vertically.
# Extra columns from one file are filled with NA in the other.
# Equivalent to Stata's append.

ces_ne <- readRDS("ces_northeast.rds")
ces_so <- readRDS("ces_south.rds")

ces_ne_south <- bind_rows(ces_ne, ces_so)
nrow(ces_ne_south) == nrow(ces_ne) + nrow(ces_so)   # TRUE

ces_ne_south |> count(census_region)


# ==============================================================================
# SECTION 11: APPEND MULTIPLE FILES IN A LOOP
# ==============================================================================

# Use map() from purrr to load multiple files, then bind_rows() to stack.
# This is cleaner than a for-loop and produces a single tibble.

region_files <- c(
  "ces_northeast.rds",
  "ces_midwest.rds",
  "ces_south.rds",
  "ces_west.rds"
)

ces_all_regions <- map(region_files, readRDS) |>
  bind_rows()

nrow(ces_all_regions) == nrow(ces)   # should be TRUE
ces_all_regions |> count(census_region)

saveRDS(ces_all_regions, "ces_all_regions.rds")
message("All four regional files stacked.")


# ==============================================================================
# SECTION 12: CHECKING FOR DUPLICATE IDs AFTER JOINS
# ==============================================================================

# After any join, check for duplicate IDs in the result.
# Duplicates in the key variable of a 1:1 join usually indicate a problem
# with the source data.

dupes <- ces_rebuilt |>
  count(caseid) |>
  filter(n > 1)

nrow(dupes)   # should be 0 for a clean cross-sectional dataset

# If there are duplicates, inspect them
# ces_rebuilt |> filter(caseid %in% dupes$caseid) |> select(caseid, ...) |> arrange(caseid)

message("Module 7 complete.")
