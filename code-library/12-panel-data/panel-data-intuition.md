# Module 12 — Panel Data: Intuition

## What Problem Does This Technique Solve?

The central problem in observational social science is confounding: the people who receive a treatment or have a characteristic differ in ways that also affect the outcome. Higher-educated people vote at higher rates, but they also differ from lower-educated people in income, media consumption, and social networks. When you compare voters to non-voters, you cannot separate the effect of education from the effects of these correlated traits, most of which you did not measure.

Panel data, also called longitudinal data, follows the same units (people, counties, organizations) across multiple time points. This creates a powerful opportunity: you can compare each unit to itself across time, rather than comparing different units to each other. When you do that, every time-invariant characteristic of the unit, whether observed or not, drops out of the comparison. You do not need to measure someone's personality, cultural background, family history, or any other stable trait; they are automatically controlled because you are looking at how that same person changed.

The CES includes some panel components and wave-to-wave comparisons. More generally, county-level or state-level panel data (e.g., election returns across multiple years combined with policy variables) are a workhorse of political sociology.

---

## Within-Person Variation: What Fixed Effects Actually Use

Fixed effects estimation works exclusively with variation that occurs within units over time. If you are studying individuals, FE asks: among the observations of person i, how did changes in the predictor X correlate with changes in the outcome Y?

A concrete example: you want to know whether county unemployment affects Republican vote share. You have 50 counties measured over 10 elections. FE compares each county to itself: in years when county i had higher unemployment than its own average, did it vote more Republican? The analysis is entirely within-county. Cross-county comparisons, where wealthy counties differ from poor counties in dozens of ways, play no role.

The transformation that accomplishes this is demeaning: subtract each unit's mean from each of its observations. After demeaning, a county whose unemployment is always high has a de-meaned unemployment of zero in every year and contributes nothing to the estimate. Only counties that fluctuate contribute.

---

## When Fixed Effects Hurts You

FE's strength is also its limitation. Because FE only uses within-unit variation, it cannot estimate effects of variables that do not change within units over your observation window.

**Time-invariant predictors are completely absorbed.** If you are studying gender effects with individual-level panel data, gender (for most respondents in most datasets) does not change. FE eats the gender variable along with all other unit-specific constants. You cannot estimate the effect of gender with individual FE. This is not a limitation to work around; it is the mathematical consequence of the demeaning.

**Low within-unit variation reduces precision.** If a predictor rarely changes within units, the within-unit variation is small, and your standard errors will be large. FE is efficient only when there is meaningful variation over time. A variable that is 90% between-unit and 10% within-unit may produce very imprecise FE estimates even in a large panel.

**FE cannot identify long-run effects well.** Short panels with few time points capture short-run dynamics. Effects that unfold slowly over many years require long panels that most researchers do not have.

---

## Random Effects and the Hausman Test

The random effects (RE) model is an alternative to FE. Instead of treating unit-specific constants as parameters to be estimated and eliminated, RE treats them as random variables drawn from a distribution. This allows RE to estimate effects of time-invariant predictors and is more efficient than FE when the assumption holds.

The critical assumption for RE: the unit-specific constants must be uncorrelated with the predictors. If the things that make county i permanently different (geography, history, culture) are correlated with your time-varying predictor (policy changes, economic shocks), RE is inconsistent. FE, which eliminates the unit-specific constant, is consistent even in this case.

**The Hausman test in plain language:** if RE is consistent, both FE and RE give you the right answer, so their estimates should be close. If RE is inconsistent (because the unit effects are correlated with the predictors), RE estimates drift away from the truth while FE stays correct. The Hausman test formalizes this: it tests whether FE and RE estimates differ significantly. A large, significant difference is evidence that RE is inconsistent and FE should be preferred.

The Hausman test is a diagnostic, not a proof. Rejecting RE does not mean your FE estimates are valid (they have their own assumptions). It means RE's specific assumption fails.

---

## Difference-in-Differences

Difference-in-differences (DiD) is a panel estimator designed for natural experiments: one group (treated) experiences a policy change, another group (control) does not, and you observe both before and after.

The intuition: the treated group's post-minus-pre difference includes both the treatment effect and any time trends that would have happened regardless. The control group's post-minus-pre difference captures only the time trend (since they were not treated). Subtracting the control trend from the treated trend isolates the treatment effect.

This subtraction is the "double difference": (treated_after - treated_before) - (control_after - control_before).

**The parallel trends assumption** is the crucial and untenable-to-verify-perfectly assumption behind DiD: in the absence of treatment, the treated and control groups would have followed parallel time trends. Not the same level, but the same trend. If the treated group was already diverging from the control group before treatment for reasons unrelated to treatment, DiD cannot isolate the treatment effect.

Parallel trends is an assumption, not a data property. It cannot be tested in the post-period (you never observe the counterfactual). It can be examined pre-treatment.

**Event-study plots** extend DiD by estimating a separate treatment effect for each time period before and after treatment, rather than collapsing to a single before/after contrast. A good event-study plot shows: (1) pre-treatment coefficients close to zero (supporting parallel pre-trends); (2) a treatment effect that turns on at the treatment period and evolves in a theoretically sensible way afterward. These plots are the best available empirical evidence for or against parallel trends.

---

## Strengths, Weaknesses, and Alternatives

| | Fixed Effects Panel Estimation |
|---|---|
| **Strengths** | Controls for all time-invariant confounders, observed and unobserved; strong identification when within-unit variation is meaningful |
| **Weaknesses** | Cannot estimate effects of time-invariant predictors; low efficiency when within-unit variation is sparse; does not handle time-varying confounders; results sensitive to measurement error (which amplifies under demeaning) |
| **Alternatives** | Random effects is more efficient but requires stronger assumptions. First differences is equivalent to FE for T=2 but differs for T>2 panels with heteroskedastic errors. Synthetic control methods construct a weighted control unit when there is only one treated unit. DiD with staggered adoption (different units treated at different times) requires more careful estimators than simple two-way FE when treatment effects are heterogeneous. |
