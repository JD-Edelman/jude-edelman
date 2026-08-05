# Visualization: Mathematical Derivation

## Symbols

| Symbol | Meaning |
|--------|---------|
| x | Evaluation point on the real line |
| xᵢ | Observed data value for observation i |
| n | Sample size |
| f(x) | True underlying probability density function |
| f̂(x) | Estimated (kernel density) density function |
| K(u) | Kernel function; a smooth, symmetric probability density |
| h | Bandwidth; controls smoothness of the KDE |
| u | Standardized distance: (x - xᵢ)/h |
| μ₂(K) | Second moment of the kernel: ∫ u² K(u) du |
| R(K) | Roughness of the kernel: ∫ K²(u) du |
| σ̂ | Sample standard deviation of the data |
| h* | Optimal (Silverman) bandwidth |
| MISE | Mean integrated squared error |
| X̄ | Sample mean |
| s | Sample standard deviation |
| SE | Standard error of the mean: s/√n |
| μ | True population mean |
| σ² | Population variance |
| t_{α/2, n-1} | t critical value with n-1 degrees of freedom at tail probability α/2 |
| β̂ₖ | OLS estimate of the k-th regression coefficient |
| SE(β̂ₖ) | Standard error of β̂ₖ |
| p | Number of parameters in the regression model |
| r_{XY} | Pearson correlation between X and Y |
| β̂_std | Standardized regression coefficient |

---

## Part A — Kernel Density Estimation

**In practice:** When you produce a density plot in Stata (kdensity) or R (geom_density), the software is computing a KDE under the hood. The shape you see depends critically on the bandwidth h. Understanding the math tells you when to trust the default and when to override it.

### The Problem with Histograms

Given n observed data values x₁, x₂, ..., xₙ, we want to estimate the underlying probability density function f(x) at any point x on the real line.

A histogram with bin width h estimates f(x) by:

```
f̂_hist(x) = (1/nh) · #{i : xᵢ falls in the same bin as x}
```

This is a step function: discontinuous, sensitive to bin edge placement, and coarse. Two analysts using the same data but different bin starting points can produce visibly different histograms. The KDE fixes this.

### The KDE Formula

The **kernel density estimator** smooths by replacing the box-counting with a smooth kernel function K placed at each observation:

```
f̂(x) = (1/nh) Σᵢ₌₁ⁿ K((x - xᵢ)/h)
```

The argument (x - xᵢ)/h is the standardized distance from the evaluation point to observation i, measured in units of the bandwidth. Each observation contributes a small bump centered at xᵢ, and the KDE is the sum of all n bumps, normalized so the result is a valid density.

### The Gaussian Kernel

The most common choice is the **Gaussian kernel**:

```
K(u) = (1/√(2π)) · exp(-u²/2)
```

This is simply the standard normal density evaluated at u.

**Showing K integrates to 1.** The integral of K(u) over all u is the integral of the standard normal density:

```
∫₋∞^∞ K(u) du = ∫₋∞^∞ (1/√(2π)) exp(-u²/2) du = 1
```

This is the standard Gaussian integral, provable by squaring it, converting to polar coordinates, and evaluating. The result confirms K is a valid probability density.

**Why this matters for the KDE.** Because K integrates to 1, the KDE f̂(x) also integrates to 1:

```
∫₋∞^∞ f̂(x) dx = (1/nh) Σᵢ ∫₋∞^∞ K((x - xᵢ)/h) dx
```

Substitute u = (x - xᵢ)/h, so dx = h du:

```
= (1/nh) Σᵢ h · ∫₋∞^∞ K(u) du = (1/n) Σᵢ 1 = 1
```

So f̂ is itself a valid density, regardless of bandwidth h. You can integrate the KDE to get probabilities, just as you would the true density.

### Bias-Variance Tradeoff for Bandwidth Selection

#### Bias of the KDE

The expected value of f̂(x) at a single point x is:

```
E[f̂(x)] = (1/h) ∫ K((x - t)/h) f(t) dt
```

Substitute u = (t - x)/h, so t = x + uh and dt = h du:

```
E[f̂(x)] = ∫ K(u) f(x + uh) du
```

Expand f(x + uh) in a Taylor series around x:

```
f(x + uh) = f(x) + uh f'(x) + (u²h²/2) f''(x) + O(h³)
```

Plug in and integrate term by term, using three kernel properties:
- ∫ K(u) du = 1 (K is a valid density)
- ∫ u K(u) du = 0 (K is symmetric, so odd moments vanish)
- ∫ u² K(u) du = μ₂(K) (second moment; for the Gaussian kernel, μ₂ = 1)

```
E[f̂(x)] = f(x) · 1 + f'(x) · h · 0 + f''(x) · (h²/2) · μ₂(K) + O(h³)
```

The **bias** at x is therefore:

```
Bias[f̂(x)] = E[f̂(x)] - f(x) ≈ (h²/2) · μ₂(K) · f''(x)
```

Bias grows with h². Where f has strong curvature (peaks or valleys), large h smears over real features. Where f is nearly linear (f'' ≈ 0), the KDE is approximately unbiased regardless of h.

#### Variance of the KDE

The variance at x (for large n) is approximately:

```
Var[f̂(x)] ≈ f(x) · R(K) / (nh)
```

where R(K) = ∫ K²(u) du. For the Gaussian kernel, R(K) = 1/(2√π) ≈ 0.282.

As h increases (more smoothing), variance decreases. As h decreases, variance increases and the estimate becomes spiky. The analyst cannot have both low bias and low variance; choosing h is choosing where to sit on this tradeoff.

#### The Mean Integrated Squared Error

The global tradeoff is summarized by the **mean integrated squared error** (MISE):

```
MISE(h) = ∫ [Bias²(f̂(x)) + Var(f̂(x))] dx
         ≈ (h⁴/4) · μ₂(K)² · ∫ [f''(x)]² dx + R(K)/(nh)
```

The first term grows with h (bias penalty); the second shrinks with h (variance benefit). Minimizing over h by taking d(MISE)/dh = 0:

```
h* = [ R(K) / (μ₂(K)² · ∫[f''(x)]² dx · n) ]^(1/5)
```

This scales as n^(-1/5): as sample size grows, the optimal bandwidth shrinks, but slowly. Quadrupling n only halves the optimal bandwidth approximately (4^(-1/5) ≈ 0.758).

### Silverman's Rule of Thumb

The term ∫[f''(x)]² dx depends on the true density, which we don't know. If we assume f is Gaussian with variance σ², then ∫[f''(x)]² dx = 3/(8√π σ⁵). Plugging in for the Gaussian kernel yields **Silverman's rule of thumb**:

```
h* = 1.06 · σ̂ · n^(-1/5)
```

where σ̂ is the sample standard deviation (or a robust alternative like the interquartile range divided by 1.34).

For n = 1,000 and σ̂ = 1: h* ≈ 1.06 · 1 · 1000^(-0.2) ≈ 0.106. For n = 100 and σ̂ = 1: h* ≈ 1.06 · 1 · 100^(-0.2) ≈ 0.149. The bandwidth grows as sample size shrinks, automatically smoothing more when data are sparse. This is the correct behavior: with fewer observations, you need to borrow more information from neighbors to get a stable estimate.

Silverman's rule is the default bandwidth in most software and works well for unimodal, roughly symmetric distributions. It over-smooths for multimodal distributions, so if you suspect multiple modes (for example, a bimodal income distribution), reduce h manually or use a data-driven selector like cross-validation.

---

## Part B — Error Bars and Confidence Intervals

**In practice:** Bar charts and point plots in social science papers almost always show error bars, but authors frequently fail to state what the bars represent. SE bars and 95% CI bars look different and answer different questions. Misreading them is one of the most common errors in interpreting published figures.

### Two Different Things Error Bars Can Show

Let X₁, ..., Xₙ be a random sample from a population with mean μ and variance σ². Define:

```
X̄ = (1/n) Σᵢ Xᵢ             (sample mean)
s² = (1/(n-1)) Σᵢ (Xᵢ - X̄)² (sample variance)
SE = s/√n                     (standard error of the mean)
```

**SE bars** show X̄ ± SE. They answer: how precisely have we estimated the mean? One SE above and below spans approximately the middle 68% of the sampling distribution of X̄ (assuming normality).

**95% CI bars** show X̄ ± t_{α/2, n-1} · SE. They answer: what is the plausible range of the true population mean? These bars are wider. If you show SE bars on a presentation slide, the audience may interpret them as 95% CIs, which would overstate your precision; state explicitly which you are showing.

### Deriving the 95% CI from the Pivot Quantity

The key is the **pivot quantity**: a function of the data and the unknown parameter whose distribution does not depend on any unknown parameter.

```
(X̄ - μ) / (s/√n) ~ t_{n-1}
```

This follows from the fact that (n-1)s²/σ² ~ χ²_{n-1} and is independent of X̄ when observations are i.i.d. normal. The ratio of a standard normal to the square root of a scaled chi-squared is, by definition, a t-distribution.

Start from the probability statement:

```
P(-t_{α/2, n-1} ≤ (X̄ - μ)/(s/√n) ≤ t_{α/2, n-1}) = 1 - α
```

Rearrange to isolate μ:

```
P(X̄ - t_{α/2, n-1} · s/√n ≤ μ ≤ X̄ + t_{α/2, n-1} · s/√n) = 1 - α
```

The 95% CI is:

```
X̄ ± t_{0.025, n-1} · s/√n
```

For n > 30, t_{0.025, n-1} ≈ 1.96, so the familiar "mean ± 1.96 SE" approximation is valid. For smaller samples, the exact t critical value (which is larger) must be used.

### The Overlapping CI Fallacy

A common mistake: concluding that two groups are not significantly different because their 95% CI bars overlap visually.

Let X̄₁ and X̄₂ be group means with standard errors SE₁ and SE₂. The SE of their difference is:

```
SE(X̄₁ - X̄₂) = √(SE₁² + SE₂²)
```

The 95% CI for the difference is:

```
(X̄₁ - X̄₂) ± 1.96 · √(SE₁² + SE₂²)
```

Two CIs can overlap visually even when this interval for the difference excludes zero, because the SE of the difference is smaller than the sum of the individual SEs. Specifically, two groups' 95% CI bars can overlap by up to about half a bar-width and the difference can still be statistically significant at p < 0.05.

The practical recommendation: plot SE bars (tighter, less likely to cause this confusion) and report the formal test of the difference separately. Never eyeball CI bars to infer significance of a difference.

---

## Part C — Coefficient Plots

**In practice:** Coefficient plots are becoming the standard alternative to regression tables in top sociology journals. They communicate the same information more efficiently: magnitude, direction, uncertainty, and significance are all visible at once without reading rows of numbers.

### What Is Being Plotted

In a multiple regression Y = β₀ + β₁X₁ + ... + βₖXₖ + ε, the OLS estimator produces β̂ = (X'X)⁻¹X'Y with covariance matrix Var(β̂) = σ²(X'X)⁻¹.

For each coefficient k, the estimated standard error is:

```
SE(β̂ₖ) = √[σ̂² · ((X'X)⁻¹)ₖₖ]
```

where σ̂² = SSR/(n-p) and p is the number of parameters.

The coefficient plot for predictor k shows:
- Point: β̂ₖ on the horizontal axis
- Interval: β̂ₖ ± t_{α/2, n-p} · SE(β̂ₖ) as horizontal error bars
- Reference line: a vertical line at β̂ₖ = 0

The **95% CI** for the k-th coefficient is:

```
β̂ₖ ± t_{α/2, n-p} · SE(β̂ₖ)
```

An interval that excludes zero corresponds exactly to p < 0.05 (two-sided). Dots crossing the zero line are visually obvious without reading p-values, which is the main advantage over a table.

### Why This Is More Informative Than a Table

A standard regression table gives you columns of numbers that require arithmetic to compare. A coefficient plot encodes relative magnitude as horizontal position (further right means larger positive effect), uncertainty as bar length (longer bar means less precise estimate), and significance as whether the bar crosses zero. All four dimensions are processed simultaneously by the eye.

A coefficient with a large positive β̂ and a narrow CI communicates both large effect and high confidence. A coefficient with a small β̂ and a wide CI communicates small or uncertain effect. Tables force the reader to do this synthesis mentally; coefficient plots present it directly.

### Standardized Coefficients

When predictors are on different scales (income in dollars, age in years, education in years), the raw coefficients β̂ₖ are not directly comparable in magnitude. Standardizing fixes this.

If both X and Y are standardized to mean 0 and standard deviation 1 before estimation, the resulting coefficient is the **standardized coefficient**:

```
β̂_std = β̂ₖ · (σ_Xₖ / σ_Y)
```

In the bivariate case (one predictor), the standardized coefficient equals the Pearson correlation:

```
β̂_std = r_{XY}
```

This follows from the OLS formula for a single predictor: β̂ = Σ(xᵢ - x̄)(yᵢ - ȳ) / Σ(xᵢ - x̄)², which equals r_{XY} · (σ_Y / σ_X). After standardizing X and Y, σ_X = σ_Y = 1, so β̂_std = r_{XY}.

Standardized coefficients are directly comparable across predictors: the one with the largest |β̂_std| has the strongest linear association with Y, regardless of original units. This makes coefficient plots especially powerful when all displayed coefficients are standardized: the visual distance from zero immediately ranks predictors by importance.
