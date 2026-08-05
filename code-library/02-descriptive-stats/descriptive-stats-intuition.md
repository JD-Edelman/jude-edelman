# Module 02 — Descriptive Statistics: Intuition

## What Problem Does This Solve?

Before any model, before any hypothesis test, you need to know what your data actually look like. Descriptive statistics answer a deceptively simple question: what is going on in this sample? They compress thousands of observations into a small number of summaries that reveal the shape, center, spread, and relationships in your data.

In the CES 2020 dataset you have hundreds of variables and tens of thousands of respondents. No one can read a column of 60,000 vote-choice responses. But a mean, a distribution, a cross-tabulation, and a handful of conditional comparisons let you hold the structure of that data in your head, catch errors in your coding, and decide what inferential questions are even worth asking.

Skipping descriptives is how researchers end up presenting regression coefficients that are artifacts of coding errors, outliers, or bizarre distributions.

---

## Central Tendency vs. Spread: Why You Need Both

Central tendency asks: where is the middle of this distribution? Spread asks: how much do observations vary around that middle?

A researcher who reports only the mean is telling you where the distribution is centered but not how widely it fans out. Consider two hypothetical income distributions: both have a mean of $55,000, but one has a standard deviation of $5,000 (nearly everyone is close to the mean) and the other has a standard deviation of $40,000 (enormous inequality). These are fundamentally different social realities, but identical means.

Conversely, reporting only spread without center is equally incomplete. Always report both.

---

## Mean vs. Median for Skewed Distributions

The mean is the arithmetic center of mass: every observation pulls it proportionally to its distance from zero. This makes the mean sensitive to extreme values. In a right-skewed distribution (a long upper tail, which is the shape of virtually every income, wealth, and consumption variable in survey data), a small number of very high values drag the mean upward, well above the point where most respondents actually cluster.

The median is the value that splits the distribution in half: 50% of observations fall below it and 50% above. Extreme values in the tail have no influence on the median beyond the fact of being above it. For right-skewed distributions, the median is almost always lower than the mean and more representative of the "typical" respondent.

When the mean and median diverge sharply, that divergence is itself a substantive finding: it tells you the distribution is skewed, which may affect your choice of model (log transformation, quantile regression) and how you communicate results to a policy audience.

---

## What Variance Actually Is

Variance is the average squared distance from the mean. The squaring serves two purposes: it makes all deviations positive (so negative and positive deviations do not cancel), and it penalizes large deviations disproportionately relative to small ones.

The intuition is that variance asks: if I pick a random observation, how far away from the mean should I expect it to be? (More precisely, it asks about the expected squared distance, and the standard deviation recovers the expected distance by taking the square root.) A variable with low variance is one where nearly all respondents gave similar answers. A variable with high variance is one where respondents were spread all over the scale. A variable with zero variance is a constant: useless for any model because it cannot covary with anything.

---

## The Purpose of a Cross-Tabulation

A cross-tabulation (crosstab) counts how many observations fall into each cell defined by the combination of two categorical variables. It is the descriptive workhorse for asking: do these two categorical things go together?

In the CES 2020 context, a crosstab of party identification by presidential vote choice shows you exactly how many self-identified Republicans voted for Biden, how many Democrats voted for Trump, and so on. The raw cell counts become more interpretable as row or column percentages, which answer: conditional on being a Democrat, what fraction voted for each candidate?

A chi-square test of independence is the standard inferential test applied to crosstabs: it asks whether the pattern of cell counts differs from what you would expect if the two variables were completely unrelated. The descriptive and inferential functions are complementary. The crosstab shows you the pattern; the chi-square test assesses whether the pattern is likely to reflect something real in the population or could plausibly be sampling noise.

---

## T-test vs. Regression: When to Use Each

A t-test compares the means of a continuous variable between two groups. It is the right tool when your research question is exactly: does the average value of Y differ between group A and group B?

An OLS regression is the right tool when you want to compare group means while holding other variables constant, or when you have more than one predictor, or when at least one predictor is continuous rather than binary.

An independent-samples t-test of Y by a binary group indicator G is mathematically equivalent to a bivariate regression of Y on G (the t-statistic equals the regression t-statistic exactly). But regression generalizes immediately to multiple controls, interaction terms, and continuous predictors, while the t-test does not.

The practical guidance: use a t-test when your question is genuinely simple and you have a single binary grouping. Use regression when you need to control for anything, have multiple predictors, or want to produce conditional estimates.

---

## Survey Weights and Why Unweighted Means Are Biased

Complex probability surveys like CES 2020 do not sample respondents with equal probability. Some groups (racial minorities, rural residents, low-education households) are deliberately oversampled to ensure enough observations for subgroup analysis. Others may be underrepresented due to nonresponse patterns that correlate with the variables you are studying.

If you compute an unweighted mean of political knowledge scores across all 60,000 CES respondents, you are implicitly treating each respondent as equally representative of the U.S. adult population. But an oversampled rural resident counts once in your mean and once in the population, while an undersampled urban resident also counts once in your mean but represents many people in the population. The unweighted mean does not estimate the population mean; it estimates the sample mean, which is a biased estimate of the population quantity.

Survey weights correct this. Each respondent is assigned a weight wᵢ that reflects how many population members they represent. A respondent with weight 3.2 should count 3.2 times as much as a respondent with weight 1.0 when estimating population quantities. The weighted mean, computed as the sum of (weight × value) divided by the sum of weights, is a consistent estimator of the population mean under standard survey sampling theory.

For descriptive tables in a sociology paper using CES 2020, always weight your means, proportions, and cross-tabulations. The exception is when you are explicitly describing your sample rather than making population-level claims, which is a different and rarer goal.
