# Module 10 — Multiple Imputation: Math

## Symbols Used in This File

| Symbol | Meaning |
|---|---|
| M | Number of imputed datasets |
| m | Index over imputed datasets, m = 1, ..., M |
| Q̂_m | Point estimate of parameter Q from imputed dataset m |
| Û_m | Within-imputation variance (= squared SE) from dataset m |
| Q̄ | Pooled point estimate across M datasets |
| Ū | Average within-imputation variance |
| B | Between-imputation variance |
| T | Total variance of pooled estimate |
| λ | Fraction of missing information (FMI) |
| ν | Degrees of freedom for pooled test |
| Xⱼ | The j-th variable being imputed |
| X₋ⱼ | All variables except Xⱼ |
| p | Number of variables with missing values |
| T_iter | Number of MICE iterations |
| α, σ²_Z, σ²_ε | Parameters in a linear model used for variance derivation |

---

## Part A — Rubin's Rules

After creating M complete imputed datasets and running the analysis on each, you have M sets of estimates. Rubin's rules combine them into a single inferential statement.

### Step 1: Pool the Point Estimates

The pooled estimate is the simple average across M imputed datasets:

Q̄ = (1/M) Σₘ₌₁ᴹ Q̂_m

This is unbiased for the true population parameter Q under MAR, because each Q̂_m is an unbiased estimate and the averaging over M datasets averages over the imputation uncertainty.

### Step 2: Compute the Within-Imputation Variance

Let Û_m = [SE(Q̂_m)]² be the estimated variance of Q̂_m from imputed dataset m. The average within-imputation variance is:

Ū = (1/M) Σₘ₌₁ᴹ Û_m

This captures the ordinary sampling variability you would have with complete data: how much the estimate would vary across samples of the same size from the population.

### Step 3: Compute the Between-Imputation Variance

The between-imputation variance captures how much the estimates vary across the M datasets due to uncertainty about the missing values:

B = [1/(M-1)] Σₘ₌₁ᴹ (Q̂_m - Q̄)²

This is just the sample variance of the M point estimates. If the missing data contribute little uncertainty (few missing values, strong predictors), B will be small. If the missing data are informative for Q, B will be large.

### Step 4: Total Variance

The total variance combines both sources with a finite-M correction:

T = Ū + (1 + 1/M) · B

The factor (1 + 1/M) accounts for the fact that Q̄ is itself estimated from a finite number M of imputed datasets rather than from infinitely many. If M → ∞, the factor approaches 1 and T = Ū + B. For finite M, the between-imputation variance is slightly inflated.

**Why (1 + 1/M) and not (1)?**

If you had an infinite number of imputations, the average Q̄ would converge to the true posterior mean of Q given the observed data, and B would equal the true posterior variance B_∞. With only M imputations, the estimator Q̄ has an additional source of variability: the Monte Carlo error from using M draws instead of ∞. The variance of this Monte Carlo error is B_∞/M ≈ B/M. Adding this to B_∞ ≈ B gives B + B/M = (1 + 1/M)B.

### Step 5: Pooled Standard Error and Inference

The pooled standard error is:

SE_pooled = √T

The pooled test statistic for H₀: Q = 0 is:

t = Q̄ / √T

which is referred to a t-distribution with ν degrees of freedom (see Part B).

---

## Part B — Degrees of Freedom: The Barnard-Rubin Formula

### Fraction of Missing Information

The FMI λ quantifies how much of the total variance T is attributable to the missing data:

λ = (1 + 1/M) · B / T

When λ = 0, all uncertainty comes from sampling variability (no information lost to missingness). When λ = 1, all uncertainty comes from the imputation (the data provide essentially no information about Q).

### Adjusted Degrees of Freedom

For a complete dataset of size n with k regression coefficients, degrees of freedom for a t-test would be n - k. With imputed data, the effective degrees of freedom depend on both M and λ:

ν = (M - 1) / λ²

This is the large-sample (Barnard-Rubin) formula. The original Rubin (1987) formula is slightly different; software typically implements a modified version that also accounts for the complete-data degrees of freedom. The key behavior:

- When λ is small (few missing data), ν is large, and the t-distribution approaches normal. The missing data impose little penalty.
- When λ is large (severe missingness), ν is small, giving a heavy-tailed t-distribution and wide confidence intervals. This is correct: severe missing data genuinely reduce what you can conclude.
- When M is small, ν is also constrained by M - 1, penalizing for having too few imputed datasets. This is why older practice (M = 5) with high FMI (λ = 0.4) gave only ν = (5-1)/0.16 = 25 degrees of freedom even for large n. Increasing M to 20 gives ν = 19/0.16 = 119, much closer to the complete-data degrees of freedom.

---

## Part C — The MICE Algorithm

### Setup

Let there be p variables X₁, X₂, ..., Xₚ each with some missing values, on n observations.

**Initialization:** Replace all missing values with column means:

x̃ⱼᵢ ← x̄ⱼ   for all i where Xⱼ is missing

These initial values are rough. Their only purpose is to provide a starting point for the iterative procedure.

### One MICE Iteration

For each variable j = 1, 2, ..., p in turn:

1. **Set aside current imputations for Xⱼ.** Identify the set Mⱼ = {i : Xⱼᵢ is originally missing}. For these rows, the current value of x̃ⱼᵢ is a working imputation, not observed data.

2. **Fit the imputation model.** Using only the observed rows of Xⱼ (all i not in Mⱼ), fit a regression:

   Xⱼ = β₀ + X₋ⱼ β + ε

   where X₋ⱼ is the matrix of all other variables (using their currently imputed values for any rows where they were missing). Obtain coefficient estimates β̂ and residual variance estimate σ̂².

3. **Draw from the posterior.** Draw new coefficient values from their posterior distribution:

   σ²* ~ [Scaled Inverse-χ² with n_obs - p degrees of freedom and scale σ̂²]
   β* ~ N(β̂, σ²* (X'_obs X_obs)⁻¹)

   where n_obs is the number of observed rows for Xⱼ and X_obs is the predictor matrix on those rows.

4. **Generate imputed values.** For each row i in Mⱼ, draw:

   x̃ⱼᵢ ~ N(x_{-j,i} β*, σ²*)

   This replaces the previous imputed value with a new draw from the posterior predictive distribution.

After cycling through all j, one iteration is complete.

### Convergence

Run the cycle for T_iter iterations. Convergence means the distribution of the imputed values has stabilized. In practice, check convergence by plotting the mean and variance of each imputed variable across iterations. These traces should appear stationary (no trend, mixing freely around a stable level) by roughly iteration 10-20.

**Theoretical justification:** Each pass through the p conditional distributions constitutes one sweep of a Gibbs sampler. Under regularity conditions (proper conditional posteriors, a proper joint posterior), the Gibbs sampler converges in distribution to the joint posterior p(X_missing | X_observed). This is the theoretically correct target: draws from this posterior predictive distribution represent M plausible complete datasets given the observed data.

After T_iter iterations, extract M complete datasets at evenly-spaced iteration points (or run M independent chains from different starting values). These are the M imputed datasets fed into Rubin's rules.

---

## Part D — Why the Posterior Draw Preserves Variance

**Claim:** Imputing the conditional mean E[Xⱼ | X₋ⱼ] instead of drawing from the posterior reduces the variance of the imputed variable below the true variance σ²_Xⱼ.

**Derivation:**

Suppose the true data-generating process is:

X = αZ + ε

where Z is a scalar predictor, ε ~ N(0, σ²_ε), and Z and ε are independent.

The true variance of X is:

Var(X) = α² Var(Z) + σ²_ε = α²σ²_Z + σ²_ε

Now suppose we impute missing values of X by the conditional mean:

x̃ = E[X | Z] = αZ

The variance of the imputed variable is:

Var(x̃) = α² Var(Z) = α²σ²_Z

Since σ²_ε > 0, we have:

Var(x̃) = α²σ²_Z < α²σ²_Z + σ²_ε = Var(X)

The imputed variable is less variable than the true variable. This is not a matter of degree; it is guaranteed whenever any residual variance exists in the true model (i.e., whenever prediction is not perfect).

**Consequence:** If X appears as a predictor in your outcome model, attenuating Var(X) reduces the variance of X in the dataset. The regression coefficient on X in the outcome model is:

β̂_X = Cov(X, Y) / Var(X)

If Var(X) is shrunk artificially toward zero while Cov(X, Y) is shrunk less or unchanged, β̂_X will be biased. The direction depends on the specific model, but in practice conditional mean imputation attenuates (shrinks toward zero) the correlation between X and Y, mimicking measurement error attenuation.

**The fix:** draw x̃ ~ N(αZ, σ²_ε) rather than setting x̃ = αZ. The draw adds back the residual noise, restoring Var(x̃) ≈ Var(X) in expectation. This is exactly what the posterior predictive draw in the MICE algorithm does at Step 4 of each variable's imputation.
