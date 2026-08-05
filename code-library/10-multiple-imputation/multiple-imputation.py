# ==============================================================================
#  MODULE 10: MULTIPLE IMPUTATION WITH SKLEARN & MICEFOREST
#  Dataset: CES 2020 (cleaned in Module 1)
#
#  Stack: sklearn (IterativeImputer = MICE), miceforest (random-forest MICE)
#
#  Two Python MI options:
#  1. sklearn.impute.IterativeImputer — MICE with linear/bayesian ridge models
#     Built into sklearn; no extra install needed.
#  2. miceforest — MICE with random forest models; better for non-linear data
#     pip install miceforest
#
#  Neither has the full Rubin's rules pooling infrastructure of R's mice
#  or Stata's mi. We implement Rubin's rules manually for regression models.
# ==============================================================================

import pandas as pd
import numpy as np
import statsmodels.formula.api as smf
import matplotlib.pyplot as plt
import seaborn as sns

from sklearn.experimental import enable_iterative_imputer   # must import to enable
from sklearn.impute import IterativeImputer, SimpleImputer
from sklearn.linear_model import BayesianRidge

ces = pd.read_parquet("CES2020_clean.parquet")


# ==============================================================================
# SECTION 1: ASSESS MISSING DATA
# ==============================================================================

analysis_vars = [
    "age", "sex", "education", "race_eth", "college", "white_nh",
    "census_region", "state_fips",
    "ideology5", "party_id3", "party_id7", "dem", "rep",
    "imm_restrict", "econ_retro", "hh_income_change", "approve_trump",
    "self_rated_health",
    "voted", "biden_voter",
    "wt_post"
]

ces_sub = ces[analysis_vars].copy()

print("Missing data (%):")
missing = ces_sub.isna().mean().mul(100).round(2).sort_values(ascending=False)
print(missing[missing > 0])

# Variables we will impute (covariates only — never impute outcomes)
impute_vars = [
    "ideology5", "party_id7", "party_id3",
    "econ_retro", "hh_income_change", "approve_trump", "self_rated_health"
]

# Variables that are complete or outcomes (used as predictors in imputation only)
complete_vars = [
    "age", "sex", "education", "college", "white_nh",
    "census_region", "voted", "biden_voter"
]

# Is missingness on ideology5 related to observed variables? (MAR check)
m_miss = smf.logit(
    "miss_ideo ~ age + C(sex) + college + white_nh + C(census_region)",
    data = ces_sub.assign(miss_ideo=ces_sub["ideology5"].isna())
).fit(disp=False)

print("\nMAR check — predictors of ideology5 missingness:")
print(m_miss.pvalues.round(4))


# ==============================================================================
# SECTION 2: SET UP MICE WITH SKLEARN ITERATIVEIMPUTER
# ==============================================================================

# IterativeImputer implements MICE using sklearn estimators for each variable.
# estimator = BayesianRidge() is similar to Stata's pmm for continuous vars.
#
# Key parameters:
#   max_iter    = number of rounds of imputation (default 10)
#   n_nearest_features = use only k most correlated features per variable
#   random_state = for reproducibility
#   sample_posterior = True → draw from posterior (correct for MI uncertainty)

# Select features for imputation model (numeric only for IterativeImputer)
imp_features = impute_vars + complete_vars
ces_imp_input = ces_sub[imp_features].copy()

# Run m=20 imputations
M = 20
imputed_datasets = []

for i in range(M):
    imputer = IterativeImputer(
        estimator      = BayesianRidge(),
        max_iter       = 10,
        sample_posterior = True,    # draw from posterior — required for proper MI
        random_state   = 20240101 + i,
        verbose        = 0
    )
    imp_array = imputer.fit_transform(ces_imp_input)
    imp_df    = pd.DataFrame(imp_array, columns=imp_features)

    # Round imputed categorical variables to nearest integer
    for col in ["ideology5", "party_id7", "party_id3",
                "econ_retro", "hh_income_change", "approve_trump",
                "self_rated_health"]:
        if col in imp_df.columns:
            imp_df[col] = np.round(imp_df[col]).astype(int)

    # Merge imputed values back onto the full dataset
    ces_full_imp = ces_sub.copy()
    for col in impute_vars:
        ces_full_imp[col] = imp_df[col].values

    imputed_datasets.append(ces_full_imp)

print(f"\nImputation complete: m={M} datasets created.")


# ==============================================================================
# SECTION 3: DIAGNOSTICS
# ==============================================================================

# Compare means of imputed vs. observed values across datasets

print("\nMean ideology5 across imputed datasets (should be stable):")
means = [d["ideology5"].mean() for d in imputed_datasets]
print(f"  Range: {min(means):.3f} – {max(means):.3f}")
print(f"  Observed mean: {ces_sub['ideology5'].mean():.3f}")

# Density comparison: observed vs. first 3 imputed datasets
fig, ax = plt.subplots(figsize=(8, 5))

sns.kdeplot(ces_sub["ideology5"].dropna(), label="Observed", color="black",
            linewidth=2, ax=ax)
for i, d in enumerate(imputed_datasets[:3]):
    sns.kdeplot(d["ideology5"], label=f"Imputed {i+1}",
                alpha=0.5, ax=ax)

ax.set_xlabel("Ideology (1=Very Lib, 5=Very Con)")
ax.set_title("Observed vs. Imputed Ideology Distributions")
ax.legend()
plt.tight_layout()
plt.savefig("mi_density_ideology.png", dpi=300)
plt.close()


# ==============================================================================
# SECTION 4: ANALYZE — RUN MODELS ON ALL M DATASETS
# ==============================================================================

# Run the same model on each imputed dataset and collect results

formula = (
    "imm_restrict ~ education + age + ideology5 + party_id7 + "
    "C(sex) + C(census_region) + college + white_nh"
)

m_results = []
for d in imputed_datasets:
    m = smf.ols(formula, data=d).fit()
    m_results.append(m)

print(f"\nModels fit on {len(m_results)} imputed datasets.")


# ==============================================================================
# SECTION 5: POOL RESULTS WITH RUBIN'S RULES
# ==============================================================================

def rubins_rules(results, param):
    """
    Pool estimates across m fitted models using Rubin's (1987) rules.

    Returns: pooled estimate, total SE, degrees of freedom, p-value.
    """
    m = len(results)

    # Extract estimates and variances for this parameter
    qs    = np.array([r.params[param]   for r in results if param in r.params])
    us    = np.array([r.bse[param]**2   for r in results if param in r.params])

    m_eff = len(qs)
    if m_eff == 0:
        return None

    q_bar = qs.mean()                       # pooled estimate
    u_bar = us.mean()                       # within-imputation variance
    b     = qs.var(ddof=1)                  # between-imputation variance
    t_var = u_bar + (1 + 1/m_eff) * b      # total variance (Rubin's rules)
    se    = np.sqrt(t_var)

    # Degrees of freedom (Barnard & Rubin 1999)
    lam   = (1 + 1/m_eff) * b / t_var      # fraction of missing info
    nu_old = (m_eff - 1) / lam**2
    nu_obs = (1 - lam) * (r.df_resid + 1) / (r.df_resid + 3) * r.df_resid
    df    = 1 / (1/nu_old + 1/nu_obs) if nu_obs > 0 else nu_old

    from scipy import stats
    t_stat = q_bar / se
    p_val  = 2 * stats.t.sf(abs(t_stat), df=df)

    return {
        "estimate": q_bar,
        "se":       se,
        "t":        t_stat,
        "df":       df,
        "p_value":  p_val,
        "fmi":      lam,                    # fraction of missing information
        "ci_low":   q_bar - 1.96 * se,
        "ci_high":  q_bar + 1.96 * se,
    }


# Get all parameters from the first model
all_params = m_results[0].params.index.tolist()

pooled_rows = []
for param in all_params:
    result = rubins_rules(m_results, param)
    if result:
        result["term"] = param
        pooled_rows.append(result)

pooled_df = pd.DataFrame(pooled_rows).set_index("term")
pooled_df = pooled_df.round(4)

print("\nPooled MI Results (Rubin's Rules):")
print(pooled_df[["estimate", "se", "t", "p_value", "fmi"]].to_string())

# FMI interpretation:
# fmi ≈ 0   = imputation had little effect (variable had little missing)
# fmi > 0.3 = substantial missing-data uncertainty — consider more imputations


# ==============================================================================
# SECTION 6: COMPARE MI TO COMPLETE-CASE
# ==============================================================================

# Complete-case OLS
cc_model = smf.ols(formula, data=ces).fit()

print("\nComparison: education coefficient")
print(f"  Complete-case: {cc_model.params.get('education', np.nan):.4f} "
      f"(SE={cc_model.bse.get('education', np.nan):.4f})")

if "education" in pooled_df.index:
    print(f"  MI pooled:     {pooled_df.loc['education','estimate']:.4f} "
          f"(SE={pooled_df.loc['education','se']:.4f})")


# ==============================================================================
# SECTION 7: MICEFOREST (RANDOM FOREST MICE)
# ==============================================================================

# miceforest uses random forests for imputation — handles non-linear
# relationships and interactions automatically. Better for complex data.
# pip install miceforest

try:
    import miceforest as mf

    kernel = mf.ImputationKernel(
        data         = ces_sub[imp_features],
        num_datasets = 5,                  # use 5 for speed in demo; 20 for production
        random_state = 20240101
    )

    kernel.mice(
        iterations = 3,   # number of MICE iterations (more = better convergence)
        verbose    = False
    )

    # Run the model on each imputed dataset
    mf_results = []
    for d_idx in range(kernel.num_datasets):
        d = kernel.complete_data(d_idx)
        m = smf.ols(formula, data=d).fit()
        mf_results.append(m)

    # Pool
    mf_pooled = []
    for param in mf_results[0].params.index:
        r = rubins_rules(mf_results, param)
        if r:
            r["term"] = param
            mf_pooled.append(r)

    mf_pooled_df = pd.DataFrame(mf_pooled).set_index("term").round(4)
    print("\nMICEforest Pooled Results (education):")
    if "education" in mf_pooled_df.index:
        print(mf_pooled_df.loc["education", ["estimate", "se", "p_value"]])

except ImportError:
    print("\nmiceforest not installed — run: pip install miceforest")


# ==============================================================================
# SECTION 8: PASSIVE VARIABLES AFTER IMPUTATION
# ==============================================================================

# Variables derived from imputed variables must be recomputed in each
# imputed dataset. Do this AFTER imputation is complete.

for d in imputed_datasets:
    d["dem"] = (d["party_id3"] == 1).astype(int)
    d["rep"] = (d["party_id3"] == 2).astype(int)

# Verify consistency
for i, d in enumerate(imputed_datasets[:3]):
    consistency = (d["dem"] == (d["party_id3"] == 1)).mean()
    print(f"Imputed dataset {i+1} — dem consistency: {consistency:.4f}")


# ==============================================================================
# SECTION 9: SAVE IMPUTED DATASETS
# ==============================================================================

# Stack all imputed datasets with an imputation index
all_imp = pd.concat(
    [d.assign(imp_id=i) for i, d in enumerate(imputed_datasets)],
    axis=0,
    ignore_index=True
)

all_imp.to_parquet("CES2020_imputed_long.parquet", index=False)
print(f"\nSaved: CES2020_imputed_long.parquet")
print(f"  Shape: {all_imp.shape}  (m={M} datasets stacked)")

# Save pooled results
pooled_df.to_csv("mi_pooled_results.csv")
print("Saved: mi_pooled_results.csv")

print("\nModule 10 complete.")
