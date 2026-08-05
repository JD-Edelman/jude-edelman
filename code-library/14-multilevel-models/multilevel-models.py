# =============================================================================
# MODULE 14: MULTILEVEL MODELS (MIXED-EFFECTS REGRESSION)
# CES 2020 Social Science Code Library
# =============================================================================
# What this file covers:
#   1. Imports and data load
#   2. Null model + ICC from variance components
#   3. Random intercept model with predictors
#   4. Random slope model (re_formula API)
#   5. Extracting state random effects (correct key: "Intercept")
#   6. Likelihood ratio test between models
#   7. Plotting state random effects
#   8. Note on linearmodels.PanelOLS as a fixed-effects alternative
#
# Why multilevel models?
#   CES respondents are nested within states. People in the same state share
#   political context, media, economics — so their approval ratings aren't
#   fully independent. Treating them as independent (plain OLS) underestimates
#   standard errors and can produce misleading significance tests. Multilevel
#   models partition that shared variance explicitly.
#
# Level 1 = individual respondents
# Level 2 = states (the "groups" in statsmodels MixedLM)
# =============================================================================

import warnings
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import statsmodels.formula.api as smf
from scipy import stats

warnings.filterwarnings("ignore")


# =============================================================================
# 1. LOAD DATA
# =============================================================================

ces = pd.read_stata("ces2020.dta")

print("=== CES 2020 loaded ===")
print(f"Rows: {len(ces):,}   Columns: {ces.shape[1]}")
print("\nKey variable summary:")
print(ces[["approval_pres", "ideo5", "faminc_new",
           "gender", "race", "inputstate"]].describe())

# Drop rows missing any variable used across all models.
# Dropping once here keeps sample size consistent across model comparisons.
analysis_vars = ["approval_pres", "ideo5", "faminc_new",
                 "gender", "race", "inputstate"]
ces_clean = ces[analysis_vars].dropna().copy()

print(f"\nAnalytic sample after listwise deletion: {len(ces_clean):,} rows")
print(f"Number of states (groups): {ces_clean['inputstate'].nunique()}")


# =============================================================================
# 2. NULL MODEL (INTERCEPT-ONLY) AND ICC
# =============================================================================
# The null model has no predictors. It partitions the total variance in
# approval_pres into two components:
#
#   tau^2  (between-group variance): how much states differ from each other
#   sigma^2 (within-group variance):  how much individuals differ within states
#
# From these we compute the ICC (Intraclass Correlation Coefficient):
#
#   ICC = tau^2 / (tau^2 + sigma^2)
#
# ICC interpretation: the fraction of total variance attributable to group
# membership. An ICC of 0.10 means 10% of the variance in approval is
# explained simply by which state you live in — enough to make multilevel
# modeling worthwhile. Conventional thresholds: < .05 = low, .05-.15 = moderate,
# > .15 = substantial. Any non-trivial ICC justifies the approach.
#
# reml=True uses Restricted Maximum Likelihood, which gives unbiased variance
# estimates and is the standard for variance component estimation.

print("\n" + "=" * 65)
print("2. NULL MODEL (intercept-only)")
print("=" * 65)

null_fit = smf.mixedlm(
    "approval_pres ~ 1",
    ces_clean,
    groups=ces_clean["inputstate"]
).fit(reml=True)

print(null_fit.summary())

# --- Extract variance components ---
# cov_re is a 1x1 DataFrame for a random-intercept model; .iloc[0,0] pulls the scalar.
tau2   = float(null_fit.cov_re.iloc[0, 0])   # between-state variance
sigma2 = null_fit.scale                        # within-state (residual) variance
icc    = tau2 / (tau2 + sigma2)

print(f"\nBetween-state variance  tau^2  = {tau2:.4f}")
print(f"Within-state variance   sigma^2 = {sigma2:.4f}")
print(f"ICC = {tau2:.4f} / ({tau2:.4f} + {sigma2:.4f}) = {icc:.4f}")
print(f"     -> {icc * 100:.1f}% of variance in approval is between states")

if icc < 0.05:
    print("     Clustering is modest; multilevel modeling is conservative but correct.")
elif icc < 0.15:
    print("     Moderate clustering; multilevel modeling is appropriate.")
else:
    print("     Substantial clustering; multilevel modeling is clearly warranted.")


# =============================================================================
# 3. RANDOM INTERCEPT MODEL WITH PREDICTORS
# =============================================================================
# Each state gets its own intercept (random), but the slopes (effects of
# ideo5, faminc_new, gender, race) are assumed the same across states (fixed).
# This is the standard "random intercepts, fixed slopes" model.
#
# C(gender) and C(race) tell the formula parser to treat these as categorical
# dummies. The lowest numeric code becomes the reference category.

print("\n" + "=" * 65)
print("3. RANDOM INTERCEPT MODEL WITH PREDICTORS")
print("=" * 65)

ri_fit = smf.mixedlm(
    "approval_pres ~ ideo5 + faminc_new + C(gender) + C(race)",
    ces_clean,
    groups=ces_clean["inputstate"]
).fit(reml=True)

print(ri_fit.summary())

# How much between-state variance remains after controlling for covariates?
tau2_ri  = float(ri_fit.cov_re.iloc[0, 0])
sigma2_ri = ri_fit.scale
icc_ri   = tau2_ri / (tau2_ri + sigma2_ri)

print(f"\nBetween-state variance after controls: {tau2_ri:.4f}")
print(f"ICC after controls: {icc_ri:.4f}")
print(f"Change in ICC from null: {icc - icc_ri:+.4f}")
print("  (Reduction in tau^2 means covariates explain some between-state variance)")


# =============================================================================
# 4. RANDOM SLOPE MODEL
# =============================================================================
# Here we ask: does the ideology-approval relationship vary across states?
# Maybe ideology predicts approval much more strongly in highly polarized states
# than in moderate ones. A random slope model lets the ideo5 coefficient
# differ by state.
#
# The correct statsmodels API is re_formula="~ideo5". This tells MixedLM to
# give each group (state) its own random intercept AND its own random slope
# for ideo5.
#
# Common mistake to avoid: smf.formulatools does not exist as a public API.
# Another old pattern (passing exog_re manually) works but re_formula is
# cleaner and is the documented way.

print("\n" + "=" * 65)
print("4. RANDOM SLOPE MODEL (ideo5 slope varies by state)")
print("=" * 65)

# Use a focused dataset for this model: only the variables it needs
ces_rs = ces[["approval_pres", "ideo5", "inputstate"]].dropna().copy()
print(f"Rows for random slope model: {len(ces_rs):,}")

rs_fit = smf.mixedlm(
    "approval_pres ~ ideo5",
    ces_rs,
    groups=ces_rs["inputstate"],
    re_formula="~ideo5"   # <-- correct API; gives random intercept + random slope
).fit(reml=True)

print(rs_fit.summary())

# Inspect the random effects structure for one state
sample_state = list(rs_fit.random_effects.keys())[0]
print(f"\nRandom effects keys for state '{sample_state}':")
print(rs_fit.random_effects[sample_state])
print("  -> Keys are 'Intercept' and 'ideo5'; each state has both")

# Extract state-level slope deviations
slope_deviations = pd.Series(
    {k: v["ideo5"] for k, v in rs_fit.random_effects.items()},
    name="ideo5_slope_deviation"
).sort_values()

print(f"\nVariation in ideo5 slope across states:")
print(slope_deviations.describe())
print(f"\nMost negative slope deviation (ideology matters least): {slope_deviations.idxmin()}")
print(f"Most positive slope deviation (ideology matters most):  {slope_deviations.idxmax()}")


# =============================================================================
# 5. EXTRACT AND PLOT STATE RANDOM EFFECTS (from random intercept model)
# =============================================================================
# ri_fit.random_effects is a dict: {state_label: pd.Series}
# Each Series has index "Intercept" — that is the name of the random effect.
# (This changed from older statsmodels versions that used "Group".)
#
# Each value is the state's estimated deviation from the grand intercept.
# Positive = that state has higher-than-average approval holding covariates fixed.

print("\n" + "=" * 65)
print("5. RANDOM EFFECTS FROM RANDOM INTERCEPT MODEL")
print("=" * 65)

# Correct extraction — key is "Intercept"
state_re = pd.Series(
    {k: v["Intercept"] for k, v in ri_fit.random_effects.items()},
    name="random_intercept"
).sort_values()

print("State random effects (sorted):")
print(state_re.describe())
print(f"\nTop 5 states (highest approval deviation):\n{state_re.tail(5)}")
print(f"\nBottom 5 states (lowest approval deviation):\n{state_re.head(5)}")

# --- Horizontal bar chart ---
fig, ax = plt.subplots(figsize=(9, 11))
colors = ["#c0392b" if v < 0 else "#2980b9" for v in state_re.values]

ax.barh(
    range(len(state_re)),
    state_re.values,
    color=colors,
    edgecolor="white",
    linewidth=0.3
)
ax.axvline(0, color="black", linewidth=0.9, linestyle="--")
ax.set_yticks(range(len(state_re)))
ax.set_yticklabels(state_re.index.astype(str), fontsize=7)
ax.set_xlabel("Random intercept deviation from grand mean", fontsize=10)
ax.set_title(
    "State-Level Random Effects on Presidential Approval\n"
    "CES 2020 — Blue = above average, Red = below average",
    fontsize=11
)
plt.tight_layout()
plt.savefig("state_random_effects.png", dpi=150, bbox_inches="tight")
plt.show()
print("Plot saved: state_random_effects.png")


# =============================================================================
# 6. LIKELIHOOD RATIO TEST (LRT): NULL vs. RANDOM INTERCEPT
# =============================================================================
# The LRT tests whether adding predictors significantly improves model fit.
# It compares log-likelihoods: a more complex model always fits better, but
# the LRT tells us whether the gain exceeds what chance alone would produce.
#
# CRITICAL: LRT requires ML (Maximum Likelihood), NOT REML. REML log-likelihoods
# are not directly comparable across models with different fixed-effects
# structures. Always refit with reml=False for LRT.
#
# Test statistic: LR = 2 * (ll_complex - ll_simple) ~ chi^2(df)
# df = difference in number of estimated parameters

print("\n" + "=" * 65)
print("6. LIKELIHOOD RATIO TEST: Null vs. Random Intercept + Predictors")
print("=" * 65)

null_ml = smf.mixedlm(
    "approval_pres ~ 1",
    ces_clean,
    groups=ces_clean["inputstate"]
).fit(reml=False)

ri_ml = smf.mixedlm(
    "approval_pres ~ ideo5 + faminc_new + C(gender) + C(race)",
    ces_clean,
    groups=ces_clean["inputstate"]
).fit(reml=False)

ll_null   = null_ml.llf
ll_ri     = ri_ml.llf
lr_stat   = 2 * (ll_ri - ll_null)
df_diff   = ri_ml.df_modelwc - null_ml.df_modelwc
p_lrt     = stats.chi2.sf(lr_stat, df=df_diff)

print(f"Log-likelihood (null model):         {ll_null:,.2f}")
print(f"Log-likelihood (RI + predictors):    {ll_ri:,.2f}")
print(f"LR statistic (chi-squared):          {lr_stat:.2f}")
print(f"Degrees of freedom:                  {int(df_diff)}")
print(f"p-value:                             {p_lrt:.4e}")

if p_lrt < 0.001:
    print("\nResult: Predictors very significantly improve fit (p < .001)")
elif p_lrt < 0.05:
    print("\nResult: Predictors significantly improve fit (p < .05)")
else:
    print("\nResult: Adding predictors does not significantly improve fit (p >= .05)")


# =============================================================================
# 7. NOTE ON linearmodels.PanelOLS AS FIXED-EFFECTS ALTERNATIVE
# =============================================================================
# Mixed-effects and fixed-effects models are different philosophies:
#
# Mixed effects (MixedLM):
#   - Treats state effects as random draws from a distribution
#   - "Partial pooling": states borrow strength from each other
#   - Can estimate group-level (state-level) predictors
#   - Assumes random effects are uncorrelated with predictors — if violated,
#     estimates are biased. Test this with a Hausman-type comparison.
#   - Works well for cross-sectional nested data like CES
#
# Fixed effects (PanelOLS, or dummy variables in OLS):
#   - Treats each state as a unique entity with its own dummy parameter
#   - Controls for ALL unobserved time-invariant state-level confounders,
#     even those not in your data
#   - Cannot estimate effects of anything that does not vary within states
#   - Appropriate for panel data (same units observed over time)
#
# For cross-sectional CES data there is no "time" dimension, so PanelOLS is
# not the right tool. But if you had CES stacked across multiple years,
# you would set it up like this:
#
#   from linearmodels import PanelOLS
#   import linearmodels
#
#   ces_panel = ces_multi_year.set_index(["caseid", "year"])
#   fe_model = PanelOLS(
#       ces_panel["approval_pres"],
#       ces_panel[["ideo5", "faminc_new"]],
#       entity_effects=True    # absorbs state fixed effects
#   )
#   fe_result = fe_model.fit(cov_type="clustered", cluster_entity=True)
#   print(fe_result.summary)
#
# Rule of thumb:
#   Use MixedLM when you have many groups and want to make inferences
#   about the population of groups, or when you have group-level predictors.
#   Use fixed effects when you're worried about unobserved group-level
#   confounding and all your variation of interest is within groups.

print("\n" + "=" * 65)
print("7. FIXED EFFECTS NOTE")
print("=" * 65)
print("""
linearmodels.PanelOLS is the Python equivalent of Stata's xtreg, fe.
It requires a multi-index (entity, time) and is designed for panel data.
For cross-sectional data, state fixed effects can be included as dummies
in an OLS model: smf.ols("approval_pres ~ ideo5 + C(inputstate)", ces).fit()
This is equivalent but loses interpretability of the state-level variance.

Key diagnostic: compare mixed-effects and fixed-effects estimates.
Large differences suggest the random-effects assumption (uncorrelated RE
and predictors) is violated, favoring the fixed-effects approach.
""")

print("\n=== Module 14 complete. ===")
