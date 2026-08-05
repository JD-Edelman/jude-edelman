# ==============================================================================
#  MODULE 9: DATA CLEANING & VALIDATION
#  Dataset: CES 2020 (cleaned in Module 1)
#
#  Stack: pandas, numpy, missingno (missing data viz)
#  pip install missingno
# ==============================================================================

import pandas as pd
import numpy as np
import missingno as msno
import matplotlib.pyplot as plt
from scipy import stats

ces = pd.read_parquet("CES2020_clean.parquet")


# ==============================================================================
# SECTION 1: INITIAL AUDIT
# ==============================================================================

print("Shape:", ces.shape)
print("\nColumn types:\n", ces.dtypes.head(20))
print("\nFirst 3 rows:\n", ces.head(3))

# pandas describe() gives the five-number summary for numerics
# For a full skim-like summary, use the pandas-profiling/ydata-profiling package:
#   pip install ydata-profiling
#   from ydata_profiling import ProfileReport
#   profile = ProfileReport(ces); profile.to_file("ces_profile.html")

print("\nDescriptive stats (selected vars):")
print(ces[["age", "education", "ideology5", "imm_restrict", "econ_retro"]].describe().round(2))


# ==============================================================================
# SECTION 2: MISSING DATA AUDIT
# ==============================================================================

# Proportion missing for every column
missing_summary = (
    ces.isna()
    .mean()
    .mul(100)
    .round(2)
    .rename("pct_missing")
    .reset_index()
    .rename(columns={"index": "variable"})
    .sort_values("pct_missing", ascending=False)
)

print("\nMissing data (all columns with any NA):")
print(missing_summary[missing_summary["pct_missing"] > 0].to_string(index=False))

# Visualize missing data patterns
key_vars = ["age", "education", "ideology5", "party_id3",
            "imm_restrict", "voted", "biden_voter", "white_nh", "college"]

fig, ax = plt.subplots(figsize=(10, 5))
msno.matrix(ces[key_vars], ax=ax, sparkline=False)
ax.set_title("Missing Data Pattern — Key Analysis Variables")
plt.tight_layout()
plt.savefig("missing_data_pattern.png", dpi=300)
plt.close()

# Bar chart of missing proportions
msno.bar(ces[key_vars], figsize=(10, 5), fontsize=10, color="navy")
plt.title("Proportion Non-Missing by Variable")
plt.tight_layout()
plt.savefig("missing_data_bar.png", dpi=300)
plt.close()

# Check whether missingness on ideology5 clusters in certain groups
print("\n% missing ideology5 by party_id3:")
print(
    ces.assign(miss_ideo=ces["ideology5"].isna())
    .groupby("party_id3")["miss_ideo"]
    .mean()
    .mul(100)
    .round(2)
)


# ==============================================================================
# SECTION 3: LOGICAL CONSISTENCY CHECKS
# ==============================================================================

# Collect all checks in a DataFrame for a clean summary report

checks = {}

# Age plausibility
checks["Age < 18 or > 110"] = (
    (ces["age"] < 18) | (ces["age"] > 110)
).sum()

# Biden voter but didn't vote
checks["Biden voter but voted == 0"] = (
    ces["biden_voter"].notna() & (ces["voted"] == 0)
).sum()

# College recode consistency
checks["college=1 but educ < 5"] = (
    (ces["college"] == 1) & (ces["education"] < 5)
).sum()
checks["college=0 but educ >= 5"] = (
    (ces["college"] == 0) & (ces["education"] >= 5)
).sum()

# White non-Hispanic consistency
checks["white_nh error"] = (
    (ces["white_nh"] == 1) & ~((ces["race_eth"] == 1) & (ces["hispanic_id"] == 2))
).sum()

# Party ID consistency
checks["Strong Rep coded as Dem"] = (
    (ces["party_id7"] == 7) & (ces["party_id3"] == 1)
).sum()

check_df = pd.DataFrame.from_dict(checks, orient="index", columns=["n_flagged"])
check_df["pass"] = check_df["n_flagged"] == 0

print("\nLogical Consistency Checks:")
print(check_df.to_string())

# Assert all checks pass (uncomment in production)
# assert check_df["pass"].all(), "Consistency checks failed"


# ==============================================================================
# SECTION 4: DUPLICATE ID CHECK
# ==============================================================================

# duplicated() returns True for every row that is a duplicate
dupes = ces[ces.duplicated(subset=["caseid"], keep=False)]
print(f"\nDuplicate caseids: {len(dupes):,} (should be 0)")

# Value counts — any caseid appearing more than once?
id_counts = ces["caseid"].value_counts()
print(f"Max times any caseid appears: {id_counts.max()}")

assert len(dupes) == 0, "Duplicate caseids found"


# ==============================================================================
# SECTION 5: OUTLIER DETECTION
# ==============================================================================

# Z-score method: |z| > 4 for large N
z_age = (ces["age"] - ces["age"].mean()) / ces["age"].std()
high_z = ces[(z_age.abs() > 4) & z_age.notna()]
print(f"\nAge outliers (|z| > 4): {len(high_z):,}")
print(high_z[["caseid", "age"]].head(10))

# IQR method (robust to extreme values)
q1, q3 = ces["age"].quantile([0.25, 0.75])
iqr     = q3 - q1
lo, hi  = q1 - 3 * iqr, q3 + 3 * iqr
iqr_out = ces[(ces["age"] < lo) | (ces["age"] > hi)]
print(f"Age IQR outliers (3×IQR): {len(iqr_out):,}")


# ==============================================================================
# SECTION 6: HANDLING MISSING DATA
# ==============================================================================

# LISTWISE DELETION (default in statsmodels)
import statsmodels.formula.api as smf

m = smf.ols("imm_restrict ~ education + age + ideology5", data=ces).fit()
print(f"\nModel N: {int(m.nobs):,} | Total N: {len(ces):,} | "
      f"Dropped: {len(ces) - int(m.nobs):,}")

# MEAN IMPUTATION (mechanics demo — not recommended for inference)
ces_imp = ces.copy()
ces_imp["ideology5_imp"] = ces["ideology5"].fillna(ces["ideology5"].mean())

print(f"\nMean imputed ideology5: "
      f"mean={ces_imp['ideology5_imp'].mean():.3f}, "
      f"sd={ces_imp['ideology5_imp'].std():.3f} "
      f"(vs original: sd={ces['ideology5'].std():.3f})")
# SD decreases after mean imputation — a known problem

del ces_imp

# FORWARD FILL (for time-ordered panel data — not appropriate here,
# shown for reference)
# ces_panel_sorted.sort_values(["caseid","wave"]).groupby("caseid")["ideology5"].ffill()

# MULTIPLE IMPUTATION — see Module 10 (using sklearn IterativeImputer)


# ==============================================================================
# SECTION 7: RECODING VARIABLES
# ==============================================================================

# Age groups with pd.cut()
ces["age_group"] = pd.cut(
    ces["age"],
    bins   = [17, 29, 44, 59, 200],
    labels = ["18-29", "30-44", "45-59", "60+"],
    right  = True
)
print("\nAge groups:\n", ces["age_group"].value_counts().sort_index())

# Ideology collapsed to 3 categories using pd.cut
ces["ideology3"] = pd.cut(
    ces["ideology5"],
    bins   = [0, 2, 3, 5],
    labels = ["Liberal", "Moderate", "Conservative"],
    right  = True
)
print("\nIdeology3:\n", ces["ideology3"].value_counts())

# Quartiles with pd.qcut()
ces["educ_quartile"] = pd.qcut(
    ces["education"],
    q      = 4,
    labels = ["Q1", "Q2", "Q3", "Q4"],
    duplicates = "drop"
)
print("\nEducation quartiles:\n", ces["educ_quartile"].value_counts().sort_index())


# ==============================================================================
# SECTION 8: STANDARDIZING VARIABLES (Z-SCORES)
# ==============================================================================

# scipy.stats.zscore() or manual normalization
for col in ["age", "education", "ideology5", "imm_restrict", "econ_retro"]:
    ces[f"z_{col}"] = (ces[col] - ces[col].mean()) / ces[col].std()

print("\nStandardized variable means (should be ~0):")
z_cols = [c for c in ces.columns if c.startswith("z_")]
print(ces[z_cols].mean().round(6))

print("Standardized variable SDs (should be ~1):")
print(ces[z_cols].std().round(6))

# Regression with standardized predictors
m_std = smf.ols(
    "z_imm_restrict ~ z_education + z_age + z_ideology5 + C(sex)",
    data=ces
).fit()
print("\nStandardized coefficients:\n", m_std.params.round(4))

# Drop z-score columns
ces = ces.drop(columns=z_cols)


# ==============================================================================
# SECTION 9: STRING CLEANING FOR MERGE KEYS
# ==============================================================================

# Simulate a state name column (as you'd get from a messy CSV)
state_map = {12:"Florida", 13:"Georgia", 36:"New York",
             48:"texas", 6:" California ", 42:"Pennsylvania"}

ces["state_name_raw"] = ces["state_fips"].map(state_map)

# Standardize: strip, lower, replace spaces
ces["state_key"] = (
    ces["state_name_raw"]
    .str.strip()
    .str.lower()
    .str.replace(r"\s+", " ", regex=True)
)

print("\nSample state keys:")
print(ces[["state_fips", "state_name_raw", "state_key"]].dropna().head(10))

ces = ces.drop(columns=["state_name_raw", "state_key"])


# ==============================================================================
# SECTION 10: ASSERTING DATA QUALITY BEFORE ANALYSIS
# ==============================================================================

# Production-grade validation: assert statements stop execution if violated.
# Run these at the start of any analysis script that depends on cleaned data.

def validate_ces(df):
    """Assert data quality constraints for CES analysis dataset."""
    # ID is unique
    assert df["caseid"].nunique() == len(df), "Duplicate caseids"

    # Age is plausible
    assert (df["age"].dropna() >= 18).all(), "Respondent younger than 18"
    assert (df["age"].dropna() <= 115).all(), "Respondent older than 115"

    # Binary vars are only 0/1/NaN
    for col in ["voted", "college", "white_nh", "dem", "rep", "biden_voter"]:
        vals = df[col].dropna().unique()
        assert set(vals).issubset({0, 1}), f"{col} has values outside {{0,1}}: {vals}"

    # imm_restrict is bounded [0, 5]
    valid = df["imm_restrict"].dropna()
    assert (valid >= 0).all() and (valid <= 5).all(), "imm_restrict out of [0,5] range"

    # biden_voter is only among voters
    assert (df.loc[df["biden_voter"].notna(), "voted"] == 1).all(), \
        "biden_voter coded for non-voters"

    print("All validation checks passed.")

validate_ces(ces)


# ==============================================================================
# SECTION 11: SAVE ANALYSIS-READY DATASET
# ==============================================================================

ces.to_parquet("CES2020_analysis_ready.parquet", index=False)
ces.to_csv("CES2020_analysis_ready.csv", index=False)

print("\nModule 9 complete. Analysis-ready dataset saved.")
