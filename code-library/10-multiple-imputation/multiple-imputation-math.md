# Multiple Imputation: Mathematical Derivation

## Symbols

| Symbol | Meaning |
|--------|---------|
| M | Number of imputed datasets |
| m | Index over imputed datasets, m = 1, ..., M |
| Q | True population parameter of interest (e.g., a regression coefficient) |
| Q̂_m | Point estimate of Q from the analysis of imputed dataset m |
| Û_m | Within-imputation variance (squared SE) from imputed dataset m |
| Q̄ | Pooled point estimate across M datasets (Rubin's Rules) |
| Ū | Average within-imputation variance |
| B | Between-imputation variance |
| T | Total variance of the pooled estimate |
| λ | Fraction of missing information (FMI) |
| ν | Degrees of freedom for the pooled t-test |
| Xⱼ | The j-th variable being imputed |
| X₋ⱼ | All variables except Xⱼ |
| Mⱼ | Set of row indices where Xⱼ is originally missing |
| x̃ⱼᵢ | Current imputed value of Xⱼ for observation i |
| x̄ⱼ | Column mean of Xⱼ over observed rows |
| p | Number of variables with missing values |
| T_iter | Number of MICE Gibbs sampler iterations |
| β̂, σ̂² | OLS coefficient estimate and residual variance from the imputation model |
| β* , σ²* | Posterior draws of imputation model parameters |
| α | True coefficient in the data-generating process for the variance derivation |
| σ²_Z | Variance of the predictor Z in the variance derivation |
| σ²_ε | Residual variance in the data-generating process |
| n_obs | Number of observed rows for variable Xⱼ in the current MICE step |

---

## Part A — Rubin's Rules

**In practice:** You run your regression (or whatever analysis) on each of the M completed datasets separately, producing M sets of estimates. Rubin's Rules tell you how to combine them into a single publishable result: one coefficient, one standard error, one p-value.

### Step 1: Pool the Point Estimates

The pooled estimate is the simple average of the M estimates:

```
Q̄ = (1/M) Σₘ₌₁ᴹ Q̂_m
```

This is unbiased for the true population parameter Q under MAR, because each Q̂_m is an unbiased estimate and averaging over M datasets averages out the imputation uncertainty.

If your 20 imputed datasets give education coefficients of 0.31, 0.28, 0.33, and so on, the pooled estimate is their average: roughly 0.30. This is a weighted average of the information in each complete dataset.

### Step 2: Compute the Within-Imputation Variance

Let Û_m = [SE(Q̂_m)]² be the estimated variance of Q̂_m from imputed dataset m. Average these across all M datasets:

```
Ū = (1/M) Σₘ₌₁ᴹ Û_m
```

This is the uncertainty you would have even if there were no missing data. It is the ordinary sampling variability, reflecting how much the estimate would bounce around across different samples of the same size from the population.

### Step 3: Compute the Between-Imputation Variance

The between-imputation variance captures how much the M point estimates differ from each other due to uncertainty about the missing values:

```
B = [1/(M-1)] Σₘ₌₁ᴹ (Q̂_m - Q̄)²
```

This is the sample variance of the M point estimates. If the missing data contribute little uncertainty (few missing values, or strong predictors in the imputation model), B will be small. If the missing data are informative for Q, B will be large.

If B is large relative to Ū, your missing data are informative for the parameter of interest and you need more imputations (larger M) to stabilize the estimate.

### Step 4: Total Variance

The total variance of the pooled estimate combines both sources with a finite-M correction:

```
T = Ū + (1 + 1/M) · B
```

The factor (1 + 1/M) accounts for the fact that Q̄ is estimated from a finite number M of imputed datasets rather than infinitely many. If M → ∞, the factor approaches 1 and T = Ū + B. The extra 1/M term is the **Monte Carlo error** in Q̄ from using only M draws: the variance of Q̄ as a Monte Carlo estimator of the posterior mean contributes B/M to the total variance.

With M = 5 imputations and λ = 0.30, your SE is inflated by about 30% relative to a complete dataset. With M = 20, the Monte Carlo error in that inflation is negligible.

### Step 5: Pooled Inference

The pooled standard error:

```
SE_pooled = √T
```

The pooled test statistic for H₀: Q = 0:

```
t = Q̄ / √T
```

This t-statistic is referred to a t-distribution with ν degrees of freedom, derived in Part B below.

---

## Part B — Degrees of Freedom and the Fraction of Missing Information

**In practice:** FMI and degrees of freedom tell you how much the missing data are costing you. A high FMI means your missing data substantially inflate your standard errors and reduce the power of your tests.

### Fraction of Missing Information (FMI)

The **FMI** λ quantifies what proportion of the total variance T is attributable to the missing data rather than to ordinary sampling variability:

```
λ = (1 + 1/M) · B / T
```

When λ = 0, all uncertainty comes from sampling variability (no information is lost to missingness). When λ = 1, all uncertainty comes from the imputation (the data provide essentially no information about Q).

An FMI of 0.05 means the missing data cost you about 5% efficiency, which is essentially nothing. An FMI of 0.40 means your effective sample size is about 60% of what it would be with complete data.

### Adjusted Degrees of Freedom

The **Barnard-Rubin** degrees-of-freedom formula for imputed data is:

```
ν = (M - 1) / λ²
```

The key behavior:

- When λ is small (little missing data), ν is large and the t-distribution approaches the normal. The missing data impose little penalty.
- When λ is large (severe missingness), ν is small, giving a heavy-tailed t-distribution and wide confidence intervals. This is appropriate: severe missing data genuinely reduce what you can conclude.
- When M is small, ν is also constrained by M - 1, penalizing you for having too few imputed datasets.

### Numerical Example

Suppose λ = 0.20 (20% of the variance is due to missing data).

With M = 20 imputations:

```
ν = (20 - 1) / (0.20)²
  = 19 / 0.04
  = 475
```

With M = 5 imputations and the same λ:

```
ν = (5 - 1) / (0.20)²
  = 4 / 0.04
  = 100
```

More imputations give you more degrees of freedom for the test, producing less conservative inference. With M = 5, you are using a t(100) distribution; with M = 20, you are nearly at the normal (t(475) ≈ z). The old default of M = 5 imputations was adequate only when FMI was very small. For FMI around 0.20 or higher, M = 20 or more is advisable.

---

## Part C — The MICE Algorithm

**In practice:** MICE (Multivariate Imputation by Chained Equations) is how modern software (R's `mice`, Stata's `mi impute chained`) actually generates the imputed datasets. It handles mixed variable types and complex missingness patterns by iterating through one variable at a time.

### Setup

Let there be p variables X₁, X₂, ..., Xₚ each with some missing values, on n observations.

**Initialization:** Replace all missing values with column means:

```
x̃ⱼᵢ ← x̄ⱼ   for all i where Xⱼ is missing
```

These initial values are rough placeholders. Their only purpose is to give the iterative procedure somewhere to start.

### One MICE Iteration

For each variable j = 1, 2, ..., p in turn:

**Step 1: Identify missing rows.** Let Mⱼ = {i : Xⱼᵢ is originally missing}. For these rows, x̃ⱼᵢ is a working imputation, not real data.

**Step 2: Fit the imputation model.** Using only the observed rows of Xⱼ (all i not in Mⱼ), fit a regression:

```
Xⱼ = β₀ + X₋ⱼ β + ε
```

where X₋ⱼ is the matrix of all other variables, using their currently imputed values for any rows where they were missing. Obtain coefficient estimates β̂ and residual variance estimate σ̂².

**Step 3: Draw from the posterior.** Rather than using β̂ directly, draw new parameter values from the posterior distribution:

```
σ²* ~ [Scaled Inverse-χ² with n_obs - p degrees of freedom and scale σ̂²]
β*  ~ N(β̂,  σ²* (X'_obs X_obs)⁻¹)
```

This step injects uncertainty about the imputation model itself. It is essential for preserving variance (see Part D).

**Step 4: Generate imputed values.** For each row i in Mⱼ, draw:

```
x̃ⱼᵢ ~ N(x_{-j,i} β*,  σ²*)
```

This replaces the previous imputed value with a draw from the **posterior predictive distribution**: a value that is plausible given the data and uncertain given the parameters.

After cycling through all p variables, one iteration is complete.

### Convergence

Run the cycle for T_iter iterations. Convergence means the distribution of imputed values has stabilized. In practice: run 10 to 20 iterations and plot the mean and SD of each imputed variable across iterations. If the traces look like white noise around a stable level, the chain has converged. A trace that is still trending upward or downward at iteration 20 indicates the chain has not mixed and you should run more iterations.

**Theoretical justification:** Each pass through the p conditional distributions constitutes one sweep of a **Gibbs sampler**. Under regularity conditions (proper conditional posteriors, a proper joint posterior), the Gibbs sampler converges in distribution to the joint posterior p(X_missing | X_observed). Draws from this posterior predictive distribution represent M plausible complete datasets given the observed data, which is exactly what Rubin's Rules require.

After T_iter burn-in iterations, extract M complete datasets at evenly-spaced iteration points (or run M independent chains from different starting values). These are the M imputed datasets that feed into Rubin's Rules.

---

## Part D — Why Posterior Draws Preserve Variance

**In practice:** Some older imputation approaches replace missing values with the regression prediction (the conditional mean). This section shows why that deflates variance and biases downstream analyses, and why the posterior draw in MICE fixes the problem.

**Claim:** Imputing the conditional mean E[Xⱼ | X₋ⱼ] instead of drawing from the posterior reduces the variance of the imputed variable below its true variance.

### Derivation

Suppose the true data-generating process is:

```
X = αZ + ε
```

where Z is a scalar predictor, ε ~ N(0, σ²_ε), and Z and ε are independent. The true variance of X:

```
Var(X) = α² Var(Z) + σ²_ε = α²σ²_Z + σ²_ε
```

Now suppose we impute missing values of X by the conditional mean:

```
x̃ = E[X | Z] = αZ
```

The variance of these imputed values:

```
Var(x̃) = α² Var(Z) = α²σ²_Z
```

Comparing:

```
Var(x̃) = α²σ²_Z  <  α²σ²_Z + σ²_ε = Var(X)
```

The imputed variable is less variable than the real variable. This is not a matter of degree; it is guaranteed whenever any residual variance σ²_ε > 0 exists in the true model, meaning whenever prediction is imperfect.

**Why this harms downstream analysis:** If X appears as a predictor in your outcome model, the regression coefficient on X depends on Var(X):

```
β̂_X = Cov(X, Y) / Var(X)
```

Artificially shrinking Var(X) while Cov(X, Y) is shrunk less (or not at all) biases β̂_X. The direction depends on the specific model, but in practice **conditional mean imputation** attenuates the correlation between X and Y, mimicking classical measurement error attenuation.

**The fix:** draw x̃ ~ N(αZ, σ²_ε) rather than setting x̃ = αZ. The draw adds back the residual noise, restoring Var(x̃) ≈ Var(X) in expectation. This is exactly what Step 4 of the MICE algorithm does.

Conditional mean imputation is like replacing every missing value with the regression prediction. It makes the imputed variable look like a perfect linear function of the predictors, which is never true of real data.
