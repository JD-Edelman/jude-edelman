# Multilevel Models: Mathematical Derivation

## Symbols

| Symbol | Meaning |
|--------|---------|
| i | Individual (level-1 unit), i = 1, ..., n_j |
| j | Group (level-2 unit), j = 1, ..., J |
| Y_ij | Outcome for individual i in group j |
| X_ij | Individual-level predictor for individual i in group j |
| W_j | Group-level predictor for group j |
| β₀j | Group-specific intercept for group j |
| β₁j | Group-specific slope for group j (random slope model) |
| γ₀₀ | Grand intercept: population average baseline |
| γ₁₀ | Average slope of X across all groups |
| γ₁₁ | Cross-level interaction coefficient |
| u₀j | Random intercept deviation for group j |
| u₁j | Random slope deviation for group j |
| ε_ij | Individual-level residual for person i in group j |
| τ²₀₀ | Variance of random intercepts (between-group variance in baselines) |
| τ²₁₁ | Variance of random slopes (between-group variance in X effects) |
| τ₀₁ | Covariance between random intercepts and random slopes |
| σ² | Variance of level-1 residuals (within-group variance) |
| T | 2x2 covariance matrix of the random effects vector (u₀j, u₁j) |
| ICC | Intraclass correlation coefficient |
| n_j | Number of individuals in group j |
| n̄ | Average group size across all groups |
| DEFF | Design effect due to clustering |
| Ȳ_j | Observed mean outcome for group j |
| γ̂₀₀ | Estimated grand intercept |
| ũ₀j | Empirical Bayes (shrunken) estimate of u₀j |
| λ_j | Shrinkage weight for group j |
| V_j | Marginal covariance matrix of outcomes for group j |
| Z_j | Design matrix for random effects in group j |

---

## Part A — The Random Intercept Model

**In practice:** You have survey respondents nested in states, students nested in schools, or workers nested in organizations. The random intercept model lets each group have its own baseline level of the outcome while still estimating a single slope for individual-level predictors. It is the minimal multilevel specification and the right starting point before adding complexity.

### Level-1 Equation

For individual i in group j:

```
Y_ij = β₀j + β₁ X_ij + ε_ij
```

The subscript j on β₀j means each group gets its own intercept, not a fixed dummy, but a draw from a distribution. The slope β₁ is the same across all groups (fixed). The residual ε_ij ~ N(0, σ²) is individual-level noise unexplained by X or group membership.

i indexes individuals; j indexes groups (states, schools, organizations). The level-2 subscript j on β₀j is the defining feature: each group gets its own intercept rather than a shared one.

### Level-2 Equation

The group intercept β₀j is itself modeled as a grand mean plus a group-specific deviation:

```
β₀j = γ₀₀ + u₀j
```

where γ₀₀ is the grand intercept (the average baseline across all groups) and u₀j is the **random effect** for group j, assumed:

```
u₀j ~ N(0, τ²₀₀)
```

The variance τ²₀₀ controls how spread out the group baselines are. If τ²₀₀ = 0, all groups share the same intercept and a standard OLS regression is sufficient.

### Combined (Reduced-Form) Equation

Substitute the level-2 equation into the level-1 equation:

```
Y_ij = (γ₀₀ + u₀j) + β₁ X_ij + ε_ij
Y_ij = γ₀₀ + β₁ X_ij + u₀j + ε_ij
```

The composite error u₀j + ε_ij has two parts: the group-level deviation (shared by everyone in group j) and individual-level noise. This is why treating grouped observations as independent observations is wrong: they share u₀j, creating within-group correlation that OLS does not account for.

### Implied Variance

Because u₀j and ε_ij are independent by assumption:

```
Var(Y_ij) = Var(u₀j) + Var(ε_ij) = τ²₀₀ + σ²
```

Total variance partitions cleanly into between-group variance (τ²₀₀) and within-group variance (σ²). This partition is the foundation of the ICC derived in Part B.

---

## Part B — Variance Decomposition and ICC

**In practice:** Before estimating any multilevel model, compute the ICC from a null model (no predictors). It tells you how much of the outcome's variance is between groups. Even a moderate ICC has large consequences for inference when group sizes are substantial.

### Deriving the ICC from Within-Group Correlation

Take two different individuals i and i' from the same group j. Their composite errors are:

```
e_ij  = u₀j + ε_ij
e_i'j = u₀j + ε_i'j
```

Compute their covariance. Since ε_ij and ε_i'j are independent of each other and of u₀j:

```
Cov(e_ij, e_i'j) = Cov(u₀j + ε_ij, u₀j + ε_i'j)
                 = Var(u₀j) + 0 + 0 + 0
                 = τ²₀₀
```

The correlation between two people from the same group is:

```
Corr(Y_ij, Y_i'j) = Cov(Y_ij, Y_i'j) / Var(Y_ij) = τ²₀₀ / (τ²₀₀ + σ²)
```

This ratio is the **intraclass correlation coefficient**:

```
ICC = τ²₀₀ / (τ²₀₀ + σ²)
```

The ICC is simultaneously: (1) the proportion of total variance that is between groups, and (2) the correlation between two randomly chosen people from the same group.

### Worked Example

If τ²₀₀ = 0.15 and σ² = 0.85:

```
ICC = 0.15 / (0.15 + 0.85) = 0.15 / 1.00 = 0.15
```

15% of variance in the outcome is between states; 85% is within states. An ICC of 0.10 sounds small but it implies that treating observations as independent inflates your false positive rate substantially. Even ICC = 0.05 with cluster size 20 gives a design effect close to 2.

### Design Effect

The **design effect** (DEFF) quantifies how much clustering inflates the variance of estimates compared to a simple random sample of the same size:

```
DEFF ≈ 1 + (n̄ - 1) · ICC
```

The effective sample size is N / DEFF. If ICC = 0.15 and average group size is 50:

```
DEFF = 1 + (50 - 1) × 0.15 = 1 + 7.35 = 8.35
```

A 5,000-person sample has the inferential power of roughly 5000/8.35 = 599 independent observations. Ignoring this inflates t-statistics by a factor of √8.35 ≈ 2.9. See Module 05 for more on design effects.

---

## Part C — Random Slope Extension

**In practice:** If you have reason to believe the effect of your predictor (say, education) varies across groups (states), add a random slope. The key question before doing so: do you have enough groups and enough observations per group to estimate the additional variance component τ²₁₁ reliably? As a rough rule, you need at least 30 groups for stable random slope estimation.

### Level-1 Equation

Both the intercept and the slope now carry a j subscript:

```
Y_ij = β₀j + β₁j X_ij + ε_ij
```

### Level-2 Equations

```
β₀j = γ₀₀ + u₀j
β₁j = γ₁₀ + u₁j
```

where γ₀₀ is the grand intercept, γ₁₀ is the average slope of X across groups, u₀j is the group deviation in the intercept, and u₁j is the group deviation in the slope.

The two random effects are jointly distributed as multivariate normal:

```
(u₀j, u₁j) ~ MVN(0, T)
```

where T is the 2x2 covariance matrix:

```
T = | τ²₀₀   τ₀₁  |
    | τ₀₁    τ²₁₁ |
```

τ²₁₁ > 0 means the effect of education on ideology varies across states: some states show a strong education-ideology relationship, others show almost none. τ₀₁ < 0 would mean states with high average ideology have a weaker education effect.

### Combined Equation

Substitute both level-2 equations into the level-1 equation:

```
Y_ij = (γ₀₀ + u₀j) + (γ₁₀ + u₁j) X_ij + ε_ij
Y_ij = γ₀₀ + γ₁₀ X_ij + u₀j + u₁j X_ij + ε_ij
```

The term u₁j X_ij is a group-by-predictor interaction embedded in the error structure. This is what makes the model "mixed": it has fixed effects (γ₀₀, γ₁₀) and random effects (u₀j, u₁j) that interact with predictors.

### Implied Variance (Random Slope Model)

```
Var(Y_ij) = τ²₀₀ + 2τ₀₁ X_ij + τ²₁₁ X²_ij + σ²
```

Variance is no longer constant across individuals: it depends on X_ij. Groups with extreme values of X contribute more heteroscedasticity when τ²₁₁ > 0. Heteroscedasticity in the residuals can therefore be a diagnostic signal for an omitted random slope.

---

## Part D — Cross-Level Interaction

**In practice:** Cross-level interactions are the main substantive reason to use MLM over fixed-effects regression when you have level-2 predictors. Fixed effects absorb the group-level variable entirely and cannot estimate γ₁₁. MLM models it directly and provides a standard error for it.

### Setup

Extend the level-2 equation for β₁j to include a group-level predictor W_j:

```
β₁j = γ₁₀ + γ₁₁ W_j + u₁j
```

The coefficient γ₁₁ answers: "For a one-unit increase in the group-level variable W_j, how much does the slope of X on Y change?"

### Combined Equation with Cross-Level Interaction

Substitute into the level-1 equation:

```
Y_ij = γ₀₀ + (γ₁₀ + γ₁₁ W_j + u₁j) X_ij + u₀j + ε_ij
Y_ij = γ₀₀ + γ₁₀ X_ij + γ₁₁ W_j X_ij + u₀j + u₁j X_ij + ε_ij
```

The term γ₁₁ W_j X_ij is the **cross-level interaction** in the fixed-effects part: a product of a level-2 variable and a level-1 variable. You should typically also include W_j as a main effect (to model the effect of group context on intercepts) unless you have a specific theoretical reason to exclude it.

Adding the cross-level interaction often substantially reduces τ²₁₁ because W_j now explains part of the between-group variation in slopes. The ratio (τ²₁₁_reduced / τ²₁₁_null) is sometimes called the pseudo-R² for the slope variance.

---

## Part E — REML vs. Full ML

**In practice:** You will see both "REML" and "ML" as options in lme4 (R) and mixed (Stata). The choice matters when comparing models. The short version: use REML for estimation and reporting, use ML for likelihood ratio tests comparing models with different fixed effects.

### Why OLS Fails

The combined equation has a composite error structure in which observations from the same group are correlated through the shared u₀j term. OLS assumes all errors are independent. Its γ estimates remain consistent but its variance estimates are wrong because the error covariance structure is misspecified.

### Full Maximum Likelihood (ML)

Full ML jointly maximizes the likelihood of all parameters, fixed effects and variance components together:

```
L(γ, T, σ² | Y) = ∏_j f(Y_j | γ, T, σ²)
```

The marginal likelihood for group j integrates out the random effects:

```
f(Y_j | γ, T, σ²) = ∫ f(Y_j | u_j, γ, σ²) · f(u_j | T) du_j
```

Under normality, this integral is tractable. The result is a multivariate normal marginal distribution for Y_j. Full ML yields slightly biased variance component estimates because it does not account for the degrees of freedom spent estimating fixed effects, analogous to dividing by n instead of n - k when estimating σ² in OLS.

### Restricted Maximum Likelihood (REML)

REML maximizes a modified likelihood computed from linear combinations of Y that are orthogonal to the fixed-effects design matrix. Intuitively: REML projects out the fixed effects first, then estimates variance components from the residuals. This is the multilevel analog of OLS's division by n - k rather than n.

```
REML likelihood = likelihood of (Y projected onto the null space of X)
```

REML variance component estimates are less biased than ML estimates, especially with small samples and few groups. Use REML as the default for estimating, interpreting, and reporting.

Critical caveat: REML likelihoods from two models are not comparable unless the models have identical fixed-effects specifications. To compare models with different fixed effects via a likelihood ratio test, refit both with full ML first. In lme4, calling `anova()` on two `lmer` objects with different fixed parts automatically switches to ML.

Rule of thumb:

```
Estimation and reporting => use REML
LRT comparing models with different fixed effects => use full ML
```

---

## Part F — Empirical Bayes Shrinkage

**In practice:** The group-specific estimates produced by MLM are not the raw group means. They are "shrunken" toward the grand mean, with the amount of shrinkage depending on the group's sample size. This is a feature, not a bug: small groups have noisy means, and shrinking them toward the global average reduces mean squared error.

### The Empirical Bayes Estimator

The observed group mean Ȳ_j is unbiased but noisy, especially for small n_j. The MLM's **empirical Bayes** estimate of u₀j blends the group's own data with the overall distribution of group effects:

```
ũ₀j = λ_j · (Ȳ_j - γ̂₀₀)
```

where the **shrinkage weight** λ_j is:

```
λ_j = (n_j · τ²₀₀) / (n_j · τ²₀₀ + σ²)
```

The weight in brackets is the reliability of group j's mean as an estimate of u₀j. A high weight means the model trusts that group's data; a low weight means it pulls the estimate toward zero (the grand mean).

### Behavior at the Extremes

As n_j approaches infinity:

```
λ_j => 1    (large groups: trust the observed mean, no shrinkage)
```

As n_j approaches 0:

```
λ_j => 0    (tiny groups: ignore the observed mean, collapse to grand mean)
```

### Worked Example

Suppose τ²₀₀ = 0.2 and σ² = 0.8.

For a small group with n_j = 5:

```
λ_j = (5 × 0.2) / (5 × 0.2 + 0.8) = 1.0 / 1.8 ≈ 0.56
```

The group's observed deviation from the grand mean is shrunk 44% toward zero.

For a large group with n_j = 50:

```
λ_j = (50 × 0.2) / (50 × 0.2 + 0.8) = 10.0 / 10.8 ≈ 0.93
```

Barely any shrinkage: the model almost fully trusts this group's observed mean. Small groups get pulled toward the grand mean; large groups are trusted more. In a survey with Wyoming (few respondents) and California (many respondents), Wyoming's estimated random effect will be pulled substantially toward zero, while California's will barely move. This is not bias; it is statistically optimal weighting of information.

---

## Part G — Matrix Representation

**In practice:** The matrix form is what software actually implements. You do not need to work with it by hand, but understanding it clarifies why MLM reports a covariance matrix V_j and why the log-likelihood takes the form it does.

For group j with n_j individuals, define:

```
Y_j  = n_j x 1 vector of outcomes
X_j  = n_j x p matrix of fixed-effect predictors
Z_j  = n_j x q matrix of random-effect predictors
u_j  = q x 1 vector of random effects for group j
ε_j  = n_j x 1 vector of individual residuals
```

The model for group j:

```
Y_j = X_j γ + Z_j u_j + ε_j
```

Integrating out u_j gives the marginal distribution:

```
Y_j ~ MVN(X_j γ, V_j)
```

where the marginal covariance matrix is:

```
V_j = Z_j T Z_j' + σ² I_nj
```

For the random intercept model, Z_j is a column of ones and:

```
V_j = τ²₀₀ · (1_nj)(1_nj)' + σ² I_nj
```

This is a **compound-symmetric** matrix: variance τ²₀₀ + σ² on the diagonal, covariance τ²₀₀ off-diagonal. The off-diagonal τ²₀₀ is exactly what produces the ICC.

The full log-likelihood across all J groups:

```
log L = -½ Σ_j [ n_j log(2π) + log|V_j| + (Y_j - X_j γ)' V_j⁻¹ (Y_j - X_j γ) ]
```

Maximizing this over γ, T, and σ² yields ML estimates. REML modifies the likelihood to remove the contribution of γ before optimizing the variance components, producing less-biased estimates of T and σ².
