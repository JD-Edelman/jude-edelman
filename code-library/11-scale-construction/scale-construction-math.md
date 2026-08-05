# Scale Construction: Mathematical Derivation

## Symbols

| Symbol | Meaning |
|--------|---------|
| X | Observed item score |
| T | True score (unobserved latent construct value) |
| E | Measurement error |
| σ²_T | Variance of true scores across persons |
| σ²_E | Variance of measurement errors |
| ρ | Reliability coefficient |
| k | Number of items in the scale |
| j, ℓ | Item indices |
| σ²_j | Variance of item j |
| σ²_Ej | Error variance of item j |
| S | Sum score: S = X₁ + X₂ + ... + Xₖ |
| σ²_total | Variance of the sum score S |
| α | Cronbach's alpha |
| X (bold) | p×1 vector of observed item scores |
| Λ | p×m matrix of factor loadings (p items, m factors) |
| λ_jm | Loading of item j on factor m |
| f | m×1 vector of latent factor scores |
| ε (in factor model) | p×1 vector of unique factors |
| Σ | p×p model-implied covariance matrix of observed items |
| Ψ | p×p diagonal matrix of unique variances |
| ψ_j | Unique variance of item j |
| h²_j | Communality of item j: proportion of variance explained by common factors |
| R | p×p correlation matrix of observed items |
| Q | p×p matrix of eigenvectors of R (columns are eigenvectors) |
| λ_k (eigenvalue) | k-th eigenvalue of R (distinct from factor loading λ_jm) |
| I_m | m×m identity matrix |

---

## Part A — Classical Test Theory

**In practice:** Classical Test Theory is the conceptual foundation for every reliability statistic you will encounter. Before computing Cronbach's alpha or fitting a factor model, CTT tells you what those statistics are actually measuring.

### The Basic Model

Every observed item score X decomposes into a true score T and a measurement error E:

```
X = T + E
```

with three assumptions:

1. E[E] = 0 (errors average to zero in the population)
2. Var(E) = σ²_E (errors have constant variance)
3. Cov(T, E) = 0 (the true score and the error are uncorrelated)

Every survey item is a noisy measurement of an underlying construct. The noise has two sources: random response error (forgetting, misreading, clicking wrong) and systematic method effects (question wording, response scale format, interviewer presence).

### Deriving the Variance of X

Since X = T + E and Cov(T, E) = 0:

```
Var(X) = Var(T + E) = Var(T) + Var(E) + 2 · Cov(T, E)
       = σ²_T + σ²_E
```

Total observed variance is the sum of true-score variance and error variance. The two are not directly observable separately. CTT requires additional assumptions or parallel tests to estimate them separately.

### Reliability

**Reliability** ρ is the proportion of observed variance attributable to true-score variance:

```
ρ = σ²_T / Var(X) = σ²_T / (σ²_T + σ²_E)
```

Equivalently:

```
ρ = 1 - σ²_E / Var(X)
```

Reliability ranges from 0 (all variance is error) to 1 (no error at all). A reliability of 0.80 means 80% of the variability in item scores reflects true differences between people; 20% is noise.

A key implication: the correlation between an observed item and its true score equals √ρ. A reliability of 0.70 means the item correlates √0.70 ≈ 0.84 with the true construct. A reliability of 0.40 means it correlates only √0.40 ≈ 0.63, which is arguably too noisy to use as a standalone measure.

---

## Part B — Cronbach's Alpha

**In practice:** Cronbach's alpha is the default reliability check before publishing a multi-item scale. Knowing its derivation tells you exactly what it does and does not measure, and why it can mislead if used uncritically.

### Setup

Suppose you have k items intended to measure the same construct. Each person receives a sum score:

```
S = X₁ + X₂ + ... + Xₖ
```

Let σ²_j = Var(Xⱼ) and σ²_total = Var(S). Note that:

```
σ²_total = Σⱼ σ²_j + 2 Σⱼ<ℓ Cov(Xⱼ, Xℓ)
```

The total score variance contains all item variances and all pairwise covariances.

### Tau-Equivalence Assumption

**Tau-equivalence** assumes every item measures the same true score T with the same weight, though possibly with different error variances:

```
Xⱼ = T + Eⱼ   for j = 1, ..., k
```

Under this model:

```
Cov(Xⱼ, Xℓ) = Cov(T + Eⱼ, T + Eℓ) = Var(T) = σ²_T
```

because errors are uncorrelated with each other and with T.

```
Var(Xⱼ) = σ²_T + σ²_Ej
```

### Deriving Alpha

The sum score S = Σⱼ Xⱼ. Expand its variance directly. There are k diagonal terms (the item variances) and k(k-1) off-diagonal terms (the pairwise covariances):

```
σ²_total = Σⱼ Var(Xⱼ) + Σⱼ≠ℓ Cov(Xⱼ, Xℓ)
         = Σⱼ (σ²_T + σ²_Ej) + k(k-1) · σ²_T
         = k · σ²_T + Σⱼ σ²_Ej + k(k-1) · σ²_T
         = k² · σ²_T + Σⱼ σ²_Ej
```

The true-score variance of S is k² · σ²_T (summing k equal true scores multiplies the true score k-fold, and variance scales with the square of the multiplier). Reliability of S under tau-equivalence:

```
ρ(S) = k² · σ²_T / σ²_total
```

We need to express this in terms of observable quantities. Note:

```
Σⱼ σ²_j = Σⱼ (σ²_T + σ²_Ej) = k · σ²_T + Σⱼ σ²_Ej
```

Therefore:

```
Σⱼ σ²_Ej = Σⱼ σ²_j - k · σ²_T
```

Substituting into the expression for σ²_total:

```
σ²_total = k² · σ²_T + Σⱼ σ²_j - k · σ²_T
         = k(k-1) · σ²_T + Σⱼ σ²_j
```

Solving for k · σ²_T:

```
k · σ²_T = (σ²_total - Σⱼ σ²_j) / (k-1)
```

Then k² · σ²_T = k · (σ²_total - Σⱼ σ²_j) / (k-1). Substituting into ρ(S):

```
α = ρ(S) = [k / (k-1)] · [(σ²_total - Σⱼ σ²_j) / σ²_total]
          = [k / (k-1)] · [1 - Σⱼ σ²_j / σ²_total]
```

This is **Cronbach's alpha**. It equals reliability exactly when tau-equivalence holds. When tau-equivalence is violated (items have different loadings on the true score, which is typical in practice), alpha underestimates the true reliability. Alpha is therefore a **lower bound** on reliability.

### Numerical Example

If your 5-item immigration attitude scale has item variances averaging 0.22 and a total variance of 1.50:

```
α = (5/4) · (1 - 5 · 0.22 / 1.50)
  = 1.25 · (1 - 1.10/1.50)
  = 1.25 · (1 - 0.733)
  = 1.25 · 0.267
  = 0.33
```

That is very low. The items are barely correlated with each other, which means they are likely measuring different things (or are extremely noisy). Alpha below 0.60 typically means the scale needs revision.

### Alpha as a Lower Bound

Alpha underestimates true reliability when items have different loadings on the construct, which is almost always the case. **Omega** (ω) is a better estimate in that case, but it requires fitting the factor model and specifying how many factors you believe underlie the scale. When you have reason to believe items differ substantially in how well they measure the construct, report omega alongside alpha.

Alpha also increases mechanically as k increases, even if the items are not more reliable. You can make alpha arbitrarily close to 1 by adding items, even poor-quality ones. Interpret alpha in context of k, not as an absolute indicator of quality. For k = 20 items, α = 0.70 is consistent with very weak inter-item correlations.

---

## Part C — The Common Factor Model

**In practice:** Factor analysis asks: how many underlying dimensions explain the correlations among your items? Every item is assumed to reflect a small number of latent constructs plus item-specific noise.

### The Model

Let X be a p×1 vector of observed item scores. The **common factor model** specifies:

```
X = Λf + ε
```

where:

- Λ is a p×m matrix of **factor loadings** (p items, m factors)
- f is an m×1 vector of **common factor scores**, with E[f] = 0 and Var(f) = I_m (factors are standardized and assumed orthogonal in the initial solution)
- ε is a p×1 vector of **unique factors** (item-specific variance plus measurement error), with E[ε] = 0 and Cov(f, ε) = 0

### Implied Covariance Matrix

The covariance matrix of X under the factor model:

```
Σ = Var(Λf + ε)
  = Λ Var(f) Λ' + Var(ε)
  = Λ I_m Λ' + Ψ
  = ΛΛ' + Ψ
```

where Ψ = diag(ψ₁, ψ₂, ..., ψₚ) is a diagonal matrix of unique variances. The off-diagonal elements of Σ (covariances between items) are fully explained by the common factors. The diagonal elements split into communality (explained by factors) and uniqueness (unexplained).

EFA estimates Λ and Ψ to make this implied Σ match the observed correlation matrix as closely as possible. The residual difference between the implied and observed covariance matrices is the model's misfit, and a large residual signals that additional factors may be needed.

### Communality and Uniqueness

The **communality** h²_j is the proportion of item j's variance explained by the common factors. For orthogonal factors:

```
h²_j = Σₘ λ²_jm
```

Communality is the sum of squared loadings across all factors for item j.

**Uniqueness** is the remainder:

```
ψ_j = 1 - h²_j   (for standardized items where Var(Xⱼ) = 1)
```

An item with communality h² = 0.15 has 85% of its variance unexplained by the common factors. That item is mostly noise from the factors' perspective. Consider dropping it or rewriting it so it better captures the shared construct.

### Factor Rotation

The factor solution ΛΛ' is not unique: for any orthogonal rotation matrix R (R'R = I), the model (ΛR)(ΛR)' = ΛRR'Λ' = ΛΛ' fits identically. Rotation chooses R to make the solution more interpretable.

**Varimax** rotation maximizes the variance of squared loadings within each factor, pushing loadings toward 0 or 1 and making each factor defined by a small number of high-loading items. **Oblique rotations** (Promax, Oblimin) allow factors to correlate, which is more realistic for social science constructs where attitudes about different topics are rarely truly orthogonal.

---

## Part D — PCA and Eigendecomposition

**In practice:** PCA is often confused with factor analysis, but they have different goals. PCA summarizes all variance in the items; EFA models only the shared variance. For scale construction, EFA is usually the right tool.

### Eigendecomposition of the Correlation Matrix

For a p×p correlation matrix R of standardized items, the eigendecomposition is:

```
R = Q Λ_eig Q'
```

where:

- Q = [q₁ | q₂ | ... | qₚ] is a p×p orthogonal matrix whose columns are the eigenvectors of R
- Λ_eig = diag(λ₁, λ₂, ..., λₚ) is the diagonal matrix of eigenvalues, sorted λ₁ ≥ λ₂ ≥ ... ≥ λₚ ≥ 0

The k-th **principal component** score for observation i:

```
PC_k = q_k' X_i
```

where q_k is the k-th eigenvector and X_i is the vector of standardized item scores for person i. Each PC is a linear combination of all items, with weights given by the eigenvector.

### Proportion of Variance Explained

The total variance in a correlation matrix (sum of diagonal elements) equals p, since each standardized item has variance 1. The k-th eigenvalue λ_k equals the variance of the k-th principal component across persons. Therefore:

```
Proportion of variance explained by PC_k = λ_k / Σⱼ λⱼ = λ_k / p
```

Cumulative proportion through the first q components:

```
Cumulative proportion = (Σₖ₌₁ᵠ λ_k) / p
```

### The Kaiser Criterion

The **Kaiser criterion** retains components with λ_k > 1. The rationale: a standardized item explains exactly 1 unit of variance (its own). A component with eigenvalue > 1 explains more variance than a single original item and is worth retaining. A component with eigenvalue < 1 explains less than a single item.

A scree plot is more reliable than Kaiser for choosing the number of factors. Look for the "elbow" where eigenvalues stop dropping steeply. The components to the left of the elbow are the ones worth retaining. The Kaiser criterion tends to retain too many components in large item sets and too few in small ones. Parallel analysis (comparing observed eigenvalues to eigenvalues from random data of the same size) is the most rigorous guide available.

### PCA vs. Common Factor Analysis

PCA and EFA differ fundamentally. PCA decomposes the full variance of the items, including unique variance, into orthogonal components. EFA explicitly models only the shared variance (communality) and separates it from unique variance. The factor model assumes a data-generating mechanism (latent constructs causing item responses); PCA assumes nothing. For scale construction where you want to understand what latent construct your items are measuring, EFA is the appropriate tool.
