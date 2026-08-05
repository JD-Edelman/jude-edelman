# ==============================================================================
#  MODULE 5: SURVEY-WEIGHTED ANALYSIS
#  Dataset: CES 2020 (cleaned in Module 1)
#
#  Stack: statsmodels (WLS), numpy (weighted stats)
#
#  Python does not have a single package as comprehensive as R's survey
#  package or Stata's svy suite. The best approaches are:
#    1. statsmodels WLS for weighted regression
#    2. numpy.average() for weighted means
#    3. linearmodels package for some survey designs (install separately)
#
#  For complex survey SEs (Taylor linearization), the most complete option
#  is the samplics package: pip install samplics
# ==============================================================================

import pandas as pd
import numpy as np
import statsmodels.formula.api as smf
import statsmodels.api as sm
import matplotlib.pyplot as plt

ces = pd.read_parquet("CES2020_clean.parquet")


# ==============================================================================
# SECTION 1: WHY WEIGHTS MATTER
# ==============================================================================

# CES uses post-stratification weights (wt_post) to make the sample
# nationally representative. Unweighted estimates may over- or under-represent
# certain demographic or political groups.

# Compare unweighted vs. weighted means for key variables
def weighted_mean(series, weights):
    mask = series.notna() & weights.notna()
    return np.average(series[mask], weights=weights[mask])

print("Weighted vs. Unweighted Means:")
print(f"{'Variable':<20} {'Unweighted':>12} {'Weighted':>12}")
print("-" * 46)
for col in ["age", "college", "voted", "ideology5", "biden_voter"]:
    uw = ces[col].mean()
    wt = weighted_mean(ces[col], ces["wt_post"])
    print(f"{col:<20} {uw:>12.4f} {wt:>12.4f}")


# ==============================================================================
# SECTION 2: WEIGHTED MEANS AND PROPORTIONS
# ==============================================================================

def weighted_stats(series, weights):
    """Return weighted mean and approximate SE."""
    mask = series.notna() & weights.notna()
    vals = series[mask].values
    w    = weights[mask].values
    w_norm = w / w.sum()

    wt_mean = np.average(vals, weights=w)
    # Approximate SE via weighted variance
    wt_var  = np.average((vals - wt_mean) ** 2, weights=w)
    wt_se   = np.sqrt(wt_var / mask.sum())
    return wt_mean, wt_se

for col in ["age", "college", "voted", "ideology5", "dem", "rep"]:
    mean, se = weighted_stats(ces[col], ces["wt_post"])
    print(f"{col}: weighted mean = {mean:.4f} (SE ≈ {se:.4f})")


# ==============================================================================
# SECTION 3: WEIGHTED FREQUENCY TABLES
# ==============================================================================

def weighted_crosstab(data, col, weight_col):
    """Weighted frequency table for a categorical variable."""
    valid = data[[col, weight_col]].dropna()
    return (
        valid.groupby(col)[weight_col]
        .sum()
        .pipe(lambda s: pd.DataFrame({"weighted_n": s, "pct": s / s.sum() * 100}))
        .round(2)
    )

print("\nWeighted: college")
print(weighted_crosstab(ces, "college", "wt_post"))

print("\nWeighted: voted")
print(weighted_crosstab(ces, "voted", "wt_post"))

print("\nWeighted: party_id3")
print(weighted_crosstab(ces, "party_id3", "wt_post"))


# ==============================================================================
# SECTION 4: WEIGHTED TWO-WAY TABLE
# ==============================================================================

def weighted_crosstab2(data, row_col, col_col, weight_col):
    """Weighted two-way crosstab with row percentages."""
    valid = data[[row_col, col_col, weight_col]].dropna()
    ct = valid.groupby([row_col, col_col])[weight_col].sum().unstack(fill_value=0)
    row_pct = ct.div(ct.sum(axis=1), axis=0) * 100
    return row_pct.round(1)

print("\nWeighted: party_id3 × biden_voter (row %):")
print(weighted_crosstab2(ces, "party_id3", "biden_voter", "wt_post"))

print("\nWeighted: college × voted (row %):")
print(weighted_crosstab2(ces, "college", "voted", "wt_post"))


# ==============================================================================
# SECTION 5: SURVEY-WEIGHTED OLS (WLS)
# ==============================================================================

# statsmodels WLS (Weighted Least Squares) applies weights to the regression.
# This gives correct weighted point estimates.
# Note: WLS SEs are not design-based (they don't account for clustering).
# For design-based SEs, use linearmodels or samplics.

ces_clean = ces.dropna(subset=[
    "imm_restrict", "education", "age", "sex",
    "census_region", "ideology5", "party_id7", "wt_post"
])

m_wls = smf.wls(
    "imm_restrict ~ education + age + C(sex) + C(census_region) "
    "+ ideology5 + party_id7",
    data    = ces_clean,
    weights = ces_clean["wt_post"]
).fit(cov_type="HC3")

print(m_wls.summary())

# Compare weighted vs. unweighted
m_ols = smf.ols(
    "imm_restrict ~ education + age + C(sex) + C(census_region) "
    "+ ideology5 + party_id7",
    data=ces_clean
).fit(cov_type="HC3")

print("\nCoefficient comparison: education")
print(f"  Unweighted: {m_ols.params['education']:.4f} (SE={m_ols.bse['education']:.4f})")
print(f"  Weighted:   {m_wls.params['education']:.4f} (SE={m_wls.bse['education']:.4f})")


# ==============================================================================
# SECTION 6: SURVEY-WEIGHTED LOGIT
# ==============================================================================

# statsmodels GLM with Binomial family supports frequency weights.
# For probability weights (like CES wt_post), WLS-style weighting is applied
# via the freq_weights argument in GLM.

ces_vote = ces.dropna(subset=[
    "voted", "education", "age", "sex", "census_region",
    "ideology5", "party_id7", "wt_post"
])

# Weighted logit using GLM with Binomial family + freq_weights
m_logit_wt = sm.GLM(
    ces_vote["voted"],
    sm.add_constant(pd.get_dummies(
        ces_vote[["education", "age", "ideology5", "party_id7", "sex"]],
        columns=["sex"], drop_first=True
    ).astype(float)),
    family       = sm.families.Binomial(),
    freq_weights = ces_vote["wt_post"]
).fit()

print(m_logit_wt.summary())

# Formula interface with weights
ces_vote2 = ces.dropna(subset=[
    "voted", "education", "age", "sex",
    "ideology5", "party_id7", "wt_post"
])

m_logit_wt2 = smf.glm(
    "voted ~ education + age + C(sex) + ideology5 + party_id7",
    data    = ces_vote2,
    family  = sm.families.Binomial(),
    freq_weights = ces_vote2["wt_post"]
).fit()

print(m_logit_wt2.summary())


# ==============================================================================
# SECTION 7: SUBPOPULATION ANALYSIS
# ==============================================================================

# Subset to a subpopulation BEFORE creating the model, but after filtering
# to only the subpopulation. Unlike Stata/R's survey packages, Python does
# not have a design-preserving subset mechanism — weight accordingly.

# Analysis among Black respondents
ces_black = ces[ces["race_eth"] == 2].copy()

for col in ["ideology5", "imm_restrict", "econ_retro"]:
    mean, se = weighted_stats(ces_black[col], ces_black["wt_post"])
    print(f"Black respondents — {col}: {mean:.3f} (SE ≈ {se:.4f})")

# Biden vote share among Black voters
ces_black_voters = ces_black[(ces_black["voted"] == 1) & ces_black["biden_voter"].notna()]
mean_biden, se_biden = weighted_stats(ces_black_voters["biden_voter"],
                                      ces_black_voters["wt_post"])
print(f"\nBlack voters — Biden vote share: {mean_biden:.3f}")

# Women only
ces_women = ces[ces["sex"] == 2].copy()
mean_restrict, _ = weighted_stats(ces_women["imm_restrict"], ces_women["wt_post"])
print(f"\nWomen — mean restrictionism: {mean_restrict:.3f}")


# ==============================================================================
# SECTION 8: WEIGHTED MEANS BY SUBGROUP
# ==============================================================================

# Compute weighted group means using pandas groupby + apply
def wt_mean_by_group(data, outcome, group_col, weight_col):
    """Compute weighted mean of outcome within each level of group_col."""
    valid = data[[outcome, group_col, weight_col]].dropna()
    return (
        valid.groupby(group_col)
        .apply(lambda g: np.average(g[outcome], weights=g[weight_col]),
               include_groups=False)
        .rename(f"wt_mean_{outcome}")
        .reset_index()
    )

print("\nWeighted mean ideology by party:")
print(wt_mean_by_group(ces, "ideology5", "party_id3", "wt_post"))

print("\nWeighted mean restrictionism by college:")
print(wt_mean_by_group(ces, "imm_restrict", "college", "wt_post"))

print("\nWeighted mean ideology by region:")
print(wt_mean_by_group(ces, "ideology5", "census_region", "wt_post"))


# ==============================================================================
# SECTION 9: WEIGHTED VS. UNWEIGHTED COMPARISON TABLE
# ==============================================================================

ces_biden = ces[(ces["voted"] == 1) & ces["biden_voter"].notna()].dropna(
    subset=["education", "age", "sex", "ideology5", "party_id7",
            "white_nh", "college", "imm_restrict", "wt_post"]
)

formula = ("biden_voter ~ education + age + C(sex) + ideology5 + "
           "party_id7 + white_nh + college + imm_restrict")

m_unweighted = smf.logit(formula, data=ces_biden).fit(disp=False)
m_weighted   = smf.wls(formula, data=ces_biden,
                        weights=ces_biden["wt_post"]).fit(cov_type="HC3")

# Note: comparing logit (unweighted) to WLS (weighted) for illustration.
# In production, compare weighted logit to unweighted logit.

print("\nCoefficients — Unweighted vs. Weighted:")
comparison = pd.DataFrame({
    "Unweighted (logit)": m_unweighted.params,
    "Weighted (WLS)":     m_weighted.params,
}).round(4)
print(comparison)

print("\nModule 5 complete.")
