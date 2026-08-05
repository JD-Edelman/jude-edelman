# Module 15: Propensity Score Methods -- Math Reference

---

## Notation

- i: individual unit, i = 1, ..., n
- D_i ∈ {0, 1}: treatment indicator (1 = treated, 0 = control)
- X_i: vector of observed pre-treatment covariates for unit i
- Y_i: observed outcome
- Y_i(1): potential outcome for unit i if treated (may be counterfactual)
- Y_i(0): potential outcome for unit i if not treated (may be counterfactual)
- e(X_i): propensity score = P(D_i = 1 | X_i)
- ê(X_i): estimated propensity score
- E[·]: expectation over the population
- ⊥: statistical independence

---

## Part A: The potential outcomes framework

### Defining potential outcomes

For each unit i, define two potential outcomes:

- Y_i(1): the outcome unit i would exhibit if assigned to treatment
- Y_i(0): the outcome unit i would exhibit if assigned to control

Only one of these is ever observed. The **fundamental problem of causal inference** (Holland, 1986) is that we cannot observe both simultaneously for the same unit.

The observed outcome links to the treatment indicator via the **consistency assumption** (also called SUTVA, the stable unit treatment value assumption -- no interference between units, and treatment is well-defined):

Y_i = D_i · Y_i(1) + (1 - D_i) · Y_i(0)

If D_i = 1, we observe Y_i(1). If D_i = 0, we observe Y_i(0). The other potential outcome is the **counterfactual** and remains unobserved.

### Average treatment effects

The **average treatment effect (ATE)** is the average causal effect for the entire population:

ATE = E[Y_i(1) - Y_i(0)]
    = E[Y_i(1)] - E[Y_i(0)]

The **average treatment effect on the treated (ATT)** conditions on being in the treated group:

ATT = E[Y_i(1) - Y_i(0) | D_i = 1]
    = E[Y_i(1) | D_i = 1] - E[Y_i(0) | D_i = 1]

The first term, E[Y_i(1) | D_i = 1], is directly observed: it's just the average outcome among treated units. The second term, E[Y_i(0) | D_i = 1], is counterfactual: what would the treated units' outcomes have been without treatment? This is the quantity we cannot observe and must estimate.

---

## Part B: The selection problem

### Why naive comparison fails

Define the naive estimator as the simple difference in observed means:

Δ_naive = E[Y_i | D_i = 1] - E[Y_i | D_i = 0]

Expand each term using the consistency assumption:

E[Y_i | D_i = 1] = E[Y_i(1) | D_i = 1]
E[Y_i | D_i = 0] = E[Y_i(0) | D_i = 0]

So:

Δ_naive = E[Y_i(1) | D_i = 1] - E[Y_i(0) | D_i = 0]

Add and subtract E[Y_i(0) | D_i = 1] (the counterfactual mean for treated units):

Δ_naive = [E[Y_i(1) | D_i = 1] - E[Y_i(0) | D_i = 1]]
        + [E[Y_i(0) | D_i = 1] - E[Y_i(0) | D_i = 0]]

The first bracket is the ATT. The second bracket is the **selection bias**: the difference between treated and control units in their average untreated potential outcome. If people who receive treatment would have had better outcomes even without treatment (positive selection), selection bias is positive, and the naive estimator overstates the ATT.

Selection bias = E[Y_i(0) | D_i = 1] - E[Y_i(0) | D_i = 0]

This term is generally nonzero in observational data and cannot be estimated directly because Y_i(0) | D_i = 1 is counterfactual. Propensity score methods are designed to make this term vanish by creating a re-weighted or matched comparison group such that the distribution of X is the same in both groups.

---

## Part C: Unconfoundedness (strong ignorability)

### The key assumption

Propensity score methods require the following assumption (Rosenbaum and Rubin, 1983):

(Y_i(0), Y_i(1)) ⊥ D_i | X_i

In words: conditional on the observed covariates X_i, the treatment assignment is independent of the potential outcomes. Equivalently, within any stratum defined by X, treatment looks as good as random.

This assumption has many names: unconfoundedness, ignorability, conditional exchangeability, no unmeasured confounders. They all express the same thing: you have measured everything that jointly affects treatment selection and potential outcomes.

This assumption is **untestable**: Y_i(0) for treated units and Y_i(1) for control units are never observed, so you can never directly verify independence. It is a substantive judgment call, not a statistical one.

### Overlap (positivity)

A second required assumption is **overlap** (also called positivity or common support):

0 < P(D_i = 1 | X_i) < 1   for all X_i in the support of X

Every type of unit must have some positive probability of being either treated or untreated. If some units could only ever be treated (or only ever be untreated), we have no valid comparisons for those units and the estimator is undefined or undefined in the limit.

Together, unconfoundedness and positivity are called **strong ignorability**.

---

## Part D: The propensity score

### Definition

The propensity score is:

e(X_i) = P(D_i = 1 | X_i)

It is the probability of receiving treatment given observed covariates.

### The propensity score theorem (Rosenbaum and Rubin, 1983)

**Theorem:** If unconfoundedness holds given X, then it also holds given the propensity score e(X):

(Y_i(0), Y_i(1)) ⊥ D_i | X_i  implies  (Y_i(0), Y_i(1)) ⊥ D_i | e(X_i)

**Proof sketch.** We need to show that, conditional on e(X_i), treatment assignment provides no additional information about potential outcomes.

Consider P(D_i = 1 | X_i, e(X_i)). Since e(X_i) = P(D_i = 1 | X_i) is a deterministic function of X_i:

P(D_i = 1 | X_i, e(X_i)) = P(D_i = 1 | X_i) = e(X_i)

Now consider P(D_i = 1 | e(X_i)). By the law of iterated expectations:

P(D_i = 1 | e(X_i)) = E[D_i | e(X_i)]
                     = E[E[D_i | X_i] | e(X_i)]
                     = E[e(X_i) | e(X_i)]
                     = e(X_i)

So P(D_i = 1 | X_i, e(X_i)) = P(D_i = 1 | e(X_i)) = e(X_i). This means X_i provides no additional information about D_i once you know e(X_i). Combined with unconfoundedness given X_i, this implies unconfoundedness given e(X_i).

The practical payoff: instead of conditioning on a p-dimensional covariate vector X (which is infeasible for large p), you only need to condition on the one-dimensional scalar e(X). This is the balancing property of the propensity score.

### Estimation via logistic regression

In practice, e(X_i) is unknown and must be estimated. The standard approach is logistic regression:

P(D_i = 1 | X_i) = σ(X_i β) = 1 / (1 + exp(-X_i β))

where σ(·) is the logistic sigmoid function and β is estimated by maximizing the log-likelihood:

log L(β) = Σ_i [ D_i log σ(X_i β) + (1 - D_i) log(1 - σ(X_i β)) ]

The estimated propensity score is:

ê(X_i) = σ(X_i β̂) = 1 / (1 + exp(-X_i β̂))

**Important:** the propensity score model does not need to be the "true" model for the conditional treatment probability. What matters for identification is that the balance of covariates is achieved after weighting or matching, which you verify empirically via balance diagnostics -- not by assessing the propensity score model's predictive accuracy. A propensity score model with a mediocre AUC can still produce excellent balance.

---

## Part E: IPTW estimators

### Horvitz-Thompson IPTW estimator for ATE

The IPTW estimator of the ATE weights each observation by the inverse of its probability of receiving the treatment it actually received:

τ̂_ATE = (1/n) Σ_i [ D_i · Y_i / ê(X_i) - (1 - D_i) · Y_i / (1 - ê(X_i)) ]

### Unbiasedness proof (sketch, using iterated expectations)

Show that E[D_i · Y_i / e(X_i)] = E[Y_i(1)].

E[D_i · Y_i / e(X_i)] = E[ E[D_i · Y_i / e(X_i) | X_i] ]       (tower/LIE)

Inside the inner expectation, condition on X_i:

E[D_i · Y_i / e(X_i) | X_i] = (1/e(X_i)) · E[D_i · Y_i | X_i]

By consistency, D_i · Y_i = D_i · Y_i(1):

= (1/e(X_i)) · E[D_i · Y_i(1) | X_i]

By unconfoundedness, Y_i(1) ⊥ D_i | X_i, so:

= (1/e(X_i)) · E[D_i | X_i] · E[Y_i(1) | X_i]
= (1/e(X_i)) · e(X_i) · E[Y_i(1) | X_i]
= E[Y_i(1) | X_i]

Taking the outer expectation:

E[ E[Y_i(1) | X_i] ] = E[Y_i(1)]

By the same argument, E[(1 - D_i) · Y_i / (1 - e(X_i))] = E[Y_i(0)]. Therefore:

E[τ̂_ATE] = E[Y_i(1)] - E[Y_i(0)] = ATE

### IPTW for ATT

For the ATT, the target is E[Y(1) - Y(0) | D = 1]. The ATE weights are not appropriate here because they reweight toward the full population rather than the treated subpopulation. The ATT weights are:

w_i = D_i + (1 - D_i) · ê(X_i) / (1 - ê(X_i))

For treated units: w_i = 1 (no reweighting; they define the target population).
For control units: w_i = ê(X_i) / (1 - ê(X_i)), called the odds of treatment given X_i.

Controls with high propensity scores (who resemble treated units) are upweighted. Controls with low propensity scores are downweighted (they don't represent the treated population).

The ATT estimator is:

τ̂_ATT = [Σ_i D_i Y_i / n₁] - [Σ_i (1-D_i) w_i Y_i / Σ_i (1-D_i) w_i]

where n₁ = Σ_i D_i is the number of treated units.

### Normalized (Hajek) weights

The raw IPTW estimator (Horvitz-Thompson) can be unstable when propensity scores are near 0 or 1 because the weights 1/ê and 1/(1-ê) can be very large. A more stable variant normalizes the weights within each treatment group so they sum to 1:

For treated units: w̃_i = (1/ê(X_i)) / Σ_{D_i=1} (1/ê(X_i))
For control units: w̃_i = (1/(1-ê(X_i))) / Σ_{D_i=0} (1/(1-ê(X_i)))

This Hajek estimator has slightly higher bias but substantially lower variance than the Horvitz-Thompson estimator in finite samples with extreme weights.

---

## Part F: Standardized mean difference (SMD) for balance

### Definition

For a single covariate k, the SMD between treated and control groups is:

SMD_k = (X̄_k,treated - X̄_k,control) / √[ (s²_k,treated + s²_k,control) / 2 ]

where:
- X̄_k,treated = mean of covariate k among treated units
- X̄_k,control = mean of covariate k among control units
- s²_k,treated = sample variance of covariate k among treated units
- s²_k,control = sample variance of covariate k among control units
- The denominator is the square root of the average of the two group variances, called the pooled standard deviation

### Why SMD rather than a t-test?

The t-test for covariate balance is tempting but wrong. It conflates statistical significance (which increases with sample size regardless of actual imbalance) with practical imbalance. A huge dataset can have a statistically significant but substantively trivial imbalance. SMD is a standardized effect size that does not depend on sample size and therefore provides a consistent benchmark across datasets and covariates.

### Pre- and post-weighting comparison

Compute SMD for each covariate before and after weighting/matching. Display as a "love plot" (dot plot of SMDs sorted by magnitude). The conventional threshold for adequate balance is |SMD| < 0.10 after adjustment. Covariates with |SMD| > 0.10 post-adjustment may indicate that the propensity score model is misspecified or that the overlap assumption is violated for those variables.

For binary covariates, the numerator of the SMD is the difference in proportions. For the denominator, use √[ p̄(1-p̄) ] where p̄ = (p_treated + p_control)/2, analogous to the pooled standard deviation formula for continuous variables.

---

## Part G: Overlap and weight trimming

### Why extreme propensity scores are a problem

When ê(X_i) is close to 1, the ATE weight 1/ê(X_i) approaches 1 but the control weight 1/(1-ê(X_i)) explodes. A single control unit with ê(X_i) = 0.99 receives weight 100, dominating the entire control group's contribution to the estimator. This unit's outcome has enormous influence; if it's unusual in any way, the estimate is badly distorted.

Symmetrically, treated units with ê(X_i) near 0 receive enormous ATE weights.

### Overlap (clipped) weights

One principled alternative to ATE or ATT weights targets the **overlap population** -- units for whom both treatment and control are plausible. Define:

w_i^overlap = min(ê(X_i), 1 - ê(X_i))

This weight is maximized at ê(X_i) = 0.5 (units equally likely to be treated or control) and approaches 0 at the extremes. Units with extreme propensity scores are automatically downweighted, concentrating inference on the region of good overlap. The estimand this targets is the average treatment effect for the overlap population, which is more conservative but more credible when overlap violations are present.

### Ad hoc trimming

A simpler approach: drop or truncate units outside a common support window. One rule: exclude control units with ê(X_i) below the minimum treated propensity score, and exclude treated units with ê(X_i) above the maximum control propensity score. Alternatively, trim the most extreme w% of weights (e.g., cap at the 99th percentile) and document the trimming decision. Be transparent that the trimmed estimand differs from the original ATE or ATT.

---

## Part H: Doubly robust estimation (AIPW)

### Motivation

The IPTW estimator is consistent if the propensity score model is correctly specified. Regression adjustment (outcome regression) is consistent if the outcome model is correctly specified. The **augmented IPTW (AIPW)** estimator, also called the doubly robust estimator, is consistent if **either** model is correctly specified -- it only requires both to fail simultaneously to be inconsistent.

### The AIPW estimator

Define:
- μ̂₁(X_i) = estimated E[Y_i | D_i = 1, X_i] (fitted outcome model for treated)
- μ̂₀(X_i) = estimated E[Y_i | D_i = 0, X_i] (fitted outcome model for control)
- ê(X_i) = estimated propensity score

The AIPW estimator of ATE is:

τ̂_AIPW = (1/n) Σ_i { [μ̂₁(X_i) - μ̂₀(X_i)]
                      + D_i(Y_i - μ̂₁(X_i)) / ê(X_i)
                      - (1-D_i)(Y_i - μ̂₀(X_i)) / (1-ê(X_i)) }

### Interpreting the three terms

1. μ̂₁(X_i) - μ̂₀(X_i): the regression-adjusted estimate of the treatment effect for unit i (based purely on the outcome model).

2. D_i(Y_i - μ̂₁(X_i)) / ê(X_i): a correction term for treated units. If the outcome model is correct, μ̂₁(X_i) ≈ Y_i for treated units and this term is near zero. If the outcome model is wrong, this term uses IPTW to correct the bias. This is the "augmentation."

3. -(1-D_i)(Y_i - μ̂₀(X_i)) / (1-ê(X_i)): the analogous correction for control units.

The doubly robust property arises because: if ê(X_i) is correct, the correction terms have mean zero in expectation regardless of the outcome model. If the outcome model is correct, the correction terms again vanish in expectation regardless of ê(X_i). Only when both are misspecified simultaneously does bias persist.
