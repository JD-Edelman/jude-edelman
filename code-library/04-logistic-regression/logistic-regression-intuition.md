# Logistic Regression: Intuition

## What Problem It Solves

When the outcome is binary (voted / did not vote; college degree / no degree), OLS can predict values below 0 or above 1 -- meaningless as probabilities. Logistic regression constrains predictions to (0, 1) and models the relationship on the log-odds scale, which is unbounded and linear in the predictors.

---

## When to Reach for It

**Reach for it when:**
- The outcome has exactly two categories: yes/no, survived/died, voted/abstained
- You want to make probabilistic statements ("the predicted probability of voting rises by X points")
- Sample size is large enough for maximum likelihood to be reliable (rough rule: ≥ 10 events per predictor)

**Do not reach for it when:**
- The outcome has more than two ordered categories (use ordered logit/probit)
- The outcome has more than two unordered categories (use multinomial logit)
- Complete separation exists (see below)
- The outcome is continuous or near-continuous (OLS is more interpretable)

---

## Odds and Log-Odds

An **odds** is the ratio of the probability of an event to the probability of it not occurring: odds = p/(1-p). If p = 0.75, odds = 3 (three times as likely to happen as not).

A **log-odds** (logit) is the natural log of the odds: logit(p) = log[p/(1-p)]. Log-odds range from -∞ to +∞, making them suitable for a linear model. Logistic regression models:

  log[p/(1-p)] = β₀ + β₁X₁ + β₂X₂ + ...

The exponential of a coefficient gives an **odds ratio**: OR = exp(β₁). An OR of 1.5 means the odds of the event are 1.5 times higher for a one-unit increase in X₁, holding other variables constant.

---

## Interpreting Coefficients

Odds ratios are multiplicative and asymmetric: OR = 2.0 does not mean the outcome is "twice as common," it means the *odds* doubled. For rare outcomes (p < 10%), the odds ratio approximates the relative risk. For common outcomes, it overstates the relative risk.

**Average marginal effects (AMEs)** are often preferred for substantive interpretation. An AME for X₁ says: on average across the sample, a one-unit increase in X₁ is associated with a β_AME percentage-point change in the predicted probability. This is in the same units as a linear probability model coefficient, making it easier to communicate.

---

## Model Fit

- **Pseudo-R²** (McFadden's): 1 - ℓ_full/ℓ_null where ℓ is the log-likelihood. Values of 0.2-0.4 indicate good fit, but pseudo-R² is not comparable across datasets.
- **AUC**: area under the ROC curve. Ranges from 0.5 (no better than chance) to 1.0 (perfect discrimination). Measures the model's ability to rank cases correctly, regardless of threshold.
- **Hosmer-Lemeshow test**: divides predicted probabilities into deciles and tests whether observed event rates match predicted rates. A non-significant result indicates adequate fit.

---

## The Separation Problem

**Complete separation** occurs when some linear combination of predictors perfectly predicts the outcome (every Democrat voted, no Republican did, with zero overlap). When this happens, the maximum likelihood estimator for the separated variable does not exist: the algorithm pushes the coefficient toward ±∞. Solutions include Firth's penalized likelihood or dropping/recoding the offending variable.

---

## Probit vs. Logit

Both model a binary outcome by linking a linear predictor to a probability through an S-shaped function. Logit uses the logistic (sigmoid) function; probit uses the normal CDF. Substantive results are almost identical after rescaling (logit coefficient / 1.6 ≈ probit coefficient). The choice is usually disciplinary convention; logit produces odds ratios, which are easier to communicate in sociology and epidemiology.

---

## Strengths vs. Alternatives

| Method | When logit wins | When the alternative wins |
|--------|-----------------|--------------------------|
| OLS (linear probability model) | Clean probabilistic predictions needed | Quick approximation, rarely predicted probabilities near 0/1 |
| Probit | Any; results nearly identical | Probit is theoretically motivated by latent normal variable |
| Ordered logit (Module 04 extension) | Binary outcome | Outcome has 3+ ordered categories |
| Fixed effects logit | Cross-sectional | Panel with binary outcome (incidental parameters problem) |
