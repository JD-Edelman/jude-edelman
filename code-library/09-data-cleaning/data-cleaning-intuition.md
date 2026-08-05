# Module 09 — Data Cleaning: Intuition

## What Problem Does This Technique Solve?

Statistical models are algorithms applied to numbers. They have no way to know whether those numbers are accurate, consistent, or even meaningful. A survey respondent who enters age 999, a merge that silently drops half your sample, or a miscoded dummy variable will all produce output that looks normal. The model will converge, standard errors will print, and the results will be wrong in ways that post-hoc diagnostics cannot catch. Data cleaning is the discipline of making the data truthful before analysis begins.

The "garbage in, garbage out" principle is not a warning about extreme cases. It is a description of ordinary survey data. The CES 2020, like every large-scale survey, contains skip-pattern violations, impossible values, and responses that shift meaning depending on how the question was routed. None of these are flagged automatically.

---

## When to Reach for It (and When Not To)

**Always clean before analyzing.** There is no analysis context in which raw survey data should go directly into a regression. Even simple descriptive tables need cleaned data.

**Do not treat cleaning as a one-time manual step.** If you check for errors by scrolling through a spreadsheet, those checks are not reproducible and will not re-run when the data are updated. Write assertions in code. If the data change, your checks catch new problems automatically.

**Do not clean after merging.** String standardization, recoding, and outlier review should happen on each source file before the merge, not on the merged output. Problems caught pre-merge are localized; problems caught post-merge require tracing back to which source introduced them.

---

## The Three Mechanisms of Missingness

Understanding why data are missing determines what you can legitimately do about the gap.

**Missing Completely at Random (MCAR).** The probability that an observation is missing has no relationship to any variable in your dataset, observed or unobserved. A survey software bug randomly fails to record 2% of responses regardless of who the respondent is. Under MCAR, the observed data are a simple random subsample of what you would have seen with complete data. Listwise deletion (dropping all rows with any missing value) is unbiased under MCAR because you are essentially just working with a smaller random sample.

**Missing at Random (MAR).** "At random" here is misleading jargon. It does not mean random in the ordinary sense. It means: after conditioning on the observed variables in your dataset, the probability of missingness no longer depends on the unobserved value itself. Income questions are more likely to be skipped by men than women, but conditional on gender (which you observed), the probability of skipping does not depend on the actual income value. This is the most common mechanism in social science surveys. Listwise deletion under MAR biases your estimates because the observed cases are systematically different from the missing cases in ways that affect your outcome.

**Missing Not at Random (MNAR).** The probability of missingness depends on the value that is missing, even after accounting for everything else you observed. High-income respondents skip income questions at higher rates than low-income respondents, and this is true even within any demographic subgroup you condition on. MNAR is the hardest case: standard methods including multiple imputation are not guaranteed to remove the bias, because the information you need to model the missingness is precisely the information that is missing.

The practical implication: before deciding how to handle missing data, form a substantive theory about why the values are missing. The mechanism cannot be verified from the data alone when the data are missing.

---

## Logical Consistency Checks

Logical consistency checks catch problems that no statistical method can fix downstream. A few examples from the CES 2020 context:

- A respondent reports voting in the 2020 election but also reports being 17 years old at the time of the election.
- A respondent reports being a Democrat and having voted for Trump, with no third-party affiliation.
- A Likert item has a value of 8 on a 1-7 scale.
- A continuous income variable has a value of 0 for a respondent who reports being employed full-time and owning a home.

These are not subtle edge cases. They are structural errors. They arise from data entry problems, routing logic failures, or coding errors during file preparation. They will not produce visible anomalies in means or standard deviations if the affected cells are sparse. The only way to catch them is to write explicit checks: `assert age >= 18 if voted == 1`.

The advantage of coded assertions over manual review: if the underlying data file is re-extracted, re-versioned, or handed to a collaborator who applies different early-stage filters, the assertions re-run and either pass or loudly fail. Manual review done once provides no protection against re-introduction of errors.

---

## Outliers: Error vs. True Extreme Value

An outlier is any observation that falls far from the bulk of the distribution. The important distinction is why.

**Data error outliers** arise from entry mistakes, unit mismatches, or coding failures. A household income of $9,999,999 in a dataset of ordinary Americans is almost certainly someone who entered nine nines as a missing value placeholder. A 3-month-old who reports being married is almost certainly a miscoded age. These observations do not represent reality and should be corrected or removed.

**True extreme values** are observations that accurately represent extreme cases in the population. A billionaire in a wealth survey is a legitimate outlier. A county that voted 95% for one party in a polarized state is a legitimate outlier. Removing these observations because they make your model's residuals look cleaner is a form of p-hacking. It changes your estimates to match your model's preferences rather than the world's properties.

The rule: never delete an outlier without a documented theoretical justification tied to the data-generating process. "It messes up my regression" is not a justification. "It is a known data entry error" or "it represents a fundamentally different data-generating process that is out of scope for my research question" are justifications.

Winsorizing (capping extreme values at a specified percentile) is a middle path that retains the observation while limiting its leverage. It is appropriate when you believe the true value is in the tail but the exact magnitude is unreliable.

---

## When Listwise Deletion Is Acceptable

Listwise deletion is only unbiased under MCAR, and MCAR is rarely defensible by assumption alone. The practical test: compare the observed subsample to the full sample on all variables you have. If respondents with missing data on your key variable differ systematically from those without missing data on other observed characteristics (demographic, geographic, political), MAR is more plausible than MCAR and listwise deletion will bias your results.

Even when MCAR is plausible, listwise deletion reduces sample size and therefore reduces power. For small or moderate samples, the power loss alone can motivate multiple imputation.

The one genuinely safe use of listwise deletion: when the outcome variable is missing and you have no reasonable basis for imputing the outcome. Imputing the dependent variable from predictors risks circular reasoning and generally inflates apparent fit.

---

## Strengths, Weaknesses, and Alternatives

| | Data Cleaning |
|---|---|
| **Strengths** | Catches errors no model can fix; reproducible if coded; protects against error re-introduction |
| **Weaknesses** | Time-intensive; requires domain knowledge to distinguish errors from true values; cleaning decisions are analytical decisions that affect results |
| **Alternatives** | There are no alternatives to cleaning. Multiple imputation (Module 10) handles missing data after cleaning. Nothing substitutes for verifying that the values you have are what they claim to be. |

The most important thing to internalize: cleaning decisions are researcher degrees of freedom. Dropping an "outlier," recoding a category, or treating a value as missing are all choices that affect your estimates. Document every choice, with the reason, in your code or a cleaning log. A regression is only as credible as the data that feeds it.
