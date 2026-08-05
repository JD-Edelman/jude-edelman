# Survey Weights — Intuition

## 1. What Problem Does This Solve?

The CES 2020 survey did not select respondents by flipping a fair coin for every American adult. Some people were oversampled (e.g., minority groups, residents of certain states) and some were undersampled. On top of that, not everyone who was selected actually responded, and non-response is not random: people who are highly educated, politically engaged, or have landlines respond at higher rates than others.

The result is a sample that, taken at face value, does not look like the U.S. adult population. If you calculate the sample mean of any outcome, that raw average gives too much weight to overrepresented groups and too little to underrepresented ones. Survey weights exist to fix that: each respondent is assigned a number (their weight) that tells you how many people in the target population that respondent "stands in for." When you weight the analysis correctly, a respondent from an undersampled group counts more, and someone from an oversampled group counts less, so the resulting estimates match the population rather than the sample composition.

## 2. When Would a Researcher Reach for It — and When Not?

**Reach for weights when:**

- You want population-level estimates (means, proportions, totals) that are nationally or regionally representative.
- Your outcome is correlated with the variables used to construct sampling strata or post-stratification cells (e.g., political attitudes, income, health). In that case, ignoring weights biases the estimate.
- You are fitting a regression and the sampling probability is related to the outcome even after conditioning on your covariates. The coefficient estimates themselves will be biased without weights.
- You are making claims about subpopulations (e.g., "among Black women aged 25-44...") where the sampling design may have intentionally or unintentionally over- or under-sampled that group.

**Skip or downweight the importance of weights when:**

- The weight variable is independent of the outcome conditional on all your covariates. In that case, weighted and unweighted regression converge asymptotically, and you pay a variance cost for weighting without gaining anything in bias reduction.
- You are doing purely internal, exploratory analysis and have no interest in population-level inference.
- The design is a true simple random sample with 100% response. (This is essentially never true in practice for large social surveys.)

## 3. How the Mechanism Works in Plain Language

Think of the weighted estimator as a correction ledger. The survey designer knows from Census data how many adults of each race, gender, age group, and region live in the U.S. After the survey is collected, the analyst compares those known population counts to the sample counts. If, say, Latino men aged 18-34 make up 4% of the U.S. adult population but only 2% of the sample, each Latino man in the sample gets a weight of roughly 2 — his answers count twice. If white women 65+ make up 9% of the population but 14% of the sample, each of them gets a weight less than 1.

This rebalancing step is called post-stratification. After it, a simple weighted sum of responses looks like what you would have gotten if you had sampled everyone in the right proportions to begin with.

There is also an earlier source of non-representativeness: the sampling design itself. Some units (e.g., households in rural areas) may have been harder to reach and thus had a lower probability of being included in the sample at all. The basic design weight corrects for this by giving each respondent a base weight equal to 1 divided by their probability of selection. Post-stratification weights are then calibrated on top of those base weights.

The key idea in design-based inference is that randomness comes from the sampling process, not from a hypothetical data-generating model. You are not assuming anything about how Y is distributed in the population; you are relying on the randomness of who was selected. This is different from model-based inference, which would instead specify a statistical model for Y and use that model's assumptions to justify estimates.

## 4. Honest Strengths vs. Weaknesses

**Strengths:**

- Corrects for both unequal selection probabilities and differential non-response in a principled, tractable way.
- Produces nationally representative estimates without requiring a random sample, as long as the weight construction used the right auxiliary variables.
- Integrates naturally with stratified and clustered sample designs, which are the norm in large surveys.
- When the sampling design is complex (stratified, clustered, multi-stage), design-aware variance estimation produces confidence intervals that are actually correct. Ignoring the design typically underestimates standard errors, leading to false precision.

**Weaknesses and honest caveats:**

- Weights correct only for the variables used in their construction. If an unmeasured variable drives non-response (e.g., people with strong political opinions are more likely to complete a political survey), post-stratification cannot fix that bias, no matter how sophisticated the weighting scheme.
- Weighting increases variance. Respondents with very large weights (because their group was severely undersampled) pull estimates around a lot. Effective sample size drops, sometimes dramatically.
- The "when weights don't matter for regression" condition (weight ignorability conditional on covariates) is often plausible in practice but rarely verifiable. Analysts sometimes argue it to avoid weighting, and sometimes that argument is motivated reasoning.
- Subpopulation analysis is a common trap. If you subset your data to, say, only Democratic respondents before applying the survey design, the software no longer knows that non-Democrats existed and will compute wrong standard errors. The correct approach is to define the subpopulation inside the survey design object and let the software handle it. In Stata, use the `subpop()` option with `svy:` commands rather than dropping observations before the `svyset` call.
