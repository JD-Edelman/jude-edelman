# Logistic Regression: Mathematical Derivation

## Symbols

| Symbol | Meaning |
|--------|---------|
| Y_i | Binary outcome variable for observation i; takes values 0 or 1 |
| X_i | Row vector of predictors for observation i (including intercept) |
| X | n×p design matrix |
| β | p×1 vector of logistic regression coefficients |
| β̂ | MLE estimate of β |
| β_k | Coefficient for the k-th predictor |
| p̂_i | Predicted probability P(Y_i = 1 | X_i) |
| σ(z) | Logistic (sigmoid) function: 1 / (1 + e^{−z}) |
| e | Euler's number (~2.718); base of natural log |
| log | Natural logarithm (base e) |
| ℓ(β) | Log-likelihood function |
| W | n×n diagonal weight matrix with entries p̂_i(1 − p̂_i) |
| H | Hessian matrix of the log-likelihood |
| OR_k | Odds ratio for predictor k: exp(β̂_k) |
| AME_k | Average marginal effect of predictor k on P(Y=1) |
| n | Number of observations |
| p | Number of columns in X (including intercept) |
| TPR | True positive rate (sensitivity): P(Ŷ=1 | Y=1) |
| FPR | False positive rate: 1 − specificity = P(Ŷ=1 | Y=0) |
| AUC | Area under the ROC curve |
| c | Classification threshold in (0,1) |

---

## Part A — The Problem with OLS for Binary Outcomes

**In practice:** When your outcome is a 0/1 variable (e.g., employed/not employed, placed in foster care/reunified), running OLS gives a **linear probability model** (LPM). The LPM is sometimes a useful approximation, but it has a structural problem: nothing constrains predictions to the interval (0,1).

### Why OLS fails for binary Y

The LPM fits:

```
E[Y_i | X_i] = X_i β
```

For any given observation, the predicted probability is X_iβ. But X_iβ is a linear function of X, unbounded above and below. With enough extreme predictor values, OLS will generate predicted probabilities above 1 or below 0, which are not interpretable as probabilities.

Beyond out-of-range predictions, OLS errors are heteroskedastic by construction for binary outcomes: since Y_i ∈ {0,1}, the conditional variance is p_i(1−p_i), which varies across observations. The homoskedastic standard errors from OLS are therefore always wrong with a binary outcome.

We need a link function that maps any real-valued linear predictor to the open interval (0,1). The logistic function is the standard solution.

---

## Part B — The Logistic Function and Log-Odds Link

**In practice:** The logistic curve looks like an S-shape. It compresses the linear predictor into (0,1) smoothly, with the steepest slope at p = 0.5 and flattening at the extremes.

### The sigmoid function

The **sigmoid (logistic) function** maps any real number to (0,1):

```
σ(z) = 1 / (1 + e^{−z})
```

Key properties:

```
σ(z) ∈ (0, 1)       for all z ∈ ℝ
σ(0) = 0.5
σ(−z) = 1 − σ(z)    (symmetry around 0.5)
σ'(z) = σ(z)·(1 − σ(z))    (derivative used throughout)
```

The logistic regression model is:

```
P(Y_i = 1 | X_i) = σ(X_i β) = 1 / (1 + e^{−X_i β})
```

If X_iβ = 0, the predicted probability is exactly 0.5. If X_iβ = 2, then p̂ = 1/(1+e^{−2}) ≈ 0.88. If X_iβ = −2, then p̂ ≈ 0.12. The coefficient vector β shifts and tilts this S-curve; a large positive β_k stretches the curve so that small increases in X_k produce large increases in predicted probability near p = 0.5.

### The log-odds (logit) link

To make the model interpretable as a linear equation, rearrange P(Y_i=1|X_i) = σ(X_iβ). Let p = σ(X_iβ). Then:

```
1 − p = e^{−X_i β} / (1 + e^{−X_i β})
```

```
p / (1 − p) = e^{X_i β}
```

Taking the natural log of both sides:

```
log[ p / (1 − p) ] = X_i β
```

The left side is the **logit** (log-odds) of p. It maps p ∈ (0,1) to all of ℝ, so the right-hand side can take any value and the equation is well-defined. A log-odds of 1.5 means the odds of the outcome are e^{1.5} ≈ 4.5 to 1; exponentiating converts log-odds to an odds ratio. A log-odds of 0 means the odds are exactly 1:1, corresponding to p = 0.5. Positive log-odds mean the event is more likely than not; negative log-odds mean less likely.

---

## Part C — Likelihood and Log-Likelihood

**In practice:** We cannot minimize squared errors for a 0/1 outcome the way OLS does; instead, we find the coefficient vector that makes the observed data most probable. This is maximum likelihood estimation.

### The likelihood function

For a single binary observation, the probability mass function under the logistic model is:

```
P(Y_i = y_i | X_i, β) = p̂_i^{y_i} · (1 − p̂_i)^{1−y_i}
```

When y_i = 1, this evaluates to p̂_i; when y_i = 0, it evaluates to 1 − p̂_i. For n independent observations, the joint likelihood is the product across all cases. Taking the natural log converts this product to a sum, which is easier to maximize:

```
ℓ(β) = Σ_i [ y_i log p̂_i + (1 − y_i) log(1 − p̂_i) ]
```

This is the **log-likelihood**. We maximize it over β. We use the log-likelihood rather than minimize squared errors because the OLS loss function produces predicted values that can leave the (0,1) interval, making OLS structurally inappropriate. The log-likelihood stays well-defined for any β, and its maximum yields the most probable parameter values given the data. The logistic log-likelihood is a **concave** function of β, which guarantees a unique global maximum with no local optima to worry about.

---

## Part D — Score Equations and Newton-Raphson

**In practice:** Unlike OLS, logistic regression has no closed-form solution. Software iterates an algorithm until the coefficient estimates stop changing within a convergence tolerance, typically 10^{−8} or smaller.

### The score equations

The **score** is the gradient of the log-likelihood with respect to β. Differentiating ℓ(β) and applying the chain rule, using σ'(X_iβ) = p̂_i(1 − p̂_i):

```
∂ℓ/∂β = Σ_i (y_i − p̂_i) · x_i
```

In matrix form:

```
∂ℓ/∂β = X'(y − p̂)
```

Setting this to zero gives the **score equations**:

```
X'(y − p̂) = 0
```

This looks like the OLS normal equations X'e = 0, but with a crucial difference: p̂ depends nonlinearly on β through the sigmoid function. There is no algebraic way to solve for β directly.

### Newton-Raphson iteration

The **Hessian** (matrix of second derivatives of the log-likelihood) is:

```
∂²ℓ / ∂β ∂β' = −Σ_i p̂_i(1 − p̂_i) · x_i x_i' = −X'WX
```

where W = diag(p̂_i(1 − p̂_i)) is a diagonal weight matrix. The **Newton-Raphson update** steps the coefficient estimate toward the maximum at each iteration:

```
β^{(t+1)} = β^{(t)} + (X'WX)⁻¹ X'(y − p̂^{(t)})
```

At each step, software recomputes p̂^{(t)} from the current β^{(t)}, updates W, solves a weighted least squares problem, and takes a step. This is equivalent to **iteratively reweighted least squares (IRLS)**. Iterations continue until the change in β or in the log-likelihood falls below the convergence threshold. For well-separated data without perfect prediction, convergence typically takes 5 to 15 iterations. The weights w_i = p̂_i(1 − p̂_i) are largest near p̂ = 0.5 (where the data are most informative) and shrink toward zero when p̂ is near 0 or 1 (those observations contribute little to estimation because the model is already very confident about them).

---

## Part E — Odds Ratios

**In practice:** Odds ratios are the most common way to report logistic regression results in sociology and public health, but they are frequently misinterpreted. An odds ratio is not a risk ratio and is not a probability ratio.

### Definition and derivation

The **odds ratio** for predictor k is:

```
OR_k = exp(β̂_k)
```

This follows directly from the log-odds form of the model. Increasing X_k by one unit while holding all other predictors constant shifts the log-odds by β_k:

```
log[p'/(1−p')] − log[p/(1−p)] = β_k
```

Exponentiating both sides:

```
p'/(1−p') = e^{β_k} · p/(1−p)
```

The odds after a one-unit increase in X_k equal OR_k times the odds before the increase. If OR_k = 1.5, the odds of the outcome are 50% higher. If OR_k = 0.7, the odds are 30% lower. For rare outcomes (p < 0.10), the odds ratio approximates the risk ratio reasonably well; for common outcomes, the approximation breaks down and odds ratios exaggerate the magnitude of associations relative to risk ratios.

---

## Part F — Average Marginal Effects

**In practice:** AMEs translate logistic regression results into probability-point units that are directly comparable across models and intuitive for a non-technical audience.

### Marginal effect formula

The partial effect of X_k on the predicted probability is:

```
∂P(Y=1|X) / ∂X_k = σ'(Xβ) · β_k = p̂(1 − p̂) · β_k
```

This quantity varies across observations because p̂ varies. Two respondents with different predictor profiles will have different marginal effects for the same variable. The **average marginal effect (AME)** averages the observation-specific marginal effects across the sample:

```
AME_k = (1/n) · Σ_i p̂_i(1 − p̂_i) · β̂_k
```

The AME is expressed in probability-point units, like a linear probability model coefficient, and is often easier to communicate than an odds ratio.

### Worked numerical example

Suppose β̂_k = 0.4 for a binary indicator of privatized placement, and the average value of p̂_i(1 − p̂_i) across the sample is 0.21 (which occurs when the average predicted probability is around 0.30 or 0.70):

```
AME_k = 0.4 × 0.21 = 0.084
```

The AME is approximately 0.084, meaning privatized placement is associated with about an 8.4 percentage-point increase in the probability of the outcome, on average across the sample. This is the number you would quote in a results section alongside the odds ratio: "The odds ratio was 1.49 (exp(0.4)), corresponding to an average marginal effect of 8.4 percentage points."

---

## Part G — ROC Curve and AUC

**In practice:** AUC summarizes how well the model discriminates between Y=1 and Y=0 cases across all possible classification thresholds. It is useful for model comparison but should always be paired with examination of calibration (are predicted probabilities well-calibrated?) and substantive interpretation.

### Classification at a threshold

For a threshold c ∈ (0,1), classify Ŷ_i = 1 if p̂_i ≥ c, and 0 otherwise. The two key rates are:

```
Sensitivity (TPR) = P(Ŷ = 1 | Y = 1) = TP / (TP + FN)

False Positive Rate (FPR) = P(Ŷ = 1 | Y = 0) = FP / (FP + TN)
```

where TP = true positives, FN = false negatives, FP = false positives, TN = true negatives.

### The ROC curve and AUC

The **ROC curve** plots sensitivity (y-axis) against FPR (x-axis) as c sweeps from 1 down to 0. At c = 1, no cases are classified as 1 (sensitivity = 0, FPR = 0, lower-left corner). At c = 0, every case is classified as 1 (sensitivity = 1, FPR = 1, upper-right corner). A better model hugs the upper-left corner across all thresholds.

**AUC** is the area under this curve:

```
AUC = P(p̂_i > p̂_j | Y_i = 1, Y_j = 0)
```

This is a probability: the chance that a randomly chosen case with Y=1 receives a higher predicted probability than a randomly chosen case with Y=0. A random classifier scores AUC = 0.5 (its ROC curve is the diagonal). A perfect classifier scores AUC = 1.0.

### Reading AUC in applied work

An AUC of 0.70 means the model correctly ranks a Y=1 case above a Y=0 case 70% of the time. This is better than chance but indicates substantial overlap between the predicted probability distributions of the two groups; many cases near the threshold will be misclassified regardless of which threshold you choose. An AUC of 0.85 is considered good in most social science applications: the model has meaningful discriminative ability and the two groups are fairly well separated in predicted probability space. AUC above 0.90 is unusual in sociology without strong predictors or some form of overfitting to the sample.

AUC does not tell you whether predicted probabilities are accurate in an absolute sense (calibration), only whether cases are ranked correctly. A model can have AUC = 0.85 but systematically predict probabilities of 0.30 where the true rate is 0.60; always assess calibration alongside discrimination when predictions will inform decisions.
