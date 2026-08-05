# Module 12 — Panel Data: Math

## Symbols Used in This File

| Symbol | Meaning |
|---|---|
| i | Unit index (person, county, organization), i = 1, ..., N |
| t | Time index, t = 1, ..., T |
| Y_it | Outcome for unit i at time t |
| X_it | Vector of time-varying covariates for unit i at time t |
| α_i | Unit fixed effect (time-invariant, unit-specific intercept) |
| λ_t | Time fixed effect (unit-invariant, time-specific intercept) |
| ε_it | Idiosyncratic error term |
| β | Coefficient vector on time-varying covariates |
| Ȳ_i· | Mean of Y_it over time for unit i: (1/T) Σ_t Y_it |
| Ÿ_it | Within-transformed (demeaned) outcome: Y_it - Ȳ_i· |
| β̂_FE | Fixed effects estimator of β |
| β̂_RE | Random effects estimator of β |
| θ | Quasi-demeaning parameter in RE |
| σ²_α | Variance of unit effects α_i |
| σ²_ε | Variance of idiosyncratic errors ε_it |
| H | Hausman test statistic |
| k | Number of regressors in X_it |
| D_i, P_t | Treatment and post-period indicators in DiD |
| δ | DiD coefficient (ATT under parallel trends) |

---

## Part A — The Two-Way Error Components Model

The baseline panel data model is:

Y_it = α_i + λ_t + X_it β + ε_it

**Definitions of each term:**

- α_i is the unit fixed effect: a separate intercept for each unit i that captures everything about unit i that does not change over time (personality, geography, culture, historical legacies). There are N such parameters.
- λ_t is the time fixed effect: a separate intercept for each period t that captures anything affecting all units equally in that period (macroeconomic shocks, election years, national policy changes). There are T such parameters.
- X_it β is the contribution of time-varying covariates. β is the main object of interest.
- ε_it is the idiosyncratic error: the part of Y_it that is specific to unit i at time t and unexplained by everything else. Assumed E[ε_it] = 0 and Cov(X_it, ε_it) = 0.

The key property: α_i can be correlated with X_it. If high-α_i units (those with high baseline outcomes) also have persistently high X_it values (richer counties have better infrastructure and more economic activity), OLS on pooled data would be biased. FE allows and corrects for this correlation.

---

## Part B — The Within (Demeaning) Transformation

### Derivation of the Transformation

Compute the time-mean of the model for unit i:

Ȳ_i· = α_i + λ̄_i· + X̄_i· β + ε̄_i·

where λ̄_i· = (1/T) Σ_t λ_t and X̄_i· = (1/T) Σ_t X_it and ε̄_i· = (1/T) Σ_t ε_it.

Subtract the time-mean from the original equation:

Y_it - Ȳ_i· = (α_i - α_i) + (λ_t - λ̄_i·) + (X_it - X̄_i·)β + (ε_it - ε̄_i·)

Define the within-transformed variables:

Ÿ_it = Y_it - Ȳ_i·
Ẍ_it = X_it - X̄_i·
ε̈_it = ε_it - ε̄_i·

The unit effect α_i cancels exactly (α_i - α_i = 0). The demeaned model is:

Ÿ_it = (λ_t - λ̄_i·) + Ẍ_it β + ε̈_it

If time fixed effects λ_t are included, they are handled by adding period dummies to the within-transformed regression (or by time-demeaning as well). The unit effect is eliminated regardless.

### The FE Estimator

After demeaning, OLS on the transformed data gives the FE estimator:

β̂_FE = (Σ_i Σ_t Ẍ_it Ẍ_it')⁻¹ (Σ_i Σ_t Ẍ_it Ÿ_it)

This is the standard OLS formula applied to the within-transformed data. β̂_FE estimates only from variation within units over time; cross-unit variation is fully absorbed by the demeaning.

### Unbiasedness Despite Correlated Unit Effects

**Claim:** β̂_FE is unbiased even when Cov(α_i, X_it) ≠ 0.

**Proof sketch:**

Substitute the true model into the FE estimator:

β̂_FE = β + (Σ_i Σ_t Ẍ_it Ẍ_it')⁻¹ (Σ_i Σ_t Ẍ_it ε̈_it)

For unbiasedness we need E[Σ_i Σ_t Ẍ_it ε̈_it] = 0.

Note that Ẍ_it = X_it - X̄_i· and ε̈_it = ε_it - ε̄_i·. The term Σ_i Σ_t Ẍ_it ε̈_it involves only the within-unit variation in X and ε. If Cov(X_it, ε_it) = 0 (the standard strict exogeneity assumption), then:

E[Ẍ_it ε̈_it] = E[(X_it - X̄_i·)(ε_it - ε̄_i·)] = Cov(X_it, ε_it) - Cov(X̄_i·, ε_it) - ...

Under strict exogeneity (X_it uncorrelated with ε_is for all s and t), all covariance terms involving X and ε vanish and E[β̂_FE] = β.

Critically: the term involving α_i was eliminated by demeaning. Even if α_i is arbitrarily correlated with X_it, it does not appear in the demeaned model and cannot bias β̂_FE.

---

## Part C — Random Effects GLS

### The Quasi-Demeaning Transformation

Instead of subtracting the full unit mean, RE subtracts a fraction θ of it:

Y*_it = Y_it - θ Ȳ_i·

where:

θ = 1 - σ_ε / √(T σ²_α + σ²_ε)

**Interpretation of θ:**

θ depends on the signal-to-noise ratio of the unit effects.

- If σ²_α is very large relative to σ²_ε (unit effects dominate): T σ²_α >> σ²_ε, so √(T σ²_α + σ²_ε) ≈ √(T σ²_α) >> σ_ε, so θ ≈ 1. The transformation approaches full demeaning and RE approaches FE.

- If σ²_α ≈ 0 (no unit effects): √(T σ²_α + σ²_ε) ≈ σ_ε, so θ ≈ 1 - 1 = 0. No demeaning; RE approaches pooled OLS.

RE thus uses a data-adaptive blend of within-unit and cross-unit information. When unit effects are negligible, cross-unit variation is informative and RE uses it. When unit effects are large, only within-unit variation is reliable and RE leans toward FE.

The RE estimator is:

β̂_RE = (Σ_i Σ_t X*_it X*_it')⁻¹ (Σ_i Σ_t X*_it Y*_it)

where X*_it = X_it - θ X̄_i· is the quasi-demeaned predictor.

**The critical assumption for RE consistency:** Cov(α_i, X_it) = 0. The unit effects must be uncorrelated with the predictors. Unlike FE, RE cannot accommodate this correlation because it does not eliminate α_i.

---

## Part D — The Hausman Test

### Setup

Under H₀ (RE is consistent), both β̂_FE and β̂_RE are consistent estimators of β. Their difference β̂_FE - β̂_RE converges to zero in probability.

Under H₁ (RE is inconsistent because Cov(α_i, X_it) ≠ 0), β̂_RE is biased and inconsistent while β̂_FE remains consistent. The difference β̂_FE - β̂_RE diverges from zero.

### Test Statistic

H = (β̂_FE - β̂_RE)' [Var(β̂_FE) - Var(β̂_RE)]⁻¹ (β̂_FE - β̂_RE)

Under H₀, H ~ χ²(k) where k is the number of regressors in X_it.

**Why [Var(β̂_FE) - Var(β̂_RE)]?**

Under H₀, RE is efficient (Gauss-Markov among linear unbiased estimators), so Var(β̂_RE) ≤ Var(β̂_FE) element-wise. The matrix [Var(β̂_FE) - Var(β̂_RE)] is positive semi-definite under H₀, making the test statistic non-negative. The Hausman (1978) result shows that under H₀:

Cov(β̂_FE, β̂_RE) = Var(β̂_RE)

(FE and RE share the same asymptotic information about β when both are consistent). This means Var(β̂_FE - β̂_RE) = Var(β̂_FE) - Var(β̂_RE), which is used in the denominator.

**Decision rule:** Reject RE in favor of FE if H > χ²_critical(k) at your chosen significance level (typically 0.05). In practice, many researchers use the clustered-robust version of this test.

---

## Part E — DiD as a 2×2 Regression

### Setup

Define:
- D_i = 1 if unit i is in the treated group, D_i = 0 if control
- P_t = 1 if time period t is post-treatment, P_t = 0 if pre-treatment

The DiD estimator is the coefficient on the interaction D_i × P_t in the regression:

Y_it = β₀ + β₁ D_i + β₂ P_t + β₃ (D_i × P_t) + ε_it

### Showing β₃ is the DiD Estimator

Compute the cell means from the regression:

- E[Y | D=0, P=0] = β₀
- E[Y | D=0, P=1] = β₀ + β₂
- E[Y | D=1, P=0] = β₀ + β₁
- E[Y | D=1, P=1] = β₀ + β₁ + β₂ + β₃

The double difference:

(E[Y|D=1,P=1] - E[Y|D=1,P=0]) - (E[Y|D=0,P=1] - E[Y|D=0,P=0])

= [(β₀ + β₁ + β₂ + β₃) - (β₀ + β₁)] - [(β₀ + β₂) - β₀]

= (β₂ + β₃) - β₂

= β₃

So β₃ exactly equals the difference-in-differences: the pre-post change in the treated group minus the pre-post change in the control group.

### The ATT Under Parallel Trends

The ATT (average treatment effect on the treated) is:

ATT = E[Y_it(1) - Y_it(0) | D_i = 1, P_t = 1]

where Y_it(1) is the potential outcome with treatment and Y_it(0) is the counterfactual outcome without treatment. Only Y_it(1) is observed for treated units post-treatment.

The parallel trends assumption states:

E[Y_it(0) | D_i=1, P_t=1] - E[Y_it(0) | D_i=1, P_t=0] = E[Y_it(0) | D_i=0, P_t=1] - E[Y_it(0) | D_i=0, P_t=0]

In words: the counterfactual trend for the treated group equals the observed trend for the control group. Under this assumption:

ATT = (Ȳ_{treated,post} - Ȳ_{treated,pre}) - (Ȳ_{control,post} - Ȳ_{control,pre}) = β₃

The regression estimator β̂₃ is an unbiased estimator of the ATT under parallel trends and the usual OLS assumptions on ε_it.
