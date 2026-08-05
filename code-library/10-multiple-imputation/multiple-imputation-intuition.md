# Module 10 — Multiple Imputation: Intuition

## What Problem Does This Technique Solve?

Missing data are the norm in survey research, not the exception. The CES 2020 has item nonresponse on income, political knowledge, and many attitudinal items. The default in most software, listwise deletion, drops every row that has a missing value on any variable in your model. This causes two distinct problems.

First, it loses statistical power. If 15% of respondents skip an income question and 10% skip a job satisfaction item and those two missingness patterns overlap partially, you may end up with far fewer complete cases than you expect. Each dropped observation reduces the precision of your estimates.

Second, and more seriously, it biases your estimates whenever missingness is related to your outcome or predictors (MAR, as formalized in Module 09). If politically disengaged respondents are more likely to skip ideology questions, and political engagement is related to the outcome you are studying, your complete-case sample systematically overrepresents engaged respondents. Your regression is answering a different question than you think.

Multiple imputation (MI) solves both problems by filling in the missing values, not with a single guess, but with a set of M plausible values drawn from the posterior distribution of the missing data given the observed data. Each imputed dataset is complete and can be analyzed normally. The results are pooled across datasets using Rubin's rules (covered in the math file).

---

## Why You Need More Than One Imputed Dataset

Suppose you imputed each missing value with a single best guess (the conditional mean). You now have one complete dataset. You run your model and get a coefficient of, say, 0.42 with a standard error of 0.08.

The problem: that standard error reflects only the sampling variability in your dataset, treating the imputed values as if they were known. But they are not known. You made them up. There is uncertainty in those imputations, and that uncertainty should propagate into your final confidence intervals. A single imputation hides this uncertainty and produces standard errors that are too small, making results look more precise than they are.

Using M imputed datasets solves this. You analyze each dataset separately, getting M slightly different estimates. The spread across those M estimates reflects the imputation uncertainty. Rubin's rules combine the within-dataset uncertainty (average standard error) with the between-dataset uncertainty (variance of the M point estimates) to produce a total standard error that honestly reflects both sources of variability. Typically M = 20 to 40 is sufficient for modern practice, though M = 5 was the old standard.

---

## Why You Must Draw from the Posterior, Not Just Predict the Mean

A tempting shortcut: fit a regression to predict the missing variable from observed variables, then plug in the predicted value. This is called conditional mean imputation, and it is flawed in a specific way.

The conditional mean E[X | Z] is the center of the distribution of X given Z, but it strips out the residual variance. Every imputed value lands exactly on the regression line. As a result, the imputed variable has less variance than the true variable. This attenuates (shrinks toward zero) any correlations involving the imputed variable. If you are imputing income and income is a predictor in your model, attenuating its variance shrinks its regression coefficient. Your results are systematically wrong.

The fix is to draw from the posterior predictive distribution rather than just predicting the mean. This means: fit the model, then add a random draw of residual noise to each predicted value. The imputed values now scatter around the regression line in a way that preserves the true variance. (The math file derives this formally.)

---

## The MICE Algorithm in Plain Language

MICE stands for Multivariate Imputation by Chained Equations. It handles the realistic case where multiple variables are missing, possibly on different rows.

The challenge: to impute variable X₁ you want to condition on X₂, X₃, and so on. But X₂ might itself be missing on some rows. MICE handles this with an iterative procedure:

1. **Initialize.** Fill all missing values with column means (a rough starting point, not the final imputation).

2. **Cycle through variables.** For each variable Xⱼ that has any missing values:
   - Set aside the current imputed values for Xⱼ (putting missingness back).
   - Fit a regression model: Xⱼ predicted by all other variables (including their current imputed values).
   - For each missing row, draw a new imputed value from the posterior predictive distribution of this model.
   - Replace the missing values of Xⱼ with these draws.

3. **Repeat.** One complete pass through all variables is one iteration. Run for enough iterations (typically 10-20) that the imputed values stabilize.

4. **Extract.** After convergence, extract M complete datasets at M different iteration checkpoints (or run M independent chains). These are your M imputed datasets.

The algorithm works because each variable's model conditions on the best current information about all other variables. Early iterations have poor conditioning (the initial means are rough), but the estimates refine with each pass. This is justified by Gibbs sampler theory: the chained conditional regressions converge to draws from the joint posterior of all missing values given all observed values.

Each variable's regression model can be adapted to its type. Binary variables use logistic regression; ordinal variables use proportional-odds models; continuous variables use linear regression. This flexibility is one of MICE's main practical advantages.

---

## What the Fraction of Missing Information Tells You

The fraction of missing information (FMI), denoted λ, is a key diagnostic that comes out of Rubin's rules. It ranges from 0 to 1 and tells you how much of your total uncertainty about a parameter comes from the missing data rather than from sampling variability.

- λ ≈ 0.05: 5% of your uncertainty is due to missingness. MI provides a modest improvement over complete-case analysis.
- λ ≈ 0.30: 30% of your uncertainty comes from the gap in the data. This is substantial. MI is doing important work, and the number of imputed datasets M needs to be larger to adequately capture this uncertainty.
- λ ≈ 0.50 or higher: Serious missing data problem. Even MI may not fully resolve the bias if the missingness mechanism is MNAR.

The FMI also determines the degrees of freedom for your pooled t-tests, which affects how wide your confidence intervals are. Variables with high FMI will have wider intervals even after imputation, correctly signaling that the data are not providing much information about those parameters.

---

## When MI Is Not Worth the Complexity

Multiple imputation adds analytical complexity and requires choices (number of imputations, imputation model specification, convergence checking). It is not always necessary.

**Skip MI when:** The proportion of missing data on all relevant variables is below roughly 5%, the data are plausibly MCAR, and sample size is large enough that listwise deletion does not meaningfully reduce power. In these cases, complete-case analysis is defensible and much simpler.

**Skip MI when the outcome alone is missing.** If your dependent variable Y is missing but your predictors are fully observed, imputing Y from predictors introduces circular reasoning and inflates apparent fit. Rows with missing Y should be dropped (or the source of missingness should be modeled explicitly).

**Be cautious when:** The missingness mechanism is plausibly MNAR. MI assumes MAR. If missingness depends on the unobserved value even after conditioning on everything in your imputation model, MI will not fully remove the bias. Document this as a limitation and consider sensitivity analyses.

---

## Strengths, Weaknesses, and Alternatives

| | Multiple Imputation |
|---|---|
| **Strengths** | Unbiased under MAR; preserves sample size and power; propagates imputation uncertainty into final SEs; handles multiple missing variables jointly |
| **Weaknesses** | Assumes MAR (cannot verify); requires specifying an imputation model that is at least as rich as the analysis model; computationally intensive; results can vary across runs if M is small |
| **Alternatives** | Full Information Maximum Likelihood (FIML) is mathematically equivalent to MI under MAR and is preferred for structural equation models. Inverse probability weighting (IPW) reweights complete cases to correct for differential nonresponse, but requires modeling the missingness probability rather than the missing values. For MNAR, selection models and pattern mixture models exist but are heavily assumption-dependent. |
