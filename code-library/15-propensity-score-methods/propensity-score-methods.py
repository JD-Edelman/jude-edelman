# =============================================================================
# MODULE 15: PROPENSITY SCORE METHODS
# CES 2020 Social Science Code Library
# =============================================================================
# What this file covers:
#   1. Imports and data load
#   2. Define treatment: college education (educ >= 5)
#   3. Estimate propensity scores via logistic regression (sklearn)
#   4. Clip propensity scores before computing weights
#   5. Common support: correct overlap region calculation
#   6. ATE weights (inverse probability weighting)
#   7. ATT weights
#   8. Nearest-neighbor matching — with/without replacement explained
#   9. Standardized mean difference (SMD) with correct pooled-SD formula
#  10. AIPW (doubly robust) sketch
#  11. Note on combining propensity weights with survey weights
#
# Core assumption (unconfoundedness / ignorability):
#   Conditional on observed covariates X, treatment assignment is independent
#   of potential outcomes. This is UNTESTABLE from the data — it must be
#   justified theoretically and documented carefully in any write-up.
#   Sensitivity analyses (e.g., Rosenbaum bounds) can assess fragility.
# =============================================================================

import warnings
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import statsmodels.formula.api as smf
from scipy import stats
from sklearn.linear_model import LogisticRegression
from sklearn.neighbors import NearestNeighbors
from sklearn.preprocessing import StandardScaler

warnings.filterwarnings("ignore")


# =============================================================================
# 1. LOAD DATA
# =============================================================================

ces = pd.read_stata("ces2020.dta")

print("=== CES 2020 loaded ===")
print(f"Rows: {len(ces):,}   Columns: {ces.shape[1]}")


# =============================================================================
# 2. DEFINE TREATMENT VARIABLE
# =============================================================================
# Treatment: college education (educ >= 5 in CES coding).
# CES educ codes: 1=No HS, 2=HS, 3=Some college, 4=2-year, 5=4-year, 6=Post-grad
# college = 1 if respondent has a 4-year degree or higher.
#
# We use numeric codes, not string labels, per project convention.

ces["college"] = (ces["educ"] >= 5).astype(int)

# Covariates to condition on. These must be measured BEFORE the treatment
# (or be pre-treatment characteristics) to avoid conditioning on mediators.
covariates = ["ideo5", "faminc_new", "gender", "race", "birthyr"]

# Build the analytic sample: drop rows missing treatment, outcome, or covariates
analysis_vars = covariates + ["college", "approval_pres"]
ces_ps = ces[analysis_vars].dropna().copy().reset_index(drop=True)

print(f"\nAnalytic sample after listwise deletion: {len(ces_ps):,} rows")
print(f"Treatment distribution:")
print(ces_ps["college"].value_counts().rename({0: "No college (0)", 1: "College (1)"}))


# =============================================================================
# 3. ESTIMATE PROPENSITY SCORES VIA LOGISTIC REGRESSION
# =============================================================================
# The propensity score e(X) = P(D=1 | X) is the conditional probability of
# receiving treatment given pre-treatment covariates. We estimate it with a
# logistic regression. sklearn's LogisticRegression scales well and is easy
# to use here.
#
# Always standardize continuous covariates before fitting (helps convergence).
# Note that sklearn does not print a summary; if you want coefficients and
# standard errors, refit with statsmodels.logit after getting the pscore.

X_raw  = ces_ps[covariates].values
D      = ces_ps["college"].values

scaler = StandardScaler()
X      = scaler.fit_transform(X_raw)

lr     = LogisticRegression(max_iter=1000, solver="lbfgs", C=1.0)
lr.fit(X, D)

ces_ps["pscore"] = lr.predict_proba(X)[:, 1]

print("\nRaw propensity score summary by treatment group (before clipping):")
print(ces_ps.groupby("college")["pscore"].describe().round(4))


# =============================================================================
# 4. CLIP PROPENSITY SCORES BEFORE COMPUTING WEIGHTS
# =============================================================================
# Propensity scores at or near 0 or 1 create extreme IPW weights (dividing by
# a near-zero number). We clip BEFORE computing any weights — not after.
# Clipping to [0.01, 0.99] is a common conservative choice. You can tighten
# to [0.05, 0.95] for more aggressive trimming.
#
# This is an empirical decision with tradeoffs: tighter clipping reduces
# variance of estimates at the cost of potential bias. Always report what
# bounds you used and how many units were affected.

CLIP_LOW  = 0.01
CLIP_HIGH = 0.99

n_outside = ((ces_ps["pscore"] < CLIP_LOW) | (ces_ps["pscore"] > CLIP_HIGH)).sum()
ces_ps["pscore"] = ces_ps["pscore"].clip(CLIP_LOW, CLIP_HIGH)

print(f"\nPropensity score clipping: [{CLIP_LOW}, {CLIP_HIGH}]")
print(f"Units with pscore outside clip bounds: {n_outside} "
      f"({n_outside / len(ces_ps) * 100:.2f}% of sample)")

print("\nPropensity score summary by treatment group (after clipping):")
print(ces_ps.groupby("college")["pscore"].describe().round(4))


# =============================================================================
# 5. COMMON SUPPORT (OVERLAP REGION)
# =============================================================================
# Common support is the range of pscore values where BOTH treated and control
# units exist. Units outside this range are extrapolating — we have no
# comparable counterpart for them — and should be dropped.
#
# Correct calculation:
#   min_support = max of the two groups' minimums  (the higher floor)
#   max_support = min of the two groups' maximums  (the lower ceiling)
#
# This defines the intersection of both distributions, not just one side.
#
# A common mistake is using only the treated distribution's range, which
# keeps control units that have no treated counterpart. Always use both.

treated = ces_ps[ces_ps["college"] == 1]["pscore"]
control = ces_ps[ces_ps["college"] == 0]["pscore"]

min_support = max(treated.min(), control.min())  # higher of the two minimums
max_support = min(treated.max(), control.max())  # lower of the two maximums

print(f"\nCommon support region: [{min_support:.4f}, {max_support:.4f}]")

n_before = len(ces_ps)
ces_cs   = ces_ps[
    (ces_ps["pscore"] >= min_support) & (ces_ps["pscore"] <= max_support)
].copy().reset_index(drop=True)
n_after  = len(ces_cs)
n_dropped = n_before - n_after

print(f"Dropped {n_dropped} units outside common support "
      f"({n_dropped / n_before * 100:.2f}% of sample)")
print(f"Common-support sample: {n_after:,} rows")

# --- Overlap plot ---
fig, ax = plt.subplots(figsize=(8, 4))
ces_cs[ces_cs["college"] == 1]["pscore"].plot.kde(
    ax=ax, label="College (treated)", color="#2980b9", linewidth=2
)
ces_cs[ces_cs["college"] == 0]["pscore"].plot.kde(
    ax=ax, label="No college (control)", color="#c0392b", linewidth=2
)
ax.axvline(min_support, color="gray", linestyle="--", linewidth=1,
           label=f"Common support: [{min_support:.3f}, {max_support:.3f}]")
ax.axvline(max_support, color="gray", linestyle="--", linewidth=1)
ax.set_xlabel("Estimated propensity score")
ax.set_title("Overlap Check: Propensity Score Distributions (after clipping + common support)")
ax.legend(fontsize=9)
plt.tight_layout()
plt.savefig("overlap.png", dpi=150)
plt.show()
print("Overlap plot saved: overlap.png")


# =============================================================================
# 6. ATE WEIGHTS (Average Treatment Effect)
# =============================================================================
# ATE answers: what is the average effect of treatment for everyone in the
# population (treated and control combined)?
#
# IPW weights re-weight each observation so that treated and control groups
# look like the full population on observed covariates:
#
#   Treated:  w = 1 / e(X)
#   Control:  w = 1 / (1 - e(X))
#
# High pscore treated units: already likely to be treated, so they get low
# weight (not very informative). Low pscore treated units are surprising, so
# they get high weight. Mirror logic for controls.
#
# We normalize weights within each arm so they sum to 1 (stabilized IPW).
# Stabilized weights have better finite-sample behavior.

# Raw ATE weights
ces_cs["ate_w_raw"] = np.where(
    ces_cs["college"] == 1,
    1.0 / ces_cs["pscore"],
    1.0 / (1.0 - ces_cs["pscore"])
)

# Stabilized ATE weights: multiply by marginal treatment probability
p_treat = ces_cs["college"].mean()
ces_cs["ate_weight"] = np.where(
    ces_cs["college"] == 1,
    p_treat / ces_cs["pscore"],
    (1 - p_treat) / (1.0 - ces_cs["pscore"])
)

print("\n=== ATE Weights (stabilized) ===")
print(ces_cs.groupby("college")["ate_weight"].describe().round(4))
print(f"Sum of ATE weights (treated): {ces_cs.loc[ces_cs['college']==1,'ate_weight'].sum():.1f}")
print(f"Sum of ATE weights (control): {ces_cs.loc[ces_cs['college']==0,'ate_weight'].sum():.1f}")


# =============================================================================
# 7. ATT WEIGHTS (Average Treatment Effect on the Treated)
# =============================================================================
# ATT answers: what is the average effect of treatment FOR PEOPLE WHO ACTUALLY
# RECEIVED IT? This is often more policy-relevant ("would the treated group
# have been better off without the treatment?").
#
# ATT weights:
#   Treated:  w = 1   (keep as-is; these are our target population)
#   Control:  w = e(X) / (1 - e(X))   (re-weight controls to look like treated)
#
# Controls with high pscore (similar to treated) get high weight.
# Controls with low pscore (very unlike treated) get low weight.

ces_cs["att_weight"] = np.where(
    ces_cs["college"] == 1,
    1.0,
    ces_cs["pscore"] / (1.0 - ces_cs["pscore"])
)

print("\n=== ATT Weights ===")
print(ces_cs.groupby("college")["att_weight"].describe().round(4))

# Optional: cap extreme weights at the 99th percentile to reduce variance
w99 = ces_cs["att_weight"].quantile(0.99)
n_capped = (ces_cs["att_weight"] > w99).sum()
ces_cs["att_weight"] = ces_cs["att_weight"].clip(upper=w99)
print(f"Weights capped at 99th percentile ({w99:.3f}): {n_capped} units affected")


# =============================================================================
# 8. NEAREST-NEIGHBOR MATCHING
# =============================================================================
# Matching finds, for each treated unit, a control unit with a similar pscore.
# Unlike IPW which keeps everyone (just re-weighted), matching creates a
# balanced subset.
#
# MATCHING WITH REPLACEMENT vs. WITHOUT REPLACEMENT:
#
# With replacement (the default below):
#   - Each control unit can serve as a match for multiple treated units
#   - Better matches on average (lower bias)
#   - Effective sample size may be smaller (some controls used many times)
#   - No deduplication needed in the treatment group; just use the matched pairs
#
# Without replacement:
#   - Each control unit used at most once
#   - May accept worse matches in low-overlap regions
#   - Simple to implement: after matching, deduplicate controls by taking the
#     first time each control was matched (or by random draw among ties)
#   - See deduplication example below

treated_df  = ces_cs[ces_cs["college"] == 1].copy().reset_index(drop=True)
control_df  = ces_cs[ces_cs["college"] == 0].copy().reset_index(drop=True)

nn = NearestNeighbors(n_neighbors=1, metric="euclidean")
nn.fit(control_df[["pscore"]])
distances, indices = nn.kneighbors(treated_df[["pscore"]])

# indices.flatten(): for each treated row i, the index of its nearest control
matched_controls = control_df.iloc[indices.flatten()].copy()
matched_controls.index = treated_df.index  # align indices for pd.concat

# This is matching WITH REPLACEMENT: the same control unit may appear multiple
# times (once for each treated unit it was nearest to).
matched_with_rep = pd.concat([treated_df, matched_controls], ignore_index=True)
print(f"\n=== Nearest-Neighbor Matching (with replacement) ===")
print(f"Treated units:                        {len(treated_df):,}")
print(f"Control matches (with replacement):   {len(matched_controls):,}")
print(f"Unique control units used:            {matched_controls.index.nunique():,}")
print(f"Total matched dataset rows:           {len(matched_with_rep):,}")

# --- Without replacement: deduplicate controls ---
# If you want matching without replacement, keep only the first time each
# control is used (by original row position). This removes re-use.
ctrl_idx_series = pd.Series(indices.flatten(), name="ctrl_idx")
# Keep only the first match for each control index
first_use = ctrl_idx_series.drop_duplicates(keep="first")
deduped_controls = control_df.iloc[first_use.values].copy()

print(f"\n--- If matching WITHOUT replacement (deduplicated controls): ---")
print(f"Unique control units retained:        {len(deduped_controls):,}")
print(f"Treated units matched:                {len(first_use):,}")
print("  (Some treated units lose their match when controls are deduplicated;")
print("   you can keep only the treated units that still have a match.)")

# --- Check balance in matched sample (pscore distribution) ---
print(f"\nPscore by group in matched sample (with replacement):")
print(matched_with_rep.groupby("college")["pscore"].describe().round(4))


# =============================================================================
# 9. STANDARDIZED MEAN DIFFERENCE (SMD)
# =============================================================================
# SMD measures how well-balanced a covariate is between treated and control
# groups, in standard deviation units — so it's comparable across variables
# regardless of their scale.
#
# Correct formula (Cohen's d with pooled SD):
#
#   SMD = (mean_treated - mean_control) / pooled_SD
#
#   pooled_SD = sqrt( [(n_t - 1)*var_t + (n_c - 1)*var_c] / (n_t + n_c - 2) )
#
# This formula weights variances by sample size, which is correct when groups
# are unequal in size. The simpler sqrt((var_t + var_c) / 2) is only correct
# when both groups have the same N.
#
# Rule of thumb: |SMD| < 0.10 is well-balanced, < 0.25 is acceptable.

def smd(var_name, treat_col, df):
    """
    Compute standardized mean difference using pooled SD weighted by sample size.
    """
    t = df.loc[df[treat_col] == 1, var_name].dropna()
    c = df.loc[df[treat_col] == 0, var_name].dropna()
    n_t, n_c   = len(t), len(c)
    mean_diff  = t.mean() - c.mean()
    pooled_var = ((n_t - 1) * t.var() + (n_c - 1) * c.var()) / (n_t + n_c - 2)
    pooled_sd  = np.sqrt(pooled_var)
    if pooled_sd == 0:
        return np.nan
    return mean_diff / pooled_sd

print("\n=== Standardized Mean Differences ===")
print(f"{'Covariate':<15}  {'Pre-matching':>13}  {'Post-match (ATE-wtd)':>21}")
print("-" * 55)

for cov in covariates:
    pre  = smd(cov, "college", ces_cs)
    # Weighted SMD requires computing weighted means/variances separately
    def weighted_smd(var_name, treat_col, df, weight_col):
        t   = df[df[treat_col] == 1]
        c   = df[df[treat_col] == 0]
        wt  = t[weight_col]
        wc  = c[weight_col]
        mt  = np.average(t[var_name], weights=wt)
        mc  = np.average(c[var_name], weights=wc)
        vt  = np.average((t[var_name] - mt) ** 2, weights=wt)
        vc  = np.average((c[var_name] - mc) ** 2, weights=wc)
        ps  = np.sqrt((vt + vc) / 2)
        return (mt - mc) / ps if ps != 0 else np.nan

    post = weighted_smd(cov, "college", ces_cs, "ate_weight")
    balance = "GOOD" if abs(post) < 0.10 else ("OK" if abs(post) < 0.25 else "POOR")
    print(f"{cov:<15}  {pre:>+13.4f}  {post:>+21.4f}  {balance}")


# =============================================================================
# 10. OUTCOME ANALYSIS: NAIVE, ATE-WEIGHTED, ATT-WEIGHTED, MATCHED
# =============================================================================

print("\n=== Outcome Analysis: Effect of College on Presidential Approval ===")

# Naive OLS (no adjustment for selection)
naive = smf.ols("approval_pres ~ college", data=ces_cs).fit()
print(f"Naive OLS coefficient:       {naive.params['college']:.4f}  "
      f"(p={naive.pvalues['college']:.4f})")

# ATE: IPW-weighted regression
ate_model = smf.wls(
    "approval_pres ~ college",
    data=ces_cs,
    weights=ces_cs["ate_weight"]
).fit()
print(f"IPW ATE coefficient:         {ate_model.params['college']:.4f}  "
      f"(p={ate_model.pvalues['college']:.4f})")

# ATT: IPW-weighted regression with ATT weights
att_model = smf.wls(
    "approval_pres ~ college",
    data=ces_cs,
    weights=ces_cs["att_weight"]
).fit()
print(f"IPW ATT coefficient:         {att_model.params['college']:.4f}  "
      f"(p={att_model.pvalues['college']:.4f})")

# Matched-sample estimate (with replacement)
matched_ols = smf.ols(
    "approval_pres ~ college",
    data=matched_with_rep
).fit()
print(f"Matched OLS coefficient:     {matched_ols.params['college']:.4f}  "
      f"(p={matched_ols.pvalues['college']:.4f})")

print("""
Interpreting differences across estimators:
  Naive OLS conflates the causal effect with selection bias (college-educated
  people differ systematically from others in ways that also affect approval).
  IPW ATE = average effect for everyone; ATT = average effect for the treated.
  If ATE and ATT differ substantially, the effect is heterogeneous — it matters
  more (or less) for people who tend to get a college education.
""")


# =============================================================================
# 11. AIPW — AUGMENTED IPW (DOUBLY ROBUST ESTIMATOR) SKETCH
# =============================================================================
# AIPW combines a propensity score model (already estimated) with an outcome
# model. It is "doubly robust" in the sense that the estimate is consistent if
# EITHER the propensity model or the outcome model is correctly specified.
# In practice, getting both right is best, but the robustness is useful
# insurance.
#
# AIPW estimator for ATE:
#
#   tau_AIPW = (1/n) * sum_i [
#       mu_1(X_i)                            <- outcome model prediction if treated
#     - mu_0(X_i)                            <- outcome model prediction if control
#     + D_i * (Y_i - mu_1(X_i)) / e(X_i)   <- IPW correction for treated
#     - (1-D_i) * (Y_i - mu_0(X_i)) / (1 - e(X_i))  <- IPW correction for control
#   ]
#
# Step 1: Fit outcome model separately on treated and control
# Step 2: Predict potential outcomes for everyone under both conditions
# Step 3: Combine with IPW correction terms

print("\n=== AIPW (Doubly Robust) Sketch ===")

Y  = ces_cs["approval_pres"].values
D  = ces_cs["college"].values
ps = ces_cs["pscore"].values

# Outcome model: fit on treated only, then predict for all
treated_mask = D == 1
control_mask = D == 0

# X was built from ces_ps; re-transform ces_cs covariates for the AIPW section
# so the array dimensions match the common-support sample
X_cs = scaler.transform(ces_cs[covariates].values)

from sklearn.linear_model import LinearRegression

outcome_model_t = LinearRegression()
outcome_model_t.fit(X_cs[treated_mask], Y[treated_mask])
mu_1 = outcome_model_t.predict(X_cs)   # predicted Y if everyone were treated

outcome_model_c = LinearRegression()
outcome_model_c.fit(X_cs[control_mask], Y[control_mask])
mu_0 = outcome_model_c.predict(X_cs)   # predicted Y if everyone were control

# AIPW correction terms
ipw_treated = D * (Y - mu_1) / ps
ipw_control = (1 - D) * (Y - mu_0) / (1 - ps)

# Doubly robust ATE
aipw_scores = (mu_1 - mu_0) + ipw_treated - ipw_control
aipw_ate    = aipw_scores.mean()
aipw_se     = aipw_scores.std() / np.sqrt(len(aipw_scores))
aipw_ci_low = aipw_ate - 1.96 * aipw_se
aipw_ci_hi  = aipw_ate + 1.96 * aipw_se

print(f"AIPW ATE estimate:  {aipw_ate:.4f}")
print(f"AIPW Std Error:     {aipw_se:.4f}")
print(f"95% CI:             [{aipw_ci_low:.4f}, {aipw_ci_hi:.4f}]")
print("""
AIPW interpretation:
  If the propensity model is wrong but the outcome model is right -> consistent
  If the outcome model is wrong but the propensity model is right -> consistent
  Both wrong -> biased (no free lunch; model both carefully)
  AIPW typically has lower bias than IPW alone and is the recommended estimator
  when using machine learning models for either component.
""")


# =============================================================================
# 12. NOTE ON COMBINING PROPENSITY WEIGHTS WITH SURVEY WEIGHTS
# =============================================================================
# CES 2020 includes survey weights (commonweight, commonpostweight) that account
# for the complex sampling design. If you want nationally representative causal
# estimates, you need to combine the propensity (IPW) weights with the survey
# weights.
#
# How to combine:
#   combined_weight = survey_weight * ipw_weight
#   Then normalize so the weights sum to n (or 1) within each arm.
#
# There is no universally agreed correct way to normalize combined weights.
# One approach:
#   - Within treated: combined_w_treated = survey_w * (1/pscore)
#     Normalize: multiply by n_treated / sum(combined_w_treated)
#   - Within control: combined_w_control = survey_w * (1/(1-pscore))
#     Normalize: multiply by n_control / sum(combined_w_control)
#
# Example (ATE):
#
#   ces_cs = ces_cs.merge(ces[["caseid","commonweight"]], on="caseid", how="left")
#   ces_cs["combined_w"] = ces_cs["commonweight"] * ces_cs["ate_w_raw"]
#   # Normalize within each treatment arm
#   for arm in [0, 1]:
#       mask = ces_cs["college"] == arm
#       total = ces_cs.loc[mask, "combined_w"].sum()
#       n_arm = mask.sum()
#       ces_cs.loc[mask, "combined_w"] *= n_arm / total
#
#   ate_svy_model = smf.wls(
#       "approval_pres ~ college",
#       data=ces_cs,
#       weights=ces_cs["combined_w"]
#   ).fit()
#
# For variance estimation with combined weights, use a sandwich estimator or
# bootstrap — standard OLS SEs will be wrong.

print("\n=== Note: Combining with Survey Weights ===")
print("""
To produce nationally representative causal estimates:
  1. Merge survey weights (commonweight) onto the analytic dataset
  2. Multiply survey weight by IPW weight: combined = survey_w * ipw_w
  3. Normalize combined weights within each treatment arm
  4. Use as weights in WLS for outcome analysis
  5. Use HC2/HC3 robust SEs or bootstrap for valid inference

See code comments above for the full implementation sketch.
""")

print("\n=== Module 15 complete. ===")
