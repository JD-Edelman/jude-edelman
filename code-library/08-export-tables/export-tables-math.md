# Export Tables: Mathematical Derivation

## Symbols

| Symbol | Meaning |
|--------|---------|
| Y | n×1 outcome vector |
| X | n×p design matrix (includes intercept column) |
| β | p×1 true coefficient vector |
| β̂ | OLS estimator: β̂ = (X'X)⁻¹X'Y |
| ε | n×1 error vector |
| ê | n×1 residual vector: ê = Y - Xβ̂ |
| n | Number of observations |
| p | Number of parameters (including intercept) |
| SSR | Residual sum of squares: ê'ê = Σᵢ êᵢ² |
| SST | Total sum of squares: Σᵢ (yᵢ - ȳ)² |
| SSM | Model sum of squares: SST - SSR |
| σ² | True error variance |
| σ̂² | Estimated error variance: SSR/(n-p) |
| σₖ | True standard deviation of β̂ₖ |
| SE(β̂ₖ) | Estimated standard error of β̂ₖ |
| t | t-statistic for testing H₀: βₖ = 0 |
| t_{α/2, n-p} | t critical value with n-p degrees of freedom |
| R² | Coefficient of determination |
| R²_adj | Adjusted R² |
| ℓ̂ | Maximized log-likelihood |
| p̂ᵢ | Predicted probability in logistic regression |
| AIC | Akaike Information Criterion |
| BIC | Bayesian Information Criterion (Schwarz criterion) |
| MDE | Minimum detectable effect |
| z_{α/2} | Standard normal critical value at tail probability α/2 |
| z_γ | Standard normal critical value for power 1-γ |

---

## Part A — The t-Statistic and p-Value

**In practice:** Every regression output you will ever read contains t-statistics and p-values. Understanding the derivation tells you exactly what assumptions are required for those numbers to be valid, and when to be skeptical of them.

### Setup

We have fit the OLS model Y = Xβ + ε where Y is an n×1 outcome vector, X is an n×p design matrix (including the intercept column), β is a p×1 coefficient vector, and ε is an n×1 error vector.

The OLS estimator is:

```
β̂ = (X'X)⁻¹X'Y
```

Under the OLS assumptions (X is full rank; ε ~ N(0, σ²I)), the distribution of β̂ is:

```
β̂ ~ N(β, σ²(X'X)⁻¹)
```

For a single coefficient β̂ₖ:

```
β̂ₖ ~ N(βₖ, σ² · [(X'X)⁻¹]ₖₖ)
```

Standardizing:

```
(β̂ₖ - βₖ) / σₖ ~ N(0, 1)
```

where σₖ = σ · √[(X'X)⁻¹]ₖₖ.

### Deriving the t-Statistic

We don't know σ, so replace it with σ̂ = √(SSR/(n-p)). The **estimated standard error** is:

```
SE(β̂ₖ) = σ̂ · √[(X'X)⁻¹]ₖₖ
```

Under the null hypothesis H₀: βₖ = 0, the ratio:

```
t = β̂ₖ / SE(β̂ₖ)
```

follows a t-distribution with n - p degrees of freedom. This requires two facts:
1. (β̂ₖ - 0) / σₖ ~ N(0, 1)
2. (n-p)σ̂² / σ² ~ χ²_{n-p}, and this quantity is independent of β̂ₖ

The ratio of a standard normal to the square root of a χ²_{n-p}/(n-p) quantity is, by definition, a t_{n-p} random variable.

In Stata output this t-statistic appears in the "t" column. In R's summary(), it is labeled "t value". The p-value in the next column is 2·P(T > |t|).

### Two-Sided p-Value

The two-sided p-value for observed test statistic t_obs is:

```
p = 2 · P(T > |t_obs| | H₀)
```

where T ~ t_{n-p}. The factor of 2 accounts for both tails of the symmetric distribution. We reject H₀ at level α when p < α, equivalently when |t_obs| > t_{α/2, n-p}. As n grows large relative to p, the t_{n-p} distribution converges to N(0,1), which is why large-sample work uses z = 1.96 as the 95% critical value.

---

## Part B — Confidence Intervals

**In practice:** A regression table without confidence intervals forces readers to do mental arithmetic from β̂ and SE to recover the interval. Most journals now require or strongly prefer CIs. Reporting them also subtly shifts attention from significance to magnitude.

### Deriving the CI from the Pivot Quantity

The key is the **pivot quantity**: a function of the data and the parameter whose distribution does not depend on any unknown parameter.

```
(β̂ₖ - βₖ) / SE(β̂ₖ) ~ t_{n-p}
```

We know this distribution exactly (t_{n-p} under normality assumptions). Define t_{α/2, n-p} as the critical value such that P(|T| ≤ t_{α/2, n-p}) = 1 - α.

Start from the probability statement:

```
P(-t_{α/2, n-p} ≤ (β̂ₖ - βₖ) / SE(β̂ₖ) ≤ t_{α/2, n-p}) = 1 - α
```

Multiply all parts by SE(β̂ₖ) (positive, so inequality direction preserved):

```
P(-t_{α/2, n-p} · SE(β̂ₖ) ≤ β̂ₖ - βₖ ≤ t_{α/2, n-p} · SE(β̂ₖ)) = 1 - α
```

Subtract β̂ₖ and multiply by -1 (flip inequalities):

```
P(β̂ₖ - t_{α/2, n-p} · SE(β̂ₖ) ≤ βₖ ≤ β̂ₖ + t_{α/2, n-p} · SE(β̂ₖ)) = 1 - α
```

The **(1-α) confidence interval** is:

```
β̂ₖ ± t_{α/2, n-p} · SE(β̂ₖ)
```

For α = 0.05 and large n: t_{0.025, n-p} ≈ 1.96. For small samples (n - p < 30), the exact t critical value is noticeably larger, making the interval wider to reflect the additional uncertainty from estimating σ.

A 95% CI of [0.12, 0.48] means: in repeated sampling, 95% of such intervals would contain the true β. It does NOT mean "there is a 95% chance β is in this interval." The true β is fixed, not random. The interval is the random object here, varying from sample to sample.

---

## Part C — R² and Adjusted R²

**In practice:** R² is the first thing many readers look at in a regression table. Understanding when it is informative and when it is not will prevent you from both over-trusting and under-trusting reported model fit.

### Decomposition of Variance

Define:

```
SST = Σ(yᵢ - ȳ)²         (total variation in Y around its mean)
SSR = Σêᵢ²                (residual variation unexplained by the model)
SSM = SST - SSR            (variation explained by the model)
```

**R²** is the proportion of variance in Y explained by the model:

```
R² = SSM / SST = 1 - SSR / SST
```

An R² of 0.35 in a cross-sectional sociology study is typical and reasonable. An R² of 0.95 in the same context should raise suspicion of collinearity, overfitting, or a conceptual problem like predicting a variable with itself.

### Why R² Cannot Decrease When a Variable Is Added

Adding a predictor gives the OLS estimator more degrees of freedom to minimize SSR. The unconstrained minimizer over a larger parameter space can only do as well as or better than the constrained minimizer over the smaller space.

Formally: let β̂ be the OLS estimates with p parameters, and let β̂* be the OLS estimates with p+1 parameters. Setting the new variable's coefficient to zero in the expanded model recovers the original model exactly, achieving the same SSR. Since OLS minimizes SSR, the expanded model achieves:

```
SSR* ≤ SSR
```

Therefore:

```
R²* = 1 - SSR*/SST ≥ 1 - SSR/SST = R²
```

R² is a non-decreasing function of the number of predictors. A model with 20 random noise variables will have higher R² than the same model with 10 of them, even though the extra 10 predict nothing. This is why you should never compare models by raw R² alone when they have different numbers of predictors.

### Adjusted R²

**Adjusted R²** penalizes for added parameters by adjusting both SSR and SST by their respective degrees of freedom:

```
R²_adj = 1 - (SSR / (n - p)) / (SST / (n - 1))
```

Expanding:

```
R²_adj = 1 - (SSR · (n - 1)) / (SST · (n - p))
        = 1 - (1 - R²) · (n - 1) / (n - p)
```

When a new variable is added, p increases by 1 and the denominator (n - p) decreases. This makes the penalty term (1 - R²)(n-1)/(n-p) larger, reducing R²_adj unless the new variable reduces SSR enough to compensate. A variable that explains nothing increases SSR/(n-p) because the denominator shrinks while the numerator is nearly unchanged. Adjusted R² can therefore decrease when an uninformative variable is added, which is the desirable property for model comparison.

---

## Part D — AIC and BIC for Likelihood-Based Models

**In practice:** AIC and BIC are the workhorse model-selection criteria for logistic regression, mixed models, and survival models, where R² has no clean interpretation. They give you a principled way to compare models with different numbers of predictors.

### Likelihood Setup

Logistic regression estimates parameters β by maximizing the **log-likelihood**. With binary outcome Yᵢ ∈ {0,1} and predicted probability p̂ᵢ = 1/(1 + exp(-Xᵢβ)):

```
ℓ(β) = Σᵢ [Yᵢ log(p̂ᵢ) + (1 - Yᵢ) log(1 - p̂ᵢ)]
```

Let ℓ̂ = ℓ(β̂) be the **maximized log-likelihood** (evaluated at the MLE). Higher ℓ̂ means better fit. Adding parameters always weakly increases ℓ̂, for the same reason R² cannot decrease; so raw likelihood cannot serve as a model-selection criterion.

### AIC

The **Akaike Information Criterion** is:

```
AIC = -2ℓ̂ + 2p
```

where p is the number of estimated parameters. The term -2ℓ̂ is the **deviance** (lower is better fit); the term 2p is the penalty for complexity. AIC is on a scale where lower is better.

The factor of 2 is conventional and derives from Akaike's asymptotic result: the expected difference in log-likelihood between a fitted model and a new dataset from the same process is approximately p (the number of parameters). Multiplying by -2 puts AIC on the deviance scale.

### BIC

The **Bayesian Information Criterion** (also called the Schwarz criterion) is:

```
BIC = -2ℓ̂ + p · ln(n)
```

The penalty is now p · ln(n) instead of 2p. For n > e² ≈ 7.4, we have ln(n) > 2, so BIC penalizes complexity more severely than AIC. For n = 1,000 (a modest survey sample), ln(1000) ≈ 6.9, so BIC penalizes each parameter roughly 3.5 times more heavily than AIC. For n = 60,000 (roughly the CES 2020 sample), ln(60,000) ≈ 11.0, making BIC extremely conservative about adding parameters.

### Worked Comparison

Suppose you fit two logistic regression models on the same outcome:

```
Model 1: AIC = 1420, p = 8 parameters
Model 2: AIC = 1404, p = 10 parameters
```

Model 2 is preferred. The lower-AIC model is preferred. The difference of 16 is large by conventional standards (a difference greater than 10 is considered strong evidence against the higher-AIC model). Note that Model 2 has more parameters but still wins, because its improved fit (lower deviance) more than compensates for the added complexity penalty.

The practical consequence of the AIC/BIC tradeoff: in large samples, AIC tends to prefer more complex models (it rewards fit gains from adding predictors), while BIC tends to prefer simpler models (its large-n penalty overwhelms modest fit improvements). For applied social science where parsimony and interpretability matter, BIC's conservatism is often appropriate. For prediction tasks where fit matters more, AIC is often preferred.

---

## Part E — What Significance Stars Hide

**In practice:** Significance stars are ubiquitous in sociology tables, but they compress continuous p-values into a three-level categorical variable. Understanding what they hide is essential for correctly reading other people's work and for deciding how much information your own tables communicate.

### What Stars Are

Stars encode the p-value into three categories:

```
*   denotes p < .05
**  denotes p < .01
*** denotes p < .001
```

These correspond to the null rejection region for one of three pre-specified thresholds. They are decision rules built into the reporting format.

A coefficient with p = 0.048 and a coefficient with p = 0.002 both get one star in most schemes. They are telling very different stories about the evidence.

### The Power-Versus-Sample-Size Tradeoff

Consider a true population effect β = 0.10 (substantively small but nonzero) in a two-sided t-test. The t-statistic is:

```
t = β̂ / SE(β̂) = β̂ / (σ / √n)
```

As n grows, SE → 0 and t → ∞. For any fixed nonzero effect β, there exists n large enough that t exceeds 1.96 with probability approaching 1. A survey of 60,000 respondents will produce statistically significant results for effects that are trivially small in substantive terms.

Now consider a small study (n = 200) with a large true effect β = 0.50. The t-statistic may still fall below 1.96 because SE = σ/√200 is large. The estimate will not earn a star despite the large effect.

### Minimum Detectable Effect

At the 5% level with power 1-γ, the **minimum detectable effect** (MDE) satisfies:

```
MDE = (z_{α/2} + z_γ) · SE = (1.96 + z_γ) · σ/√n
```

For 80% power: z_{0.20} = 0.84, so:

```
MDE = 2.80 · σ/√n
```

As n doubles, MDE shrinks by √2 ≈ 1.41. A study with four times the sample size can detect effects half as large. Stars tell you nothing about where the study sits on this curve. A *** result in a very large sample may be a negligible effect; a blank in a small study may be a large effect the study lacked power to detect.

### Why Reporting Both p-Values and Effect Sizes Is More Informative

The full information content of a hypothesis test is captured by reporting:
1. β̂ (the point estimate, giving direction and magnitude)
2. SE(β̂) or the 95% CI (giving precision)
3. The exact p-value (giving the probability of the observed |t| or larger under H₀)
4. A substantive interpretation of β̂ (what does a one-unit change mean in context?)

Stars contribute only to point 3, and only in a coarsened form. They are useful as a quick scan for readers, but they are not a substitute for the quantities above. Reporting "β̂ = 0.03, SE = 0.01, p = .003 ***" gives more information than "β̂ = 0.03 ***", and incomparably more than "***" alone.
