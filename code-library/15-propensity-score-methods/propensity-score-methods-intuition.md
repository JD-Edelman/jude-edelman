# Module 15: Propensity Score Methods -- Intuition Guide

---

## 1. What problem does this technique solve?

In an experiment, you randomly assign who receives treatment and who doesn't. Because assignment is random, the two groups (treated and control) are, on average, identical on every characteristic -- measured or unmeasured -- before the treatment is applied. Any difference in outcomes you observe afterward can be attributed to the treatment itself.

In observational data, nobody randomized anything. People sort into treatment (a policy, an experience, a behavior) based on who they are. In the CES 2020, imagine you want to estimate the effect of consuming political news daily on political efficacy. People who consume news daily are systematically different from people who don't: they are more educated, more politically interested, and probably already higher in efficacy before they ever read a newspaper. A naive comparison of outcomes between daily news consumers and non-consumers doesn't tell you what news consumption does -- it tells you what kind of person is a daily news consumer.

This is **selection bias**: the difference in outcomes between treated and control groups reflects not just the treatment effect but also the pre-existing differences between the groups. Propensity score methods are a family of techniques for adjusting observed data to more closely resemble what you would have gotten from a randomized experiment -- under the crucial assumption that you have measured all the variables that drive selection.

---

## 2. When would a researcher reach for this -- and when not?

**Reach for propensity score methods when:**

- You have observational data with a binary treatment and a rich set of measured pre-treatment covariates.
- You believe selection into treatment is driven primarily by observed characteristics (unconfoundedness holds, at least approximately).
- You want to estimate a causal effect in a way that is transparent about which comparisons you are making (matching makes the counterfactual comparison explicit in a way that regression does not).
- You want to separate the design stage (constructing comparable groups) from the analysis stage (running the outcome regression), following the Rubin model of causal inference.

**Do not reach for propensity score methods when:**

- There is strong reason to believe unmeasured variables drive selection. Adding propensity score adjustment cannot fix unmeasured confounding -- it only adjusts for what you measured. If education drives treatment assignment and you didn't measure education, weighting on measured covariates doesn't help.
- You have an instrument (a variable that affects treatment but has no direct effect on the outcome). Instrumental variables (IV) can handle unmeasured confounding in ways that propensity score methods cannot.
- You have panel data spanning the pre-treatment period. Difference-in-differences (DiD) controls for time-invariant unmeasured confounders using within-unit comparisons over time.
- Your treatment is continuous (e.g., hours of news consumed per week). Standard propensity score methods are designed for binary treatments, though extensions exist (generalized propensity scores).
- Overlap fails badly (see below). If treated and control units are too different for any reasonable comparison to be made, no statistical method can rescue the analysis from that fundamental lack of evidence.

---

## 3. The mechanism in plain language

**The propensity score as a summary.** Suppose selection into treatment depends on five covariates: age, education, income, political interest, and urban/rural status. You can't easily hold all five constant simultaneously. The propensity score summarizes all five into one number: the probability that a particular person, given their observed characteristics, would be treated. It is a dimensionality reduction tool with a special property -- conditioning on this single number is, in theory, equivalent to conditioning on all five covariates simultaneously.

**Matching in plain language.** Find each treated unit a control unit that has a similar propensity score. You are saying: "I'll compare this treated person to a control person who looked equally likely to be treated based on everything we measured, but who wasn't." After matching, you compare their outcomes. The remaining difference is your estimate of the treatment effect.

**IPTW in plain language.** Instead of finding matched pairs, you reweight the entire sample. Treated people who had a low probability of being treated (they look like non-treated people) are uncommon among the treated, so they must be upweighted to represent all the treated-looking people who weren't treated. Control people who had a high probability of being treated (they look a lot like treated people) are rare among controls and must be upweighted. After reweighting, the treated group and control group should look similar on all measured covariates, as if treatment had been randomized. You then compare average outcomes between the reweighted groups.

**Why common support matters.** If a treated person has a propensity score of 0.98 -- they were almost certain to be treated given their characteristics -- there is almost nobody in the control group who looks like them. Either you can't find a match, or any match you find is a very poor one. IPTW handles this differently (it assigns an extreme weight) but extreme weights create enormous variance in the estimator and are driven by a handful of unusual observations. The "common support" assumption says there must be some probability of both treatment and control for every type of person in your data. Without it, you are extrapolating rather than comparing.

**Balance diagnostics.** After matching or weighting, you check whether the adjusted treated and control groups actually look similar on all covariates. You don't rely on the propensity score model being correct -- you check empirically. The standardized mean difference (SMD) for each covariate measures the gap between treated and control means in pooled standard deviation units. The conventional threshold for good balance is |SMD| < 0.10 after adjustment.

**ATE vs. ATT.** These are two different target quantities.

The average treatment effect (ATE) answers: "What would happen on average if we took everyone in the population and randomly assigned them to treatment versus control?" It averages the treatment effect over the entire population.

The average treatment effect on the treated (ATT) answers: "What did treatment do for the people who actually received it?" It only asks about the treated group: what would their outcomes have been if they hadn't been treated?

These differ whenever the treatment effect itself varies across types of people, and when treated and untreated people differ systematically. In most policy research, ATT is more relevant: you care about the effect on the people the policy actually reached. IPTW uses different weights for ATE versus ATT (see the math file for details).

---

## 4. Strengths, weaknesses, and alternatives

**Strengths:**

- Makes the comparison being made explicit and transparent. Matching visualizes the counterfactual: you can literally see which control unit is being compared to which treated unit.
- Separates design from analysis: balance the sample first, then run any outcome model you want. Reduces the risk of "peeking" at outcomes while adjusting the model.
- Flexible: you can match, weight, or stratify. You can combine propensity scores with outcome regression for doubly robust estimation.
- Intuitive communication to non-statistical audiences: "we found control units who looked just like the treated units on every measured characteristic."

**Weaknesses:**

- The entire approach rests on unconfoundedness, which is untestable. You can check measured covariates but cannot verify that unmeasured variables are balanced.
- Extreme propensity scores (near 0 or 1) create large IPTW weights, inflating variance and making the estimator sensitive to a small number of units.
- Matching discards control units that aren't matched, which can reduce statistical power substantially, especially 1:1 matching without replacement.
- Post-matching/weighting, you still need to choose an outcome model and that model can be misspecified.
- Propensity score methods are not a substitute for design: they cannot create the comparability that comes from actual randomization.

**Alternatives:**

- **Regression adjustment:** include covariates directly in a regression of outcome on treatment. Simpler but relies entirely on correct functional form specification. Can extrapolate well beyond the data if treated and control units don't overlap.
- **Doubly robust estimators (AIPW):** combine a propensity score model with an outcome model. Consistent if either model is correctly specified (not necessarily both).
- **Instrumental variables (IV):** handles unmeasured confounding if a valid instrument exists. Estimates a local average treatment effect (LATE) for compliers, not the full ATE or ATT.
- **Difference-in-differences (DiD):** requires panel data but controls for time-invariant unmeasured confounders. Relies on parallel trends rather than unconfoundedness.
- **Regression discontinuity (RD):** when treatment assignment is determined by a cutoff on a running variable, comparison near the cutoff approximates a local experiment. Highly credible but narrow in scope.

The choice among these depends on what variation you can credibly exploit and what assumption you're more willing to defend. Propensity score methods require "I measured everything that matters." IV requires "I have a variable that affects treatment but nothing else." DiD requires "trends in treated and control units would have been parallel absent treatment." None is universally better.
