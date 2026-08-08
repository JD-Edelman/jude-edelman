# ==============================================================================
#  MODULE 6: DATA VISUALIZATION WITH MATPLOTLIB & SEABORN
#  Dataset: CES 2020 (cleaned in Module 1)
#
#  Stack: matplotlib (base), seaborn (statistical graphics)
#
#  seaborn is built on matplotlib and provides high-level statistical plots
#  with sensible defaults. Use seaborn for most plots; drop to matplotlib
#  when you need fine-grained control.
# ==============================================================================

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.ticker as mtick
import seaborn as sns
import statsmodels.formula.api as smf

ces = pd.read_parquet("CES2020_clean.parquet")

# Set global style
sns.set_theme(style="whitegrid", palette="deep", font_scale=1.1)
plt.rcParams["figure.dpi"] = 150


# ==============================================================================
# SECTION 1: HISTOGRAM — CONTINUOUS VARIABLE
# ==============================================================================

fig, ax = plt.subplots(figsize=(9, 5))

sns.histplot(
    ces["age"].dropna(),
    bins   = 30,
    color  = "navy",
    alpha  = 0.8,
    kde    = True,         # overlay kernel density estimate
    ax     = ax,
)

ax.set_xlabel("Age")
ax.set_ylabel("Count")
ax.set_title("Age Distribution of CES 2020 Respondents")
plt.tight_layout()
plt.savefig("hist_age.png", dpi=300)
plt.close()

# Immigration restrictionism (discrete — use countplot)
fig, ax = plt.subplots(figsize=(8, 5))
sns.countplot(
    x      = ces["imm_restrict"].dropna().astype(int),
    color  = "darkgreen",
    alpha  = 0.8,
    ax     = ax,
)
ax.set_xlabel("Restrictionism Score (0 = Least, 5 = Most)")
ax.set_ylabel("Count")
ax.set_title("Immigration Restrictionism Index")
plt.tight_layout()
plt.savefig("hist_imm_restrict.png", dpi=300)
plt.close()


# ==============================================================================
# SECTION 2: BAR CHARTS — PROPORTIONS WITH ERROR BARS
# ==============================================================================

# Compute proportions and standard errors per education level
voted_by_educ = (
    ces.dropna(subset=["voted", "education"])
    .groupby("education")["voted"]
    .agg(["mean", "count"])
    .reset_index()
    .rename(columns={"mean": "prop_voted", "count": "n"})
)
voted_by_educ["se"] = np.sqrt(
    voted_by_educ["prop_voted"] * (1 - voted_by_educ["prop_voted"])
    / voted_by_educ["n"]
)

fig, ax = plt.subplots(figsize=(9, 5))
ax.bar(voted_by_educ["education"], voted_by_educ["prop_voted"],
       color="navy", alpha=0.8)
ax.errorbar(voted_by_educ["education"], voted_by_educ["prop_voted"],
            yerr=1.96 * voted_by_educ["se"],
            fmt="none", color="gray", capsize=4)
ax.axhline(0.5, color="red", linestyle="--", linewidth=1)
ax.set_xticks(range(1, 7))
ax.set_xticklabels(["No HS","HS grad","Some coll.","Assoc.","Bach.","Postgrad"])
ax.yaxis.set_major_formatter(mtick.PercentFormatter(xmax=1))
ax.set_xlabel("Education Level")
ax.set_ylabel("Proportion Who Voted")
ax.set_title("Voter Turnout by Education Level")
plt.tight_layout()
plt.savefig("bar_voted_by_educ.png", dpi=300)
plt.close()

# Biden vote share by party
biden_by_party = (
    ces[(ces["voted"] == 1) & ces["biden_voter"].notna() & ces["party_id3"].notna()]
    .groupby("party_id3")["biden_voter"]
    .mean()
    .reset_index()
)

party_labels = {1: "Democrat", 2: "Republican", 3: "Independent"}
party_colors = {1: "blue", 2: "red", 3: "darkgreen"}

fig, ax = plt.subplots(figsize=(7, 5))
bars = ax.bar(
    [party_labels[p] for p in biden_by_party["party_id3"]],
    biden_by_party["biden_voter"],
    color=[party_colors[p] for p in biden_by_party["party_id3"]],
    alpha=0.85
)
for bar, val in zip(bars, biden_by_party["biden_voter"]):
    ax.text(bar.get_x() + bar.get_width() / 2, val + 0.01,
            f"{val:.0%}", ha="center", va="bottom", fontsize=11)

ax.axhline(0.5, color="gray", linestyle="--", linewidth=1)
ax.yaxis.set_major_formatter(mtick.PercentFormatter(xmax=1))
ax.set_ylim(0, 1.1)
ax.set_ylabel("Proportion Voting Biden")
ax.set_title("Biden Vote Share by Party ID (Voters Only)")
plt.tight_layout()
plt.savefig("bar_biden_by_party.png", dpi=300)
plt.close()


# ==============================================================================
# SECTION 3: BOX PLOTS
# ==============================================================================

fig, axes = plt.subplots(1, 2, figsize=(13, 5))

# Restrictionism by party
valid = ces.dropna(subset=["imm_restrict", "party_id3"]).copy()
valid["party_id3"] = valid["party_id3"].astype(int)
party_order = [1, 2, 3]
party_names = {1: "Democrat", 2: "Republican", 3: "Independent"}
party_palette = {1: "steelblue", 2: "firebrick", 3: "darkgreen"}

sns.boxplot(
    data      = valid,
    x         = "party_id3",
    y         = "imm_restrict",
    order     = party_order,
    hue       = "party_id3",
    hue_order = party_order,
    palette   = party_palette,
    legend    = False,
    ax        = axes[0],
)
axes[0].set_xticklabels([party_names[p] for p in party_order])
axes[0].set_xlabel("Party ID")
axes[0].set_ylabel("Restrictionism (0–5)")
axes[0].set_title("Immigration Restrictionism by Party")

# Age by voter turnout
voted_valid = ces.dropna(subset=["age", "voted"]).copy()
voted_valid["voted"] = voted_valid["voted"].astype(int)
sns.boxplot(
    data      = voted_valid,
    x         = "voted",
    y         = "age",
    hue       = "voted",
    palette   = {0: "gray", 1: "navy"},
    legend    = False,
    ax        = axes[1],
)
axes[1].set_xticklabels(["Did Not Vote", "Voted"])
axes[1].set_xlabel("")
axes[1].set_ylabel("Age")
axes[1].set_title("Age by Voter Turnout")

plt.tight_layout()
plt.savefig("boxplots.png", dpi=300)
plt.close()


# ==============================================================================
# SECTION 4: SCATTER PLOT WITH FITTED LINE
# ==============================================================================

fig, axes = plt.subplots(1, 2, figsize=(13, 5))

# Age vs. restrictionism
_pool = ces[["age", "imm_restrict"]].dropna()
sample = _pool.sample(min(5000, len(_pool)), random_state=1)

axes[0].scatter(sample["age"], sample["imm_restrict"],
                alpha=0.1, s=5, color="navy")
# Overlay OLS line
m = smf.ols("imm_restrict ~ age", data=sample).fit()
x_line = np.linspace(sample["age"].min(), sample["age"].max(), 100)
axes[0].plot(x_line, m.params["Intercept"] + m.params["age"] * x_line,
             color="red", linewidth=2)
axes[0].set_xlabel("Age")
axes[0].set_ylabel("Restrictionism (0–5)")
axes[0].set_title("Age and Immigration Restrictionism")

# Education vs. ideology (loess-style via seaborn lowess)
_pool2 = ces[["education", "ideology5"]].dropna()
sample2 = _pool2.sample(min(5000, len(_pool2)), random_state=2)
axes[1].scatter(sample2["education"] + np.random.uniform(-0.2, 0.2, len(sample2)),
                sample2["ideology5"]  + np.random.uniform(-0.2, 0.2, len(sample2)),
                alpha=0.05, s=3, color="darkgreen")

sns.regplot(data=sample2, x="education", y="ideology5",
            scatter=False, lowess=True,
            line_kws={"color": "orange", "linewidth": 2},
            ax=axes[1])
axes[1].set_xlabel("Education Level")
axes[1].set_ylabel("Ideology (1=Liberal, 5=Conservative)")
axes[1].set_title("Education and Ideology (LOWESS)")

plt.tight_layout()
plt.savefig("scatter_plots.png", dpi=300)
plt.close()


# ==============================================================================
# SECTION 5: COEFFICIENT PLOT (FOREST PLOT)
# ==============================================================================

import statsmodels.formula.api as smf

m_turnout = smf.logit(
    "voted ~ education + age + C(sex) + C(census_region) + ideology5 + party_id7",
    data=ces
).fit(disp=False)

coef  = m_turnout.params.drop("Intercept")
ci    = m_turnout.conf_int().drop("Intercept")
pvals = m_turnout.pvalues.drop("Intercept")

coef_df = pd.DataFrame({
    "coef":    coef,
    "ci_low":  ci[0],
    "ci_high": ci[1],
    "sig":     pvals < 0.05,
}).reset_index().rename(columns={"index": "term"})

# Clean up term labels
term_labels = {
    "education":                "Education",
    "age":                      "Age",
    "C(sex)[T.2]":              "Female",
    "C(census_region)[T.2]":    "Midwest",
    "C(census_region)[T.3]":    "South",
    "C(census_region)[T.4]":    "West",
    "ideology5":                "Ideology",
    "party_id7":                "Party ID",
}
coef_df["label"] = coef_df["term"].map(term_labels).fillna(coef_df["term"])
coef_df = coef_df.sort_values("coef")

fig, ax = plt.subplots(figsize=(9, 6))

# errorbar doesn't accept per-point color arrays — draw each term separately
for i, (_, row) in enumerate(coef_df.iterrows()):
    c = "navy" if row["sig"] else "gray"
    ax.errorbar(
        x    = row["coef"],
        y    = i,
        xerr = [[row["coef"] - row["ci_low"]], [row["ci_high"] - row["coef"]]],
        fmt       = "o",
        color     = c,
        ecolor    = c,
        capsize   = 4,
        linewidth = 1.5,
    )
ax.axvline(0, color="gray", linestyle="--", linewidth=1)
ax.set_yticks(range(len(coef_df)))
ax.set_yticklabels(coef_df["label"])
ax.set_xlabel("Log-Odds Coefficient (95% CI)")
ax.set_title("Logit Coefficients: Voter Turnout Model")
plt.tight_layout()
plt.savefig("coefplot_turnout.png", dpi=300)
plt.close()


# ==============================================================================
# SECTION 6: PREDICTED PROBABILITY PLOT
# ==============================================================================

from itertools import product

m_pred = smf.logit(
    "voted ~ education + age + C(sex) + ideology5 + party_id7",
    data=ces
).fit(disp=False)

grid = pd.DataFrame(
    list(product(range(1, 7), [1, 2])),
    columns=["education", "sex"]
)
grid["age"]       = ces["age"].mean()
grid["ideology5"] = ces["ideology5"].mean()
grid["party_id7"] = ces["party_id7"].mean()
grid["pr_voted"]  = m_pred.predict(grid)

fig, ax = plt.subplots(figsize=(9, 5))
for sex_val, label, color in [(1, "Male", "navy"), (2, "Female", "firebrick")]:
    sub = grid[grid["sex"] == sex_val]
    ax.plot(sub["education"], sub["pr_voted"],
            color=color, label=label, linewidth=2, marker="o")

ax.set_xticks(range(1, 7))
ax.set_xticklabels(["No HS","HS","Some coll.","Assoc.","Bach.","Postgrad"])
ax.yaxis.set_major_formatter(mtick.PercentFormatter(xmax=1))
ax.set_xlabel("Education Level")
ax.set_ylabel("Pr(Voted)")
ax.set_title("Predicted Probability of Voting by Education and Sex")
ax.legend()
ax.set_ylim(0, 1)
plt.tight_layout()
plt.savefig("pred_prob_voted.png", dpi=300)
plt.close()


# ==============================================================================
# SECTION 7: PROFILE PLOT (GROUP MEANS OVER A COVARIATE)
# ==============================================================================

profile = (
    ces.dropna(subset=["imm_restrict", "education", "party_id3"])
    .groupby(["education", "party_id3"])["imm_restrict"]
    .agg(["mean", "sem"])
    .reset_index()
    .rename(columns={"mean": "mean_restrict", "sem": "se"})
)

fig, ax = plt.subplots(figsize=(9, 5))
colors_party = {1: "blue", 2: "red", 3: "darkgreen"}
labels_party = {1: "Democrat", 2: "Republican", 3: "Independent"}

for pid, grp in profile.groupby("party_id3"):
    ax.plot(grp["education"], grp["mean_restrict"],
            color=colors_party[pid], label=labels_party[pid],
            linewidth=2, marker="o")
    ax.fill_between(grp["education"],
                    grp["mean_restrict"] - 1.96 * grp["se"],
                    grp["mean_restrict"] + 1.96 * grp["se"],
                    color=colors_party[pid], alpha=0.1)

ax.axhline(2.5, color="gray", linestyle="--", linewidth=1)
ax.set_xticks(range(1, 7))
ax.set_xticklabels(["No HS","HS","Some coll.","Assoc.","Bach.","Postgrad"])
ax.set_xlabel("Education Level")
ax.set_ylabel("Mean Restrictionism (0–5)")
ax.set_title("Immigration Restrictionism by Education and Party")
ax.legend(title="Party ID")
plt.tight_layout()
plt.savefig("profile_restrict_educ_party.png", dpi=300)
plt.close()


# ==============================================================================
# SECTION 8: FACETED PLOTS (SMALL MULTIPLES)
# ==============================================================================

# seaborn's FacetGrid creates small multiples
biden_educ_region = (
    ces[(ces["voted"] == 1) & ces["biden_voter"].notna()
        & ces["census_region"].notna() & ces["education"].notna()]
    .groupby(["census_region", "education"])["biden_voter"]
    .mean()
    .reset_index()
    .rename(columns={"biden_voter": "prop_biden"})
)

region_map = {1: "Northeast", 2: "Midwest", 3: "South", 4: "West"}
biden_educ_region["region"] = biden_educ_region["census_region"].map(region_map)

g = sns.FacetGrid(biden_educ_region, col="region", col_wrap=2,
                  height=4, aspect=1.2)
g.map(plt.bar, "education", "prop_biden", color="steelblue", alpha=0.8)
g.map(plt.axhline, y=0.5, color="red", linestyle="--", linewidth=1)
g.set_axis_labels("Education Level", "Prop. Voting Biden")
g.set_titles(col_template="{col_name}")
g.figure.suptitle("Biden Vote Share by Education, Faceted by Region",
                   y=1.02, fontsize=14)
plt.tight_layout()
plt.savefig("facet_biden_educ_region.png", dpi=300)
plt.close()


# ==============================================================================
# SECTION 9: COMBINING PLOTS WITH SUBPLOTS
# ==============================================================================

fig, axes = plt.subplots(1, 3, figsize=(15, 5))

# Age
axes[0].hist(ces["age"].dropna(), bins=25, color="navy", alpha=0.8, edgecolor="white")
axes[0].set_title("Age")
axes[0].set_xlabel("Age")

# Restrictionism
restrict_counts = ces["imm_restrict"].dropna().value_counts().sort_index()
axes[1].bar(restrict_counts.index.astype(int), restrict_counts.values,
            color="darkgreen", alpha=0.8, edgecolor="white")
axes[1].set_title("Restrictionism")
axes[1].set_xlabel("Score (0–5)")

# Ideology
ideo_counts = ces["ideology5"].dropna().value_counts().sort_index()
axes[2].bar(ideo_counts.index.astype(int), ideo_counts.values,
            color="firebrick", alpha=0.8, edgecolor="white")
axes[2].set_xticks([1, 2, 3, 4, 5])
axes[2].set_xticklabels(["V.Lib","Lib","Mod","Con","V.Con"])
axes[2].set_title("Ideology")
axes[2].set_xlabel("Self-Reported Ideology")

fig.suptitle("CES 2020: Key Variable Distributions", fontsize=14)
plt.tight_layout()
plt.savefig("combined_distributions.png", dpi=300)
plt.close()


# ==============================================================================
# SECTION 10: SEABORN HEATMAP — CORRELATION MATRIX
# ==============================================================================

corr_vars = ["age", "education", "ideology5", "imm_restrict",
             "econ_retro", "college", "biden_voter", "dem", "rep"]

corr_matrix = ces[corr_vars].corr()

fig, ax = plt.subplots(figsize=(9, 7))
mask = np.triu(np.ones_like(corr_matrix, dtype=bool))   # hide upper triangle

sns.heatmap(
    corr_matrix,
    mask       = mask,
    annot      = True,
    fmt        = ".2f",
    cmap       = "RdBu_r",
    center     = 0,
    vmin       = -1,
    vmax       = 1,
    linewidths = 0.5,
    ax         = ax,
)
ax.set_title("Correlation Matrix — Key CES 2020 Variables")
plt.tight_layout()
plt.savefig("heatmap_correlations.png", dpi=300)
plt.close()

print("Module 6 complete. Check your directory for .png files.")
