# Visualization — Math

## Part A: Kernel Density Estimation

### Setup

Given n observed data values x₁, x₂, ..., xₙ (e.g., household income for CES respondents), we want to estimate the underlying probability density function f(x) at any point x on the real line.

A histogram with bin width h estimates f(x) by:

f̂_hist(x) = (1/nh) · #{i : xᵢ falls in the same bin as x}

This is a step function: discontinuous, sensitive to bin edge placement, and coarse.

### The KDE Formula

The kernel density estimator smooths by replacing the box-counting with a smooth kernel function K placed at each observation:

f̂(x) = (1/nh) Σᵢ₌₁ⁿ K((x - xᵢ)/h)

where:
- x is the evaluation point (any real number)
- xᵢ are the observed data values
- h > 0 is the bandwidth (controls smoothness)
- K is the kernel function (a smooth, symmetric density)

The argument (x - xᵢ)/h is the standardized distance from the evaluation point to observation i, measured in units of the bandwidth.

### The Gaussian Kernel

The most common choice is the Gaussian (standard normal) kernel:

K(u) = (1/√(2π)) · exp(-u²/2)

**Showing it integrates to 1.** The integral of K(u) over all u is just the integral of the standard normal density:

∫₋∞^∞ K(u) du = ∫₋∞^∞ (1/√(2π)) exp(-u²/2) du = 1

This is the standard Gaussian integral, provable by squaring it, converting to polar coordinates, and evaluating. The result confirms that K is a valid probability density.

**Why this matters.** Because K integrates to 1, the KDE f̂(x) also integrates to 1 over x:

∫₋∞^∞ f̂(x) dx = (1/nh) Σᵢ ∫₋∞^∞ K((x - xᵢ)/h) dx

Substitute u = (x - xᵢ)/h, so dx = h du:

= (1/nh) Σᵢ h · ∫₋∞^∞ K(u) du = (1/n) Σᵢ 1 = 1

So f̂ is itself a valid density, regardless of the bandwidth h.

### Bias-Variance Tradeoff for Bandwidth Selection

#### Bias of the KDE

The expected value of f̂(x) at a single point x is:

E[f̂(x)] = (1/h) ∫ K((x - t)/h) f(t) dt

Substitute u = (t - x)/h, so t = x + uh and dt = h du:

E[f̂(x)] = ∫ K(u) f(x + uh) du

Expand f(x + uh) in a Taylor series around x:

f(x + uh) = f(x) + uh f'(x) + (u²h²/2) f''(x) + O(h³)

Plug in and integrate term by term, using the kernel properties:
- ∫ K(u) du = 1
- ∫ u K(u) du = 0 (kernel is symmetric, so odd moments vanish)
- ∫ u² K(u) du = μ₂(K) (second moment of the kernel; for Gaussian, μ₂ = 1)

E[f̂(x)] = f(x) · 1 + f'(x) · h · 0 + f''(x) · h²/2 · μ₂(K) + O(h³)

Bias at x:

Bias[f̂(x)] = E[f̂(x)] - f(x) ≈ (h²/2) · μ₂(K) · f''(x)

The bias depends on h²: larger bandwidth means larger bias. The bias also depends on f''(x), the curvature of the true density. Where f is linear (f'' = 0), the KDE is approximately unbiased regardless of h. Where f has strong curvature (peaks or valleys), large h smears over real features.

#### Variance of the KDE

The variance at x (for large n) is approximately:

Var[f̂(x)] ≈ f(x) · R(K) / (nh)

where R(K) = ∫ K²(u) du. For the Gaussian kernel, R(K) = 1/(2√π) ≈ 0.282.

As h increases (more smoothing), variance decreases. As h decreases (less smoothing), variance increases and the estimate becomes spiky.

#### The Mean Integrated Squared Error

The global tradeoff is summarized by the mean integrated squared error (MISE):

MISE(h) = ∫ [Bias²(f̂(x)) + Var(f̂(x))] dx

≈ (h⁴/4) · μ₂(K)² · ∫ [f''(x)]² dx + R(K)/(nh)

The first term grows with h (bias penalty); the second shrinks with h (variance benefit). Minimizing over h by taking d(MISE)/dh = 0:

h* = [ R(K) / (μ₂(K)² · ∫[f''(x)]² dx · n) ]^(1/5)

This scales as n^(-1/5): as sample size grows, the optimal bandwidth shrinks, but slowly.

### Silverman's Rule of Thumb

The term ∫[f''(x)]² dx depends on the true density, which we don't know. If we assume f is Gaussian with variance σ², then ∫[f''(x)]² dx = 3/(8√π σ⁵). Plugging in for the Gaussian kernel gives:

h* = 1.06 · σ̂ · n^(-1/5)

where σ̂ is the sample standard deviation (or a robust alternative like 1.06 times the interquartile range divided by 1.34). This is Silverman's rule of thumb. It is the default bandwidth in most software and works well for unimodal, roughly symmetric distributions. It over-smooths for multimodal distributions, so if you suspect multiple modes, reduce h manually or use a data-driven selector like cross-validation.

---

## Part B: Error Bars in Bar and Point Charts

### Two Different Things Error Bars Can Show

Let X₁, ..., Xₙ be a random sample from a population with mean μ and variance σ². Define:

- Sample mean: X̄ = (1/n) Σᵢ Xᵢ
- Sample variance: s² = (1/(n-1)) Σᵢ (Xᵢ - X̄)²
- Standard error: SE = s/√n

**SE bars** show X̄ ± SE. They answer the question: how precisely have we estimated the mean? One SE above and below the mean spans approximately the middle 68% of the sampling distribution of X̄, assuming normality.

**95% CI bars** show X̄ ± t_{α/2, n-1} · SE. They answer the question: what is the plausible range of the true population mean?

These are not the same question, and the bars look different. SE bars are narrower. If you show SE bars on a presentation slide, the audience may interpret them as 95% CIs, which would overstate your precision.

### Deriving the 95% CI for a Population Mean

The pivot quantity is:

(X̄ - μ) / (s/√n) ~ t_{n-1}

where t_{n-1} is the Student's t-distribution with n-1 degrees of freedom. This follows from the fact that (n-1)s²/σ² ~ χ²_{n-1} and is independent of X̄ when observations are i.i.d. normal. The ratio of a standard normal to the square root of a scaled chi-squared is by definition a t-distribution.

From the pivot:

P(-t_{α/2, n-1} ≤ (X̄ - μ)/(s/√n) ≤ t_{α/2, n-1}) = 1 - α

Rearrange to isolate μ:

P(X̄ - t_{α/2, n-1} · s/√n ≤ μ ≤ X̄ + t_{α/2, n-1} · s/√n) = 1 - α

The 95% CI is:

X̄ ± t_{0.025, n-1} · s/√n

For n > 30, t_{0.025, n-1} ≈ 1.96, so the familiar "mean ± 1.96 SE" approximation is valid. For smaller samples, the exact t critical value (which is larger) must be used.

---

## Part C: Coefficient Plots

### What Is Being Plotted

In a multiple regression Y = β₀ + β₁X₁ + ... + βₖXₖ + ε, the OLS estimator produces β̂ = (X'X)⁻¹X'Y with covariance matrix Var(β̂) = σ²(X'X)⁻¹.

For each coefficient k, the estimated standard error is SE(β̂ₖ) = √[σ̂² · ((X'X)⁻¹)ₖₖ], where σ̂² = SSR/(n-p) and p is the number of parameters.

The coefficient plot for predictor k shows:

- Point: β̂ₖ on the horizontal axis
- Interval: β̂ₖ ± 1.96 · SE(β̂ₖ) (95% CI, assuming large n)
- Reference line: vertical line at β̂ₖ = 0

### Why This Is More Informative Than a Table

A standard regression table gives you:

| Variable | β̂  | SE   | t    | p    |
|----------|-----|------|------|------|
| Age      | 0.03| 0.01 | 3.0  | .003 |
| Income   | 0.18| 0.04 | 4.5  | <.001|
| Education| 0.22| 0.06 | 3.7  | <.001|

A coefficient plot of the same information shows immediately:

1. Education has the largest effect (the point is furthest right).
2. Income is second, Age is smallest.
3. All three CIs miss zero (all are statistically distinguishable from null).
4. The Education and Income CIs overlap substantially (the effects are not precisely distinguishable from each other).

Point 4 in particular is nearly impossible to read from a table without doing arithmetic. The visual representation encodes relative magnitude and interval overlap as a spatial relationship, which the brain processes immediately.

**When a reference line other than zero is useful.** In models where you care about whether an effect exceeds a substantive threshold (e.g., "is the effect larger than a 1-point difference on a 10-point scale?"), you can add a second reference line at that value. CIs that do not cross the threshold provide stronger evidence than mere rejection of the zero null.
