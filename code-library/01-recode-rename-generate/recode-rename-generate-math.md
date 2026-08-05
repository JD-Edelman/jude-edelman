# Module 01 — Recode, Rename, Generate: Math

---

## Part A: Indicator (Dummy) Variable Algebra

### The K-category expansion

Let C be a categorical variable taking K distinct values, labeled c₁, c₂, ..., c_K. To enter C into a linear model we cannot use the raw integer codes directly: those codes carry implicit ordinal or ratio information that the categories do not actually possess (the difference between "Democrat" coded 1 and "Republican" coded 2 is not meaningful as a quantity).

The standard encoding creates K-1 binary indicator variables. Define:

  D_k(i) = 1  if observation i belongs to category c_k
  D_k(i) = 0  otherwise

for k = 1, 2, ..., K-1. Category c_K is the **reference category**, left out of the model.

Why K-1 and not K? Because D₁ + D₂ + ... + D_K = 1 for every observation (each unit belongs to exactly one category). If you included all K dummies, this column of ones would be a perfect linear combination of the other K-1 columns and of the intercept column, making the design matrix X rank-deficient. The system X'X would be singular and have no inverse; the OLS estimator (X'X)⁻¹X'y would be undefined.

### The design matrix with dummies

Suppose n = 5 observations, K = 3 categories (c₁, c₂, c₃), and c₃ is the reference. The observations belong to categories: c₁, c₂, c₁, c₃, c₂.

The design matrix X (intercept + 2 dummies + one continuous predictor z) is:

```
     1   D₁  D₂   z
  [  1    1   0   z₁ ]
  [  1    0   1   z₂ ]
  [  1    1   0   z₃ ]
  [  1    0   0   z₄ ]
  [  1    0   1   z₅ ]
```

The model is:

  y = β₀ + β₁D₁ + β₂D₂ + γz + ε

**Interpretation of coefficients:**

- β₀ = expected y for an observation in category c₃ (the reference) with z = 0.
- β₁ = expected difference in y between category c₁ and category c₃, holding z fixed.
- β₂ = expected difference in y between category c₂ and category c₃, holding z fixed.
- γ = expected change in y per one-unit increase in z, within any category.

The choice of reference category changes the numeric values of β₀, β₁, and β₂ but does not change fitted values or model fit. The reference category should be the substantively meaningful baseline (usually the largest or most theoretically central group).

---

## Part B: Linear Transformations of Variables

### Setup

Let X be a random variable with mean μ_X and variance σ²_X. Define a linearly transformed variable:

  Z = aX + b

where a ≠ 0 and b are constants.

### Effect on the mean

The expected value operator is linear:

  E[Z] = E[aX + b]
       = aE[X] + b
       = aμ_X + b

So adding a constant b shifts the mean by b, and multiplying by a scales the mean by a.

### Effect on the variance

Variance measures spread around the mean, so additive shifts vanish:

  Var(Z) = Var(aX + b)
          = E[(aX + b - E[aX + b])²]
          = E[(aX + b - aμ_X - b)²]
          = E[(a(X - μ_X))²]
          = a²E[(X - μ_X)²]
          = a²σ²_X

The standard deviation transforms as:

  σ_Z = |a| · σ_X

Adding a constant has no effect on spread. Multiplying by a scales the standard deviation by |a|.

### Effect on a regression coefficient

Suppose the regression model is:

  y = α + βX + ε

and you replace X with Z = aX + b. Substituting X = (Z - b)/a:

  y = α + β · (Z - b)/a + ε
    = (α - βb/a) + (β/a)Z + ε

So the new coefficient on Z is β/a, and the new intercept is α - βb/a.

Practical consequences:

- *Centering (b = -X̄, a = 1):* the coefficient is unchanged; only the intercept changes to reflect the new zero point.
- *Standardizing (b = -X̄, a = 1/s_X):* the coefficient becomes β · s_X, interpretable as the change in y per one-standard-deviation increase in X.
- *Rescaling for interpretability (e.g., a = 1/1000 to convert dollars to thousands):* the coefficient becomes β · 1000, i.e., it grows by the inverse of the scaling factor.

This means that renaming or rescaling a variable to make it human-readable does not distort your estimates; it changes only the numeric representation of the coefficient, not the underlying relationship.

---

## Part C: Missing Value Propagation

### Formal definition

Let X be a variable for observation i. Define the missing indicator:

  M_i = 1  if X_i is missing (not observed)
  M_i = 0  if X_i is observed

In software, a missing value is represented by a special token (NaN in Python/R, `.` in Stata). The propagation rule for arithmetic is:

  If M_i = 1, then f(X_i) = NaN for any function f.

Concretely: NaN + 3 = NaN, NaN × 5 = NaN, max(NaN, 2) = NaN (in most implementations). Missing-ness is contagious within an expression.

### The bias from treating sentinel codes as valid values

Suppose the true distribution of X has N_obs observed values x₁, ..., x_{n_obs} and N_mis missing cases. The data supplier encodes missing as the sentinel value s (e.g., s = 9 for "refused" on a 1-5 scale, or s = 99 for "don't know" on an age variable).

If an analyst fails to declare s as missing and instead includes it in a mean calculation:

  X̄_corrupt = (1/(n_obs + N_mis)) · [Σ_{i: M_i=0} x_i + N_mis · s]

The true mean of observed values is:

  X̄_true = (1/n_obs) · Σ_{i: M_i=0} x_i

The bias is:

  Bias = X̄_corrupt - X̄_true

Substituting:

  X̄_corrupt = (n_obs · X̄_true + N_mis · s) / (n_obs + N_mis)

  Bias = (n_obs · X̄_true + N_mis · s) / (n_obs + N_mis) - X̄_true

  Bias = [n_obs · X̄_true + N_mis · s - (n_obs + N_mis) · X̄_true] / (n_obs + N_mis)

  Bias = [N_mis · s - N_mis · X̄_true] / (n_obs + N_mis)

  Bias = N_mis(s - X̄_true) / (n_obs + N_mis)

Let f_mis = N_mis / (n_obs + N_mis) be the missing fraction. Then:

  Bias = f_mis · (s - X̄_true)

**Reading the formula:**

- If the sentinel s is larger than the true mean (e.g., s = 9 on a 1-5 scale where X̄_true ≈ 3), the bias is positive: the corrupt mean is inflated.
- The bias grows linearly with the missing fraction f_mis. Even 5% missing with s = 9 and X̄_true = 3 produces a bias of 0.05 × 6 = 0.30 scale points, which on a 5-point scale is substantively non-trivial.
- The bias is zero only if s = X̄_true (the sentinel happens to equal the true mean, which is never guaranteed) or if f_mis = 0 (no missing data).

### Propagation into regression

If X (with sentinel codes left as valid values) enters a regression as a predictor, the bias in X̄ propagates into bias in β̂. The OLS formula β̂ = (X'X)⁻¹X'y depends on the cross-products of every row of X with the outcome y. Sentinel values in X create spurious covariance between X and y that has nothing to do with the true relationship. There is no general closed-form expression for this bias because it depends on which observations are missing and whether missingness is related to y, but the direction and rough magnitude can be assessed by examining the sentinel value relative to the observed distribution of X.

The only safe rule: declare all sentinel codes as missing before any arithmetic, before any regression, before any cross-tabulation. This is not a preliminary nicety; it is a validity requirement.
