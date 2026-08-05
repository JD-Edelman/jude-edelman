# Module 09 — Data Cleaning: Math

## Symbols Used in This File

| Symbol | Meaning |
|---|---|
| X | Variable of interest, possibly with missing values |
| Z | Set of fully observed covariates |
| R | Missingness indicator: R = 1 if X is observed, R = 0 if X is missing |
| x̄ | Sample mean of X over observed values |
| s | Sample standard deviation of X |
| xᵢ | The i-th observation of X |
| n | Total sample size |
| Q1, Q3 | 25th and 75th percentiles |
| IQR | Interquartile range = Q3 - Q1 |
| Φ | Standard normal CDF |
| σ² | Population variance |
| μ | Population mean |

---

## Part A — Formalizing the Three Missing Data Mechanisms

Let X be a variable with some missing values. Define a binary indicator R where R = 1 if the observation is present and R = 0 if it is absent. The mechanism of missingness is a statement about how R relates to X and to other observed variables Z.

### MCAR (Missing Completely at Random)

**Definition:** P(R = 0 | X, Z) = P(R = 0) for all values of X and Z.

The probability of being missing is a constant, c, regardless of what X equals or what Z equals. Missingness is statistically independent of all data, observed and unobserved.

**Consequence for listwise deletion:** The observed data (rows where R = 1) form a simple random sample of the full data. Any estimator computed on the observed data is unbiased for the population parameter, because the observed and missing cases are exchangeable.

Formally, let θ be any population parameter (mean, regression coefficient, etc.). Let θ̂_obs be the estimator computed on observed cases only. Under MCAR:

E[θ̂_obs] = θ

because the observed cases are a random draw from the same distribution as the full data.

### MAR (Missing at Random)

**Definition:** P(R = 0 | X, Z) = P(R = 0 | Z) for all values of X.

After conditioning on the observed covariates Z, the probability of missingness no longer depends on the value of X itself. Missingness may be related to X, but only through Z.

**Example:** High-income respondents are more likely to skip an income question. But if you know a respondent's education and occupation (both in Z), the probability of skipping no longer varies with their actual income level. The association between missingness and income runs through education and occupation.

**Consequence for listwise deletion:** Listwise deletion is biased under MAR. To see why, consider estimating the mean of X. The complete-case mean is:

E[X | R = 1] = E[X | R = 1, Z = z] · P(Z = z | R = 1) summed over z

Under MAR, E[X | R = 1, Z = z] = E[X | Z = z] (missingness within strata defined by Z is random). But P(Z = z | R = 1) ≠ P(Z = z) because Z predicts missingness, so the observed sample is not a random draw from the marginal distribution of X. The observed mean is a reweighted version of the population mean, with observed strata overweighted.

Concretely: if lower-education respondents are more likely to complete an income question, and lower-education respondents also have lower incomes, then the complete-case mean income overestimates the population mean income.

### MNAR (Missing Not at Random)

**Definition:** P(R = 0 | X, Z) depends on X even after conditioning on Z.

No set of observed variables renders missingness independent of the missing value itself.

**Consequence:** Standard missing data remedies, including multiple imputation (Module 10), do not solve the bias under MNAR without an explicit model of the missingness mechanism. The missingness mechanism must be modeled jointly with the outcome, which requires assumptions that cannot be tested from the observed data alone. MNAR problems are generally acknowledged, sensitivity-analyzed, and left as a caveat rather than "fixed."

---

## Part B — Outlier Detection

### Z-Score Method

The z-score for observation i is:

z_i = (xᵢ - x̄) / s

where x̄ = (1/n) Σᵢ xᵢ and s = √[(1/(n-1)) Σᵢ (xᵢ - x̄)²].

An observation is flagged as a potential outlier if |z_i| > k, where k = 3 is conventional for moderate n and k = 4 is used for large n (n > 100,000) to reduce false positives.

**Expected false flags under normality:**

If X ~ N(μ, σ²), what is the expected number of observations flagged purely by chance?

The probability that a single observation exceeds the threshold in either tail is:

P(|Z| > k) = 2 · [1 - Φ(k)]

where Φ is the standard normal CDF. For a sample of n observations:

Expected false flags = 2n · [1 - Φ(k)]

At k = 3: Φ(3) ≈ 0.9987, so P(|Z| > 3) ≈ 0.0027, giving about 2.7 expected false flags per 1,000 observations.

At k = 4: Φ(4) ≈ 0.99997, so P(|Z| > 4) ≈ 0.000063, giving about 0.063 expected false flags per 1,000 observations.

This tells you how aggressive your flagging rule is. For n = 50,000 (roughly CES 2020 size), k = 3 would flag about 135 observations purely by chance. That is still a useful filter; you investigate the flags rather than automatically dropping them.

**Limitation:** The z-score uses the sample mean and standard deviation, which are themselves sensitive to outliers. A very extreme outlier inflates s, which shrinks |z_i| for that outlier and potentially masks it. The IQR method avoids this.

### IQR (Tukey Fences) Method

Compute Q1 (the 25th sample percentile) and Q3 (the 75th sample percentile). Define:

IQR = Q3 - Q1

Flag observation i as an outlier if:

xᵢ < Q1 - 1.5 · IQR   or   xᵢ > Q3 + 1.5 · IQR

**Deriving the fence location for a normal distribution:**

For X ~ N(μ, σ²), the theoretical quartiles are:

Q1 = μ - 0.6745σ   (because Φ(0.6745) = 0.75, so Q1 is at the 25th percentile)
Q3 = μ + 0.6745σ

Therefore:

IQR = Q3 - Q1 = 2 · 0.6745σ = 1.349σ

The upper Tukey fence is:

Q3 + 1.5 · IQR = (μ + 0.6745σ) + 1.5 · (1.349σ)
               = μ + 0.6745σ + 2.0235σ
               = μ + 2.698σ
               ≈ μ + 2.7σ

So for a perfectly normal distribution, the Tukey upper fence sits at approximately μ + 2.7σ. The fraction of the normal distribution above this is:

P(Z > 2.7) ≈ 0.0035

Both tails together: about 0.7% of observations would be flagged in a perfectly normal sample. This is a slightly more lenient filter than k = 3 (0.27%) but uses robust statistics (Q1, Q3) that are not distorted by the outliers themselves.

---

## Part C — Bessel's Correction

### The Bias of the Naive Variance Estimator

The naive (biased) estimator divides by n:

σ̂²_naive = (1/n) Σᵢ (xᵢ - x̄)²

**Claim:** E[σ̂²_naive] = σ²(n-1)/n, which is less than σ².

**Derivation:**

Start with the definition of x̄ = (1/n) Σᵢ xᵢ.

Write xᵢ - x̄ = (xᵢ - μ) - (x̄ - μ). Then:

(xᵢ - x̄)² = [(xᵢ - μ) - (x̄ - μ)]²
            = (xᵢ - μ)² - 2(xᵢ - μ)(x̄ - μ) + (x̄ - μ)²

Sum over i:

Σᵢ (xᵢ - x̄)² = Σᵢ (xᵢ - μ)² - 2(x̄ - μ) Σᵢ (xᵢ - μ) + n(x̄ - μ)²

Note that Σᵢ (xᵢ - μ) = n(x̄ - μ), so:

Σᵢ (xᵢ - x̄)² = Σᵢ (xᵢ - μ)² - 2(x̄ - μ) · n(x̄ - μ) + n(x̄ - μ)²
               = Σᵢ (xᵢ - μ)² - 2n(x̄ - μ)² + n(x̄ - μ)²
               = Σᵢ (xᵢ - μ)² - n(x̄ - μ)²

Now take expectations. Since E[(xᵢ - μ)²] = σ² for all i:

E[Σᵢ (xᵢ - μ)²] = nσ²

Since Var(x̄) = σ²/n, we have E[(x̄ - μ)²] = σ²/n:

E[n(x̄ - μ)²] = n · σ²/n = σ²

Putting it together:

E[Σᵢ (xᵢ - x̄)²] = nσ² - σ² = (n-1)σ²

Therefore:

E[σ̂²_naive] = (1/n) · (n-1)σ² = σ²(n-1)/n < σ²

The naive estimator underestimates the true variance because x̄ is computed from the same sample, pulling the deviations toward zero. This is the degrees-of-freedom adjustment: the sample mean "uses up" one degree of freedom.

### Bessel's Corrected Estimator

Dividing by (n-1) instead of n removes the bias:

s² = (1/(n-1)) Σᵢ (xᵢ - x̄)²

E[s²] = (1/(n-1)) · (n-1)σ² = σ²  ✓

This is why software, including Stata's `summarize` and R's `var()`, defaults to n-1 in the denominator. The distinction matters most at small n. For n = 1,000, the bias from using n is only 0.1%. For n = 10, using n understates the variance by 10%.
