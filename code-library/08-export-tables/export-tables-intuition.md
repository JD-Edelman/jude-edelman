# Export Tables — Intuition

## 1. What Problem Does This Solve?

You have fit a regression. The software gives you a block of output in the console: coefficients, standard errors, t-statistics, p-values, R², sample size. That output is not a publication table. It is formatted for the analyst, not the reader. It includes things a reader does not need (intermediate iteration output from maximum likelihood), omits things they do need (notes about how SEs were computed), and cannot be dropped into a Word document or LaTeX file without manual retyping.

Export table tools (esttab and estout in Stata, modelsummary in R) solve two problems at once. First, they format regression output into a table that meets disciplinary and journal conventions. Second, they automate the transfer from software to document, eliminating the transcription errors that occur when you type numbers by hand. A single typo in a coefficient is invisible to reviewers but embarrassing if caught, and manual retyping of 16 regression models with 12 covariates each is a realistic path to errors.

## 2. What Belongs in a Regression Table and Why

**Coefficients.** The core quantity of interest. Readers need them to assess direction, magnitude, and substantive importance.

**Standard errors (in parentheses below the coefficient) or confidence intervals.** The reader needs to understand the precision of the estimate, not just its direction. SEs allow any reader to reconstruct a t-statistic or confidence interval. Parenthetical SEs are the discipline standard in sociology and political science. The alternative, parenthetical t-statistics, is rarely used in applied social science because t-statistics scale with sample size in a way that hides whether an effect is precisely estimated or just based on a huge sample.

**Significance indicators.** Stars at conventional thresholds (p < .05, p < .01, p < .001) are a shorthand that experienced readers scan quickly. They do not replace exact p-values, but they provide an at-a-glance signal. The debate over stars is real (see below), but they are still expected in most sociology journals.

**Sample size (N).** Always. The reader needs this to assess whether the analysis is adequately powered and to understand the scope of inference.

**Model fit statistic.** For OLS: R² (or adjusted R² if the table shows multiple nested models). For logit: pseudo-R², AIC, or BIC. For survey-weighted models: some adjusted fit measure. These help the reader assess how much variance the model explains and how models compare.

**Footnotes.** Indicate what the parenthetical values are (SEs? CIs? robust SEs? cluster-robust SEs?). Note survey weights if used. Note the reference category for categorical predictors. None of this fits in the table body but all of it matters for interpretation.

## 3. The Stars Debate

Significance stars have been criticized (accurately) on these grounds:

- They collapse a continuous quantity (the p-value) into a three-level categorical variable, discarding information.
- A coefficient with p = .049 gets a star; one with p = .051 does not, even though there is essentially no difference in evidence.
- Stars focus attention on whether an effect exists rather than on its size, which is usually the more important question.
- Large samples produce tiny p-values for trivial effects; small samples produce large p-values for large effects. Stars conflate these.

Despite this, most sociology journals still expect stars, and reviewers notice their absence. A practical resolution: always report exact p-values alongside stars (e.g., in a footnote or in a supplementary table), report effect sizes with context (what does a one-unit change mean substantively?), and note in the text when a "non-significant" coefficient has a confidence interval that rules out meaningful effects vs. one that is just underpowered.

## 4. Table Design for a Methods Paper vs. an Applied Paper

**Methods paper**: the audience wants to evaluate the estimation procedure. Show everything: all coefficients including controls, the covariance structure if relevant, model diagnostics. Completeness matters more than elegance.

**Applied paper**: the audience wants to understand your argument. Show the coefficients that directly test your hypotheses prominently. Move control variable coefficients to an appendix or collapse them into a single row labeled "Controls included: yes." Readers who care about the controls can find them; readers following your argument should not have to scan past 12 demographic coefficients to find the one number that tests your hypothesis.

## 5. Log-Odds vs. Odds Ratios

Logistic regression coefficients are log-odds: the additive change in the log-odds of the outcome for a one-unit change in the predictor. Log-odds are directly interpretable in terms of sign (positive = higher probability) and comparison across models (log-odds are comparable across nested models in a way odds ratios are not), but their magnitude is hard to interpret without conversion.

Odds ratios (OR = exp(β)) are multiplicative and easier for many audiences: an OR of 1.5 means the odds of the outcome are 1.5 times as high for a one-unit increase in the predictor. But ORs cannot be directly averaged or compared across groups with different baseline probabilities.

The choice depends on audience. For a methods audience, log-odds. For a clinical or policy audience, odds ratios. For a general sociology audience, either, as long as you explain what you are showing. Never report both in the same table without clear labeling.

## 6. Why Automated Table Generation Is Better Than Manual Transcription

When you type a table by hand:

- A single digit transposition (0.382 becomes 0.832) passes silently.
- You may copy from an intermediate model run rather than the final one.
- Rerunning the model with a slightly different sample requires retyping the whole table.
- Collaboration requires coordinating which model is "final."

When you use esttab or modelsummary:

- The table is generated programmatically from the stored estimates object.
- Rerunning the model and the table script updates everything automatically.
- The table reflects whatever is in the stored estimate, which is definitionally the model you ran.
- Version control on the script records every change to the table's inputs.

The cost is learning the syntax, which is nontrivial but fixed. The benefit compounds across every paper you write.
