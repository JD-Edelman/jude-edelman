# =============================================================================
# MODULE 15: PROPENSITY SCORE METHODS
# CES 2020 Social Science Code Library
# =============================================================================
# Topics covered:
#   - Propensity score estimation with sklearn LogisticRegression
#   - Common support / overlap visualization
#   - Nearest-neighbor matching (manual implementation via NearestNeighbors)
#   - IPTW weights (ATE and ATT)
#   - Standardized mean differences (SMD) for balance diagnostics
#   - Weighted outcome regression via statsmodels WLS
#
# Data note: CES 2020 is stored as .parquet.
#   pip install pyarrow
#   import pyarrow.parquet as pq
#
# Unconfoundedness assumption:
#   Conditioning on observed covariates X makes treatment independent of
#   potential outcomes. This is untestable; document carefully.
# =============================================================================

import pandas as pd
import numpy as np
from sklearn.linear_model import LogisticRegression
from sklearn.neighbors import NearestNeighbors
from sklearn.preprocessing import StandardScaler
import statsmodels.api as sm
import statsmodels.formula.api as smf
import matplotlib.pyplot as plt

# --- SECTION 1: ESTIMATE PROPENSITY SCORES (logit) ---
# ces = pd.read_parquet("path/to/CES2020.parquet", engine="pyarrow")
# covariates = ["covariate1", "covariate2", "covariate3"]
# X = ces[covariates].values
# D = ces["treatment_var"].values
# lr = LogisticRegression(max_iter=1000, solver="lbfgs")
# lr.fit(X, D)
# ces["pscore"] = lr.predict_proba(X)[:, 1]
# print(ces.groupby("treatment_var")["pscore"].describe())

# --- SECTION 2: COMMON SUPPORT AND OVERLAP ---
# fig, ax = plt.subplots(figsize=(8, 4))
# ces.query("treatment_var == 1")["pscore"].plot.kde(ax=ax, label="Treated")
# ces.query("treatment_var == 0")["pscore"].plot.kde(ax=ax, label="Control")
# ax.set_xlabel("Estimated propensity score")
# ax.set_title("Overlap check: propensity score distributions")
# ax.legend(); plt.tight_layout(); plt.savefig("overlap.png", dpi=150)
# Trim to common support: keep only rows within [treated_min, control_max]

# --- SECTION 3: NEAREST-NEIGHBOR MATCHING ---
# treated = ces[ces["treatment_var"] == 1].copy()
# control = ces[ces["treatment_var"] == 0].copy()
# nn = NearestNeighbors(n_neighbors=1, metric="euclidean")
# nn.fit(control[["pscore"]])
# distances, indices = nn.kneighbors(treated[["pscore"]])
# matched_controls = control.iloc[indices.flatten()].copy()
# matched_data = pd.concat([treated, matched_controls], ignore_index=True)

# --- SECTION 4: IPTW WEIGHTS ---
# ATE weights
# ces["ate_weight"] = np.where(
#     ces["treatment_var"] == 1,
#     1 / ces["pscore"],
#     1 / (1 - ces["pscore"])
# )
# ATT weights
# ces["att_weight"] = np.where(
#     ces["treatment_var"] == 1,
#     1.0,
#     ces["pscore"] / (1 - ces["pscore"])
# )
# Trim extreme weights (e.g., cap at 99th percentile)

# --- SECTION 5: BALANCE DIAGNOSTICS (standardized differences) ---
# def smd(var, treat_col, df):
#     t = df.loc[df[treat_col] == 1, var]
#     c = df.loc[df[treat_col] == 0, var]
#     pooled_sd = np.sqrt((t.var() + c.var()) / 2)
#     return (t.mean() - c.mean()) / pooled_sd
#
# for cov in covariates:
#     pre  = smd(cov, "treatment_var", ces)
#     post = smd(cov, "treatment_var", matched_data)
#     print(f"{cov:20s}  pre-SMD={pre:+.3f}  post-SMD={post:+.3f}")

# --- SECTION 6: OUTCOME ANALYSIS ---
# Naive OLS
# naive = smf.ols("outcome_var ~ treatment_var", data=ces).fit()
# print(naive.summary())
# IPTW-weighted ATE (WLS)
# ate_model = smf.wls("outcome_var ~ treatment_var",
#                      data=ces, weights=ces["ate_weight"]).fit()
# print(ate_model.summary())
# IPTW-weighted ATT
# att_model = smf.wls("outcome_var ~ treatment_var",
#                      data=ces, weights=ces["att_weight"]).fit()
# print(att_model.summary())
