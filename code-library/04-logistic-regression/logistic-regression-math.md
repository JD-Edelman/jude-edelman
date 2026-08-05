# Logistic Regression: Mathematical Derivation

## The Problem with OLS for Binary Outcomes

The linear probability model fits E[Y|X] = Xβ, where Y ∈ {0,1}. This is unbounded: nothing prevents Xβ from going below 0 or above 1. We need a function that maps any real number to (0,1).

---

## The Logistic Function

Define the **sigmoid (logistic) function**:

  σ(z) = 1 / (1 + e^{-z})

Properties:
- σ(z) ∈ (0, 1) for all z ∈ ℝ
- σ(0) = 0.5
- σ(-z) = 1 - σ(z)
- σ'(z) = σ(z)(1 - σ(z))   (this derivative is used repeatedly below)

The model is:

  P(Yᵢ = 1 | Xᵢ) = σ(Xᵢβ) = 1 / (1 + e^{-Xᵢβ})

where Xᵢ is the i-th row of the predictor matrix (including an intercept) and β is the coefficient vector.

---

## The Log-Odds (Logit) Link

Rearrange the model equation. Let p = σ(Xᵢβ). Then:

  1 - p = 1 - 1/(1+e^{-Xᵢβ}) = e^{-Xᵢβ}/(1+e^{-Xᵢβ})

  p/(1-p) = 1/e^{-Xᵢβ} = e^{Xᵢβ}

  log[p/(1-p)] = Xᵢβ

This is the **logit (log-odds)** transformation. It maps p ∈ (0,1) to ℝ, making the right-hand side a valid linear predictor.

---

## Likelihood and Log-Likelihood

For a single binary observation (yᵢ, Xᵢ), the probability mass function is:

  P(Yᵢ = yᵢ | Xᵢ, β) = p̂ᵢ^{yᵢ} · (1 - p̂ᵢ)^{1-yᵢ}

where p̂ᵢ = σ(Xᵢβ). For a sample of n independent observations, the **log-likelihood** is:

  ℓ(β) = Σᵢ [ yᵢ log p̂ᵢ + (1-yᵢ) log(1-p̂ᵢ) ]

         = Σᵢ [ yᵢ log σ(Xᵢβ) + (1-yᵢ) log(1 - σ(Xᵢβ)) ]

This is a concave function of β, so it has a unique global maximum (no local optima to worry about).

---

## The Score Equations

The score (gradient of ℓ with respect to β) is:

  ∂ℓ/∂β = Σᵢ [ yᵢ · (1/p̂ᵢ) · σ'(Xᵢβ) · Xᵢ - (1-yᵢ) · (1/(1-p̂ᵢ)) · σ'(Xᵢβ) · Xᵢ ]

Using σ'(Xᵢβ) = p̂ᵢ(1 - p̂ᵢ):

  = Σᵢ [ yᵢ(1-p̂ᵢ) - (1-yᵢ)p̂ᵢ ] Xᵢ

  = Σᵢ (yᵢ - p̂ᵢ) Xᵢ

In matrix form: ∂ℓ/∂β = X'(y - p̂). There is no closed-form solution to X'(y - p̂) = 0 because p̂ depends nonlinearly on β. Estimation requires iterative methods.

---

## Newton-Raphson (IRLS)

The Hessian (matrix of second derivatives) is:

  ∂²ℓ/∂β∂β' = -Σᵢ p̂ᵢ(1-p̂ᵢ) xᵢxᵢ' = -X'WX

where W = diag(p̂ᵢ(1-p̂ᵢ)). The Newton-Raphson update is:

  β^{(t+1)} = β^{(t)} + (X'WX)⁻¹ X'(y - p̂^{(t)})

This is equivalent to iteratively reweighted least squares (IRLS): at each step, solve a weighted OLS problem with weights wᵢ = p̂ᵢ(1-p̂ᵢ). Weights are smallest when p̂ᵢ is near 0 or 1 (those observations contribute little to estimation).

---

## Odds Ratios

The odds ratio for predictor k is:

  OR_k = exp(β̂ₖ)

Interpretation: a one-unit increase in Xₖ multiplies the odds of Y=1 by OR_k, holding other predictors constant. This follows directly from the log-odds form:

  log[p/(1-p)] = β₀ + βₖXₖ + ...

Increasing Xₖ by 1: log[p'/(1-p')] - log[p/(1-p)] = βₖ, so p'/(1-p') = e^{βₖ} · p/(1-p).

---

## Average Marginal Effects

The partial effect of Xₖ on the probability is:

  ∂P(Y=1|X) / ∂Xₖ = σ'(Xβ) · βₖ = p̂(1-p̂) · βₖ

This varies across observations because p̂ varies. The **average marginal effect (AME)** averages over the sample:

  AME_k = (1/n) Σᵢ p̂ᵢ(1-p̂ᵢ) · β̂ₖ

The AME is in probability-point units (like a linear probability model coefficient) and is often easier to communicate than odds ratios.

---

## ROC Curve and AUC

For a threshold c ∈ [0,1], classify Ŷᵢ = 1 if p̂ᵢ ≥ c. Define:

  Sensitivity (TPR) = P(Ŷ=1 | Y=1) = TP / (TP + FN)
  Specificity      = P(Ŷ=0 | Y=0) = TN / (TN + FP)
  False Positive Rate (FPR) = 1 - Specificity

The ROC curve plots Sensitivity (y-axis) against FPR (x-axis) as c sweeps from 1 to 0. The AUC is the area under this curve, equal to the probability that the model assigns a higher predicted probability to a randomly chosen positive case than to a randomly chosen negative case:

  AUC = P(p̂ᵢ > p̂ⱼ | Yᵢ=1, Yⱼ=0)

A random classifier has AUC = 0.5; a perfect classifier has AUC = 1.0.
