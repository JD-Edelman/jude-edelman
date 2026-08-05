# Descriptive Statistics: Mathematical Derivation

## Symbols

| Symbol | Meaning |
|--------|---------|
| N | Population size |
| n | Sample size |
| X_i | Value of variable X for population unit i |
| x_i | Value of variable X for sample unit i |
| μ | Population mean of X |
| X̄ | Sample mean of X |
| σ² | Population variance of X |
| s² | Sample variance of X (unbiased, divides by n−1) |
| s²_b | Biased sample variance (divides by n) |
| s | Sample standard deviation |
| E[·] | Expectation operator |
| Var(·) | Variance operator |
| Cov(X,Y) | Sample covariance between X and Y |
| Ȳ | Sample mean of Y |
| s_X, s_Y | Sample standard deviations of X and Y |
| r | Pearson correlation coefficient |
| O_rc | Observed count in row r, column c of a contingency table |
| E_rc | Expected count in cell (r,c) under independence |
| n_r· | Row r marginal total |
| n·_c | Column c marginal total |
| n | Grand total of a contingency table |
| R | Number of rows in a contingency table |
| C | Number of columns in a contingency table |
| χ² | Chi-square test statistic |
| df | Degrees of freedom |
| w_i | Sampling weight for observation i |
| X̄_w | Weighted mean of X |
| π_i | Probability of selection for unit i |

---

## Part A — Mean and Variance

**In practice:** The sample mean and variance are the first statistics you compute for any variable. Knowing why the sample variance divides by n−1 rather than n is not pedantic; it matters whenever you construct confidence intervals or test statistics from small to moderate samples.

### Population and sample means

The **population mean** is the average of all N units in the target population:

```
μ = (1/N) · Σ X_i     (i = 1, ..., N)
```

Because we rarely observe every unit, we work with the **sample mean** computed from n observed cases:

```
X̄ = (1/n) · Σ x_i     (i = 1, ..., n)
```

X̄ is an **unbiased estimator** of μ. To verify, apply the expectation operator to X̄, using the fact that each sampled unit has E[x_i] = μ:

```
E[X̄] = E[(1/n) · Σ x_i]
       = (1/n) · Σ E[x_i]
       = (1/n) · n · μ
       = μ
```

On average across all possible samples, X̄ hits the population mean exactly. This holds regardless of the shape of the distribution of X; no normality assumption is required.

### Population variance and Bessel's correction

The **population variance** measures the average squared distance of each unit from the population mean:

```
σ² = (1/N) · Σ (X_i − μ)²
```

The natural sample analog, dividing by n, produces the biased estimate:

```
s²_b = (1/n) · Σ (x_i − X̄)²
```

To see why this underestimates σ², start with an algebraic identity. For each observation:

```
(x_i − X̄)² = (x_i − μ) − (X̄ − μ)
```

Squaring and summing across all n observations, and using the fact that cross-terms sum to zero:

```
Σ (x_i − X̄)² = Σ (x_i − μ)² − n·(X̄ − μ)²
```

Taking expectations on both sides, and noting that Var(X̄) = σ²/n:

```
E[Σ (x_i − X̄)²] = n·σ² − n · (σ²/n)
                 = n·σ² − σ²
                 = (n−1)·σ²
```

So dividing by n gives E[s²_b] = (n−1)σ²/n, which is less than σ². The sample mean "uses up" one degree of freedom by centering the deviations on X̄ rather than on the true μ, making the sum of squared deviations systematically too small. **Bessel's correction** divides by n−1 instead:

```
s² = (1/(n−1)) · Σ (x_i − X̄)²
```

This gives E[s²] = σ², an unbiased estimate. For n = 30, the uncorrected estimate understates the variance by 1/30 ≈ 3.3%. For n = 5, the understatement is 1/5 = 20%, large enough to noticeably widen standard errors and narrow confidence intervals if you use the wrong denominator.

---

## Part B — Pearson's Correlation

**In practice:** Correlation is the most-reported measure of bivariate association in social science, but it only captures linear relationships. Knowing the Cauchy-Schwarz derivation of the bounds reminds you that r = 0 is compatible with strong curved or non-monotone relationships.

### Covariance

The **sample covariance** between X and Y measures how the two variables move together, expressed in the original units of both variables:

```
Cov(X, Y) = (1/(n−1)) · Σ (x_i − X̄)(y_i − Ȳ)
```

A positive covariance means that observations above the mean of X tend to be above the mean of Y. The magnitude of covariance depends on the scales of X and Y, which makes it difficult to interpret directly.

### Pearson correlation

**Pearson's r** standardizes the covariance by the product of the two standard deviations, removing the unit dependence:

```
r = Cov(X, Y) / (s_X · s_Y)
```

### Why r is bounded between −1 and 1

The **Cauchy-Schwarz inequality** states that for any two sequences a_i and b_i:

```
[Σ a_i · b_i]²  ≤  (Σ a_i²) · (Σ b_i²)
```

Set a_i = (x_i − X̄) and b_i = (y_i − Ȳ). Then the left side is [Cov(X,Y)·(n−1)]² and the right side is [s_X·(n−1)½]²·[s_Y·(n−1)½]². Dividing both sides by [s_X · s_Y · (n−1)]² gives:

```
r²  ≤  1
```

Therefore −1 ≤ r ≤ 1. Equality holds when a_i and b_i are proportional for every i, meaning all points fall exactly on a straight line. r = 1 when the line has a positive slope; r = −1 when it has a negative slope.

A dataset with a U-shaped or sinusoidal relationship between X and Y can easily have r ≈ 0 because the positive and negative deviations cancel. Always plot your data before trusting a correlation summary.

---

## Part C — Chi-Square Test of Independence

**In practice:** When you cross-tabulate two categorical variables (e.g., race by housing tenure), chi-square tells you whether the row and column classifications are statistically independent or whether some cells are more (or less) common than chance would predict.

### Expected counts under independence

For a table with R rows and C columns, let O_rc be the observed count in cell (r, c). Under the null hypothesis of independence, the probability of falling in row r and column c is the product of the marginal probabilities. This gives the **expected count**:

```
E_rc = (n_r· × n·_c) / n
```

where n_r· is the total count in row r, n·_c is the total count in column c, and n is the grand total. If independence holds, each cell's expected count is what you would predict from the row and column totals alone.

### The chi-square statistic

The test statistic sums the squared relative discrepancies between observed and expected counts across all cells:

```
χ² = Σ_r Σ_c  (O_rc − E_rc)² / E_rc
```

Large values of χ² indicate that at least one cell deviates substantially from what independence predicts. As a rule of thumb, the chi-square approximation is reliable when every cell has an expected count of at least 5.

### Degrees of freedom

The table has R × C cells, but not all deviations are free to vary independently. Constraints from the observed marginal totals reduce the free parameters. The row totals impose R constraints and the column totals impose C constraints, but these share one constraint (they must all add to the same grand total n). The effective number of constraints is R + C − 1. Therefore:

```
df = R·C − (R + C − 1) = (R−1)·(C−1)
```

For a 2×2 table, df = (2−1)(2−1) = 1. Under the null hypothesis of independence and with adequate cell counts, χ² ~ χ²(df).

### Worked 2×2 example

Suppose you cross-tabulate sex (Male/Female) by homeownership (Owner/Renter) for n = 200 respondents:

```
              Owner   Renter   Total
Male            60      40      100
Female          50      50      100
Total          110      90      200
```

Expected counts:

```
E(Male, Owner)   = 100 × 110 / 200 = 55
E(Male, Renter)  = 100 × 90  / 200 = 45
E(Female, Owner) = 100 × 110 / 200 = 55
E(Female, Renter)= 100 × 90  / 200 = 45
```

Chi-square statistic:

```
χ² = (60−55)²/55 + (40−45)²/45 + (50−55)²/55 + (50−45)²/45
   = 25/55 + 25/45 + 25/55 + 25/45
   = 0.455 + 0.556 + 0.455 + 0.556
   ≈ 2.02
```

With df = 1 and χ² ≈ 2.02, the p-value is roughly 0.16; we do not reject independence at conventional thresholds. The observed discrepancies are consistent with sampling variation.

---

## Part D — Weighted Mean

**In practice:** Complex surveys like the ACS, CPS, or NYTD use stratified or clustered sampling designs that do not give every respondent an equal probability of selection. Ignoring weights produces estimates that represent your sample, not the target population.

### Definition and reduction to the simple mean

When observations have sampling weights w_i (typically proportional to 1/π_i, where π_i is the probability of selection), the **weighted mean** is:

```
X̄_w = (Σ w_i · x_i) / (Σ w_i)
```

When all weights are equal, say w_i = w for all i, the expression simplifies:

```
X̄_w = (w · Σ x_i) / (n · w) = (1/n) · Σ x_i = X̄
```

The ordinary sample mean is a special case of the weighted mean with uniform weights. This is reassuring: you are not using a different formula, just a generalized one.

### What the weights do

A respondent from an undersampled group receives a weight greater than 1, so their data counts for more than one person in the estimate. A respondent from an oversampled group receives a weight less than 1. The weighted mean effectively inflates rare-group observations to restore population representativeness.

In the Current Population Survey, for example, rural respondents are sometimes oversampled to ensure reliable state-level estimates. A rural respondent might carry a weight of 0.6, while an urban respondent might carry a weight of 1.4. The unweighted mean of a national income variable would overrepresent rural incomes because those respondents appear more frequently in the sample than they do in the population. The weighted mean corrects this by scaling each observation back to its population share before averaging.

Ignoring survey weights when they are present is not a conservative choice; it is a systematic bias of unknown direction and magnitude, depending on how the variable of interest correlates with the sampling design.
