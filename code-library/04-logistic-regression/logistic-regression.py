# ==============================================================================
#  MODULE 4: LOGISTIC REGRESSION
#  Dataset: CES 2020 (cleaned in Module 1)
#
#  Stack: statsmodels (logit/probit), sklearn (ROC/AUC), matplotlib
# ==============================================================================

import pandas as pd
import numpy as np
import statsmodels.formula.api as smf
import statsmodels.api as sm
import matplotlib.pyplot as plt
from scipy import stats
from sklearn.metrics import roc_curve, auc, classification_report, confusion_matrix

ces = pd.read_parquet("CES2020_clean.parquet")


# ==============================================================================
# SECTION 1: SIMPLE LOGIT — DID RESPONDENT VOTE?
# ==============================================================================

# smf.logit() uses the same formula syntax as smf.ols().
# family = Binomial with logit link is the default.
# fit() returns a LogitResults object with the same summary() interface.

m_voted_simple = smf.logit("voted ~ education", data=ces).fit()
print(m_voted_simple.summary())

# Coefficients are in LOG-ODDS units.
# Use np.exp() to convert to odds ratios.


# ==============================================================================
# SECTION 2: ODDS RATIOS
# ==============================================================================

def odds_ratio_table(result):
    """Return a DataFrame with ORs and 95% CIs."""
    coefs = result.params
    conf  = result.conf_int()
    pvals = result.pvalues

    or_df = pd.DataFrame({
        "OR":       np.exp(coefs),
        "CI_low":   np.exp(conf[0]),
        "CI_high":  np.exp(conf[1]),
        "p_value":  pvals,
    }).round(4)

    or_df["sig"] = or_df["p_value"].apply(
        lambda p: "***" if p < .001 else "**" if p < .01 else "*" if p < .05 else ""
    )
    return or_df

print("\nOdds Ratios — Simple Turnout Model:")
print(odds_ratio_table(m_voted_simple))


# ==============================================================================
# SECTION 3: FULL TURNOUT MODEL
# ==============================================================================

m_voted_full = smf.logit(
    "voted ~ education + age + C(sex) + C(census_region) "
    "+ ideology5 + party_id7 + college + white_nh + imm_restrict + econ_retro",
    data=ces
).fit(cov_type="HC3")

print(m_voted_full.summary())
print("\nORs — Full Turnout Model:")
print(odds_ratio_table(m_voted_full))


# ==============================================================================
# SECTION 4: BIDEN VOTE CHOICE (VOTERS ONLY)
# ==============================================================================

ces_voters = ces[(ces["voted"] == 1) & ces["biden_voter"].notna()].copy()

m_biden = smf.logit(
    "biden_voter ~ education + age + C(sex) + C(census_region) "
    "+ ideology5 + party_id7 + college + white_nh + imm_restrict + econ_retro",
    data=ces_voters
).fit(cov_type="HC3")

print("\nBiden Vote Choice — ORs:")
print(odds_ratio_table(m_biden))


# ==============================================================================
# SECTION 5: AVERAGE MARGINAL EFFECTS (AME)
# ==============================================================================

# statsmodels computes marginal effects via .get_margeff()
# at="overall" = average marginal effect (AME) — averaged across all observations
# at="mean"    = marginal effect at the mean (MEM)
# method="dydx" = derivative (change in probability per unit change in X)

m_base = smf.logit(
    "voted ~ education + age + C(sex) + ideology5 + party_id7",
    data=ces
).fit(disp=False)

me = m_base.get_margeff(at="overall", method="dydx")
print(me.summary())

# The "dy/dx" column shows: on average, a 1-unit increase in X is associated
# with this many percentage points change in Pr(voted=1).


# ==============================================================================
# SECTION 6: PREDICTED PROBABILITIES AT SPECIFIC VALUES
# ==============================================================================

# Build a prediction grid: vary education from 1-6, hold others at their mean
pred_grid = pd.DataFrame({
    "education":    range(1, 7),
    "age":          ces["age"].mean(),
    "sex":          1,
    "ideology5":    ces["ideology5"].mean(),
    "party_id7":    ces["party_id7"].mean(),
})

pred_grid["pr_voted"] = m_base.predict(pred_grid)

# Confidence intervals via delta method (manual)
# For clean CIs use the margins approach or bootstrap

print("\nPredicted Pr(voted) by education:")
print(pred_grid[["education", "pr_voted"]].round(3))

# Plot
plt.figure(figsize=(8, 5))
plt.plot(pred_grid["education"], pred_grid["pr_voted"],
         color="navy", linewidth=2, marker="o")
plt.xticks(range(1, 7),
           ["No HS", "HS grad", "Some coll.", "Assoc.", "Bach.", "Postgrad"])
plt.xlabel("Education Level")
plt.ylabel("Pr(Voted)")
plt.title("Predicted Probability of Voting by Education")
plt.ylim(0, 1)
plt.grid(alpha=0.3)
plt.tight_layout()
plt.savefig("pred_prob_voted_educ.png", dpi=300)
plt.close()


# ==============================================================================
# SECTION 7: PREDICTED PROBABILITY BY SEX AND EDUCATION
# ==============================================================================

from itertools import product

grid = pd.DataFrame(
    list(product(range(1, 7), [1, 2])),
    columns=["education", "sex"]
)
grid["age"]       = ces["age"].mean()
grid["ideology5"] = ces["ideology5"].mean()
grid["party_id7"] = ces["party_id7"].mean()

m_interact = smf.logit(
    "voted ~ education * C(sex) + age + ideology5",
    data=ces
).fit(disp=False)

grid["pr_voted"] = m_interact.predict(grid)

fig, ax = plt.subplots(figsize=(8, 5))
for sex_val, label, color in [(1, "Male", "navy"), (2, "Female", "firebrick")]:
    sub = grid[grid["sex"] == sex_val]
    ax.plot(sub["education"], sub["pr_voted"],
            color=color, label=label, linewidth=2, marker="o")

ax.set_xticks(range(1, 7))
ax.set_xticklabels(["No HS","HS","Some coll.","Assoc.","Bach.","Postgrad"])
ax.set_xlabel("Education Level")
ax.set_ylabel("Pr(Voted)")
ax.set_title("Predicted Pr(Voted) by Education and Sex")
ax.legend()
ax.set_ylim(0, 1)
plt.tight_layout()
plt.savefig("pred_prob_voted_sex.png", dpi=300)
plt.close()


# ==============================================================================
# SECTION 8: GOODNESS OF FIT
# ==============================================================================

# McFadden's pseudo R-squared
# = 1 - (log-likelihood of full / log-likelihood of null)

null_model = smf.logit("voted ~ 1", data=ces).fit(disp=False)
pseudo_r2  = 1 - (m_voted_full.llf / null_model.llf)
print(f"\nMcFadden pseudo R2: {pseudo_r2:.3f}")

# AIC and BIC
print(f"AIC: {m_voted_full.aic:.1f}")
print(f"BIC: {m_voted_full.bic:.1f}")

# Classification table at 0.5 threshold
y_true = m_voted_full.model.endog
y_pred = (m_voted_full.predict() > 0.5).astype(int)

print("\nClassification Report:")
print(classification_report(y_true, y_pred, target_names=["Did not vote", "Voted"]))

cm = confusion_matrix(y_true, y_pred)
print("Confusion matrix:\n", cm)

accuracy = (y_pred == y_true).mean()
print(f"Accuracy: {accuracy:.3f}")


# ==============================================================================
# SECTION 9: ROC CURVE AND AUC
# ==============================================================================

y_prob = m_voted_full.predict()
fpr, tpr, thresholds = roc_curve(y_true, y_prob)
roc_auc = auc(fpr, tpr)

print(f"\nAUC: {roc_auc:.3f}")
# AUC > 0.7 = acceptable; > 0.8 = excellent

plt.figure(figsize=(7, 6))
plt.plot(fpr, tpr, color="navy", linewidth=2,
         label=f"ROC Curve (AUC = {roc_auc:.3f})")
plt.plot([0, 1], [0, 1], color="gray", linestyle="--", label="Random (AUC = 0.5)")
plt.xlabel("False Positive Rate (1 - Specificity)")
plt.ylabel("True Positive Rate (Sensitivity)")
plt.title("ROC Curve: Voter Turnout Logit Model")
plt.legend()
plt.tight_layout()
plt.savefig("roc_turnout.png", dpi=300)
plt.close()


# ==============================================================================
# SECTION 10: PROBIT AS ALTERNATIVE
# ==============================================================================

m_probit = smf.probit(
    "voted ~ education + age + C(sex) + ideology5 + party_id7",
    data=ces
).fit(disp=False)

print(m_probit.summary())

# AMEs from probit — should be similar to logit AMEs
me_probit = m_probit.get_margeff(at="overall")
print(me_probit.summary())


# ==============================================================================
# SECTION 11: SIDE-BY-SIDE RESULTS TABLE
# ==============================================================================

l1 = smf.logit("voted ~ education + age + C(sex) + ideology5", data=ces).fit(disp=False)
l2 = smf.logit("voted ~ education + age + C(sex) + ideology5 + party_id7 + college", data=ces).fit(disp=False)
l3 = smf.logit("voted ~ education + age + C(sex) + ideology5 + party_id7 + college + white_nh + imm_restrict", data=ces).fit(disp=False)

for name, m in [("Model 1", l1), ("Model 2", l2), ("Model 3", l3)]:
    print(f"\n{name}  —  AIC={m.aic:.0f}  N={int(m.nobs)}")
    print(odds_ratio_table(m).to_string())

print("\nModule 4 complete.")
