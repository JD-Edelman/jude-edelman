# Panel Data: Mathematical Derivation

## Symbols

| Symbol | Meaning |
|--------|---------|
| i | Unit index (person, county, organization), i = 1, ..., N |
| t | Time index, t = 1, ..., T |
| Y_it | Outcome for unit i at time t |
| X_it | Vector of time-varying covariates for unit i at time t |
| α_i | Unit fixed effect (time-invariant, unit-specific intercept) |
| λ_t | Time fixed effect (unit-invariant, time-specific intercept) |
| ε_it | Idiosyncratic error: unit-and-time-specific residual |
| β | Coefficient vector on time-varying covariates (main target of inference) |
| Ȳ_i· | Time-mean of Y for unit i: (1/T) Σ_t Y_it |
| X̄_i· | Time-mean of X for unit i: (1/T) Σ_t X_it |
| λ̄_i· | Time-mean of time effects: (1/T) Σ_t λ_t |
| ε̄_i· | Time-mean of idiosyncratic errors for unit i |
| Ÿ_it | Within-transformed outcome: Y_it - Ȳ_i· |
| Ẍ_it | Within-transformed predictor: X_it - X̄_i· |
| ε̈_it | Within-transformed error: ε_it - ε̄_i· |
| β̂_FE | Fixed effects estimator of β |
| β̂_RE | Random effects GLS estimator of β |
| θ | Quasi-demeaning parameter in the RE transformation |
| σ²_α | Variance of unit effects α_i across units |
| σ²_ε | Variance of idiosyncratic errors ε_it |
| Y*_it | Quasi-demeaned outcome in the RE transformation |
| X*_it | Quasi-demeaned predictor in the RE transformation |
| H | Hausman test statistic |
| k | Number of regressors in X_it |
| D_i | Treatment indicator: D_i = 1 if treated unit, 0 if control |
| P_t | Post-period indicator: P_t = 1 if post-treatment period, 0 if pre |
| β₀, β₁, β₂, β₃ | Regression coefficients in the DiD model |
| δ | ATT (average treatment effect on the treated) under parallel trends |
| Y_it(1), Y_it(0) | Potential outcomes with and without treatment |

---

## Part A — The Two-Way Error Components Model

**In practice:** Every panel regression starts here. The decomposition of the error term into a unit effect, a time effect, and an idiosyncratic residual is what makes panel data different from a cross-section.

The baseline panel data model:

```
Y_it = α_i + λ_t + X_it β + ε_it
```

Each component plays a distinct role:

- α_i is the **unit fixed effect**: a separate intercept for each unit i that captures everything about unit i that does not change over time. There are N such parameters.
- λ_t is the **time fixed effect**: a separate intercept for each period t that captures anything affecting all units equally in that period (macroeconomic shocks, election years, national policy changes). There are T such parameters.
- X_it β is the contribution of **time-varying covariates**. β is the main object of inference.
- ε_it is the **idiosyncratic error**: the part of Y_it specific to unit i at time t and unexplained by everything else. Assumed E[ε_it] = 0 and Cov(X_it, ε_it) = 0.

α_i is everything about person i that does not change: personality, family background, innate ability, race, place of birth. You never need to measure these things explicitly. The fixed effects estimator automatically controls for all of them, whether or not you know what they are.

The key property of this model is that α_i can be freely correlated with X_it. If high-α_i units (those with high baseline outcomes) also have persistently high X_it values, pooled OLS would be biased. Fixed effects allows and corrects for this correlation.

---

## Part B — Within Transformation and the FE Estimator

**In practice:** The fixed effects estimator works by removing the unit effect entirely before estimating β. This section shows the algebra.

### Derivation of the Within Transformation

Compute the time-mean of the model for unit i by averaging both sides over t:

```
Ȳ_i· = α_i + λ̄_i· + X̄_i· β + ε̄_i·
```

Subtract the time-mean from the original equation period by period:

```
Y_it - Ȳ_i· = (α_i - α_i) + (λ_t - λ̄_i·) + (X_it - X̄_i·)β + (ε_it - ε̄_i·)
```

Define the **within-transformed** (demeaned) variables:

```
Ÿ_it = Y_it - Ȳ_i·
Ẍ_it = X_it - X̄_i·
ε̈_it = ε_it - ε̄_i·
```

The unit effect α_i cancels exactly because α_i - α_i = 0. The demeaned model:

```
Ÿ_it = (λ_t - λ̄_i·) + Ẍ_it β + ε̈_it
```

This is the magic of fixed effects. A variable correlated with both X and Y will bias OLS, but if it is time-invariant, demeaning removes it entirely, even if you never observed it or even knew it existed.

### The FE Estimator

After demeaning, OLS on the transformed data gives the **FE estimator**:

```
β̂_FE = (Σ_i Σ_t Ẍ_it Ẍ_it')⁻¹ (Σ_i Σ_t Ẍ_it Ÿ_it)
```

This is the standard OLS formula applied to within-transformed data. β̂_FE estimates β using only variation within units over time. Cross-unit variation is fully absorbed by the demeaning and contributes nothing to the estimate.

FE only uses variation within units across time. If education never changes for anyone in your panel, it drops out entirely and you cannot estimate its effect. This is the key limitation of fixed effects: any time-invariant predictor, including demographic variables like race or sex, cannot be identified.

### Unbiasedness Despite Correlated Unit Effects

**Claim:** β̂_FE is unbiased even when Cov(α_i, X_it) ≠ 0.

**Proof sketch:** Substitute the true model into the FE estimator:

```
β̂_FE = β + (Σ_i Σ_t Ẍ_it Ẍ_it')⁻¹ (Σ_i Σ_t Ẍ_it ε̈_it)
```

For unbiasedness we need:

```
E[Σ_i Σ_t Ẍ_it ε̈_it] = 0
```

Under **strict exogeneity** (X_it is uncorrelated with ε_is for all s and t, not just the contemporaneous error), all covariance terms involving X and ε vanish:

```
E[Ẍ_it ε̈_it] = E[(X_it - X̄_i·)(ε_it - ε̄_i·)] = 0
```

and therefore E[β̂_FE] = β.

Critically: the term involving α_i was eliminated by demeaning before this expectation was ever taken. Even if α_i is arbitrarily correlated with X_it, it does not appear in the demeaned model and cannot bias β̂_FE.

Pooled OLS regressing ideology on income would be biased if high-income people are also systematically more conservative for non-income reasons (some fixed α_i). FE removes that bias by looking only at how each person's ideology changed when their own income changed over time.

---

## Part C — Random Effects GLS

**In practice:** RE is more efficient than FE when the unit effects are actually uncorrelated with the predictors. RE uses both within-unit and between-unit variation. The Hausman test (Part D) decides which is appropriate.

### The Quasi-Demeaning Transformation

Instead of subtracting the full unit mean, RE subtracts a fraction θ of it:

```
Y*_it = Y_it - θ Ȳ_i·
```

where θ is chosen to be:

```
θ = 1 - σ_ε / √(T σ²_α + σ²_ε)
```

Think of θ as a dial. When θ = 1, RE equals FE (use only within-unit variation). When θ = 0, RE equals pooled OLS (use all variation, both within and between units). The data choose θ based on how large the unit effects are relative to the idiosyncratic noise.

**Interpretation of the two extremes:**

If σ²_α is very large (unit effects dominate): T σ²_α >> σ²_ε, so √(T σ²_α + σ²_ε) >> σ_ε, so θ ≈ 1. Full demeaning. RE approaches FE.

If σ²_α ≈ 0 (no unit effects): √(T σ²_α + σ²_ε) ≈ σ_ε, so θ ≈ 1 - 1 = 0. No demeaning. RE approaches pooled OLS.

The RE estimator:

```
β̂_RE = (Σ_i Σ_t X*_it X*_it')⁻¹ (Σ_i Σ_t X*_it Y*_it)
```

where X*_it = X_it - θ X̄_i· is the quasi-demeaned predictor.

**The critical assumption for RE consistency:** Cov(α_i, X_it) = 0. The unit effects must be uncorrelated with the predictors. Unlike FE, RE does not eliminate α_i from the model; it treats α_i as part of the composite error. If α_i is correlated with X_it, the composite error is correlated with X_it and β̂_RE is biased and inconsistent.

---

## Part D — The Hausman Test

**In practice:** The Hausman test is the standard way to choose between FE and RE. It asks whether the two estimators give the same answer in your data.

### Setup

Under H₀ (RE is consistent), both β̂_FE and β̂_RE are consistent. Their difference converges to zero in probability.

Under H₁ (RE is inconsistent because Cov(α_i, X_it) ≠ 0), β̂_RE is biased while β̂_FE remains consistent. The difference diverges from zero.

### Test Statistic

```
H = (β̂_FE - β̂_RE)' [Var(β̂_FE) - Var(β̂_RE)]⁻¹ (β̂_FE - β̂_RE)
```

Under H₀, H ~ χ²(k) where k is the number of regressors in X_it.

**Why [Var(β̂_FE) - Var(β̂_RE)] in the denominator?**

Under H₀, RE is efficient (Gauss-Markov among linear unbiased estimators), so Var(β̂_RE) ≤ Var(β̂_FE). The matrix [Var(β̂_FE) - Var(β̂_RE)] is positive semi-definite under H₀, making H non-negative. The Hausman (1978) result shows that under H₀:

```
Cov(β̂_FE, β̂_RE) = Var(β̂_RE)
```

which means:

```
Var(β̂_FE - β̂_RE) = Var(β̂_FE) - Var(β̂_RE)
```

This identity is what allows the denominator to serve as the correct variance for the difference.

**Decision rule:** Reject RE in favor of FE if H > χ²_critical(k) at your chosen significance level (typically 0.05). In practice, many researchers use the clustered-robust version of this test.

A significant Hausman test (p < 0.05) tells you to use FE. The unit effects are correlated with your predictors, and RE's efficiency advantage is not worth the bias it introduces.

---

## Part E — DiD as a 2×2 Regression

**In practice:** Difference-in-differences is the most common quasi-experimental design in sociology. The regression formulation generalizes the simple 2×2 table to handle controls, multiple periods, and staggered treatment timing.

### Setup

Define:

- D_i = 1 if unit i is in the treated group, D_i = 0 if control
- P_t = 1 if time period t is post-treatment, P_t = 0 if pre-treatment

The **DiD estimator** is the coefficient on the interaction D_i × P_t in the regression:

```
Y_it = β₀ + β₁ D_i + β₂ P_t + β₃ (D_i × P_t) + ε_it
```

### Showing β₃ is the DiD Estimator

Compute the four group means implied by the regression:

```
E[Y | D=0, P=0] = β₀
E[Y | D=0, P=1] = β₀ + β₂
E[Y | D=1, P=0] = β₀ + β₁
E[Y | D=1, P=1] = β₀ + β₁ + β₂ + β₃
```

The **double difference** (post-minus-pre for treated, minus post-minus-pre for control):

```
(E[Y|D=1,P=1] - E[Y|D=1,P=0]) - (E[Y|D=0,P=1] - E[Y|D=0,P=0])
  = [(β₀ + β₁ + β₂ + β₃) - (β₀ + β₁)] - [(β₀ + β₂) - β₀]
  = (β₂ + β₃) - β₂
  = β₃
```

β₃ exactly equals the difference-in-differences: the pre-to-post change in the treated group minus the pre-to-post change in the control group.

The DiD estimate β₃ is literally the 2×2 table double difference. You could compute it by hand from four group means. The regression just formalizes this and lets you add control variables, cluster standard errors, and extend to multiple periods.

### The ATT Under Parallel Trends

The **ATT** (average treatment effect on the treated) is:

```
ATT = E[Y_it(1) - Y_it(0) | D_i = 1, P_t = 1]
```

where Y_it(1) is the potential outcome under treatment and Y_it(0) is the counterfactual (what the treated unit would have experienced without treatment). Only Y_it(1) is observed for treated units in the post period.

The **parallel trends assumption** provides the counterfactual:

```
E[Y_it(0) | D_i=1, P_t=1] - E[Y_it(0) | D_i=1, P_t=0]
  = E[Y_it(0) | D_i=0, P_t=1] - E[Y_it(0) | D_i=0, P_t=0]
```

In words: the trend the treated group would have followed without treatment equals the observed trend for the control group. Under this assumption:

```
ATT = (Ȳ_{treated,post} - Ȳ_{treated,pre}) - (Ȳ_{control,post} - Ȳ_{control,pre}) = β₃
```

The regression estimator β̂₃ is an unbiased estimator of the ATT under parallel trends and the usual OLS assumptions on ε_it. Parallel trends is an assumption about counterfactual trends, not about pre-treatment levels, and it cannot be tested directly (only the pre-treatment portion of the trend is observed).
