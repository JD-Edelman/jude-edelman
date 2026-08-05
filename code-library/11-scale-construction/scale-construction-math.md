# Module 11 — Scale Construction: Math

## Symbols Used in This File

| Symbol | Meaning |
|---|---|
| X | Observed item score |
| T | True score (unobserved) |
| E | Measurement error |
| σ²_T | Variance of true scores across persons |
| σ²_E | Variance of measurement errors |
| ρ | Reliability coefficient |
| k | Number of items in the scale |
| σ²_j | Variance of item j |
| σ²_total | Variance of the sum score across all k items |
| α | Cronbach's alpha |
| X | (bold) p×1 vector of observed item scores |
| Λ | p×m matrix of factor loadings (p items, m factors) |
| f | m×1 vector of latent factor scores |
| ε | p×1 vector of unique factors (item-specific error) |
| Σ | p×p covariance matrix of observed items |
| Ψ | p×p diagonal matrix of unique variances |
| h²_j | Communality of item j |
| R | p×p correlation matrix of observed items |
| Q | p×p matrix of eigenvectors of R |
| λ_k | k-th eigenvalue of R (not to be confused with factor loadings Λ) |

---

## Part A — Classical Test Theory (CTT)

### The Basic Model

Every observed item score X decomposes into a true score T and a measurement error E:

X = T + E

with the following assumptions:
- E[E] = 0 (errors average to zero in the population)
- Var(E) = σ²_E (errors have constant variance)
- Cov(T, E) = 0 (the true score and the error are uncorrelated)

### Deriving the Variance of X

Since X = T + E and Cov(T, E) = 0:

Var(X) = Var(T + E) = Var(T) + Var(E) + 2·Cov(T, E)
        = σ²_T + σ²_E + 2·0
        = σ²_T + σ²_E

Total observed variance is the sum of true-score variance and error variance. The two are not directly observable separately; CTT requires additional assumptions or parallel tests to estimate them.

### Reliability

Reliability ρ is the proportion of observed variance attributable to true-score variance:

ρ = σ²_T / Var(X) = σ²_T / (σ²_T + σ²_E)

Equivalently:

ρ = 1 - σ²_E / Var(X)

Reliability ranges from 0 (all variance is error) to 1 (no error). A reliability of 0.80 means 80% of the variability in item scores reflects true differences between people and 20% is noise.

A key implication: the correlation between an observed item and its true score equals √ρ (the square root of reliability). If ρ = 0.80, the item correlates 0.894 with the construct it is trying to measure, even under ideal conditions.

---

## Part B — Cronbach's Alpha

### Setup

Suppose you have k items intended to measure the same construct. Each person receives a sum score S = X₁ + X₂ + ... + Xₖ. Let σ²_j = Var(Xⱼ) and σ²_total = Var(S).

Note that σ²_total = Σⱼ σ²_j + 2 Σⱼ<ℓ Cov(Xⱼ, Xℓ), so σ²_total contains all the item variances and all the pairwise covariances.

### Derivation Under Tau-Equivalence

Tau-equivalence assumes every item measures the same true score T with the same weight (but possibly different error variances):

Xⱼ = T + Eⱼ   for j = 1, ..., k

Under this model:
- Cov(Xⱼ, Xℓ) = Cov(T + Eⱼ, T + Eℓ) = Var(T) = σ²_T  (since errors are uncorrelated with each other and with T)
- Var(Xⱼ) = σ²_T + σ²_Ej

The sum score S = Σⱼ Xⱼ. Its variance:

σ²_total = Var(Σⱼ Xⱼ) = k · σ²_T + Σⱼ σ²_Ej + 2 · [k(k-1)/2] · σ²_T   ... wait, let's be careful.

Expand directly. There are k diagonal terms and k(k-1) off-diagonal terms:

σ²_total = Σⱼ Var(Xⱼ) + Σⱼ≠ℓ Cov(Xⱼ, Xℓ)
         = Σⱼ (σ²_T + σ²_Ej) + k(k-1) · σ²_T
         = k · σ²_T + Σⱼ σ²_Ej + k(k-1) · σ²_T
         = k² · σ²_T + Σⱼ σ²_Ej

The true-score variance of S is k² · σ²_T (summing k equal true scores multiplies the true score k-fold, and variance scales with the square of the multiplier).

Reliability of S under tau-equivalence:

ρ(S) = k² · σ²_T / σ²_total

We need to express this in terms of observable quantities. Note:

Σⱼ σ²_j = Σⱼ (σ²_T + σ²_Ej) = k · σ²_T + Σⱼ σ²_Ej

So:

Σⱼ σ²_Ej = Σⱼ σ²_j - k · σ²_T

And:

σ²_total = k² · σ²_T + Σⱼ σ²_j - k · σ²_T = k(k-1) · σ²_T + Σⱼ σ²_j

Solve for k · σ²_T:

k · σ²_T = (σ²_total - Σⱼ σ²_j) / (k-1)

Then k² · σ²_T = k · (σ²_total - Σⱼ σ²_j) / (k-1).

Substituting into ρ(S):

α = ρ(S) = [k / (k-1)] · [(σ²_total - Σⱼ σ²_j) / σ²_total]
          = [k / (k-1)] · [1 - Σⱼ σ²_j / σ²_total]

This is Cronbach's alpha. It is exactly equal to reliability when tau-equivalence holds (equal true-score factor loadings). When tau-equivalence is violated (items have different loadings on the true score, which is typical), alpha underestimates the true reliability. Alpha is therefore a lower bound on reliability.

### Practical Reading of Alpha

Alpha increases mechanically as k increases, even if the items are not more reliable. You can make alpha arbitrarily close to 1 by adding items, even items of poor quality. Interpret alpha in context of k, not as an absolute measure of quality. Commonly cited thresholds (α > 0.70 acceptable, α > 0.80 good) assume moderate k. For k = 20 items, α = 0.70 is actually consistent with very weak inter-item correlations.

---

## Part C — The Common Factor Model

### The Model

Let X be a p×1 vector of observed item scores. The common factor model specifies:

X = Λ f + ε

where:
- Λ is a p×m matrix of factor loadings (m is the number of common factors)
- f is an m×1 vector of common factor scores, with E[f] = 0 and Var(f) = I_m (factors are standardized and assumed orthogonal in the initial solution)
- ε is a p×1 vector of unique factors (item-specific variance plus error), with E[ε] = 0 and Cov(f, ε) = 0

### Implied Covariance Matrix

The covariance matrix of X:

Σ = Var(Λf + ε) = Λ Var(f) Λ' + Var(ε) + Λ Cov(f, ε) + Cov(f, ε)' Λ'

Since Cov(f, ε) = 0 and Var(f) = I:

Σ = Λ I Λ' + Ψ = ΛΛ' + Ψ

where Ψ = Var(ε) = diag(ψ₁, ψ₂, ..., ψₚ) is diagonal. The off-diagonal elements of Σ (covariances between items) are fully explained by the common factors. The diagonal elements of Σ (variances of items) split into communality (explained by factors) and uniqueness (unexplained).

### Communality and Uniqueness

The communality of item j is the proportion of item j's variance explained by the common factors. For orthogonal factors:

h²_j = Σₘ λ²_jm

where λ_jm is the loading of item j on factor m. Communality is the sum of squared loadings across all factors for that item.

Uniqueness:

ψ_j = 1 - h²_j   (for standardized items where Var(Xⱼ) = 1)

An item with communality 0.64 has 64% of its variance explained by the common factors and 36% unique (measurement error + item-specific content).

### Factor Rotation

The factor solution ΛΛ' is not unique: for any orthogonal rotation matrix R (R'R = I), the model (ΛR)(ΛR)' = ΛRR'Λ' = ΛΛ' fits identically. Rotation chooses R to make the solution interpretable. Varimax rotation maximizes the variance of squared loadings within each factor, pushing loadings toward 0 or 1 and making each factor defined by a small number of high-loading items. Oblique rotations (Promax, Oblimin) allow factors to correlate, which is more realistic for social science constructs.

---

## Part D — Principal Components Analysis

### Eigendecomposition

For a p×p correlation matrix R of standardized items, the eigendecomposition is:

R = Q Λ_eig Q'

where:
- Q = [q₁ | q₂ | ... | qₚ] is a p×p orthogonal matrix of eigenvectors (each column is an eigenvector)
- Λ_eig = diag(λ₁, λ₂, ..., λₚ) is the diagonal matrix of eigenvalues, sorted λ₁ ≥ λ₂ ≥ ... ≥ λₚ ≥ 0

The k-th principal component score for observation i is:

PC_k = q_k' X_i

where q_k is the k-th eigenvector and X_i is the vector of standardized item scores for person i.

### Proportion of Variance Explained

The total variance in a correlation matrix (sum of diagonal elements) equals p (each standardized item has variance 1). The k-th eigenvalue λ_k equals the variance of the k-th principal component across persons. Therefore:

Proportion of variance explained by PC_k = λ_k / Σⱼ λⱼ = λ_k / p

To explain cumulative proportion through the first q components:

Cumulative proportion = (Σₖ₌₁^q λ_k) / p

### The Kaiser Criterion

The Kaiser criterion retains components with λ_k > 1. The rationale: a standardized item explains exactly 1 unit of variance (its own variance, since it is standardized). A component with eigenvalue > 1 explains more variance than a single original variable and therefore is "worth" retaining. A component with eigenvalue < 1 explains less than a single item and is discarding rather than summarizing information.

**Limitation:** The Kaiser criterion tends to retain too many components in large item sets and too few in small ones. The scree plot (eigenvalue vs. component number) and parallel analysis (comparing observed eigenvalues to eigenvalues from random data of the same size) are more reliable guides to the number of factors in practice.

### PCA vs. Common Factor Analysis

PCA and EFA are sometimes confused but differ fundamentally. PCA has no model: it decomposes the full variance of the items (including unique variance) into orthogonal components. EFA explicitly models only the shared variance (communality) and separates it from unique variance. For scale construction, EFA is the appropriate tool because you want to understand the shared latent structure, not summarize all variance including noise.
