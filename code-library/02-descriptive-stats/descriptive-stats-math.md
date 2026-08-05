# Descriptive Statistics: Mathematical Foundations

## 1. Population Mean and Sample Mean

Let X be a variable measured on N population units. The **population mean** is:

  μ = (1/N) Σᵢ Xᵢ   (i = 1, ..., N)

In practice we observe only a sample of n units. The **sample mean** is:

  X̄ = (1/n) Σᵢ xᵢ   (i = 1, ..., n)

X̄ is an unbiased estimator of μ: E[X̄] = μ (each xᵢ is drawn with E[xᵢ] = μ, and expectation is linear).

---

## 2. Variance and Bessel's Correction

The **population variance** measures average squared deviation from the center:

  σ² = (1/N) Σᵢ (Xᵢ - μ)²

The naive **sample variance** using n in the denominator is:

  s²_biased = (1/n) Σᵢ (xᵢ - X̄)²

This is biased downward. To see why, expand:

  Σᵢ (xᵢ - X̄)² = Σᵢ (xᵢ - μ)² - n(X̄ - μ)²

Taking expectations:

  E[Σᵢ (xᵢ - X̄)²] = nσ² - n · Var(X̄) = nσ² - n · (σ²/n) = (n-1)σ²

So dividing by n gives E[s²_biased] = (n-1)σ²/n < σ². Dividing by **(n-1)** corrects the bias:

  s² = (1/(n-1)) Σᵢ (xᵢ - X̄)²

  E[s²] = σ²   ✓

The standard deviation is s = √s². Note s is not itself unbiased for σ (Jensen's inequality), but the bias is small for moderate n.

---

## 3. Pearson's Correlation Coefficient

The **sample covariance** between X and Y is:

  Cov(X, Y) = (1/(n-1)) Σᵢ (xᵢ - X̄)(yᵢ - Ȳ)

The **Pearson correlation** standardizes this:

  r = Cov(X, Y) / (s_X · s_Y)

**Why is r bounded in [-1, 1]?** The Cauchy-Schwarz inequality states:

  [Σᵢ aᵢbᵢ]² ≤ (Σᵢ aᵢ²)(Σᵢ bᵢ²)

Setting aᵢ = (xᵢ - X̄) and bᵢ = (yᵢ - Ȳ):

  [Σᵢ (xᵢ - X̄)(yᵢ - Ȳ)]² ≤ Σᵢ(xᵢ - X̄)² · Σᵢ(yᵢ - Ȳ)²

Dividing both sides by [s_X · s_Y · (n-1)]² gives r² ≤ 1, so -1 ≤ r ≤ 1.

r = 1 when all points lie on a line with positive slope; r = -1 when the slope is negative.

---

## 4. Chi-Square Test of Independence

For a two-way contingency table with R rows and C columns, let:
- O_rc = observed count in cell (r, c)
- n_r· = row r total, n·_c = column c total, n = grand total
- E_rc = expected count under independence = (n_r· × n·_c) / n

Under the null hypothesis of independence:

  χ² = Σ_r Σ_c (O_rc - E_rc)² / E_rc

Under H₀ and with large enough cell counts (E_rc ≥ 5 as a rule of thumb), χ² ~ χ²_{df}.

**Degrees of freedom:** The table has R × C cells. Constraints: row totals sum to n (R constraints) and column totals sum to n (C constraints), but these share one constraint (the grand total), leaving R + C - 1 constraints total. So df = RC - (R + C - 1) = **(R-1)(C-1)**.

---

## 5. Weighted Mean

When observations have sampling weights w₁, ..., wₙ (with wᵢ ∝ 1/πᵢ where πᵢ is the probability of selection), the simple mean is a biased estimate of the population mean. The **weighted mean** is:

  X̄_w = (Σᵢ wᵢ xᵢ) / (Σᵢ wᵢ)

When all weights are equal (wᵢ = w for all i), X̄_w = (w Σᵢ xᵢ) / (nw) = X̄. So the simple mean is a special case.

The weighted variance is:

  s²_w = [Σᵢ wᵢ (xᵢ - X̄_w)²] / [Σᵢ wᵢ - 1]

The denominator adjustment parallels Bessel's correction and ensures an approximately unbiased variance estimate under the assumed sampling model.
