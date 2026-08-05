# OLS Regression: Mathematical Derivation

## Setup

Let y be an **n×1 vector** of observed outcomes. Let X be an **n×p matrix** of predictors, where the first column is a vector of ones (the intercept) and each subsequent column holds a predictor variable. Let **β** be a **p×1 vector** of unknown coefficients and **ε** an **n×1 vector** of unobserved errors.

The linear model is:

  y = Xβ + ε

---

## Deriving the OLS Estimator

OLS chooses β̂ to minimize the **sum of squared residuals**:

  S(β) = (y - Xβ)'(y - Xβ)

Expand:

  S(β) = y'y - 2β'X'y + β'X'Xβ

Take the gradient with respect to β and set to zero:

  ∂S/∂β = -2X'y + 2X'Xβ = 0

Solving:

  X'Xβ̂ = X'y   (the "normal equations")

  β̂ = (X'X)⁻¹X'y

This inverse exists if and only if X has **full column rank** (no predictor is an exact linear combination of others, i.e., no perfect multicollinearity).

---

## Fitted Values and the Hat Matrix

The fitted (predicted) values are:

  ŷ = Xβ̂ = X(X'X)⁻¹X'y = Hy

where **H = X(X'X)⁻¹X'** is the **hat matrix** (it "puts the hat on y"). H is symmetric and idempotent: H² = H. The residuals are:

  e = y - ŷ = (I - H)y

Note: H·e = 0 (residuals are orthogonal to the column space of X), so X'e = 0 (residuals are uncorrelated with every predictor, by construction).

The diagonal elements hᵢᵢ of H are the **leverage values**: they measure how far observation i's predictor values are from the center. hᵢᵢ ∈ [1/n, 1]; observations with high leverage have strong influence on the fit.

---

## Unbiasedness

Under the assumption E[ε] = 0 (errors average zero, or equivalently the model is correctly specified in expectation):

  E[β̂] = E[(X'X)⁻¹X'y]
        = (X'X)⁻¹X' E[y]
        = (X'X)⁻¹X' Xβ
        = β   ✓

---

## Variance of β̂ (Homoskedastic Case)

Under Var(ε) = σ²I (errors are independent and identically distributed):

  Var(β̂) = Var[(X'X)⁻¹X'y]
           = (X'X)⁻¹X' Var(y) X(X'X)⁻¹
           = (X'X)⁻¹X' (σ²I) X(X'X)⁻¹
           = σ²(X'X)⁻¹

The standard error of β̂ₖ is the square root of the k-th diagonal element: SE(β̂ₖ) = σ · √[(X'X)⁻¹]ₖₖ. In practice σ² is unknown and estimated by σ̂² = e'e/(n-p).

---

## HC3 Heteroskedasticity-Consistent Variance

When errors are heteroskedastic (Var(εᵢ) = σᵢ², not constant), the formula σ²(X'X)⁻¹ is wrong. The **HC3 sandwich estimator** is:

  V_HC3 = (X'X)⁻¹ [Σᵢ eᵢ²/(1-hᵢᵢ)² · xᵢxᵢ'] (X'X)⁻¹

where eᵢ is the OLS residual for observation i, hᵢᵢ is the i-th leverage, and xᵢ is the i-th row of X (as a column vector). The (1-hᵢᵢ)² correction inflates the squared residual for high-leverage points, giving more conservative (larger) standard errors than HC0. HC3 performs well in small samples.

---

## Clustered Standard Errors

When observations are grouped into G clusters (e.g., respondents within states) and errors within clusters are correlated, the clustered variance estimator is:

  V_cl = (X'X)⁻¹ [Σ_g X_g'e_g e_g'X_g] (X'X)⁻¹ · (G/(G-1)) · ((n-1)/(n-p))

where X_g and e_g stack the rows/residuals for cluster g. The correction factors adjust for finite cluster counts. When G is small (< 30-50), clustered SEs become unreliable.

---

## R² and Goodness of Fit

Partition the total variation in y:

  SST = SSR + SSE
  Σᵢ(yᵢ-ȳ)² = Σᵢ(ŷᵢ-ȳ)² + Σᵢeᵢ²

R² = 1 - SSE/SST = fraction of total variance explained by the model.

**R² cannot decrease** when a predictor is added: adding X_new to the model gives the constrained OLS estimator at least as much flexibility, so SSE_new ≤ SSE_old.

Adjusted R² penalizes for extra parameters:

  R²_adj = 1 - (SSE/(n-p)) / (SST/(n-1))

Unlike R², R²_adj can decrease when a weak predictor is added, because the increase in the denominator's penalty (n-p → n-p-1) can outweigh the small decrease in SSE.
