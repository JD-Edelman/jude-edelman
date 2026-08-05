# OLS Regression: Intuition

## What Problem It Solves

You have an outcome you want to explain (immigration restrictionism, vote choice, income) and multiple predictors measured on the same people. OLS draws the best-fitting linear surface through that cloud of points and tells you how much each predictor is associated with the outcome, holding all others constant.

---

## When to Reach for OLS

**Reach for it when:**
- The outcome is continuous or near-continuous (ideology on a 1-5 scale, income in dollars, test scores)
- You want a single coefficient that summarizes the relationship in original units
- Your research question is about association or prediction, not causation (though OLS is also the backbone of many causal designs: DiD, IV, RD all deliver estimates through regression)

**Do not reach for it when:**
- The outcome is binary (use logit/probit; see Module 04)
- The outcome is a count with many zeros (use Poisson or negative binomial)
- You have only 10-20 observations and strongly non-normal errors (the t-tests rely on large-n approximations)
- The outcome is bounded and most observations pile up at the boundary (proportion data near 0 or 1: use fractional logit)

---

## How It Works

OLS finds the line (or hyperplane, with multiple predictors) that minimizes the sum of squared vertical distances between the observed outcome values and the line's predictions. "Squared" rather than absolute distances: squaring penalizes large errors more than small ones, which gives the method its nice algebraic properties, and it makes the solution unique.

The coefficient on predictor X tells you: on average, a one-unit increase in X is associated with a β-unit change in the outcome, holding all other predictors in the model constant. That "holding constant" part is what makes regression useful: it lets you isolate one relationship while statistically adjusting for others.

---

## Standard Errors and Why They Matter

The coefficient estimate β̂ is a random variable; it would take a different value in a different sample. The standard error measures how much it would vary. Two flavors matter here:

- **Default (homoskedastic) SEs**: assume the spread of errors is the same at every value of X. Almost never literally true in social science data.
- **Robust (HC3) SEs**: no assumption about error spread; valid even with heteroskedasticity. Use these by default.
- **Clustered SEs**: when observations share a common context (respondents in the same state), errors within clusters are correlated. Clustered SEs account for this. Ignoring clustering can dramatically understate uncertainty.

---

## What R² Tells You (and Doesn't)

R² is the proportion of outcome variance explained by the model. An R² of 0.30 means 30% of the variation in the outcome is accounted for by the predictors.

R² does **not** tell you:
- Whether the relationships are causal
- Whether the model is correctly specified
- Whether any particular coefficient is meaningful

R² mechanically increases whenever you add a predictor, even a useless one. Adjusted R² penalizes for that. Neither measure is a stand-in for theoretical justification.

---

## Strengths vs. Alternatives

| Method | When OLS wins | When the alternative wins |
|--------|---------------|--------------------------|
| Logit/probit | Outcome is continuous | Outcome is binary |
| Weighted OLS | Homogeneous sample | Complex survey data (Module 05) |
| Fixed effects (Module 12) | Time-invariant confounders are not a concern | You need to control for all unobserved individual-level factors |
| Ridge/Lasso | Low-dimensional, interpretable model needed | Many correlated predictors, prediction is the goal |

OLS is the workhorse of applied social science not because it is always optimal, but because its assumptions are transparent, its output is interpretable in original units, and decades of applied work make its limitations well-understood.
