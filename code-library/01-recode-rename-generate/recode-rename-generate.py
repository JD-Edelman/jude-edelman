# ==============================================================================
#  MODULE 1: IMPORT, RENAME, RECODE & GENERATE NEW VARIABLES
#  Dataset: Cooperative Election Study (CES) 2020 Common Content
#
#  Download data (CSV, ~188MB):
#  https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi%3A10.7910/DVN/E9N6PH
#
#  Citation:
#  Schaffner, Brian; Ansolabehere, Stephen; Luks, Sam, 2021,
#  "Cooperative Election Study Common Content, 2020",
#  https://doi.org/10.7910/DVN/E9N6PH, Harvard Dataverse, V4.
#
#  Stack: pandas (data), numpy (numerics)
# ==============================================================================

import pandas as pd
import numpy as np


# ==============================================================================
# SECTION 1: IMPORT CSV
# ==============================================================================

# pd.read_csv() is the primary CSV importer in pandas.
# low_memory=False prevents mixed-type inference warnings on large files.

ces = pd.read_csv("CES20_Common_OUTPUT_vv.csv", low_memory=False)

print(f"Shape: {ces.shape}")          # (rows, columns)
print(ces.dtypes.head(20))            # column names and types
print(ces.head(3))                    # first 3 rows


# ==============================================================================
# SECTION 2: RENAME VARIABLES
# ==============================================================================

# DataFrame.rename(columns={old: new}) — pass a dict mapping old → new names.
# inplace=True modifies the dataframe in-place; otherwise returns a new one.
# We use the assignment pattern (ces = ces.rename(...)) for clarity.

rename_map = {
    # Demographics
    "gender":      "sex",
    "birthyr":     "birth_year",
    "educ":        "education",
    "race":        "race_eth",
    "hispanic":    "hispanic_id",
    "votereg":     "voter_registered",
    "region":      "census_region",
    "inputstate":  "state_fips",

    # Party & ideology
    "pid3":  "party_id3",
    "pid7":  "party_id7",
    "ideo5": "ideology5",

    # Survey weights
    "weight":            "wt_post",
    "weight_cumulative": "wt_cumulative",

    # Presidential approval
    "CC20_320a": "approve_trump",
    "CC20_320b": "approve_congress",
    "CC20_320c": "approve_scotus",

    # Economy / wellbeing
    "CC20_302":  "econ_retro",
    "CC20_303":  "hh_income_change",
    "CC20_307":  "police_safety",
    "CC20_309e": "self_rated_health",

    # Healthcare
    "CC20_327a": "pol_medicare_expand",
    "CC20_327b": "pol_drug_prices",
    "CC20_327c": "pol_aca_repeal",
    "CC20_327d": "pol_medicaid_work",
    "CC20_327e": "pol_mandate_repeal",
    "CC20_327f": "pol_public_option",

    # Guns
    "CC20_330a": "pol_assault_ban",
    "CC20_330b": "pol_concealed_carry",
    "CC20_330c": "pol_background_check",

    # Immigration
    "CC20_331a": "pol_daca",
    "CC20_331b": "pol_border_patrol",
    "CC20_331c": "pol_wall",
    "CC20_331d": "pol_legal_status",
    "CC20_331e": "pol_deportation",

    # Abortion
    "CC20_332a": "pol_abort_always",
    "CC20_332b": "pol_abort_rape",
    "CC20_332c": "pol_abort_health",
    "CC20_332d": "pol_abort_heartbeat",
    "CC20_332e": "pol_abort_20wk",
    "CC20_332f": "pol_abort_fund",
    "CC20_332g": "pol_abort_ban",

    # Climate
    "CC20_333a": "pol_climate_epa",
    "CC20_333b": "pol_climate_paris",
    "CC20_333c": "pol_climate_renewables",
    "CC20_333d": "pol_climate_carbon_tax",

    # Turnout & vote
    "CC20_401": "voted_2020",
    "CC20_410": "pres_vote",
}

ces = ces.rename(columns=rename_map)


# ==============================================================================
# SECTION 3: RECODE MISSING VALUES
# ==============================================================================

# In pandas, NaN (np.nan) is the universal missing value for numeric columns.
# DataFrame.replace({old: np.nan}) replaces specific values with NaN.
# We define lists of columns by their missing-code type, then loop.

# --- 3A. Variables with codes 8 and 9 as missing ---
vars_8_9 = [
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
    "pol_climate_carbon_tax",
]

ces[vars_8_9] = ces[vars_8_9].replace({8: np.nan, 9: np.nan})

# --- 3B. Variables with codes 98 and 99 as missing ---
vars_98_99 = ["voted_2020", "pres_vote"]
ces[vars_98_99] = ces[vars_98_99].replace({98: np.nan, 99: np.nan})

# --- 3C. Recode 6 = "Not sure" on econ_retro to NaN ---
ces["econ_retro"] = ces["econ_retro"].replace({6: np.nan})

# Spot-check: confirm no 8/9/98/99 remain in key variables
for col in ["sex", "education", "pres_vote", "voted_2020"]:
    bad = ces[col].isin([8, 9, 98, 99]).sum()
    print(f"Remaining 8/9/98/99 in {col}: {bad}")


# ==============================================================================
# SECTION 4: GENERATE NEW VARIABLES
# ==============================================================================

# pandas uses direct column assignment (ces["new_col"] = expression)
# np.where(condition, value_if_true, value_if_false) is the vectorized if-else
# np.select([cond1, cond2], [val1, val2], default) handles multiple conditions

# --- 4A. Age ---
ces["age"] = 2020 - ces["birth_year"]

# Sanity check
print(f"Age range: {ces['age'].min()} – {ces['age'].max()}")
print(f"Age < 18 or > 110: {((ces['age'] < 18) | (ces['age'] > 110)).sum()}")

# --- 4B. College binary ---
ces["college"] = np.where(
    ces["education"].isna(), np.nan,
    np.where(ces["education"] >= 5, 1, 0)
).astype("Int64")   # Int64 (capital I) supports NA in integer columns

# --- 4C. Biden voter binary ---
# 1 = Biden, 0 = Trump, NaN = everyone else
ces["biden_voter"] = np.select(
    [ces["pres_vote"] == 1, ces["pres_vote"] == 2],
    [1, 0],
    default=np.nan
)
ces["biden_voter"] = ces["biden_voter"].where(ces["pres_vote"].notna())

# --- 4D. White non-Hispanic ---
ces["white_nh"] = np.where(
    ces["race_eth"].isna() | ces["hispanic_id"].isna(), np.nan,
    np.where((ces["race_eth"] == 1) & (ces["hispanic_id"] == 2), 1, 0)
)

# --- 4E. Voted binary ---
ces["voted"] = np.where(
    ces["voted_2020"].isna(), np.nan,
    np.where(ces["voted_2020"] == 5, 1, 0)
)

# --- 4F. Party dummies ---
ces["dem"] = np.where(
    ces["party_id3"].isna(), np.nan,
    np.where(ces["party_id3"] == 1, 1, 0)
)
ces["rep"] = np.where(
    ces["party_id3"].isna(), np.nan,
    np.where(ces["party_id3"] == 2, 1, 0)
)

# --- 4G. Immigration restrictionism index (0–5) ---
# Recode each item: 1 = restrictionist position
imm_cols = {
    "imm_item1": (ces["pol_daca"]          == 2),
    "imm_item2": (ces["pol_border_patrol"] == 1),
    "imm_item3": (ces["pol_wall"]          == 1),
    "imm_item4": (ces["pol_legal_status"]  == 2),
    "imm_item5": (ces["pol_deportation"]   == 1),
}

for col, condition in imm_cols.items():
    # NaN where source variable is NaN, else 1/0
    source_col = col.replace("imm_item", "")
    source_vars = {
        "1": "pol_daca", "2": "pol_border_patrol", "3": "pol_wall",
        "4": "pol_legal_status", "5": "pol_deportation"
    }
    src = source_vars[col[-1]]
    ces[col] = np.where(ces[src].isna(), np.nan, condition.astype(float))

item_cols = list(imm_cols.keys())
ces["imm_n_valid"]   = ces[item_cols].notna().sum(axis=1)
ces["imm_restrict"]  = ces[item_cols].sum(axis=1, min_count=1)  # NaN if all missing
ces["imm_restrict"]  = np.where(ces["imm_n_valid"] < 4, np.nan, ces["imm_restrict"])

# Drop temporary item columns
ces.drop(columns=item_cols + ["imm_n_valid"], inplace=True)


# ==============================================================================
# SECTION 5: SANITY CHECKS
# ==============================================================================

print(ces[["age", "college", "voted", "biden_voter",
           "white_nh", "dem", "rep", "imm_restrict"]].describe())

print(ces["biden_voter"].value_counts(dropna=False))
print(ces["college"].value_counts(dropna=False))

# Missing data summary
missing_pct = ces.isna().mean() * 100
print(missing_pct[missing_pct > 0].sort_values(ascending=False).head(20))


# ==============================================================================
# SECTION 6: SAVE CLEANED DATASET
# ==============================================================================

# Parquet is the modern binary format for pandas — fast, compressed, type-safe
# CSV is also saved for cross-software compatibility

ces.to_parquet("CES2020_clean.parquet", index=False)
ces.to_csv("CES2020_clean.csv", index=False)

print("Module 1 complete. Cleaned dataset saved.")
