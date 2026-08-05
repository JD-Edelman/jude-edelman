# OLS Regression: Mathematical Derivation

## Symbols

| Symbol | Meaning |
|--------|---------|
| y | n×1 vector of observed outcomes |
| X | n×p design matrix; first column is a vector of ones (intercept), remaining columns are predictors |
| X' | Transpose of X |
| β | p×1 vector of true (population) coefficients |
| β̂ | p×1 vector of OLS coefficient estimates |
| ε | n×1 vector of unobserved errors |
| e | n×1 vector of OLS residuals (observed, computed from data) |
| n | Number of observations |
| p | Number of columns in X (including the intercept) |
| S(β) | Sum of squared residuals as a function of β |
| H | Hat matrix: H = X(X'X)⁻¹X' |
| I | n×n identity matrix |
| ŷ | n×1 vector of fitted (predicted) values |
| h_ii | i-th diagonal element of H; leverage of observation i |
| σ² | True error variance (assumed constant under homoskedasticity) |
| σ̂² | Estimated error variance: e'e/(n−p) |
| V_HC3 | HC3 heteroskedasticity-consistent variance-covariance matrix |
| V_cl | Clustered variance-covariance matrix |
| G | Number of clusters |
| X_g, e_g | Rows of X and elements of e belonging to cluster g |
| SST | Total sum of squares: Σ(y_i − ȳ)² |
| SSR | Regression sum of squares: Σ(ŷ_i − ȳ)² |
| SSE | Error sum of squares (residual sum of squares): Σ e_i² |
| R² | Coefficient of determination |
| R²_adj | Adjusted R² |
| ȳ | Sample mean of y |

---

## Part A — Setup and Estimator Derivation

**In practice:** OLS is the workhorse estimator for linear models. Understanding the normal equations and their solution clarifies why perfect multicollinearity is fatal and why standard errors depend on the spread of the predictors.

### The linear model

Let y be an n×1 vector of outcomes and X an n×p design matrix whose first column is all ones (representing the intercept). The true data-generating model is:

```
y = Xβ + ε
```

Each row of this equation is y_i = x_i'β + ε_i, where x_i is the i-th row of X transposed into a column vector. The errors ε represent everything that determines y but is not in X.

### Minimizing the sum of squared residuals

OLS chooses β̂ to minimize the **sum of squared residuals**:

```
S(β) = (y − Xβ)'(y − Xβ)
```

Expanding the quadratic:

```
S(β) = y'y − 2β'X'y + β'X'Xβ
```

Take the gradient with respect to β and set it equal to zero:

```
∂S/∂β = −2X'y + 2X'Xβ = 0
```

Rearranging yields the **normal equations**:

```
X'X β̂ = X'y
```

Provided X has full column rank (no predictor is an exact linear combination of others), X'X is invertible and the unique solution is:

```
β̂ = (X'X)⁻¹ X'y
```

This formula says: multiply each predictor by the outcome, account for the correlations among predictors via (X'X)⁻¹, and produce a weighted combination that best fits the data in the least-squares sense. In practice, statistical software never actually computes the matrix inverse directly; instead it uses numerically stable algorithms (QR decomposition or Cholesky factorization) that solve the normal equations without inverting X'X. Direct inversion is numerically fragile and unnecessary.

---

## Part B — Hat Matrix and Residuals

**In practice:** The hat matrix tells you how much influence each observation exerts on its own fitted value. High-leverage observations can pull the regression line toward themselves and distort coefficient estimates.

### Fitted values and the hat matrix

Substituting β̂ into Xβ̂ gives the vector of **fitted values**:

```
ŷ = X β̂ = X(X'X)⁻¹X'y = Hy
```

where **H = X(X'X)⁻¹X'** is the **hat matrix** (it "puts the hat on y," turning the observed y into predicted ŷ). The hat matrix is:

- **Symmetric:** H' = H
- **Idempotent:** H·H = H (applying the projection twice has the same effect as applying it once)

The **residuals** are the difference between what was observed and what the model predicts:

```
e = y − ŷ = (I − H)y
```

A key property: X'e = 0. By construction, OLS residuals are uncorrelated with every predictor in X, including the intercept (so the residuals sum to zero when a constant is included). This is an algebraic identity, not an empirical finding.

### Leverage

The diagonal elements h_ii of H are called **leverage values**. They measure how far observation i's predictor values lie from the center of the predictor space. Leverage satisfies:

```
1/n  ≤  h_ii  ≤  1    (for all i, with intercept in model)
```

A leverage value of h_ii = 0.9 means that observation i is extremely unusual in its predictor values and that its fitted value ŷ_i is determined almost entirely by y_i itself, with little influence from the rest of the data. An observation with h_ii = 0.9 is effectively pulling the regression line through itself. High leverage does not by itself mean the observation distorts estimates; it only becomes problematic when the observation also has a large residual (then it is an influential point, captured by measures like Cook's D).

---

## Part C — Unbiasedness

**In practice:** "Unbiased" means that if you repeated your study many times under the same conditions and computed β̂ each time, the average of those estimates would converge to the true β. It does not mean any single estimate is correct.

### Deriving E[β̂] = β

Under the assumption E[ε] = 0 (the model is correctly specified in expectation, so no systematic error exists), unbiasedness follows from substituting y = Xβ + ε into the OLS formula:

```
β̂ = (X'X)⁻¹X'y
   = (X'X)⁻¹X'(Xβ + ε)
   = (X'X)⁻¹X'Xβ + (X'X)⁻¹X'ε
   = β + (X'X)⁻¹X'ε
```

Taking expectations (treating X as fixed and using E[ε] = 0):

```
E[β̂] = β + (X'X)⁻¹X' E[ε]
      = β + (X'X)⁻¹X' · 0
      = β
```

This result depends on E[ε] = 0 and on X having full column rank so that (X'X)⁻¹ exists. It does not require normality of errors, constant error variance, or independence of observations. For a researcher, unbiasedness means that an omitted variable does not bias estimates as long as the omitted variable is uncorrelated with all included predictors. The moment omitted variables correlate with X, E[ε] ≠ 0 conditional on X, and this derivation breaks down.

---

## Part D — Variance: Homoskedastic, HC3, and Clustered

**In practice:** The choice of standard errors matters most when you are testing hypotheses or constructing confidence intervals. The right variance estimator depends on the structure of the error process in your data.

### Homoskedastic variance

Under the assumption Var(ε) = σ²I (errors are independent and identically distributed with constant variance σ²):

```
Var(β̂) = (X'X)⁻¹X' Var(y) X(X'X)⁻¹
        = (X'X)⁻¹X' (σ²I) X(X'X)⁻¹
        = σ²(X'X)⁻¹
```

The standard error of β̂_k is the square root of the k-th diagonal element: SE(β̂_k) = σ·√[(X'X)⁻¹]_kk. Because σ² is unknown, it is estimated by:

```
σ̂² = e'e / (n − p)
```

dividing by n − p rather than n to account for the p parameters estimated (an analog of Bessel's correction). Plugging σ̂² in for σ² gives the familiar OLS standard errors.

### HC3 heteroskedasticity-consistent variance

When error variances differ across observations (Var(ε_i) = σ_i²), the formula σ²(X'X)⁻¹ is wrong in both direction and magnitude. The **HC3 sandwich estimator** replaces the assumed constant σ² with observation-specific squared residuals, inflated by the leverage of each point:

```
V_HC3 = (X'X)⁻¹ [ Σ_i  e_i² / (1 − h_ii)²  · x_i x_i' ] (X'X)⁻¹
```

The (1 − h_ii)² term in the denominator inflates the squared residual for high-leverage observations, producing more conservative (larger) standard errors than simpler alternatives like HC0. The intuition: a high-leverage observation has a residual that is already smaller than it would be without that observation pulling the line toward itself, so we correct upward. HC3 performs best in smaller samples and is the default robust standard error in most modern applied work. In large samples with approximately equal leverage and mild heteroskedasticity, HC3 and homoskedastic standard errors will be close; the two diverge most when you have a handful of observations with extreme predictor values and noticeably different residual magnitudes.

### Clustered standard errors

When observations are grouped into G clusters (e.g., students within schools, or respondents within counties) and errors within clusters are correlated, all standard error formulas above are wrong. The **clustered variance estimator** is:

```
V_cl = (X'X)⁻¹ [ Σ_g X_g' e_g e_g' X_g ] (X'X)⁻¹ · (G/(G−1)) · ((n−1)/(n−p))
```

where X_g and e_g stack the rows of X and the residuals for all observations in cluster g. The adjustment factors (G/(G−1) and (n−1)/(n−p)) correct for finite cluster counts. When G is small (fewer than 30 to 50 clusters), clustered standard errors become unreliable; with only 10 or 15 clusters, you may need alternative approaches such as the CR2 small-sample correction or permutation inference.

---

## Part E — R² and Adjusted R²

**In practice:** R² is widely reported but widely misread. A high R² does not validate a model; it only says the predictors account for a large share of variance in y in this sample.

### The variance partition

The total variation in y can be exactly partitioned into explained and unexplained components:

```
SST = SSR + SSE

Σ (y_i − ȳ)²  =  Σ (ŷ_i − ȳ)²  +  Σ e_i²
```

This identity holds exactly whenever the model includes an intercept. **R²** is the fraction of total variance accounted for by the model:

```
R² = 1 − SSE/SST = SSR/SST
```

R² is bounded between 0 and 1 and can be interpreted as the proportion of variance in y explained by X. A high R² tells you the model fits the sample data well. It does not tell you the model is causally correct, that coefficients are unbiased, or that the model will generalize out of sample. A model with one spurious but highly correlated predictor can have R² = 0.90 while estimating a coefficient with enormous bias.

R² cannot decrease when a predictor is added, because additional predictors give the model more flexibility to fit the existing data, and SSE can only stay the same or fall. This creates an incentive to overfit by adding predictors.

### Adjusted R²

**Adjusted R²** penalizes the addition of predictors that do not improve fit enough to justify the cost in degrees of freedom:

```
R²_adj = 1 − (SSE/(n−p)) / (SST/(n−1))
```

When a new predictor is added, p increases by 1, making the denominator of SSE/(n−p) smaller and thus SSE/(n−p) larger, which pushes R²_adj down. Whether R²_adj rises or falls depends on whether the predictor's contribution to reducing SSE outweighs this penalty. For n = 500 and k = 5 predictors (so p = 6), the penalty is mild because (n−1)/(n−p) = 499/494 ≈ 1.01. For n = 20 and k = 5, the penalty ratio is 19/14 ≈ 1.36, a substantial shrinkage that discourages adding weak predictors in small samples.
