# ==============================================================================
#  MODULE 11: SCALE CONSTRUCTION & RELIABILITY
#  Dataset: CES 2020 (cleaned in Module 1)
#
#  Stack: numpy, pandas, scipy, sklearn (PCA), factor_analyzer (EFA/CFA)
#  pip install factor_analyzer pingouin
# ==============================================================================

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from scipy import stats
from sklearn.preprocessing import StandardScaler
from sklearn.decomposition import PCA

ces = pd.read_parquet("CES2020_clean.parquet")


# ==============================================================================
# SECTION 1: RECODE ITEMS TO CONSISTENT DIRECTION
# ==============================================================================

# Each item: 1 = the focal construct (restrictionism, gun control, climate action)
# 0 = opposite position; NaN = missing

ces = ces.assign(
    # Immigration restrictionism items
    imm_item1 = np.where(ces["pol_daca"]          == 2, 1.0, np.where(ces["pol_daca"].isna(),          np.nan, 0.0)),
    imm_item2 = np.where(ces["pol_border_patrol"] == 1, 1.0, np.where(ces["pol_border_patrol"].isna(), np.nan, 0.0)),
    imm_item3 = np.where(ces["pol_wall"]          == 1, 1.0, np.where(ces["pol_wall"].isna(),          np.nan, 0.0)),
    imm_item4 = np.where(ces["pol_legal_status"]  == 2, 1.0, np.where(ces["pol_legal_status"].isna(),  np.nan, 0.0)),
    imm_item5 = np.where(ces["pol_deportation"]   == 1, 1.0, np.where(ces["pol_deportation"].isna(),   np.nan, 0.0)),

    # Gun control items
    gun_item1 = np.where(ces["pol_assault_ban"]      == 1, 1.0, np.where(ces["pol_assault_ban"].isna(),      np.nan, 0.0)),
    gun_item2 = np.where(ces["pol_concealed_carry"]  == 2, 1.0, np.where(ces["pol_concealed_carry"].isna(),  np.nan, 0.0)),
    gun_item3 = np.where(ces["pol_background_check"] == 1, 1.0, np.where(ces["pol_background_check"].isna(), np.nan, 0.0)),

    # Climate policy items
    climate_item1 = np.where(ces["pol_climate_epa"]        == 1, 1.0, np.where(ces["pol_climate_epa"].isna(),        np.nan, 0.0)),
    climate_item2 = np.where(ces["pol_climate_paris"]       == 1, 1.0, np.where(ces["pol_climate_paris"].isna(),       np.nan, 0.0)),
    climate_item3 = np.where(ces["pol_climate_renewables"]  == 1, 1.0, np.where(ces["pol_climate_renewables"].isna(),  np.nan, 0.0)),
    climate_item4 = np.where(ces["pol_climate_carbon_tax"]  == 1, 1.0, np.where(ces["pol_climate_carbon_tax"].isna(),  np.nan, 0.0)),
)

imm_items     = ces[["imm_item1","imm_item2","imm_item3","imm_item4","imm_item5"]]
gun_items     = ces[["gun_item1","gun_item2","gun_item3"]]
climate_items = ces[["climate_item1","climate_item2","climate_item3","climate_item4"]]


# ==============================================================================
# SECTION 2: CRONBACH'S ALPHA
# ==============================================================================

def cronbach_alpha(df):
    """
    Compute Cronbach's alpha for a DataFrame of items.
    Uses pairwise complete observations.
    """
    df_c = df.dropna()
    n    = df_c.shape[1]       # number of items
    N    = df_c.shape[0]       # number of respondents

    item_vars  = df_c.var(axis=0, ddof=1)       # variance of each item
    total_var  = df_c.sum(axis=1).var(ddof=1)   # variance of the total score

    alpha = (n / (n - 1)) * (1 - item_vars.sum() / total_var)
    return alpha

def alpha_if_deleted(df):
    """Cronbach's alpha if each item is deleted one at a time."""
    results = {}
    cols = df.columns.tolist()
    for col in cols:
        remaining = [c for c in cols if c != col]
        results[col] = cronbach_alpha(df[remaining])
    return pd.Series(results).round(3)

# Item-total correlations
def item_total_corr(df):
    """Correlation of each item with the sum of all other items."""
    results = {}
    cols = df.columns.tolist()
    for col in cols:
        rest = df.drop(columns=[col]).sum(axis=1)
        r, _ = stats.pearsonr(
            df[col].dropna(),
            rest[df[col].notna()]
        )
        results[col] = r
    return pd.Series(results).round(3)

print("=== IMMIGRATION SCALE ===")
print(f"Alpha: {cronbach_alpha(imm_items):.3f}")
print("Alpha if deleted:")
print(alpha_if_deleted(imm_items))
print("Item-total correlations:")
print(item_total_corr(imm_items))

print("\n=== GUN CONTROL SCALE ===")
print(f"Alpha: {cronbach_alpha(gun_items):.3f}")

print("\n=== CLIMATE POLICY SCALE ===")
print(f"Alpha: {cronbach_alpha(climate_items):.3f}")

# Benchmarks: >.9 excellent, >.8 good, >.7 acceptable, >.6 questionable

# pingouin has a cleaner alpha() with CIs:
try:
    import pingouin as pg
    print("\nPingouin alpha — immigration:")
    print(pg.cronbach_alpha(data=imm_items.dropna())[0])
except ImportError:
    print("\n(pip install pingouin for alpha with CIs)")


# ==============================================================================
# SECTION 3: ADDITIVE SCALE SCORES
# ==============================================================================

# rowMeans with minimum valid items threshold
def scale_mean(df, min_valid=None):
    """Row mean with optional minimum valid-items threshold."""
    n_valid = df.notna().sum(axis=1)
    means   = df.mean(axis=1)
    if min_valid:
        means = means.where(n_valid >= min_valid)
    return means

ces["imm_scale_mean"]     = scale_mean(imm_items, min_valid=4)
ces["gun_scale_mean"]     = scale_mean(gun_items)
ces["climate_scale_mean"] = scale_mean(climate_items)

print("\nScale descriptives:")
print(ces[["imm_scale_mean","gun_scale_mean","climate_scale_mean"]].describe().round(3))


# ==============================================================================
# SECTION 4: EXPLORATORY FACTOR ANALYSIS (EFA) WITH FACTOR_ANALYZER
# ==============================================================================

try:
    from factor_analyzer import FactorAnalyzer
    from factor_analyzer.factor_analyzer import calculate_kmo, calculate_bartlett_sphericity

    items_complete = imm_items.dropna()

    # KMO and Bartlett's test (is the correlation matrix factorable?)
    chi_sq_val, p_val = calculate_bartlett_sphericity(items_complete)
    kmo_all, kmo_model = calculate_kmo(items_complete)
    print(f"\nBartlett's test: chi2={chi_sq_val:.2f}, p={p_val:.4f}")
    print(f"KMO: {kmo_model:.3f}  (>.6 = acceptable, >.8 = good)")

    # Parallel analysis — determine number of factors
    fa_check = FactorAnalyzer(n_factors=5, rotation=None)
    fa_check.fit(items_complete)
    ev, _ = fa_check.get_eigenvalues()

    plt.figure(figsize=(7, 4))
    plt.plot(range(1, len(ev)+1), ev, "bo-", markersize=6)
    plt.axhline(1, color="red", linestyle="--", label="Eigenvalue = 1")
    plt.xlabel("Factor Number")
    plt.ylabel("Eigenvalue")
    plt.title("Scree Plot: Immigration Items")
    plt.legend()
    plt.tight_layout()
    plt.savefig("scree_immigration.png", dpi=300)
    plt.close()

    # Single-factor EFA with oblimin rotation
    fa = FactorAnalyzer(n_factors=1, rotation="oblimin")
    fa.fit(items_complete)

    loadings = pd.DataFrame(
        fa.loadings_,
        index   = items_complete.columns,
        columns = ["Factor 1"]
    ).round(3)

    communalities = pd.DataFrame(
        fa.get_communalities(),
        index   = items_complete.columns,
        columns = ["Communality"]
    ).round(3)

    print("\nFactor Loadings (1-factor EFA):")
    print(loadings)
    print("\nCommunalities:")
    print(communalities)

    # Two-factor EFA across all attitude domains
    all_items = pd.concat([
        imm_items.rename(columns=lambda c: f"imm_{c[-1]}"),
        gun_items.rename(columns=lambda c: f"gun_{c[-1]}"),
        climate_items.rename(columns=lambda c: f"clm_{c[-1]}")
    ], axis=1).dropna()

    fa3 = FactorAnalyzer(n_factors=3, rotation="oblimin")
    fa3.fit(all_items)

    loadings3 = pd.DataFrame(
        fa3.loadings_,
        index   = all_items.columns,
        columns = ["F1", "F2", "F3"]
    ).round(3)
    print("\n3-Factor EFA across all attitude domains:")
    print(loadings3)

    # Factor scores from 1-factor model
    factor_scores = fa.transform(items_complete)
    ces.loc[items_complete.index, "imm_factor_score"] = factor_scores[:, 0]

    print(f"\nFactor score summary:")
    print(ces["imm_factor_score"].describe().round(3))

    # Factor score vs. simple mean
    corr = ces[["imm_factor_score","imm_scale_mean"]].dropna().corr()
    print(f"\nFactor score × scale mean correlation: {corr.iloc[0,1]:.3f}")

except ImportError:
    print("\n(pip install factor_analyzer for EFA)")


# ==============================================================================
# SECTION 5: PRINCIPAL COMPONENTS ANALYSIS (PCA) WITH SKLEARN
# ==============================================================================

# sklearn's PCA requires complete data — drop NaN first
items_pca = imm_items.dropna()
scaler    = StandardScaler()
X_scaled  = scaler.fit_transform(items_pca)

pca = PCA(n_components=5)
pca.fit(X_scaled)

# Variance explained
var_exp = pd.DataFrame({
    "component":       range(1, 6),
    "eigenvalue":      pca.explained_variance_,
    "pct_explained":   pca.explained_variance_ratio_ * 100,
    "cumulative_pct":  np.cumsum(pca.explained_variance_ratio_) * 100,
}).round(3)

print("\nPCA Variance Explained:")
print(var_exp)

# Scree plot
plt.figure(figsize=(7, 4))
plt.bar(var_exp["component"], var_exp["pct_explained"], alpha=0.7, color="navy")
plt.axhline(20, color="red", linestyle="--", label="Reference line")
plt.xlabel("Principal Component")
plt.ylabel("% Variance Explained")
plt.title("Scree Plot: Immigration Items (PCA)")
plt.legend()
plt.tight_layout()
plt.savefig("pca_scree_immigration.png", dpi=300)
plt.close()

# Loadings (components × items)
loadings_pca = pd.DataFrame(
    pca.components_.T,
    index   = items_pca.columns,
    columns = [f"PC{i}" for i in range(1, 6)]
).round(3)

print("\nPCA Loadings:")
print(loadings_pca)

# PC1 scores
pca_1comp = PCA(n_components=1)
pc1_scores = pca_1comp.fit_transform(X_scaled).flatten()
ces.loc[items_pca.index, "pc1_imm"] = pc1_scores

# Compare PC1 to factor score
if "imm_factor_score" in ces.columns:
    corr_pca = ces[["pc1_imm", "imm_factor_score"]].dropna().corr()
    print(f"\nPC1 × factor score correlation: {corr_pca.iloc[0,1]:.3f}")


# ==============================================================================
# SECTION 6: POLYCHORIC CORRELATION (FOR ORDINAL ITEMS)
# ==============================================================================

# For binary or ordinal items, the Pearson correlation underestimates the
# true latent correlation. Polychoric correlation is more appropriate.
# The 'pingouin' package provides this.

try:
    import pingouin as pg
    # Polychoric between imm_item1 and imm_item2
    pc = pg.corr(
        x   = imm_items["imm_item1"].dropna(),
        y   = imm_items["imm_item2"].dropna(),
        method = "pearson"    # pingouin doesn't have polychoric built-in;
                               # use factor_analyzer's correlation matrix instead
    )
    print("\nPearson r — item1 × item2:")
    print(pc[["r","p-val"]].round(3))
except ImportError:
    pass


# ==============================================================================
# SECTION 7: SCALE INTER-CORRELATIONS
# ==============================================================================

# The three scales should be positively correlated (they all tap left-right ideology)
# but not perfectly (they measure distinct policy domains)

scale_corr = ces[["imm_scale_mean","gun_scale_mean","climate_scale_mean",
                   "ideology5"]].dropna().corr()

print("\nScale inter-correlations:")
print(scale_corr.round(3))

# Heatmap
fig, ax = plt.subplots(figsize=(6, 5))
sns.heatmap(
    scale_corr,
    annot      = True,
    fmt        = ".2f",
    cmap       = "RdBu_r",
    center     = 0,
    vmin       = -1,
    vmax       = 1,
    linewidths = 0.5,
    ax         = ax,
)
ax.set_title("Scale Inter-Correlations")
plt.tight_layout()
plt.savefig("scale_intercorrelations.png", dpi=300)
plt.close()


# ==============================================================================
# SECTION 8: SAVE DATASET WITH SCALES
# ==============================================================================

drop_cols = [c for c in ces.columns if "_item" in c]
ces = ces.drop(columns=drop_cols)

ces.to_parquet("CES2020_with_scales.parquet", index=False)
print("\nModule 11 complete. Dataset with scales saved.")
