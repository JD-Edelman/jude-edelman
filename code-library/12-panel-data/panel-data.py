# ==============================================================================
#  MODULE 12: PANEL DATA & REPEATED MEASURES
#  Dataset: CES 2020 (simulated two-wave panel)
#
#  Stack: linearmodels (FE/RE), statsmodels (DiD), pandas, matplotlib
#  pip install linearmodels
# ==============================================================================

import pandas as pd
import numpy as np
import statsmodels.formula.api as smf
import matplotlib.pyplot as plt
from scipy import stats

ces = pd.read_parquet("CES2020_clean.parquet")


# ==============================================================================
# SECTION 1: CREATE SIMULATED TWO-WAVE PANEL
# ==============================================================================

wave1 = ces[[
    "caseid", "age", "sex", "education", "race_eth", "college", "white_nh",
    "census_region", "state_fips", "ideology5", "party_id3", "dem", "rep",
    "imm_restrict", "econ_retro", "voted", "wt_post"
]].copy()
wave1["wave"] = 0

rng   = np.random.default_rng(20240101)
wave2 = wave1.copy()
wave2["wave"] = 1

noise = rng.normal(0, 0.5, len(wave2))

# Simulate treatment effect: college-educated shift slightly more liberal
wave2["ideology5"] = np.where(
    wave2["college"] == 1,
    wave2["ideology5"] - 0.3 + noise,
    wave2["ideology5"] + noise
)
wave2["ideology5"] = wave2["ideology5"].clip(1, 5)

panel = pd.concat([wave1, wave2], ignore_index=True).sort_values(["caseid", "wave"])

print(f"Panel: {len(panel):,} observations, {panel['caseid'].nunique():,} units")


# ==============================================================================
# SECTION 2: POOLED OLS (BASELINE)
# ==============================================================================

from statsmodels.stats.sandwich_covariance import cov_cluster

m_pooled = smf.ols(
    "ideology5 ~ college + wave + age + C(sex)",
    data=panel
).fit()

# Cluster SEs by person
cluster_groups = panel.loc[m_pooled.model.data.orig_endog.index, "caseid"]
cov_cl  = cov_cluster(m_pooled, cluster_groups)
se_cl   = np.sqrt(np.diag(cov_cl))

print("Pooled OLS (clustered SEs):")
for param, coef, se in zip(m_pooled.params.index, m_pooled.params, se_cl):
    t = coef / se
    p = 2 * stats.t.sf(abs(t), df=m_pooled.df_resid)
    print(f"  {param:<30} {coef:>8.4f}  ({se:.4f})  p={p:.4f}")


# ==============================================================================
# SECTION 3: FIXED EFFECTS (WITHIN ESTIMATOR) WITH LINEARMODELS
# ==============================================================================

# linearmodels.panel.PanelOLS provides FE/RE with correct panel SEs.
# Must set a MultiIndex (entity, time) before fitting.

try:
    from linearmodels.panel import PanelOLS, RandomEffects, BetweenOLS
    from linearmodels import PanelData

    panel_indexed = panel.set_index(["caseid", "wave"])

    # Fixed effects: absorb individual-level FE
    # entity_effects=True = demean within person (equivalent to Stata's xtreg, fe)
    m_fe = PanelOLS(
        dependent     = panel_indexed["ideology5"],
        exog          = panel_indexed[["college", "wave"]],
        entity_effects = True,
        time_effects   = False
    ).fit(cov_type="clustered", cluster_entity=True)

    print("\nFixed Effects Model:")
    print(m_fe.summary.tables[1])   # coefficient table

    # Note: age and sex are time-invariant → absorbed by entity FE → dropped
    # Only time-varying predictors remain

    # --- Random Effects ---
    m_re = RandomEffects(
        dependent = panel_indexed["ideology5"],
        exog      = panel_indexed[["college", "wave", "age"]]
    ).fit(cov_type="robust")

    print("\nRandom Effects Model:")
    print(m_re.summary.tables[1])

    # --- Hausman-style comparison (linearmodels) ---
    fe_params = m_fe.params
    re_params = m_re.params

    common = [p for p in fe_params.index if p in re_params.index]
    diff   = fe_params[common] - re_params[common]
    print(f"\nHausman-style diff (FE - RE) for college:")
    print(f"  {diff.get('college', 'N/A'):.4f}")
    print("  Large difference → prefer FE for causal inference")

except ImportError:
    print("linearmodels not installed — run: pip install linearmodels")
    m_fe = None


# ==============================================================================
# SECTION 4: FIRST DIFFERENCES (MANUAL)
# ==============================================================================

panel_fd = (
    panel.sort_values(["caseid", "wave"])
    .groupby("caseid")
    .apply(lambda g: g.set_index("wave").diff().loc[1], include_groups=False)
    .dropna(subset=["ideology5", "college"])
    .reset_index()
)

m_fd = smf.ols(
    "ideology5 ~ college",
    data=panel_fd
).fit()

# Cluster SEs by person
cluster_fd = panel_fd.loc[m_fd.model.data.orig_endog.index, "caseid"]
cov_fd     = cov_cluster(m_fd, cluster_fd)
se_fd      = np.sqrt(np.diag(cov_fd))

print("\nFirst Differences:")
for param, coef, se in zip(m_fd.params.index, m_fd.params, se_fd):
    t = coef / se
    p = 2 * stats.t.sf(abs(t), df=m_fd.df_resid)
    print(f"  {param:<20} {coef:>8.4f}  ({se:.4f})  p={p:.4f}")


# ==============================================================================
# SECTION 5: DIFFERENCE-IN-DIFFERENCES (DiD)
# ==============================================================================

panel_did = panel.assign(
    treated = panel["college"],
    post    = panel["wave"],
    did     = panel["college"] * panel["wave"]
)

# Standard DiD regression
m_did = smf.ols(
    "ideology5 ~ treated + post + did",
    data=panel_did
).fit()

cluster_did = panel_did.loc[m_did.model.data.orig_endog.index, "caseid"]
cov_did     = cov_cluster(m_did, cluster_did)
se_did      = np.sqrt(np.diag(cov_did))

print("\nDiD Regression:")
for param, coef, se in zip(m_did.params.index, m_did.params, se_did):
    t = coef / se
    p = 2 * stats.t.sf(abs(t), df=m_did.df_resid)
    stars = "***" if p < .001 else "**" if p < .01 else "*" if p < .05 else ""
    print(f"  {param:<20} {coef:>8.4f}{stars}  ({se:.4f})  p={p:.4f}")

print("\n  Interpretation: 'did' coefficient is the ATT (Average Treatment")
print("  Effect on the Treated) under the parallel trends assumption.")

# DiD with controls
m_did_ctrl = smf.ols(
    "ideology5 ~ treated * post + age + C(sex) + C(census_region)",
    data=panel_did
).fit()

cluster_ctrl = panel_did.loc[m_did_ctrl.model.data.orig_endog.index, "caseid"]
cov_ctrl     = cov_cluster(m_did_ctrl, cluster_ctrl)
se_ctrl      = np.sqrt(np.diag(cov_ctrl))

print("\nDiD with Controls — 'treated:post' (ATT):")
param  = "treated:post"
if param in m_did_ctrl.params:
    coef = m_did_ctrl.params[param]
    idx  = list(m_did_ctrl.params.index).index(param)
    se   = se_ctrl[idx]
    t    = coef / se
    p    = 2 * stats.t.sf(abs(t), df=m_did_ctrl.df_resid)
    print(f"  {coef:.4f} (SE={se:.4f}, p={p:.4f})")


# ==============================================================================
# SECTION 6: PARALLEL TRENDS PLOT
# ==============================================================================

trend = (
    panel_did.groupby(["treated", "wave"])["ideology5"]
    .mean()
    .reset_index()
    .rename(columns={"ideology5": "mean_ideo"})
)

fig, ax = plt.subplots(figsize=(7, 5))
colors = {0: "navy", 1: "firebrick"}
labels = {0: "No College (Control)", 1: "College (Treated)"}

for treated_val, grp in trend.groupby("treated"):
    ax.plot(grp["wave"], grp["mean_ideo"],
            color=colors[treated_val], label=labels[treated_val],
            linewidth=2, marker="o", markersize=8)

ax.axvline(0.5, color="gray", linestyle="--", linewidth=1, label="Treatment cutpoint")
ax.set_xticks([0, 1])
ax.set_xticklabels(["Pre", "Post"])
ax.set_xlabel("")
ax.set_ylabel("Mean Ideology (1=Very Lib, 5=Very Con)")
ax.set_title("Parallel Trends Check\nMean Ideology by Group and Wave")
ax.legend()
plt.tight_layout()
plt.savefig("parallel_trends.png", dpi=300)
plt.close()


# ==============================================================================
# SECTION 7: WITHIN VS. BETWEEN VARIANCE
# ==============================================================================

# Decompose variance into within-person and between-person components
person_means = panel.groupby("caseid")["ideology5"].mean()
panel = panel.merge(person_means.rename("ideo_person_mean"), on="caseid")

panel["ideo_within"]  = panel["ideology5"] - panel["ideo_person_mean"]
panel["ideo_between"] = panel["ideo_person_mean"] - panel["ideology5"].mean()

var_total   = panel["ideology5"].var()
var_within  = panel["ideo_within"].var()
var_between = panel["ideo_between"].var()

print(f"\nVariance decomposition — ideology5:")
print(f"  Total:   {var_total:.4f}")
print(f"  Between: {var_between:.4f} ({var_between/var_total*100:.1f}%)")
print(f"  Within:  {var_within:.4f}  ({var_within/var_total*100:.1f}%)")
print("  Fixed effects uses only the within-person variance.")

panel = panel.drop(columns=["ideo_person_mean", "ideo_within", "ideo_between"])


# ==============================================================================
# SECTION 8: SUMMARY TABLE
# ==============================================================================

print("\n" + "="*60)
print("MODEL SUMMARY")
print("="*60)
print(f"{'Model':<22} {'College coef':>14} {'N':>8}")
print("-"*60)

m_pool_cluster_coef = m_pooled.params.get("college", np.nan)
print(f"{'Pooled OLS':<22} {m_pool_cluster_coef:>14.4f} {int(m_pooled.nobs):>8,}")

if m_fe is not None and "college" in m_fe.params:
    print(f"{'Fixed Effects':<22} {m_fe.params['college']:>14.4f} {int(m_fe.nobs):>8,}")

fd_coef = m_fd.params.get("college", np.nan)
print(f"{'First Differences':<22} {fd_coef:>14.4f} {int(m_fd.nobs):>8,}")

did_coef = m_did.params.get("did", np.nan)
print(f"{'DiD (treatment×post)':<22} {did_coef:>14.4f} {int(m_did.nobs):>8,}")

print("\nModule 12 complete.")
