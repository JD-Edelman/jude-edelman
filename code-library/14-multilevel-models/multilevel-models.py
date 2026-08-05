# =============================================================================
# MODULE 14: MULTILEVEL MODELS (MIXED-EFFECTS REGRESSION)
# CES 2020 Social Science Code Library
# =============================================================================
# Topics covered:
#   - Random intercept models via statsmodels MixedLM
#   - ICC from variance components
#   - Random slopes (groups argument in MixedLM)
#   - Cross-level interactions (manual product term)
#   - Visualization of random effects with matplotlib
#
# Data note: CES 2020 is stored as .parquet. Use pandas.read_parquet() with
# the pyarrow or fastparquet engine. Ensure pyarrow is installed:
#   pip install pyarrow
# =============================================================================

import pandas as pd
import numpy as np
import statsmodels.formula.api as smf
import statsmodels.api as sm
from statsmodels.regression.mixed_linear_model import MixedLM
import matplotlib.pyplot as plt
import matplotlib.ticker as ticker

# --- SECTION 1: DATA PREP ---
# ces = pd.read_parquet("path/to/CES2020.parquet", engine="pyarrow")
# Inspect nesting: ces["inputstate"].value_counts()
# Recode variables; keep numeric codes throughout

# --- SECTION 2: NULL MODEL AND ICC ---
# null_mod = smf.mixedlm("outcome ~ 1", data=ces, groups=ces["inputstate"])
# null_fit = null_mod.fit(reml=True)
# print(null_fit.summary())
# tau2 = null_fit.cov_re.iloc[0, 0]      # between-group variance
# sigma2 = null_fit.scale                 # within-group variance
# icc = tau2 / (tau2 + sigma2)
# print(f"ICC = {icc:.4f}")

# --- SECTION 3: RANDOM INTERCEPT MODEL ---
# ri_mod = smf.mixedlm("outcome ~ predictor1 + predictor2",
#                       data=ces, groups=ces["inputstate"])
# ri_fit = ri_mod.fit(reml=True)
# print(ri_fit.summary())
# random_effects = ri_fit.random_effects  # dict of {group: u0j}

# --- SECTION 4: RANDOM SLOPE MODEL ---
# exog_re = ces[["predictor1"]]  # design matrix for random slope
# rs_mod = MixedLM(endog=ces["outcome"],
#                  exog=smf.formulatools.formula_matrices("outcome ~ predictor1", ces)[0],
#                  groups=ces["inputstate"],
#                  exog_re=exog_re)
# rs_fit = rs_mod.fit()
# print(rs_fit.summary())

# --- SECTION 5: CROSS-LEVEL INTERACTION ---
# ces["cross_level"] = ces["predictor1"] * ces["state_level_var"]
# cli_mod = smf.mixedlm("outcome ~ predictor1 + state_level_var + cross_level",
#                        data=ces, groups=ces["inputstate"])
# cli_fit = cli_mod.fit(reml=True)
# print(cli_fit.summary())

# --- SECTION 6: VISUALIZE RANDOM EFFECTS ---
# re_vals = pd.Series({k: v["Group"] for k, v in ri_fit.random_effects.items()},
#                     name="u0j").sort_values()
# fig, ax = plt.subplots(figsize=(8, 10))
# ax.barh(re_vals.index.astype(str), re_vals.values)
# ax.axvline(0, color="black", linewidth=0.8)
# ax.set_xlabel("Random intercept estimate (u0j)")
# ax.set_title("State-level random intercepts -- CES 2020")
# plt.tight_layout()
# plt.savefig("random_intercepts.png", dpi=150)
