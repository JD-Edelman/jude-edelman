# Propensity Score Methods: Mathematical Derivation

## Symbols

| Symbol | Meaning |
|--------|---------|
| i | Individual unit, i = 1, ..., n |
| D_i | Treatment indicator: 1 = treated, 0 = control |
| X_i | Vector of observed pre-treatment covariates for unit i |
| Y_i | Observed outcome for unit i |
| Y_i(1) | Potential outcome for unit i if treated (may be counterfactual) |
| Y_i(0) | Potential outcome for unit i if not treated (may be counterfactual) |
| e(X_i) | True propensity score: P(D_i = 1 | X_i) |
| ê(X_i) | Estimated propensity score |
| ATE | Average treatment effect: E[Y(1) - Y(0)] |
| ATT | Average treatment effect on the treated: E[Y(1) - Y(0) | D = 1] |
| E[·] | Expectation over the population |
| ⊥ | Statistical independence |
| Δ_naive | Naive estimator: simple difference in observed group means |
| τ̂_ATE | IPTW estimator of the ATE |
| τ̂_ATT | IPTW estimator of the ATT |
| τ̂_AIPW | Augmented IPTW (doubly robust) estimator of the ATE |
| w_i | IPTW weight for unit i |
| n₁ | Number of treated units: Σ_i D_i |
| SMD_k | Standardized mean difference for covariate k |
| X̄_k,treated | Mean of covariate k among treated units |
| X̄_k,control | Mean of covariate k among control units |
| s²_k,treated | Sample variance of covariate k among treated units |
| s²_k,control | Sample variance of covariate k among control units |
| μ̂₁(X_i) | Estimated conditional mean outcome for treated: E[Y | D=1, X_i] |
| μ̂₀(X_i) | Estimated conditional mean outcome for control: E[Y | D=0, X_i] |
| σ(·) | Logistic sigmoid function: 1/(1 + exp(-·)) |
| β | Coefficient vector in the propensity score logistic model |

---

## Part A — Potential Outcomes Framework

**In practice:** Every causal question in observational research implicitly invokes potential outcomes. Making the framework explicit forces you to state precisely what the counterfactual is and what assumption you need to estimate it. Before running any propensity score analysis, write out Y_i(1) and Y_i(0) in words for your specific study.

### Defining Potential Outcomes

For each unit i, define two **potential outcomes**:

```
Y_i(1) = the outcome unit i would have if assigned to treatment
Y_i(0) = the outcome unit i would have if assigned to control
```

Only one of these is ever observed for any given unit. This is the **fundamental problem of causal inference** (Holland, 1986): you cannot observe both simultaneously for the same person.

The observed outcome links to the treatment indicator via the **consistency assumption** (also called SUTVA: stable unit treatment value assumption, which rules out interference between units and requires a well-defined treatment):

```
Y_i = D_i · Y_i(1) + (1 - D_i) · Y_i(0)
```

If D_i = 1, we observe Y_i(1). If D_i = 0, we observe Y_i(0). The other potential outcome is the **counterfactual** and is never observed.

### Average Treatment Effects

The **average treatment effect (ATE)** is the average causal effect over the entire population:

```
ATE = E[Y_i(1) - Y_i(0)]
    = E[Y_i(1)] - E[Y_i(0)]
```

The **average treatment effect on the treated (ATT)** conditions on being in the treated group:

```
ATT = E[Y_i(1) - Y_i(0) | D_i = 1]
    = E[Y_i(1) | D_i = 1] - E[Y_i(0) | D_i = 1]
```

The first term, E[Y_i(1) | D_i = 1], is directly observed: it is the average outcome among treated units. The second term, E[Y_i(0) | D_i = 1], is counterfactual: what would treated units' outcomes have been without treatment? This is the quantity we must estimate.

ATT answers "did the program work for participants?" ATE answers "would it work for the average person in the population?" In policy evaluation, ATT is usually more relevant: you want to know if the people who actually got the treatment benefited.

---

## Part B — The Selection Problem

**In practice:** The selection problem is the reason you cannot simply compare average outcomes across treatment and control groups in observational data. People who receive treatment differ from those who do not, and those differences also affect the outcome. Propensity score methods work by removing that difference.

### Why Naive Comparison Fails

Define the naive estimator as the simple difference in observed group means:

```
Δ_naive = E[Y_i | D_i = 1] - E[Y_i | D_i = 0]
```

Expand each term using the consistency assumption:

```
E[Y_i | D_i = 1] = E[Y_i(1) | D_i = 1]
E[Y_i | D_i = 0] = E[Y_i(0) | D_i = 0]
```

So:

```
Δ_naive = E[Y_i(1) | D_i = 1] - E[Y_i(0) | D_i = 0]
```

Add and subtract the counterfactual mean E[Y_i(0) | D_i = 1]:

```
Δ_naive = [E[Y_i(1) | D_i = 1] - E[Y_i(0) | D_i = 1]]
        + [E[Y_i(0) | D_i = 1] - E[Y_i(0) | D_i = 0]]
```

The first bracket is the ATT. The second bracket is the **selection bias**: the difference between treated and control units in their average untreated potential outcome.

```
Selection bias = E[Y_i(0) | D_i = 1] - E[Y_i(0) | D_i = 0]
```

### Worked Example

Treated group earns $60k on average; control group earns $45k. The naive difference is $15k. But suppose that even without the program, the treated group would have earned $55k (because they had stronger prior credentials). Then:

```
Selection bias = $55k - $45k = $10k
True ATT = $15k - $10k = $5k
```

The program genuinely helped, but only by $5k, not $15k. Selection bias is nonzero whenever treated and control units differ on pre-treatment characteristics that also affect the outcome. This is almost always true in observational data.

---

## Part C — Unconfoundedness and the Propensity Score

**In practice:** Instead of matching on 10 covariates simultaneously (nearly impossible for high-dimensional X), propensity score methods reduce the problem to matching on a single number: the probability of treatment given covariates. This is why PSM was transformative when introduced by Rosenbaum and Rubin (1983): it made matching feasible.

### Unconfoundedness

Propensity score methods rest on the following assumption:

```
(Y_i(0), Y_i(1)) ⊥ D_i | X_i
```

In words: conditional on the observed covariates X_i, treatment assignment is independent of the potential outcomes. Within any stratum defined by X, treatment assignment is as good as random. This assumption is also called **ignorability**, **conditional exchangeability**, or **no unmeasured confounders**.

This assumption is untestable: Y_i(0) for treated units and Y_i(1) for control units are never observed, so you cannot directly verify independence. It is a substantive judgment call, not a statistical one. A second required assumption is **overlap** (also called positivity):

```
0 < P(D_i = 1 | X_i) < 1   for all X_i in the support of X
```

Every type of unit must have some positive probability of being either treated or untreated. Together, unconfoundedness and positivity are called **strong ignorability**.

### The Propensity Score

The **propensity score** is:

```
e(X_i) = P(D_i = 1 | X_i)
```

It is the probability of receiving treatment given observed covariates.

### The Rosenbaum-Rubin Theorem

**Theorem:** If unconfoundedness holds given X, then it also holds given e(X):

```
(Y_i(0), Y_i(1)) ⊥ D_i | X_i   implies   (Y_i(0), Y_i(1)) ⊥ D_i | e(X_i)
```

**Proof via iterated expectations.** We need to show that, conditional on e(X_i), treatment assignment D_i provides no additional information about potential outcomes.

First, note that e(X_i) is a deterministic function of X_i, so:

```
P(D_i = 1 | X_i, e(X_i)) = P(D_i = 1 | X_i) = e(X_i)
```

Second, by the law of iterated expectations:

```
P(D_i = 1 | e(X_i)) = E[D_i | e(X_i)]
                     = E[ E[D_i | X_i] | e(X_i) ]
                     = E[ e(X_i) | e(X_i) ]
                     = e(X_i)
```

So P(D_i = 1 | X_i, e(X_i)) = P(D_i = 1 | e(X_i)) = e(X_i). Knowing X_i provides no additional information about D_i once you know e(X_i). Combined with unconfoundedness given X_i, this implies unconfoundedness given e(X_i).

The theorem tells you that conditioning on e(X) is sufficient, but you still have to estimate e(X) correctly. Logistic regression is the standard approach. A propensity score model with mediocre AUC can still produce excellent covariate balance; what matters is the balance achieved after weighting or matching, verified empirically via diagnostics (Part E).

### Estimation via Logistic Regression

In practice, e(X_i) is unknown and must be estimated. The standard approach is logistic regression:

```
P(D_i = 1 | X_i) = σ(X_i β) = 1 / (1 + exp(-X_i β))
```

The log-likelihood to maximize:

```
log L(β) = Σ_i [ D_i log σ(X_i β) + (1 - D_i) log(1 - σ(X_i β)) ]
```

The estimated propensity score:

```
ê(X_i) = σ(X_i β̂) = 1 / (1 + exp(-X_i β̂))
```

---

## Part D — IPTW Estimator

**In practice:** IPTW creates a pseudo-population by reweighting observations. Treated units are weighted by 1/ê(X_i) to represent the population from which they were drawn; control units are weighted by 1/(1-ê(X_i)). If the propensity score is correct, the reweighted distribution of X is the same in both groups, eliminating selection bias.

### Horvitz-Thompson IPTW Estimator for ATE

Each observation is weighted by the inverse of its probability of receiving the treatment it actually received:

```
τ̂_ATE = (1/n) Σ_i [ D_i · Y_i / ê(X_i) - (1 - D_i) · Y_i / (1 - ê(X_i)) ]
```

### Unbiasedness Proof via Tower Law

Show that E[D_i · Y_i / e(X_i)] = E[Y_i(1)].

Apply the law of iterated expectations (tower law):

```
E[ D_i · Y_i / e(X_i) ] = E[ E[ D_i · Y_i / e(X_i) | X_i ] ]
```

Inside the inner expectation, condition on X_i so e(X_i) is a constant:

```
E[ D_i · Y_i / e(X_i) | X_i ] = (1/e(X_i)) · E[ D_i · Y_i | X_i ]
```

By consistency, D_i · Y_i = D_i · Y_i(1):

```
= (1/e(X_i)) · E[ D_i · Y_i(1) | X_i ]
```

By unconfoundedness, Y_i(1) ⊥ D_i | X_i, so they separate:

```
= (1/e(X_i)) · E[D_i | X_i] · E[Y_i(1) | X_i]
= (1/e(X_i)) · e(X_i) · E[Y_i(1) | X_i]
= E[Y_i(1) | X_i]
```

Taking the outer expectation:

```
E[ E[Y_i(1) | X_i] ] = E[Y_i(1)]
```

By the same argument, E[(1 - D_i) · Y_i / (1 - e(X_i))] = E[Y_i(0)]. Therefore:

```
E[τ̂_ATE] = E[Y_i(1)] - E[Y_i(0)] = ATE
```

The estimator is unbiased when the true propensity score is used. With an estimated propensity score, the estimator is consistent under correct specification of the propensity model.

### IPTW Weights for ATT

For the ATT, the target is E[Y(1) - Y(0) | D = 1]. Control units are reweighted to match the covariate distribution of the treated group:

```
w_i = D_i + (1 - D_i) · ê(X_i) / (1 - ê(X_i))
```

For treated units: w_i = 1 (they define the target population, no reweighting needed).
For control units: w_i = ê(X_i) / (1 - ê(X_i)), the odds of treatment given X_i.

An untreated unit with ê(X) = 0.8 gets ATT weight 0.8/0.2 = 4. That unit looks a lot like treated units on covariates and gets upweighted to fill the gap. An untreated unit with ê(X) = 0.1 gets weight 0.1/0.9 = 0.11: it is very different from treated units and barely contributes. The ATT estimator is:

```
τ̂_ATT = [Σ_i D_i Y_i / n₁] - [Σ_i (1-D_i) w_i Y_i / Σ_i (1-D_i) w_i]
```

### Normalized (Hajek) Weights

The raw IPTW estimator can be unstable when propensity scores are near 0 or 1 because weights 1/ê and 1/(1-ê) can explode. A more stable variant normalizes weights within each treatment group so they sum to 1:

```
For treated:  w̃_i = (1/ê(X_i)) / Σ_{D_i=1} (1/ê(X_i))
For controls: w̃_i = (1/(1-ê(X_i))) / Σ_{D_i=0} (1/(1-ê(X_i)))
```

The **Hajek estimator** has slightly higher bias but substantially lower variance than the Horvitz-Thompson estimator in finite samples with extreme weights.

---

## Part E — Balance Diagnostics (SMD)

**In practice:** After weighting or matching, you must verify that X is balanced between treatment and control groups. The standardized mean difference is the right tool: it is scale-free, sample-size-independent, and directly comparable across covariates measured in different units.

### Standardized Mean Difference

For a single continuous covariate k, the **SMD** between treated and control groups is:

```
SMD_k = (X̄_k,treated - X̄_k,control) / √[(s²_k,treated + s²_k,control) / 2]
```

The denominator is the pooled standard deviation: the square root of the average of the two group variances. It standardizes the mean difference to a common scale, analogous to a Cohen's d.

For a binary covariate with proportions p_treated and p_control:

```
SMD_k = (p_treated - p_control) / √[ (p̄(1 - p̄)) ]
where p̄ = (p_treated + p_control) / 2
```

Before matching or weighting, you might see |SMD| = 0.4 on age (a large imbalance). After IPTW, you want |SMD| < 0.10 on every covariate. Covariates still above 0.10 after adjustment suggest a misspecified propensity score model or overlap violations for those variables.

Do NOT use t-tests for balance checking. They depend on sample size: large samples can produce statistically significant imbalance that is substantively trivial, and small samples can show non-significant imbalance that is substantively large. SMD is independent of sample size and provides a consistent benchmark across datasets and covariates.

Display SMDs before and after adjustment in a **love plot** (dot plot of SMDs sorted by magnitude). This is the standard reporting format in journals that use propensity score methods.

---

## Part F — Overlap and Weight Trimming

**In practice:** Extreme propensity scores are a serious practical problem. A single control unit with ê(X) = 0.99 receives IPTW weight 1/(1-0.99) = 100, potentially dominating the entire estimate. Overlap weights and trimming are the two main solutions.

### Why Extreme Propensity Scores Are a Problem

When ê(X_i) is close to 1, the control-group ATE weight explodes:

```
1 / (1 - ê(X_i)) => infinity  as  ê(X_i) => 1
```

A single control unit with ê(X_i) = 0.99 receives weight 100, dominating the entire control group's contribution. If this unit's outcome is unusual for any reason, the estimate is badly distorted. Symmetrically, treated units with ê(X_i) near 0 receive enormous ATE weights.

### Overlap Weights

A principled alternative targets the **overlap population**: units for whom both treatment and control are plausible. Define overlap weights as:

```
w_i^overlap = min(ê(X_i), 1 - ê(X_i))
```

This weight is maximized at ê(X_i) = 0.5 (equally likely to be treated or control) and approaches zero at the extremes. Units with extreme propensity scores are automatically downweighted, concentrating inference on the region of good common support.

The estimand this targets is the average treatment effect for the overlap population: more conservative than the full ATE, but more credible when overlap violations are present. Units with ê(X) close to 0 or 1 have extreme IPTW weights that inflate variance and can dominate the estimate; overlap weights fix this by targeting the population where the data actually support comparison.

### Ad Hoc Trimming

A simpler approach: exclude units outside a common support window. One rule:

```
Exclude control units with ê(X_i) < min(ê(X_i) for treated units)
Exclude treated units with ê(X_i) > max(ê(X_i) for control units)
```

Alternatively, cap weights at a high percentile (e.g., the 99th percentile) and document the decision. Be transparent that the trimmed estimand differs from the original ATE or ATT. Any trimming decision should be reported and its effect on the estimate examined as a sensitivity check.

---

## Part G — Doubly Robust Estimation (AIPW)

**In practice:** IPTW requires a correctly specified propensity score model. Outcome regression requires a correctly specified outcome model. AIPW combines both and only fails if both are wrong at the same time. It is the preferred estimator when you are uncertain about either model.

### Motivation

The IPTW estimator is consistent if the propensity score model is correctly specified. Regression adjustment (outcome regression) is consistent if the outcome model is correctly specified. The **augmented IPTW (AIPW)** estimator, also called the **doubly robust** estimator, is consistent if either model is correctly specified. Both must fail simultaneously for the estimator to be inconsistent.

### The AIPW Estimator

Define:

```
μ̂₁(X_i) = estimated E[Y_i | D_i = 1, X_i]  (fitted outcome model for treated)
μ̂₀(X_i) = estimated E[Y_i | D_i = 0, X_i]  (fitted outcome model for control)
ê(X_i)   = estimated propensity score
```

The AIPW estimator of ATE is:

```
τ̂_AIPW = (1/n) Σ_i { [μ̂₁(X_i) - μ̂₀(X_i)]
                     + D_i (Y_i - μ̂₁(X_i)) / ê(X_i)
                     - (1 - D_i)(Y_i - μ̂₀(X_i)) / (1 - ê(X_i)) }
```

### Interpreting the Three Terms

Term 1: regression-adjusted estimate of the individual treatment effect:

```
μ̂₁(X_i) - μ̂₀(X_i)
```

This is the outcome model's prediction for unit i's treatment effect. If the outcome model is perfect, this alone gives an unbiased estimate.

Term 2: IPW correction for treated units:

```
D_i (Y_i - μ̂₁(X_i)) / ê(X_i)
```

If the outcome model is correct, μ̂₁(X_i) ≈ Y_i for treated units and this term is near zero. If the outcome model is wrong, this term uses IPTW to correct the bias. This is the "augmentation."

Term 3: analogous IPW correction for control units:

```
-(1 - D_i)(Y_i - μ̂₀(X_i)) / (1 - ê(X_i))
```

The doubly robust property arises because: if ê(X_i) is correct, the correction terms have expected value zero regardless of the outcome model. If the outcome model is correct, the correction terms vanish in expectation regardless of ê(X_i). Only when both models are simultaneously misspecified does bias persist.
