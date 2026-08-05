# ==============================================================================
#  MODULE 7: MERGE AND APPEND (JOIN AND CONCAT)
#  Dataset: CES 2020 (cleaned in Module 1)
#
#  Stack: pandas
#
#  pandas uses SQL-style join vocabulary via DataFrame.merge() and pd.concat():
#    merge(how="left")   — left join  (all rows from left, matched from right)
#    merge(how="inner")  — inner join (only matched rows)
#    merge(how="outer")  — full join  (all rows from both)
#    merge(how="right")  — right join
#    pd.concat([df1, df2], axis=0) — append rows (stack vertically)
#    pd.concat([df1, df2], axis=1) — join columns (stack horizontally, by index)
# ==============================================================================

import pandas as pd
import numpy as np

ces = pd.read_parquet("CES2020_clean.parquet")


# ==============================================================================
# SECTION 1: SPLIT THE FULL DATASET INTO THEMATIC FILES
# ==============================================================================

# Demographics file
ces_demographics = ces[[
    "caseid", "age", "sex", "education", "race_eth", "hispanic_id",
    "white_nh", "college", "birth_year", "census_region", "state_fips", "wt_post"
]]
ces_demographics.to_parquet("ces_demographics.parquet", index=False)

# Attitudes file
ces_attitudes = ces[[
    "caseid", "ideology5", "party_id3", "party_id7", "dem", "rep",
    "imm_restrict", "pol_daca", "pol_border_patrol", "pol_wall",
    "pol_legal_status", "pol_deportation",
    "pol_assault_ban", "pol_concealed_carry", "pol_background_check",
    "pol_climate_epa", "pol_climate_paris", "pol_climate_renewables",
    "pol_climate_carbon_tax",
    "econ_retro", "hh_income_change", "approve_trump", "approve_congress",
    "approve_scotus",
]]
ces_attitudes.to_parquet("ces_attitudes.parquet", index=False)

# Vote file
ces_vote = ces[["caseid", "voted", "voted_2020", "pres_vote", "biden_voter"]]
ces_vote.to_parquet("ces_vote.parquet", index=False)

# Regional subsets
for region_code, name in [(1,"northeast"), (2,"midwest"), (3,"south"), (4,"west")]:
    ces[ces["census_region"] == region_code].to_parquet(
        f"ces_{name}.parquet", index=False
    )

print("Split files created.")


# ==============================================================================
# SECTION 2: LEFT JOIN — DEMOGRAPHICS + ATTITUDES
# ==============================================================================

# pd.merge(left, right, on="key", how="join_type")
# on= specifies the shared key column(s)
# how= specifies the join type (default is "inner")

dem  = pd.read_parquet("ces_demographics.parquet")
att  = pd.read_parquet("ces_attitudes.parquet")

ces_dem_att = dem.merge(att, on="caseid", how="left")

# Quick verification
assert len(ces_dem_att) == len(dem), "Row count changed — check for mismatches"
print(f"Demographics: {len(dem):,} rows | Merged: {len(ces_dem_att):,} rows")

# Check: any attitude variables all-NaN? (would indicate failed merge)
print("Attitude NaN check:", ces_dem_att["ideology5"].isna().sum())

ces_dem_att.to_parquet("ces_dem_att.parquet", index=False)


# ==============================================================================
# SECTION 3: CHAIN MERGES — BUILD FULL DATASET FROM PARTS
# ==============================================================================

vote_df = pd.read_parquet("ces_vote.parquet")

ces_rebuilt = (
    pd.read_parquet("ces_demographics.parquet")
    .merge(pd.read_parquet("ces_attitudes.parquet"), on="caseid", how="left")
    .merge(vote_df, on="caseid", how="left")
)

print(f"Rebuilt dataset: {ces_rebuilt.shape}")
assert len(ces_rebuilt) == len(ces), "Row count mismatch after rebuild"
ces_rebuilt.to_parquet("ces_full_rebuilt.parquet", index=False)
print("Full dataset rebuilt from thematic files.")


# ==============================================================================
# SECTION 4: INNER JOIN — KEEP ONLY MATCHED ROWS
# ==============================================================================

# Drop 5% of attitudes randomly to simulate a mismatch
att_partial = att.sample(frac=0.95, random_state=42)

merged_inner = dem.merge(att_partial, on="caseid", how="inner")
merged_left  = dem.merge(att_partial, on="caseid", how="left")

print(f"\nInner join: {len(merged_inner):,} rows (only matched)")
print(f"Left join:  {len(merged_left):,} rows (all from left)")
print(f"Unmatched:  {merged_left['ideology5'].isna().sum():,} rows have NaN ideology")


# ==============================================================================
# SECTION 5: FULL (OUTER) JOIN
# ==============================================================================

merged_outer = dem.merge(att_partial, on="caseid", how="outer",
                          indicator=True)

print("\nFull join merge indicator:")
print(merged_outer["_merge"].value_counts())
# left_only   = in demographics only (no attitude match)
# right_only  = in attitudes only (no demographic match)
# both        = matched


# ==============================================================================
# SECTION 6: FINDING MISMATCHES WITH INDICATOR
# ==============================================================================

# indicator=True adds a "_merge" column showing match status.
# Equivalent to Stata's _merge variable.

merged_check = dem.merge(att_partial, on="caseid", how="left", indicator=True)

print("\nMerge indicator counts:")
print(merged_check["_merge"].value_counts())

# Extract unmatched caseids
unmatched = merged_check[merged_check["_merge"] == "left_only"]["caseid"]
print(f"\nUnmatched caseids: {len(unmatched):,}")

merged_check = merged_check.drop(columns=["_merge"])


# ==============================================================================
# SECTION 7: MANY-TO-ONE JOIN (m:1 EQUIVALENT)
# ==============================================================================

# When individual-level data merges to state-level data, many rows
# share one state — pandas handles this automatically by duplicating
# the state row for each match (just like Stata's m:1).

# Build a state-level file
state_chars = (
    ces.groupby("state_fips")
    .agg(
        state_mean_ideo  = ("ideology5", "mean"),
        n_respondents    = ("caseid", "count")
    )
    .reset_index()
)

ces_with_state = dem.merge(state_chars, on="state_fips", how="left")

print(f"\nMerge m:1 on state_fips: {len(ces_with_state):,} rows")
print(ces_with_state[["caseid", "state_fips", "state_mean_ideo"]].head(5))


# ==============================================================================
# SECTION 8: REALISTIC MISMATCH — EXTERNAL DATA
# ==============================================================================

# Simulate a state economic file missing some states
state_econ = pd.DataFrame({
    "state_fips": [1, 4, 6, 8, 9, 10, 12, 13, 17, 18],
    "state_unemp": [3.5, 5.2, 7.1, 3.9, 4.4, 4.1, 4.7, 3.8, 4.5, 3.3]
})

ces_with_econ = dem.merge(state_econ, on="state_fips", how="left")

print(f"\nState econ merge:")
print(f"  Total: {len(ces_with_econ):,}")
print(f"  Matched: {ces_with_econ['state_unemp'].notna().sum():,}")
print(f"  Unmatched: {ces_with_econ['state_unemp'].isna().sum():,}")

# Which states had no match?
unmatched_states = (
    ces_with_econ[ces_with_econ["state_unemp"].isna()]["state_fips"]
    .dropna()
    .unique()
)
print(f"  States without economic data: {sorted(unmatched_states)[:10]}")


# ==============================================================================
# SECTION 9: APPEND WITH PD.CONCAT
# ==============================================================================

# pd.concat([df1, df2], axis=0) stacks dataframes vertically.
# ignore_index=True re-numbers the index from 0.
# Extra columns from one file are filled with NaN in the other.

ne = pd.read_parquet("ces_northeast.parquet")
so = pd.read_parquet("ces_south.parquet")

ces_ne_south = pd.concat([ne, so], axis=0, ignore_index=True)
print(f"\nAppended NE + South: {len(ces_ne_south):,} rows")
print(ces_ne_south["census_region"].value_counts())


# ==============================================================================
# SECTION 10: APPEND MULTIPLE FILES IN A LOOP
# ==============================================================================

# List comprehension + pd.concat is the cleanest pattern for stacking many files

region_files = [
    "ces_northeast.parquet",
    "ces_midwest.parquet",
    "ces_south.parquet",
    "ces_west.parquet",
]

ces_all_regions = pd.concat(
    [pd.read_parquet(f) for f in region_files],
    axis         = 0,
    ignore_index = True
)

print(f"\nAll regions stacked: {len(ces_all_regions):,} rows")
print(ces_all_regions["census_region"].value_counts().sort_index())
assert len(ces_all_regions) == len(ces), "Row count mismatch after append"

ces_all_regions.to_parquet("ces_all_regions.parquet", index=False)


# ==============================================================================
# SECTION 11: DUPLICATE ID CHECK
# ==============================================================================

dupes = ces_rebuilt[ces_rebuilt.duplicated(subset=["caseid"], keep=False)]
print(f"\nDuplicate caseids: {len(dupes):,} (should be 0)")

# Programmatic assertion
assert len(dupes) == 0, "Duplicate caseids found — investigate source data"


# ==============================================================================
# SECTION 12: MERGING ON MULTIPLE KEYS
# ==============================================================================

# When the match requires more than one column (e.g., state + year),
# pass a list to on= or specify left_on= and right_on= for differently-named keys.

# Simulate a state×year file (two-key merge)
state_year = pd.DataFrame({
    "state_fips": [6, 12, 36, 48],
    "survey_year": [2020, 2020, 2020, 2020],
    "pop_millions": [39.5, 21.5, 20.2, 29.1]
})

ces_test = ces[["caseid", "state_fips"]].copy()
ces_test["survey_year"] = 2020

ces_test_merged = ces_test.merge(
    state_year,
    on  = ["state_fips", "survey_year"],   # two-column key
    how = "left"
)

print(f"\nTwo-key merge: matched {ces_test_merged['pop_millions'].notna().sum():,} rows")

print("\nModule 7 complete.")
