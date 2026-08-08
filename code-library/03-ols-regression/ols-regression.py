# ==============================================================================
#  MODULE 3: OLS LINEAR REGRESSION
#  Dataset: CES 2020 (cleaned in Module 1)
#
#  Stack: statsmodels (OLS, robust SEs), pandas, numpy, matplotlib/seaborn
# ==============================================================================

import pandas as pd
import numpy as np
import statsmodels.formula.api as smf   # R-style formula interface
import statsmodels.api as sm            # direct matrix interface
import matplotlib.pyplot as plt
import seaborn as sns
from scipy import stats

ces = pd.read_parquet("CES2020_clean.parquet")

# Convert categoricals for formula API
# C(var) in statsmodels formula creates dummy variables (like Stata's i.)
# The lowest category is the reference group by default.


# ==============================================================================
# SECTION 1: SIMPLE (BIVARIATE) OLS
# ==============================================================================

# smf.ols(formula, data).fit() mirrors R's lm() formula syntax.
# ~ separates outcome from predictors; + adds predictors.
# missing="drop" does listwise deletion (default behavior).

m_simple = smf.ols("imm_restrict ~ education", data=ces).fit()

print(m_simple.summary())

# Key output:
#   coef     = unstandardized coefficient
#   std err  = standard error
#   t        = t-statistic
#   P>|t|    = two-tailed p-value
#   [0.025, 0.975] = 95% confidence interval
#   R-squared = proportion of Y variance explained


# ==============================================================================
# SECTION 2: MULTIPLE REGRESSION
# ==============================================================================

# C(var) creates dummy variables from a categorical column.
# The reference category is the lowest value (1 = Male, 1 = Northeast).

m_demog = smf.ols(
    "imm_restrict ~ education + age + C(sex) + C(census_region)",
    data=ces
).fit()

print(m_demog.summary())


# ==============================================================================
# SECTION 3: FULL MODEL
# ==============================================================================

m_full = smf.ols(
    "imm_restrict ~ education + age + C(sex) + C(census_region) "
    "+ ideology5 + party_id7 + college",
    data=ces
).fit()

print(m_full.summary())

# Quick coefficient table
coef_df = pd.DataFrame({
    "coef":    m_full.params,
    "se":      m_full.bse,
    "t":       m_full.tvalues,
    "p":       m_full.pvalues,
    "ci_low":  m_full.conf_int()[0],
    "ci_high": m_full.conf_int()[1],
}).round(4)

print(coef_df)


# ==============================================================================
# SECTION 4: COMPARING NESTED MODELS (F-TEST)
# ==============================================================================

# Use statsmodels' f_test() to test whether added coefficients are jointly zero.
# This is the equivalent of Stata's "test ideology5 party_id7" after regress.

# Test H0: ideology5 == 0 AND party_id7 == 0 simultaneously
hypotheses = "ideology5 = 0, party_id7 = 0"
f_result = m_full.f_test(hypotheses)
f_val = float(np.squeeze(f_result.fvalue))
print(f"\nF-test (ideology5 = party_id7 = 0):")
print(f"  F = {f_val:.3f}, p = {f_result.pvalue:.4f}")


# ==============================================================================
# SECTION 5: INTERACTION TERMS
# ==============================================================================

# In statsmodels formula: * creates main effects + interaction
# a*b = a + b + a:b

m_interact = smf.ols(
    "imm_restrict ~ education * C(party_id3) + age + C(sex)",
    data=ces
).fit()

print(m_interact.summary())

# Generate predicted values across education × party combinations
from itertools import product

pred_grid = pd.DataFrame(
    list(product(range(1, 7), [1, 2, 3])),
    columns=["education", "party_id3"]
)
pred_grid["age"] = ces["age"].mean()
pred_grid["sex"] = 1   # reference category

pred_grid["predicted"] = m_interact.predict(pred_grid)

# Plot
fig, ax = plt.subplots(figsize=(9, 5))
colors = {1: "blue", 2: "red", 3: "darkgreen"}
labels = {1: "Democrat", 2: "Republican", 3: "Independent"}

for pid, grp in pred_grid.groupby("party_id3"):
    ax.plot(grp["education"], grp["predicted"],
            color=colors[pid], label=labels[pid], linewidth=2, marker="o")

ax.set_xticks(range(1, 7))
ax.set_xticklabels(["No HS","HS","Some coll.","Assoc.","Bach.","Postgrad"])
ax.set_xlabel("Education Level")
ax.set_ylabel("Predicted Restrictionism (0–5)")
ax.set_title("Predicted Immigration Restrictionism by Education & Party")
ax.legend()
plt.tight_layout()
plt.savefig("interact_imm_educ_party.png", dpi=300)
plt.close()


# ==============================================================================
# SECTION 6: ROBUST STANDARD ERRORS
# ==============================================================================

# fit().get_robustcov_results(cov_type="HC3") applies Huber-White robust SEs.
# cov_type options:
#   "HC0" "HC1" "HC2" "HC3" — heteroskedasticity-robust (HC3 is most conservative)
#   "cluster" — clustered SEs (specify groups= argument)

m_robust = smf.ols(
    "imm_restrict ~ education + age + ideology5 + C(sex) + C(census_region)",
    data=ces
).fit(cov_type="HC3")

print(m_robust.summary())

# Compare: standard vs. robust SEs for education coefficient
m_standard = smf.ols(
    "imm_restrict ~ education + age + ideology5 + C(sex)",
    data=ces
).fit()

m_hc3 = smf.ols(
    "imm_restrict ~ education + age + ideology5 + C(sex)",
    data=ces
).fit(cov_type="HC3")

print(f"\nEducation coef: {m_standard.params['education']:.4f}")
print(f"  Standard SE:  {m_standard.bse['education']:.4f}")
print(f"  Robust SE:    {m_hc3.bse['education']:.4f}")


# ==============================================================================
# SECTION 7: CLUSTERED STANDARD ERRORS
# ==============================================================================

# Groups= takes a Series or array of cluster IDs aligned with the model data.
# Use the model's index to align properly.

ces_cc = ces.dropna(subset=["imm_restrict", "education", "age", "ideology5", "sex"])

m_base = smf.ols(
    "imm_restrict ~ education + age + ideology5 + C(sex)",
    data=ces_cc
)

m_clustered = m_base.fit(
    cov_type="cluster",
    cov_kwds={"groups": ces_cc["state_fips"]}
)

print(m_clustered.summary())


# ==============================================================================
# SECTION 8: STANDARDIZED (BETA) COEFFICIENTS
# ==============================================================================

# Standardize continuous predictors before regressing.
# Coefficients are then in SD units — comparable across predictors.

def standardize(series):
    return (series - series.mean()) / series.std()

ces_std = ces.copy()
for col in ["imm_restrict", "education", "age", "ideology5", "party_id7"]:
    ces_std[f"z_{col}"] = standardize(ces[col])

m_std = smf.ols(
    "z_imm_restrict ~ z_education + z_age + z_ideology5 + z_party_id7 + C(sex)",
    data=ces_std
).fit(cov_type="HC3")

print("\nStandardized coefficients:")
print(m_std.params.round(4))


# ==============================================================================
# SECTION 9: POST-ESTIMATION DIAGNOSTICS
# ==============================================================================

m_diag = smf.ols(
    "imm_restrict ~ education + age + ideology5 + party_id7 + C(sex) + C(census_region)",
    data=ces
).fit()

fitted   = m_diag.fittedvalues
residuals = m_diag.resid
std_resid = m_diag.get_influence().resid_studentized_internal

# --- Residuals vs. Fitted ---
fig, axes = plt.subplots(1, 2, figsize=(12, 5))

axes[0].scatter(fitted, residuals, alpha=0.1, s=2, color="navy")
axes[0].axhline(0, color="red", linestyle="--")
axes[0].set_xlabel("Fitted Values")
axes[0].set_ylabel("Residuals")
axes[0].set_title("Residuals vs. Fitted")

# --- Q-Q Plot ---
stats.probplot(std_resid, dist="norm", plot=axes[1])
axes[1].set_title("Q-Q Plot of Standardized Residuals")

plt.tight_layout()
plt.savefig("diagnostics_ols.png", dpi=300)
plt.close()

# --- Cook's Distance ---
influence = m_diag.get_influence()
cooks_d   = influence.cooks_distance[0]
n         = m_diag.nobs
k         = m_diag.df_model

hi_cook = (cooks_d > 4 / n).sum()
print(f"\nHigh Cook's D (> 4/N): {hi_cook} observations")

# --- VIF (multicollinearity) ---
from statsmodels.stats.outliers_influence import variance_inflation_factor

# Build design matrix without intercept for VIF calculation
X = m_diag.model.exog
vif_data = pd.DataFrame({
    "feature": m_diag.model.exog_names,
    "VIF":     [variance_inflation_factor(X, i) for i in range(X.shape[1])]
}).round(2)
print("\nVIF:\n", vif_data)

# --- Breusch-Pagan test (heteroskedasticity) ---
from statsmodels.stats.diagnostic import het_breuschpagan

bp_stat, bp_p, _, _ = het_breuschpagan(m_diag.resid, m_diag.model.exog)
print(f"\nBreusch-Pagan: stat={bp_stat:.3f}, p={bp_p:.4f}")
if bp_p < 0.05:
    print("  → Heteroskedasticity detected — use robust SEs")


# ==============================================================================
# SECTION 10: FORMATTED RESULTS TABLE
# ==============================================================================

# Build a clean side-by-side coefficient table manually
def model_table(models, model_names, sig_levels=(.05, .01, .001)):
    rows = {}
    for name, m in zip(model_names, models):
        col = {}
        for param in m.params.index:
            coef = m.params[param]
            se   = m.bse[param]
            p    = m.pvalues[param]
            stars = (
                "***" if p < sig_levels[2] else
                "**"  if p < sig_levels[1] else
                "*"   if p < sig_levels[0] else ""
            )
            col[param] = f"{coef:.3f}{stars}"
            col[f"{param}_se"] = f"({se:.3f})"
        col["N"]   = int(m.nobs)
        col["R²"]  = round(m.rsquared, 3)
        col["Adj R²"] = round(m.rsquared_adj, 3)
        rows[name] = col
    return pd.DataFrame(rows)

m1 = smf.ols("imm_restrict ~ education", data=ces).fit()
m2 = smf.ols("imm_restrict ~ education + age + C(sex) + C(census_region)", data=ces).fit()
m3 = smf.ols("imm_restrict ~ education + age + C(sex) + C(census_region) + ideology5 + party_id7", data=ces).fit()

table = model_table([m1, m2, m3], ["Bivariate", "Demographics", "Full"])
print("\nRegression Table:\n", table)

# Save to CSV for import into Word
table.to_csv("table_ols_restrict.csv")

print("\nModule 3 complete.")
