# Survey Weights — Math

## Setup and Notation

Let U = {1, 2, ..., N} be the finite population of N units. Each unit i has a value Yᵢ of the outcome of interest. We want to estimate the population total T = Σᵢ∈U Yᵢ and the population mean Ȳ = T/N.

A probability sample S ⊆ U is drawn such that each unit i has a known, nonzero inclusion probability πᵢ = P(i ∈ S). The inclusion probabilities need not be equal.

---

## Part A: The Horvitz-Thompson Estimator

### Defining the Estimator

The Horvitz-Thompson (HT) estimator of the population total is:

T̂_HT = Σᵢ∈S Yᵢ / πᵢ

Define the design weight wᵢ = 1/πᵢ. Then T̂_HT = Σᵢ∈S wᵢ Yᵢ.

Interpretation: respondent i "represents" 1/πᵢ units of the population. If πᵢ = 0.1, then i was selected with 10% probability and stands in for 10 population members.

### Proving Unbiasedness

Define the sample membership indicator Iᵢ = 1 if i ∈ S, 0 otherwise. We can write the HT estimator over the full population:

T̂_HT = Σᵢ∈U Iᵢ · Yᵢ / πᵢ

Take the expectation over all possible samples S:

E[T̂_HT] = Σᵢ∈U E[Iᵢ] · Yᵢ / πᵢ

Because E[Iᵢ] = P(i ∈ S) = πᵢ:

E[T̂_HT] = Σᵢ∈U πᵢ · Yᵢ / πᵢ = Σᵢ∈U Yᵢ = T

The HT estimator is unbiased for T regardless of the outcome distribution. This is a pure design-based result.

### HT Estimator of the Population Mean

The population mean is Ȳ = T/N. In a probability sample, we often do not know N exactly (some units may be out of scope), so we estimate N by applying the same HT logic to a constant outcome Yᵢ = 1:

N̂ = Σᵢ∈S 1/πᵢ = Σᵢ∈S wᵢ

The HT estimator of the mean is then the ratio:

Ȳ_HT = T̂_HT / N̂ = (Σᵢ∈S wᵢ Yᵢ) / (Σᵢ∈S wᵢ)

This is a weighted mean where the weights are the design weights. Note this is a ratio estimator, not a linear estimator, so its unbiasedness is only approximate (it is consistent as n → ∞).

---

## Part B: Post-Stratification

### Setup

Suppose the population is divided into H non-overlapping post-strata indexed h = 1, ..., H with known population sizes N_h (from Census data or administrative records), where Σ_h N_h = N.

Within stratum h, the sample contains n_h units. The sample mean within stratum h is:

ȳ_h = (1/n_h) Σᵢ∈Sₕ Yᵢ

where Sₕ is the set of sampled units in stratum h.

### The Post-Stratified Estimator

The post-stratified estimator of the population mean is:

Ȳ_ps = Σ_h (N_h / N) ȳ_h

This is a weighted average of stratum means, where the weights are the population proportions N_h/N — not the sample proportions n_h/n.

### Showing This Is a Weighted Mean

Expand ȳ_h:

Ȳ_ps = Σ_h (N_h / N) · (1/n_h) · Σᵢ∈Sₕ Yᵢ

= Σ_h Σᵢ∈Sₕ (N_h / (N · n_h)) · Yᵢ

So the post-stratification weight for unit i in stratum h is:

wᵢ^(ps) = N_h / n_h   (up to the constant 1/N which cancels in the ratio estimator)

The post-stratified estimator is exactly the HT-style weighted mean with wᵢ = N_h / n_h. The ratio N_h / n_h adjusts for the fact that stratum h was either over- or undersampled relative to its population share.

### Why Post-Stratification Reduces Variance

If the stratum means ȳ_h vary across strata (i.e., H explains variance in Y), then post-stratification is more efficient than simple HT estimation because the calibration to known N_h pins down the weight given to each stratum. This is analogous to stratified random sampling, which reduces variance when the outcome varies more between strata than within them.

---

## Part C: Taylor Linearization for Variance Estimation

### The Problem

Many survey statistics are nonlinear functions of estimated totals: means, proportions, regression coefficients, and odds ratios all involve ratios or products of totals. We cannot apply simple variance formulas because the statistic is not a linear combination of the Yᵢ values.

### Linearization Setup

Let t = (t₁, t₂, ..., tₖ) be a vector of population totals, and let ĝ = g(t̂) be a smooth (differentiable) function of the estimated totals t̂ = (t̂₁, ..., t̂ₖ).

By a first-order Taylor expansion around the true value t:

g(t̂) ≈ g(t) + ∇g(t)' · (t̂ - t)

where ∇g(t) is the k×1 gradient vector with entries ∂g/∂tⱼ evaluated at t.

### Linearized Variance

Because g(t̂) ≈ g(t) plus a linear term, the variance of g(t̂) is approximately:

Var[g(t̂)] ≈ [∇g(t)]' · Var(t̂) · [∇g(t)]

In practice, we evaluate the gradient at t̂ rather than t, and plug in a design-based variance estimator for Var(t̂).

### Application to the Weighted Mean

The mean Ȳ = T_Y / T_1 where T_Y = Σ Yᵢ is the total of the outcome and T_1 = Σ 1 = N is the population size.

The gradient of g(t_Y, t_1) = t_Y / t_1 is:

∂g/∂t_Y = 1/t_1
∂g/∂t_1 = -t_Y / t_1²

So the linearized "score" for unit i is:

zᵢ = (1/N̂) · Yᵢ - (Ȳ_HT / N̂) · 1 = (Yᵢ - Ȳ_HT) / N̂

The variance of the mean reduces to:

Var(Ȳ_HT) ≈ (1/N²) · Var(Σᵢ∈S wᵢ (Yᵢ - Ȳ_HT))

### Application to Regression Coefficients

The OLS coefficient vector is β̂ = (X'WX)⁻¹ X'WY where W is the diagonal matrix of survey weights. This is a function of estimated cross-product totals (e.g., t_{XY} = Σ wᵢ XᵢYᵢ). Taylor linearization propagates variance through the matrix inversion to yield design-correct standard errors for β̂. This is why "robust" standard errors from survey packages differ from both OLS and heteroskedasticity-robust (sandwich) standard errors: the design-based variance accounts for the sampling structure, not just heteroskedasticity.

---

## Part D: The Design Effect

### Definition

Let Var_SRS(ȳ) = σ²/n be the variance of the sample mean under simple random sampling without replacement (approximately). Let Var_complex(ȳ) be the actual variance under the complex sampling design (with clustering, stratification, unequal probabilities). The design effect is:

DEFF = Var_complex(ȳ) / Var_SRS(ȳ)

DEFF > 1 means the design inflates variance relative to SRS; DEFF < 1 means it reduces variance.

### How Clustering Inflates Variance

Suppose n units are drawn in m clusters of size b each (so n = mb). Units within the same cluster share environmental, social, or interviewer effects, captured by the intraclass correlation ρ (ICC):

ρ = Cov(Yᵢ, Yⱼ | same cluster) / Var(Y)

The variance of the cluster-sample mean is approximately:

Var_cluster(ȳ) ≈ (σ²/n) · [1 + (b - 1)ρ]

So the design effect from clustering alone is:

DEFF_cluster = 1 + (b - 1)ρ

When ρ > 0 (units in the same cluster are more alike than random), DEFF > 1. For a cluster of size b = 20 and ρ = 0.05:

DEFF = 1 + (20 - 1)(0.05) = 1 + 0.95 = 1.95

The effective sample size is n / DEFF ≈ n/2. You need roughly twice as many clustered observations to achieve the same precision as a simple random sample. Ignoring clustering and using the SRS formula underestimates standard errors by a factor of √DEFF, producing confidence intervals that are too narrow and p-values that are too small.

### How Stratification Reduces Variance

When the population is divided into strata before sampling, and sampling is done independently within each stratum, the variance of the stratified estimator is:

Var_strat(ȳ) = Σ_h (N_h/N)² · (σ_h² / n_h)

where σ_h² is the within-stratum variance. Compare this to SRS variance σ²/n. The key gain comes from the between-stratum component of variance being eliminated: if the strata differ in their means, stratification removes that source of uncertainty, so DEFF < 1 and the design is more efficient than SRS.

In practice, the CES uses both stratification and clustering, so DEFF reflects the net result: clustering raises it, stratification lowers it, and the product is the actual design effect applied when computing standard errors.
