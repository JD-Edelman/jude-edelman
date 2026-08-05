# Recode, Rename, Generate: Mathematical Derivation

## Symbols

| Symbol | Meaning |
|--------|---------|
| C | A categorical variable taking K distinct values |
| K | Number of categories in C |
| D_k | Indicator (dummy) variable for category k; equals 1 if observation belongs to category k, 0 otherwise |
| X | Design matrix (n × p), including intercept column and predictor columns |
| X' | Transpose of X |
| β̂ | OLS coefficient vector estimate |
| β₀ | Intercept coefficient |
| β₁ | Slope or group-difference coefficient |
| ȳ₁, ȳ₀ | Sample means of the outcome in the group where D=1 and D=0 respectively |
| y | n×1 vector of observed outcomes |
| Z | Linearly transformed version of predictor X |
| a | Multiplicative scaling constant in the linear transformation Z = aX + b |
| b | Additive shift constant in the linear transformation Z = aX + b |
| μ | Population mean of X |
| σ² | Population variance of X |
| E[·] | Expectation operator |
| Var(·) | Variance operator |
| R_i | Missingness indicator: 1 if observation i is observed, 0 if missing |
| p | Proportion of observations that are observed (non-missing) |
| s | Sentinel (missing) code value (e.g., 9 or 99) |
| x̄_true | True mean of the variable among observed cases |
| x̄_cont | Contaminated mean computed when sentinel codes are left as valid values |
| f_mis | Fraction of observations that are missing |

---

## Part A — Indicator (Dummy) Variable Algebra

**In practice:** When you recode a categorical variable like race or region into dummies in Stata, software creates K−1 new columns. Understanding the algebra behind this choice helps you interpret intercepts correctly and avoid the perfect multicollinearity trap.

### Why K−1 dummies, not K

We need to understand what goes wrong when all K dummies are included. Each observation belongs to exactly one category, so the sum of all K indicator variables equals 1 for every row. That means the sum of all K dummy columns equals the intercept column, which is also all ones.

```
D₁ + D₂ + ... + D_K = 1   (for every observation i)
```

This is an exact linear dependency among the columns of X. When columns of X are perfectly collinear, the matrix X'X is singular (its determinant is zero) and the inverse (X'X)⁻¹ does not exist. OLS has no unique solution. Dropping one category, the **reference category**, removes this dependency and makes the system solvable.

The reference category determines what the intercept means: β₀ is the predicted outcome for an observation in the reference group, holding all other predictors at zero. Changing the reference category changes the numeric value of β₀ and of the remaining dummy coefficients, but does not change fitted values or model fit in any way.

### The design matrix for a 3-category variable

Suppose race has three categories: White (reference), Black, and Other. We include two dummies: D_Black and D_Other. Consider four example observations:

```
Observation   Race      D_Black   D_Other
     1        White        0         0
     2        Black        1         0
     3        Other        0         1
     4        Black        1         0
```

With an intercept column prepended, the design matrix X for these four rows looks like:

```
     Intercept   D_Black   D_Other
  [     1           0         0    ]   <- White
  [     1           1         0    ]   <- Black
  [     1           0         1    ]   <- Other
  [     1           1         0    ]   <- Black
```

The model is:

```
y = β₀ + β₁·D_Black + β₂·D_Other + ε
```

β₀ is the expected outcome for White respondents. β₁ is the mean difference between Black and White respondents, holding other predictors fixed. β₂ is the mean difference between Other and White respondents. No coefficient directly compares Black to Other, but that comparison can be computed as β₁ − β₂.

### The OLS coefficient on a single dummy equals a mean difference

For the simple case of one dummy D ∈ {0,1} and an intercept, the design matrix is:

```
X = [ 1   D₁  ]
    [ 1   D₂  ]
    [ ...      ]
    [ 1   Dₙ  ]
```

Compute X'X and X'y:

```
X'X = [ n       n₁      ]
      [ n₁      n₁      ]
```

where n₁ = Σ Dᵢ is the count of observations with D=1 and n₀ = n − n₁ is the count with D=0. Similarly:

```
X'y = [ Σ yᵢ        ]
      [ Σ Dᵢ yᵢ     ]
```

Inverting X'X and multiplying by X'y yields:

```
β̂₀ = ȳ₀   (mean of y among D=0 group)
β̂₁ = ȳ₁ − ȳ₀   (difference in means)
```

The OLS coefficient on a dummy variable is exactly the difference in group means. This confirms that regression with a single binary predictor and an intercept reproduces a two-sample comparison of means. If you add covariates, β̂₁ becomes the mean difference adjusted for those covariates rather than the raw difference.

---

## Part B — Linear Transformations and What They Do to Regression Coefficients

**In practice:** Researchers frequently rescale variables for interpretability: converting income from dollars to thousands, centering age at its mean, or standardizing a scale score. The math below shows exactly how those choices ripple through coefficient estimates.

### How a linear transformation changes means and variances

Let X be a variable with mean μ and variance σ². Define a new variable:

```
Z = aX + b
```

where a ≠ 0 and b are constants. The expected value of Z follows from linearity of expectation:

```
E[Z] = E[aX + b] = a·E[X] + b = aμ + b
```

Adding b shifts the mean by b; multiplying by a scales it by a. For the variance, additive shifts disappear because variance measures spread around the center, not the center itself:

```
Var(Z) = Var(aX + b)
       = E[(aX + b − (aμ + b))²]
       = E[(a(X − μ))²]
       = a²·E[(X − μ)²]
       = a²σ²
```

The standard deviation transforms as:

```
σ_Z = |a| · σ_X
```

Two special cases matter most in practice. **Mean-centering** sets b = −X̄ and a = 1, so the new variable has mean zero but identical variance and the regression coefficient is unchanged; only the intercept shifts to the predicted value at the mean of X. **Standardizing** sets a = 1/s_X and b = −X̄/s_X, producing a variable with mean 0 and standard deviation 1; the coefficient on the standardized variable is interpretable as the change in y per one-standard-deviation increase in X.

### How a linear transformation changes a regression coefficient

Suppose the true regression model is:

```
y = β₀ + β₁·X + ε
```

Now replace X with Z = aX + b. To see what happens to the coefficient, substitute X = (Z − b)/a:

```
y = β₀ + β₁·(Z − b)/a + ε
  = (β₀ − β₁b/a) + (β₁/a)·Z + ε
```

The new coefficient on Z is:

```
β̂₁_new = β̂₁ / a
```

and the new intercept is β₀ − β₁b/a. The slope rescales by the inverse of a. If you double the unit of X (a = 2, say converting years to half-years), the coefficient halves. If you divide X by 1000 (converting dollars to thousands, so a = 1/1000), the coefficient multiplies by 1000. This is why coefficients on age in years and age in decades cannot be compared numerically without rescaling; the underlying relationship is the same, but the unit of measurement differs by a factor of 10.

Predictions are unaffected: for any observation, β̂₀ + β̂₁·x = (β₀ − β₁b/a) + (β₁/a)·(ax+b), and these simplify to the same number. Rescaling is always a representational choice, not a substantive one.

---

## Part C — Missing Value Propagation and Bias from Sentinel Codes

**In practice:** Survey datasets routinely encode "refused," "don't know," and "not applicable" with numeric sentinel codes like 7, 8, 9, 97, 98, 99. If you forget to recode these before computing means or running regressions, you will silently contaminate every downstream statistic. The math below makes the size of that contamination precise.

### Setup: observed and missing cases

Let X be a variable for n total observations. Define the **missingness indicator**:

```
R_i = 1   if observation i is observed (valid)
R_i = 0   if observation i is missing
```

Let p = (1/n)Σ R_i be the proportion observed, so 1−p is the missing fraction. The true mean among observed cases is:

```
x̄_true = (1 / Σ R_i) · Σ R_i · x_i
```

### Contaminated mean when the sentinel code is treated as valid

Suppose the missing code is s (a number like 9 or 99). If the analyst leaves s in the data, the computed mean treats it as a real data value:

```
x̄_cont = (1/n) · [ Σ R_i · x_i  +  s · Σ(1 − R_i) ]
```

This can be rewritten using p and x̄_true. The sum of observed values is n·p·x̄_true, and the count of missing cases is n·(1−p):

```
x̄_cont = (1/n) · [ n·p·x̄_true + n·(1−p)·s ]
        = p · x̄_true + (1−p) · s
```

The contaminated mean is a weighted average of the true mean and the sentinel value, with the missing fraction as the weight on s. The **bias** is:

```
Bias = x̄_cont − x̄_true
     = p·x̄_true + (1−p)·s − x̄_true
     = (1−p)·s − (1−p)·x̄_true
     = (1−p) · (s − x̄_true)
```

Reading this formula: the bias equals the missing fraction times the gap between the sentinel code and the true mean. When s > x̄_true (the common case, since sentinel codes are often at the top of a scale), the bias is positive and the contaminated mean is inflated. The bias grows linearly with the proportion missing.

### Worked numerical example

Suppose you have a 1-to-5 satisfaction scale with a true mean of 3.0, and 10% of respondents are coded 9 for "refused":

```
x̄_cont = 0.90 · 3.0 + 0.10 · 9
        = 2.70 + 0.90
        = 3.60

Bias = (1 − 0.90) · (9 − 3.0) = 0.10 · 6 = 0.60
```

A contaminated mean of 3.60 compared to a true mean of 3.0 is a 20% upward distortion, large enough to reverse substantive conclusions. If 20% of cases are missing rather than 10%, the bias doubles to 1.20, more than an entire scale point. The only safe rule is to declare all sentinel codes as missing before any arithmetic, any regression, or any cross-tabulation.

### Propagation into regression

When a contaminated X enters a regression as a predictor, the spurious covariance between X and y (driven entirely by the sentinel values, not by any real relationship) contaminates β̂. The OLS formula β̂ = (X'X)⁻¹X'y depends on cross-products of every row of X with y. Sentinel values in X create artificial variation that has nothing to do with the true relationship. The direction of the resulting bias in β̂ depends on whether missingness is correlated with the outcome, so there is no simple general formula, but the problem is always present and always avoidable by proper recoding.
