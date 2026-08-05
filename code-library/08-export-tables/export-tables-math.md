# Export Tables — Math

## Setup and Notation

We have fit the OLS model Y = Xβ + ε where Y is an n×1 outcome vector, X is an n×p design matrix (including the intercept column), β is a p×1 coefficient vector, and ε is an n×1 error vector.

The OLS estimator is β̂ = (X'X)⁻¹X'Y. Define:
- ê = Y - Xβ̂ (residuals)
- SSR = ê'ê = Σᵢ êᵢ² (residual sum of squares)
- SST = Σᵢ (yᵢ - ȳ)² (total sum of squares)
- σ̂² = SSR / (n - p) (estimated error variance; divides by degrees of freedom n - p, where p counts all parameters including the intercept)

---

## Part A: The t-Statistic

### Derivation

Under the OLS assumptions (X is full rank, ε ~ N(0, σ²I)), the distribution of β̂ is:

β̂ ~ N(β, σ²(X'X)⁻¹)

For a single coefficient β̂ₖ (the k-th element):

β̂ₖ ~ N(βₖ, σ² · [(X'X)⁻¹]ₖₖ)

Define the true standard deviation of β̂ₖ as σₖ = σ · √[(X'X)⁻¹]ₖₖ. Standardizing:

(β̂ₖ - βₖ) / σₖ ~ N(0, 1)

We don't know σ, so replace it with σ̂ = √(SSR/(n-p)). The estimated standard error is:

SE(β̂ₖ) = σ̂ · √[(X'X)⁻¹]ₖₖ

Under the null hypothesis H₀: βₖ = 0, the ratio:

t = β̂ₖ / SE(β̂ₖ)

follows a t-distribution with n - p degrees of freedom. This requires two facts working together:

1. (β̂ₖ - 0) / σₖ ~ N(0, 1)
2. (n - p)σ̂² / σ² ~ χ²_{n-p}, and this quantity is independent of β̂ₖ

The ratio of a standard normal to the square root of a χ²_{n-p} / (n-p) quantity is, by definition, a t_{n-p} random variable. So:

t = β̂ₖ / SE(β̂ₖ) ~ t_{n-p} under H₀

As n grows large relative to p, the t_{n-p} distribution converges to N(0,1), which is why large-sample work uses z = 1.96 as the 95% critical value.

### Two-Sided p-Value

The two-sided p-value for observed test statistic t_obs is:

p = 2 · P(T > |t_obs| | H₀)

where T ~ t_{n-p}. The factor of 2 accounts for both tails of the symmetric distribution. We reject H₀ at level α when p < α, equivalently when |t_obs| > t_{α/2, n-p}.

---

## Part B: Confidence Interval

### Deriving the CI from the Pivot

The key is the pivot quantity, a function of the data and the parameter whose distribution does not depend on any unknown parameter:

Pivot: (β̂ₖ - βₖ) / SE(β̂ₖ) ~ t_{n-p}

We know this distribution exactly (it is t_{n-p} under normality assumptions). Define t_{α/2, n-p} as the critical value such that P(|T| ≤ t_{α/2, n-p}) = 1 - α.

Start from the probability statement:

P(-t_{α/2, n-p} ≤ (β̂ₖ - βₖ) / SE(β̂ₖ) ≤ t_{α/2, n-p}) = 1 - α

Multiply all parts by SE(β̂ₖ) (positive, so inequality direction preserved):

P(-t_{α/2, n-p} · SE(β̂ₖ) ≤ β̂ₖ - βₖ ≤ t_{α/2, n-p} · SE(β̂ₖ)) = 1 - α

Subtract β̂ₖ and multiply by -1 (flip inequalities):

P(β̂ₖ - t_{α/2, n-p} · SE(β̂ₖ) ≤ βₖ ≤ β̂ₖ + t_{α/2, n-p} · SE(β̂ₖ)) = 1 - α

The (1-α) confidence interval is:

β̂ₖ ± t_{α/2, n-p} · SE(β̂ₖ)

For α = 0.05 and large n: t_{0.025, n-p} ≈ 1.96. For small samples (n - p < 30), the exact t critical value is noticeably larger, making the interval wider to reflect the additional uncertainty from estimating σ.

This interval has the frequentist interpretation: across repeated samples from the same population, (1-α)% of intervals constructed this way will contain the true βₖ. It does not mean "there is a 95% probability that βₖ is in this specific interval." The parameter is fixed; the interval is random.

---

## Part C: R² and Adjusted R²

### Decomposition of Variance

Define SST = Σ(yᵢ - ȳ)², the total variation in Y around its mean. Define SSR = Σêᵢ² = Σ(yᵢ - ŷᵢ)², the residual variation. Define SSM = SST - SSR (the variation explained by the model).

R² = SSM / SST = 1 - SSR / SST

R² measures the proportion of variance in Y explained by the model.

### Why R² Cannot Decrease When a Variable Is Added

Adding a predictor gives the OLS estimator more degrees of freedom to minimize SSR. The unconstrained minimizer over a larger parameter space can only do as well as or better than the constrained minimizer over the smaller space. Formally:

Let β̂ be the OLS estimates with p parameters. Let β̂* be the OLS estimates with the same p parameters plus one new variable, giving p+1 parameters. Setting the new variable's coefficient to zero in the expanded model recovers the original model exactly, achieving the same SSR. Since OLS minimizes SSR, the expanded model achieves SSR* ≤ SSR.

Therefore R²* = 1 - SSR*/SST ≥ 1 - SSR/SST = R².

R² is a non-decreasing function of the number of predictors. A model with 20 random noise variables will have higher R² than the same model with 10 of them, even though the extra 10 predict nothing. This makes R² a poor criterion for model selection.

### Adjusted R²

Adjusted R² penalizes for added parameters by adjusting both SSR and SST by their respective degrees of freedom:

R²_adj = 1 - (SSR / (n - p)) / (SST / (n - 1))

= 1 - (SSR · (n - 1)) / (SST · (n - p))

= 1 - (1 - R²) · (n - 1) / (n - p)

When a new variable is added, p increases by 1, so the denominator (n - p) decreases. This makes the penalty term (1 - R²)(n-1)/(n-p) larger, reducing R²_adj unless the new variable reduces SSR enough to compensate. A variable that explains nothing raises SSR/(n-p) (the numerator barely changes, but the denominator shrinks). Adjusted R² can decrease when an uninformative variable is added, which is the desirable property.

---

## Part D: AIC and BIC for Logit Models

### Likelihood Setup

Logistic regression estimates parameters β by maximizing the log-likelihood. With binary outcome Yᵢ ∈ {0,1} and predicted probability p̂ᵢ = 1/(1 + exp(-Xᵢβ)):

ℓ(β) = Σᵢ [Yᵢ log(p̂ᵢ) + (1 - Yᵢ) log(1 - p̂ᵢ)]

Let ℓ̂ = ℓ(β̂) be the maximized log-likelihood (evaluated at the MLE). Higher ℓ̂ means better fit. Adding parameters always weakly increases ℓ̂ (for the same reason R² cannot decrease).

### AIC

AIC = -2ℓ̂ + 2p

where p is the number of estimated parameters. The term -2ℓ̂ is the deviance (smaller is better fit); the term 2p is the penalty for complexity. AIC is on a scale where lower is better.

The factor of 2 is conventional and derives from Akaike's asymptotic result: the expected difference in log-likelihood between a fitted model and a new dataset from the same process is approximately p (the number of parameters). Multiplying by -2 puts AIC on the deviance scale.

### BIC

BIC = -2ℓ̂ + p · ln(n)

The penalty is now p·ln(n) instead of 2p. For n > e² ≈ 7.4, we have ln(n) > 2, so BIC penalizes complexity more severely than AIC. For n = 1000 (a modest survey sample), ln(1000) ≈ 6.9, so BIC penalizes each parameter 3.5 times more heavily than AIC does. For n = 60,000 (roughly the CES 2020 sample), ln(60,000) ≈ 11.0, making BIC extremely conservative about adding parameters.

The practical consequence: in large samples, AIC tends to prefer more complex models (it rewards fit gains from adding predictors), while BIC tends to prefer simpler models (its large-n penalty overwhelms modest fit improvements). For applied social science where parsimony and interpretability matter, BIC's conservatism is often appropriate. For prediction tasks where fit matters more, AIC is often preferred.

---

## Part E: Significance Stars and Their Limits

### What Stars Are

Stars encode the p-value into three categories:
- * denotes p < .05
- ** denotes p < .01
- *** denotes p < .001

These correspond to the null rejection region for one of three pre-specified thresholds. They are decision rules built into the reporting format.

### The Power-vs.-Sample-Size Tradeoff

Consider a true population effect β = 0.10 (substantively small but nonzero) in a two-sided t-test with known SE structure. The t-statistic is:

t = β̂ / SE(β̂) = β̂ / (σ / √n)

As n grows, SE → 0 and t → ∞. For any fixed nonzero effect β, there exists n large enough that t exceeds 1.96 with probability approaching 1. The CES 2020 (n ≈ 60,000) will produce statistically significant results for effects that are trivially small in substantive terms.

Now consider a small study (n = 200) with a large true effect β = 0.50. The t-statistic may still fall below 1.96 because SE = σ/√200 is large. The estimate will not earn a star despite the large effect.

**Derivation of the minimum detectable effect.** At the 5% level with power 1 - γ, the minimum detectable effect (MDE) satisfies:

MDE = (z_{α/2} + z_γ) · SE = (1.96 + z_γ) · σ/√n

For 80% power: z_{0.20} = 0.84, so MDE = 2.80 · σ/√n. As n doubles, MDE shrinks by √2 ≈ 1.41. A study with four times the sample can detect effects half as large.

The implication: significance stars reflect the joint product of effect size and sample size. A *** star in a 60,000-person survey may indicate an effect so small it has no practical importance. A blank in a 150-person experiment may correspond to a large effect that the study lacked power to detect.

### Why Reporting Both p-Values and Effect Sizes Is More Informative

The full information content of a hypothesis test is captured by reporting:
1. β̂ (the point estimate, giving direction and magnitude)
2. SE(β̂) or the 95% CI (giving precision)
3. The exact p-value (giving the probability of the observed |t| or larger under H₀)
4. A substantive interpretation of β̂ (what does a one-unit change mean in context?)

Stars contribute only to point 3, and only in a coarsened form. They are useful as a quick scan for readers, but they are not a substitute for the quantities above. Reporting "β̂ = 0.03, SE = 0.01, p = .003 ***" gives more information than "β̂ = 0.03 ***" and incomparably more than "***" alone.
