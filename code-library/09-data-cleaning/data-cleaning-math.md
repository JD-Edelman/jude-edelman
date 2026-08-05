# Data Cleaning: Mathematical Derivation

## Symbols

| Symbol | Meaning |
|--------|---------|
| X | Variable of interest, possibly with missing values |
| Z | Set of fully observed covariates |
| R | Missingness indicator: R = 1 if X is observed, R = 0 if X is missing |
| θ | Any population parameter (mean, regression coefficient, etc.) |
| θ̂_obs | Estimator of θ computed on observed (complete) cases only |
| x̄ | Sample mean of X over observed values |
| s | Sample standard deviation of X |
| xᵢ | The i-th observation of X |
| n | Total sample size |
| z_i | Standardized (z-score) for observation i |
| k | Threshold for z-score outlier flagging |
| Q1, Q3 | 25th and 75th sample percentiles |
| IQR | Interquartile range: IQR = Q3 - Q1 |
| Φ | Standard normal cumulative distribution function |
| σ² | Population variance |
| σ | Population standard deviation |
| μ | Population mean |
| s² | Sample variance (Bessel-corrected) |
| σ̂²_naive | Naive (biased) sample variance dividing by n |

---

## Part A — The Three Missing Data Mechanisms

**In practice:** Before running any analysis, classify why your data are missing. The answer determines whether you can safely drop missing rows, whether multiple imputation will help, and how much of a caveat you need to report.

Let X be a variable with some missing values. Define a binary indicator R where R = 1 if the observation is present and R = 0 if it is absent. The **mechanism of missingness** is a statement about how R relates to X and to other observed variables Z.

### MCAR: Missing Completely at Random

The simplest mechanism. Missingness is a coin flip unrelated to anything.

```
P(R = 0 | X, Z) = P(R = 0)
```

The probability of being missing is a constant, regardless of what X equals or what Z equals. Missingness is statistically independent of all data, observed and unobserved. Under MCAR, the observed rows are a simple random sample of the full dataset, so any estimator computed on them is unbiased:

```
E[θ̂_obs] = θ
```

The observed cases are a random draw from the same distribution as the full data, so nothing is systematically distorted.

You can test this crudely by regressing a missingness indicator on observed covariates. If nothing predicts missingness, MCAR is plausible, though you can never prove MCAR, only fail to disprove it.

### MAR: Missing at Random

After accounting for observed variables Z, the missingness no longer depends on the unobserved value of X itself.

```
P(R = 0 | X, Z) = P(R = 0 | Z)
```

Missingness may be related to X, but only through Z. For example: high-income respondents may be more likely to skip an income question, but if you know their education and occupation (both in Z), the probability of skipping no longer varies with their actual income level. The association between missingness and income runs entirely through education and occupation.

MAR is the assumption that justifies multiple imputation. If older respondents are more likely to skip the ideology question, but age is in your dataset, the missingness is MAR and MI will correct for it.

### MNAR: Missing Not at Random

The worst case: missingness depends on the unobserved value of X even after conditioning on everything observed.

```
P(R = 0 | X, Z) depends on X even after conditioning on Z
```

No set of observed covariates renders missingness independent of the missing value itself. MNAR means the people who skip a question do so because of the answer they would have given.

If people with very liberal or very conservative ideology are more likely to skip the ideology question, no amount of imputation fully fixes the bias. You would need a **selection model** that jointly estimates the outcome and the missingness mechanism, which requires untestable assumptions.

---

## Part B — Bias of Listwise Deletion Under MAR

**In practice:** Most researchers drop missing rows without thinking carefully about the consequences. Under MCAR this is harmless; under MAR it introduces systematic bias in a predictable direction.

### Why the Complete-Case Mean Is Biased

Under MAR, the probability of being observed depends on Z. Let's trace through what the complete-case mean actually estimates.

Define the complete-case mean as the average of X restricted to observed rows (R = 1):

```
E[X | R = 1] = Σ_z  E[X | R = 1, Z = z] · P(Z = z | R = 1)
```

Under MAR, within any stratum defined by Z, missingness is random, so:

```
E[X | R = 1, Z = z] = E[X | Z = z]
```

But the distribution of Z among the observed is not the same as in the full population:

```
P(Z = z | R = 1) ≠ P(Z = z)
```

because Z predicts missingness. The observed sample overweights strata with low missingness. The complete-case mean is a distorted weighted average of the population mean.

### Numerical Example

Suppose you have two education groups with the following income data and response rates:

| Group | True mean income | Fraction of population | Response rate | Fraction of observed |
|-------|-----------------|----------------------|---------------|----------------------|
| Low education | $40,000 | 60% | 80% | 53% |
| High education | $70,000 | 40% | 50% | 47% |

True population mean income:

```
μ = 0.60 · 40000 + 0.40 · 70000 = 24000 + 28000 = $52,000
```

But lower-education respondents have an 80% response rate and high-education respondents have only a 50% rate. In the observed sample, the shares shift. The observed fraction in the low-education group is:

```
P(low edu | R=1) = (0.60 · 0.80) / (0.60 · 0.80 + 0.40 · 0.50)
                 = 0.48 / (0.48 + 0.20)
                 = 0.48 / 0.68
                 ≈ 0.706
```

And the high-education fraction in observed data is approximately 0.294. The complete-case mean:

```
E[X | R=1] = 0.706 · 40000 + 0.294 · 70000
           = 28240 + 20580
           = $48,820
```

Listwise deletion underestimates population mean income by about $3,180. The direction makes intuitive sense: higher-income (high-education) respondents are harder to reach, so they are underrepresented in the observed sample, pulling the mean down. The bias is predictable once you know which groups are underrepresented.

---

## Part C — Outlier Detection: Z-Score and IQR Methods

**In practice:** Outlier detection is not about automatically dropping observations. It is about flagging values that warrant inspection. Most real outliers in social science data are data entry errors, miscoded values, or genuine extreme cases that are theoretically interesting.

### Z-Score Method

The **z-score** for observation i standardizes its distance from the sample mean in units of standard deviations.

```
z_i = (xᵢ - x̄) / s
```

where:

```
x̄ = (1/n) Σᵢ xᵢ
```

```
s = √[ (1/(n-1)) Σᵢ (xᵢ - x̄)² ]
```

Flag observation i as a potential outlier when:

```
|z_i| > k
```

where k = 3 is conventional for moderate sample sizes and k = 4 is common for large surveys (n > 100,000).

### Expected False Flags Under Normality

For a normally distributed variable, what fraction of observations will be flagged purely by chance? A single observation from a standard normal distribution exceeds the threshold in either tail with probability:

```
P(|Z| > k) = 2 · [1 - Φ(k)]
```

Across a sample of n observations, the expected number of innocent flags is:

```
Expected false flags = 2n · [1 - Φ(k)]
```

For k = 3: Φ(3) ≈ 0.9987, so P(|Z| > 3) ≈ 0.0027. You expect about 27 false flags per 10,000 observations.

For k = 4: Φ(4) ≈ 0.99997, so P(|Z| > 4) ≈ 0.000063. You expect about 1.3 false flags per 10,000 observations.

For n = 10,000 and a normal distribution, you expect 2 · 10,000 · (1 - Φ(4)) ≈ 1.3 false flags at k = 4. For k = 3 you would expect about 27 false flags. Choose k based on how many false positives you can tolerate and how large your sample is.

**Limitation of z-scores:** The z-score uses the sample mean and standard deviation, which are themselves sensitive to outliers. A very extreme outlier inflates s, shrinking |z_i| for that outlier and potentially masking it. The IQR method avoids this problem by using robust statistics.

### IQR (Tukey Fences) Method

The **IQR method** uses the interquartile range, which is insensitive to extreme values.

Compute Q1 (the 25th sample percentile) and Q3 (the 75th sample percentile). Define:

```
IQR = Q3 - Q1
```

Flag observation i as a potential outlier if it falls outside the **Tukey fences**:

```
xᵢ < Q1 - 1.5 · IQR   or   xᵢ > Q3 + 1.5 · IQR
```

### Deriving the Fence Location for a Normal Distribution

For X ~ N(μ, σ²), the theoretical quartiles are:

```
Q1 = μ - 0.6745σ
Q3 = μ + 0.6745σ
```

These follow from Φ(0.6745) = 0.75, placing Q3 at the 75th percentile. Therefore:

```
IQR = Q3 - Q1 = 2 · 0.6745σ = 1.349σ
```

Substituting into the upper fence:

```
Q3 + 1.5 · IQR = (μ + 0.6745σ) + 1.5 · (1.349σ)
               = μ + 0.6745σ + 2.0235σ
               = μ + 2.698σ
               ≈ μ + 2.7σ
```

The probability of exceeding this fence in the upper tail of a normal distribution:

```
P(Z > 2.7) ≈ 0.0035
```

Both tails together: about 0.7% of observations would be flagged in a perfectly normal sample.

For a normal distribution, Q3 + 1.5 · IQR ≈ μ + 2.7σ. So the 1.5 · IQR rule is roughly equivalent to a 2.7-sigma rule, catching about 0.7% of a normal distribution as "outliers." This is a slightly more lenient filter than k = 3 (0.27%), but uses robust statistics (Q1, Q3) that are not distorted by the outliers themselves.

---

## Part D — Bessel's Correction

**In practice:** Every statistical package divides by n-1, not n, when computing a sample variance. This section explains why, and when the difference actually matters.

### The Bias of the Naive Variance Estimator

The naive estimator divides by n:

```
σ̂²_naive = (1/n) Σᵢ (xᵢ - x̄)²
```

**Claim:** E[σ̂²_naive] = σ²(n-1)/n, which is strictly less than σ².

### Derivation

Write xᵢ - x̄ = (xᵢ - μ) - (x̄ - μ). Squaring both sides:

```
(xᵢ - x̄)² = [(xᵢ - μ) - (x̄ - μ)]²
            = (xᵢ - μ)² - 2(xᵢ - μ)(x̄ - μ) + (x̄ - μ)²
```

Summing over all i:

```
Σᵢ (xᵢ - x̄)² = Σᵢ (xᵢ - μ)² - 2(x̄ - μ) Σᵢ (xᵢ - μ) + n(x̄ - μ)²
```

Since Σᵢ (xᵢ - μ) = n(x̄ - μ), the middle term simplifies:

```
Σᵢ (xᵢ - x̄)² = Σᵢ (xᵢ - μ)² - 2n(x̄ - μ)² + n(x̄ - μ)²
               = Σᵢ (xᵢ - μ)² - n(x̄ - μ)²
```

Now take expectations. Since E[(xᵢ - μ)²] = σ² for all i:

```
E[Σᵢ (xᵢ - μ)²] = nσ²
```

Since Var(x̄) = σ²/n:

```
E[n(x̄ - μ)²] = n · σ²/n = σ²
```

Combining:

```
E[Σᵢ (xᵢ - x̄)²] = nσ² - σ² = (n-1)σ²
```

Therefore:

```
E[σ̂²_naive] = (1/n) · (n-1)σ² = σ²(n-1)/n < σ²
```

The naive estimator underestimates the true variance because x̄ is computed from the same data, pulling the deviations artificially toward zero. The sample mean "uses up" one **degree of freedom**.

### Bessel's Corrected Estimator

Dividing by (n-1) removes the bias:

```
s² = (1/(n-1)) Σᵢ (xᵢ - x̄)²
```

```
E[s²] = (1/(n-1)) · (n-1)σ² = σ²
```

This is why Stata's `summarize` and R's `var()` both default to n-1 in the denominator. For n = 1,000, the bias from using n is only 0.1%. For n = 10, using n understates the variance by 10%. The correction matters most in small samples.
