# ==============================================================================
#  MODULE 2: DESCRIPTIVE STATISTICS & TABULATIONS
#  Dataset: CES 2020 (cleaned in Module 1)
#
#  Stack: pandas, scipy (t-tests), numpy
# ==============================================================================

import pandas as pd
import numpy as np
from scipy import stats

ces = pd.read_parquet("CES2020_clean.parquet")


# ==============================================================================
# SECTION 1: UNIVARIATE SUMMARIES — CONTINUOUS VARIABLES
# ==============================================================================

# DataFrame.describe() gives count, mean, std, min, quartiles, max
cont_vars = ["age", "education", "ideology5", "party_id7",
             "imm_restrict", "econ_retro", "self_rated_health"]

print(ces[cont_vars].describe().round(2))

# More detailed: percentiles
print(ces["age"].describe(percentiles=[.1, .25, .5, .75, .9]).round(2))

# Custom Table 1 — mean, SD, median, N for each variable
def table1_row(series):
    return pd.Series({
        "Mean":   series.mean(),
        "SD":     series.std(),
        "Median": series.median(),
        "Min":    series.min(),
        "Max":    series.max(),
        "N":      series.notna().sum(),
    })

table1 = ces[cont_vars].apply(table1_row).T.round(2)
print(table1)


# ==============================================================================
# SECTION 2: FREQUENCY TABLES — CATEGORICAL VARIABLES
# ==============================================================================

# value_counts() gives counts; normalize=True gives proportions
# dropna=False includes NaN in the count

def freq_table(series):
    counts = series.value_counts(dropna=False).sort_index()
    pct    = series.value_counts(normalize=True, dropna=False).sort_index() * 100
    return pd.DataFrame({"n": counts, "pct": pct.round(1)})

for col in ["sex", "census_region", "college", "voted",
            "biden_voter", "party_id3", "party_id7"]:
    print(f"\n--- {col} ---")
    print(freq_table(ces[col]))


# ==============================================================================
# SECTION 3: CROSS-TABULATIONS
# ==============================================================================

# pd.crosstab() produces a two-way frequency table
# normalize="index" gives row percentages

# Biden vote by college degree
ct = pd.crosstab(ces["college"], ces["biden_voter"],
                 margins=True, dropna=False)
print("\nBiden vote × College:\n", ct)

# Row percentages
ct_pct = pd.crosstab(ces["college"], ces["biden_voter"],
                     normalize="index") * 100
print(ct_pct.round(1))

# Chi-square test of independence
tbl = pd.crosstab(ces["college"].dropna(),
                  ces["biden_voter"].dropna())
chi2, p, dof, expected = stats.chi2_contingency(tbl)
print(f"\nChi2={chi2:.2f}, df={dof}, p={p:.4f}")

# Biden vote by party ID
print("\nBiden vote × Party ID (row %):")
print(
    pd.crosstab(ces["party_id3"], ces["biden_voter"],
                normalize="index").round(3) * 100
)

# Turnout by region
print("\nVoted × Region (row %):")
print(
    pd.crosstab(ces["census_region"], ces["voted"],
                normalize="index").round(3) * 100
)


# ==============================================================================
# SECTION 4: GROUP MEANS
# ==============================================================================

# groupby().agg() computes multiple statistics per group

group_means = (
    ces.groupby("biden_voter")[["age", "ideology5", "imm_restrict", "econ_retro"]]
    .agg(["mean", "std", "count"])
    .round(2)
)
print("\nGroup means by Biden vote:\n", group_means)

# By party ID
print("\nGroup means by party:")
print(
    ces.groupby("party_id3")[["ideology5", "imm_restrict"]]
    .mean()
    .round(2)
)

# By college
print("\nRestriction by college:")
print(
    ces.groupby("college")["imm_restrict"]
    .agg(["mean", "std", "count"])
    .round(2)
)


# ==============================================================================
# SECTION 5: T-TESTS — MEAN COMPARISONS
# ==============================================================================

# scipy.stats.ttest_ind() runs an independent-samples t-test
# equal_var=False → Welch's t-test (default in most social science)

def welch_ttest(df, outcome, group_col, group_vals):
    g1 = df.loc[df[group_col] == group_vals[0], outcome].dropna()
    g2 = df.loc[df[group_col] == group_vals[1], outcome].dropna()
    t, p = stats.ttest_ind(g1, g2, equal_var=False)
    print(f"{outcome} by {group_col} ({group_vals[0]} vs {group_vals[1]}): "
          f"t={t:.3f}, p={p:.4f}, "
          f"means=[{g1.mean():.2f}, {g2.mean():.2f}]")

welch_ttest(ces, "imm_restrict", "college", [0, 1])
welch_ttest(ces, "ideology5",    "biden_voter", [1, 0])
welch_ttest(ces, "age",          "voted",    [1, 0])

# Dem vs. Rep only (drop independents)
ces_partisans = ces[ces["party_id3"].isin([1, 2])]
welch_ttest(ces_partisans, "econ_retro", "party_id3", [1, 2])


# ==============================================================================
# SECTION 6: CORRELATION MATRIX
# ==============================================================================

# DataFrame.corr() computes Pearson correlations (pairwise complete obs)

corr_vars = ["age", "education", "ideology5", "imm_restrict",
             "econ_retro", "self_rated_health", "biden_voter"]

corr_matrix = ces[corr_vars].corr(method="pearson")
print("\nCorrelation matrix:\n", corr_matrix.round(3))

# With p-values (manual computation)
def corr_pvalue(df, var1, var2):
    valid = df[[var1, var2]].dropna()
    r, p  = stats.pearsonr(valid[var1], valid[var2])
    return round(r, 3), round(p, 4)

for v in ["education", "ideology5", "imm_restrict", "econ_retro"]:
    r, p = corr_pvalue(ces, "biden_voter", v)
    print(f"biden_voter × {v}: r={r}, p={p}")


# ==============================================================================
# SECTION 7: MISSING DATA PATTERNS
# ==============================================================================

key_vars = ["age", "education", "ideology5", "party_id3",
            "imm_restrict", "voted", "biden_voter"]

missing = (
    ces[key_vars]
    .isna()
    .mean()
    .mul(100)
    .round(2)
    .rename("pct_missing")
    .reset_index()
    .rename(columns={"index": "variable"})
    .sort_values("pct_missing", ascending=False)
)
print("\nMissing data (%):\n", missing)

# Is missingness on ideology5 associated with party?
miss_by_party = (
    ces.assign(miss_ideo=ces["ideology5"].isna())
    .groupby("party_id3")["miss_ideo"]
    .mean()
    .mul(100)
    .round(2)
)
print("\n% missing ideology by party:\n", miss_by_party)


# ==============================================================================
# SECTION 8: WEIGHTED DESCRIPTIVES
# ==============================================================================

# pandas doesn't have native survey-weight support for all statistics.
# Use numpy.average(values, weights=weights) for weighted means.

def weighted_mean(series, weights):
    mask = series.notna() & weights.notna()
    return np.average(series[mask], weights=weights[mask])

print("\nWeighted vs unweighted means:")
for col in ["age", "college", "voted", "ideology5"]:
    unwt = ces[col].mean()
    wt   = weighted_mean(ces[col], ces["wt_post"])
    print(f"  {col}: unweighted={unwt:.3f}, weighted={wt:.3f}")

# For full survey-weighted inference (SEs, regression), use the statsmodels
# WLS or the linearmodels package — demonstrated in Module 5.

print("\nModule 2 complete.")
