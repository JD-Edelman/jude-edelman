# Survey Weights: Mathematical Derivation

## Symbols

| Symbol | Meaning |
|--------|---------|
| U | Finite population of N units, U = {1, 2, ..., N} |
| N | Total number of units in the population |
| Yᵢ | Value of the outcome for unit i |
| T | Population total: T = Σᵢ∈U Yᵢ |
| Ȳ | Population mean: Ȳ = T/N |
| S | Probability sample drawn from U |
| πᵢ | Inclusion probability of unit i: P(i ∈ S) |
| wᵢ | Design weight for unit i: wᵢ = 1/πᵢ |
| Iᵢ | Sample membership indicator: 1 if i ∈ S, else 0 |
| T̂_HT | Horvitz-Thompson estimator of the population total |
| Ȳ_HT | Horvitz-Thompson estimator of the population mean |
| N̂ | Estimated population size from the sample |
| H | Number of post-strata |
| h | Post-stratum index |
| Nₕ | Known population size of stratum h |
| nₕ | Number of sampled units in stratum h |
| ȳₕ | Sample mean within stratum h |
| Ȳ_ps | Post-stratified estimator of the population mean |
| wᵢ^(ps) | Post-stratification weight for unit i in stratum h |
| g(t̂) | Smooth function of estimated population totals |
| ∇g(t) | Gradient vector of g evaluated at true totals t |
| zᵢ | Linearized score for unit i |
| DEFF | Design effect |
| ρ | Intraclass correlation (ICC) within clusters |
| b | Number of units per cluster |
| m | Number of clusters |
| σ² | Population variance of Y |
| σₕ² | Within-stratum variance in stratum h |

---

## Part A — The Horvitz-Thompson Estimator

**In practice:** When you download NYTD or CES data with survey weights, the weight variable is wᵢ = 1/πᵢ. Multiplying each person's outcome by their weight and summing gives a nationally representative total.

### Defining the Estimator

The **Horvitz-Thompson (HT) estimator** of the population total is:

```
T̂_HT = Σᵢ∈S Yᵢ / πᵢ
```

Define the **design weight** wᵢ = 1/πᵢ. Then:

```
T̂_HT = Σᵢ∈S wᵢ Yᵢ
```

A respondent with πᵢ = 0.05 gets weight 20, meaning they "count as" 20 population members in the estimate.

### Proving Unbiasedness

Define the sample membership indicator Iᵢ = 1 if i ∈ S, 0 otherwise. We can rewrite the HT estimator over the full population:

```
T̂_HT = Σᵢ∈U Iᵢ · Yᵢ / πᵢ
```

Take the expectation over all possible samples S:

```
E[T̂_HT] = Σᵢ∈U E[Iᵢ] · Yᵢ / πᵢ
```

Because E[Iᵢ] = P(i ∈ S) = πᵢ, the πᵢ cancels:

```
E[T̂_HT] = Σᵢ∈U πᵢ · Yᵢ / πᵢ = Σᵢ∈U Yᵢ = T
```

Unbiasedness holds regardless of how Y is distributed. The guarantee comes entirely from the probability sampling design, not from assumptions about the data.

### HT Estimator of the Population Mean

The population mean is Ȳ = T/N. We often do not know N exactly, so we estimate it by applying the HT logic to the constant outcome Yᵢ = 1:

```
N̂ = Σᵢ∈S 1/πᵢ = Σᵢ∈S wᵢ
```

The **HT estimator of the mean** is then the ratio:

```
Ȳ_HT = T̂_HT / N̂ = (Σᵢ∈S wᵢ Yᵢ) / (Σᵢ∈S wᵢ)
```

This is a **ratio estimator** and is only approximately unbiased; the approximation is excellent for large samples but can be slightly off for small n.

---

## Part B — Post-Stratification

**In practice:** If your survey over-sampled young adults, post-stratification re-weights each age group back to its known Census proportion, removing that source of bias before you run any regressions.

### Setup

Suppose the population is divided into H non-overlapping **post-strata** indexed h = 1, ..., H with known population sizes Nₕ (from Census data or administrative records), where Σₕ Nₕ = N.

Within stratum h, the sample contains nₕ units. The sample mean within stratum h is:

```
ȳₕ = (1/nₕ) Σᵢ∈Sₕ Yᵢ
```

where Sₕ is the set of sampled units in stratum h.

### The Post-Stratified Estimator

The **post-stratified estimator** of the population mean is:

```
Ȳ_ps = Σₕ (Nₕ / N) · ȳₕ
```

This is a weighted average of stratum means, where the weights are the population proportions Nₕ/N, not the sample proportions nₕ/n.

### Showing This Is a Weighted Mean

Expand ȳₕ:

```
Ȳ_ps = Σₕ (Nₕ / N) · (1/nₕ) · Σᵢ∈Sₕ Yᵢ
      = Σₕ Σᵢ∈Sₕ (Nₕ / (N · nₕ)) · Yᵢ
```

So the **post-stratification weight** for unit i in stratum h is:

```
wᵢ^(ps) = Nₕ / nₕ
```

(up to the constant 1/N, which cancels in the ratio estimator).

If young men are 15% of the population but only 8% of your sample, their weight is roughly 15/8 ≈ 1.88. Their responses are multiplied by that factor in every weighted estimate.

### Why Post-Stratification Reduces Variance

If the stratum means ȳₕ vary across strata (that is, H explains variance in Y), then post-stratification is more efficient than simple HT estimation. The calibration to known Nₕ pins down the weight given to each stratum, removing between-stratum variance from the error. This is analogous to stratified random sampling, which reduces variance when the outcome varies more between strata than within them.

---

## Part C — Taylor Linearization for Variance Estimation

**In practice:** This is why you must use svyset in Stata or the survey package in R. Applying OLS standard errors to weighted survey data ignores the design structure and typically produces standard errors that are too small.

### The Problem

Many survey statistics are nonlinear functions of estimated totals: means, proportions, regression coefficients, and odds ratios all involve ratios or products of totals. We cannot apply simple variance formulas because the statistic is not a linear combination of the Yᵢ values.

### Linearization Setup

Let t = (t₁, t₂, ..., tₖ) be a vector of population totals, and let ĝ = g(t̂) be a smooth (differentiable) function of the estimated totals t̂ = (t̂₁, ..., t̂ₖ).

By a first-order **Taylor expansion** around the true value t:

```
g(t̂) ≈ g(t) + ∇g(t)' · (t̂ - t)
```

where ∇g(t) is the k×1 gradient vector with entries ∂g/∂tⱼ evaluated at t.

### Linearized Variance

Because g(t̂) ≈ g(t) plus a linear term, the variance of g(t̂) is approximately:

```
Var[g(t̂)] ≈ [∇g(t)]' · Var(t̂) · [∇g(t)]
```

In practice, we evaluate the gradient at t̂ rather than t, and plug in a design-based variance estimator for Var(t̂).

### Application to the Weighted Mean

The mean Ȳ = T_Y / T_1 where T_Y = Σ Yᵢ and T_1 = Σ 1 = N. The gradient of g(t_Y, t_1) = t_Y / t_1 is:

```
∂g/∂t_Y = 1/t_1
∂g/∂t_1 = -t_Y / t_1²
```

So the linearized "score" for unit i is:

```
zᵢ = (Yᵢ - Ȳ_HT) / N̂
```

The variance of the mean reduces to:

```
Var(Ȳ_HT) ≈ (1/N²) · Var(Σᵢ∈S wᵢ (Yᵢ - Ȳ_HT))
```

This is why survey package standard errors are larger than naive OLS standard errors even with the same data and model. The design-based variance accounts for the full sampling structure, not just heteroskedasticity.

### Application to Regression Coefficients

The OLS coefficient vector is β̂ = (X'WX)⁻¹ X'WY where W is the diagonal matrix of survey weights. This is a function of estimated cross-product totals (for example, t_{XY} = Σ wᵢ XᵢYᵢ). Taylor linearization propagates variance through the matrix inversion to yield design-correct standard errors for β̂.

---

## Part D — The Design Effect

**In practice:** Cluster sampling (selecting households within neighborhoods, students within schools) is cheaper but statistically less efficient than simple random sampling. DEFF tells you exactly how much efficiency you have lost.

### Definition

Let Var_SRS(ȳ) = σ²/n be the variance of the sample mean under simple random sampling. Let Var_complex(ȳ) be the actual variance under the complex sampling design. The **design effect** is:

```
DEFF = Var_complex(ȳ) / Var_SRS(ȳ)
```

DEFF > 1 means the design inflates variance relative to SRS; DEFF < 1 means it reduces variance.

### How Clustering Inflates Variance

Suppose n units are drawn in m clusters of size b each (so n = mb). Units within the same cluster share environmental, social, or interviewer effects, captured by the **intraclass correlation** ρ (ICC):

```
ρ = Cov(Yᵢ, Yⱼ | same cluster) / Var(Y)
```

The variance of the cluster-sample mean is approximately:

```
Var_cluster(ȳ) ≈ (σ²/n) · [1 + (b - 1)ρ]
```

So the design effect from clustering alone is:

```
DEFF_cluster = 1 + (b - 1)ρ
```

For a cluster of size b = 20 and ρ = 0.05:

```
DEFF = 1 + (20 - 1)(0.05) = 1 + 0.95 = 1.95
```

Your 2,000-person clustered sample gives you the precision of a simple random sample of about 1,026. Ignoring clustering and using the SRS formula underestimates standard errors by a factor of √DEFF, producing confidence intervals that are too narrow and p-values that are too small.

### How Stratification Reduces Variance

When the population is divided into strata before sampling, the variance of the stratified estimator is:

```
Var_strat(ȳ) = Σₕ (Nₕ/N)² · (σₕ² / nₕ)
```

where σₕ² is the within-stratum variance. The key gain: the between-stratum component of variance is eliminated. If the strata differ in their means, stratification removes that source of uncertainty, yielding DEFF < 1. In practice, most complex surveys use both stratification and clustering, so DEFF reflects the net result: clustering raises it, stratification lowers it, and their combination is the actual design effect applied when computing standard errors.
