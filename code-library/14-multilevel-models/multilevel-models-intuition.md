# Module 14: Multilevel Models -- Intuition Guide

---

## 1. What problem does this technique solve?

Survey data rarely comes from a simple random sample of independent individuals. In the CES 2020, respondents live in states, states have different political cultures, policy environments, and demographic compositions. If you run a standard OLS regression and pretend each respondent is independent, you are making a claim that knowing someone lives in Mississippi tells you nothing extra about their outcome once you account for their individual characteristics. That claim is almost certainly wrong.

The technical name for this problem is **non-independence due to clustering**. Observations from the same group tend to be more similar to each other than observations drawn at random from the full population. When you ignore that similarity, your standard errors are too small -- your model is acting as if you have more independent pieces of information than you actually do. The result is inflated t-statistics and false positives. Multilevel models (also called mixed-effects models or hierarchical linear models) solve this by explicitly modeling the clustering structure.

---

## 2. When would a researcher reach for this -- and when not?

**Reach for multilevel models when:**

- Your data has a clear nesting structure (respondents in states, students in schools, workers in firms, waves in individuals) and that structure is substantively meaningful, not just a nuisance.
- You want to include predictors that live at the group level (state-level unemployment rate, school funding per pupil). Fixed effects cannot estimate coefficients on variables that don't vary within groups.
- Your groups are few in number or have small sample sizes within them. Fixed effects become unreliable when groups have only a handful of observations; multilevel models use partial pooling to stabilize estimates.
- You are genuinely interested in the variance across groups, not just the average effect.
- You want to make predictions for new groups not in your data (a random-effects assumption enables that; a fixed-effects assumption does not).

**Do not reach for multilevel models when:**

- Your primary goal is causal identification and you want to control for all time-invariant group characteristics without modeling them. Fixed effects are more conservative and make fewer distributional assumptions.
- You have a very large number of groups with many observations per group and no interest in between-group variation. OLS with clustered standard errors may be sufficient.
- The nesting structure is arbitrary or very shallow (e.g., two groups). With only two or three groups there is not enough information to estimate a distribution of random effects.

---

## 3. How it works -- plain language

**The clustering problem visualized.** Imagine you survey 50 respondents per state. If you run OLS, you implicitly act as if all 50 are independent draws from the same population. But Alabamans share a state legislature, news media ecosystem, and social environment that makes their opinions more correlated with each other than with Oregonians. Your 50 Alabaman observations don't give you 50 independent data points -- you get something less.

**What a random intercept does.** A random intercept model says: each group (state) gets its own baseline level of the outcome, and those baselines are treated as a sample from a normal distribution centered at the overall mean. You're not estimating a separate dummy variable for each state. Instead, you're estimating the *distribution* of state baselines -- specifically, its mean and variance. The individual state deviations from that mean are called random effects.

This matters because it changes how the model treats small and large states differently. A state with 500 respondents gives you a precise estimate of its baseline. A state with 15 respondents gives you a noisy one. The multilevel model automatically blends each group's observed deviation with the grand mean, pulling small-sample groups closer to the center. This is called **shrinkage** or **partial pooling**.

**Shrinkage is a feature, not a bug.** Suppose Wyoming has 12 respondents in your CES sample and happens to have an extreme average outcome just by chance. A fixed-effects model takes that extreme average at face value. A multilevel model says: "given how little data we have from Wyoming, we should trust this estimate less and pull it toward the overall mean." You lose a little bit on Wyoming specifically, but you gain a lot in aggregate predictive accuracy. This is mathematically equivalent to putting a regularizing prior on the group effects.

**Random slopes.** A random intercept only lets groups differ in their baseline level. A random slope lets groups differ in how strongly a predictor relates to the outcome. Maybe the gender gap in political trust is large in some states and small (or reversed) in others. A random slope on gender within state allows the model to estimate that variation.

**Cross-level interactions.** Once you have a random slope, you can ask: what explains the variation in that slope across states? Enter a state-level variable (e.g., state median income) to moderate the individual-level slope. The coefficient on the product of the state variable and the individual variable is called a cross-level interaction. It answers the question: "Does the effect of X on Y for individuals depend on the group context those individuals live in?"

**The intraclass correlation (ICC).** The ICC is a single number between 0 and 1 that summarizes how much of the total variance in your outcome lives between groups rather than within them. An ICC of 0 means groups are irrelevant -- everyone is as different from their group-mates as from strangers. An ICC of 0.20 means 20% of the variability in the outcome is explained just by knowing which group someone belongs to, before you know anything else about them. The ICC also equals the expected correlation between two randomly chosen people from the same group.

---

## 4. Strengths, weaknesses, and alternatives

**Strengths:**

- Corrects standard errors for clustering, reducing false positives.
- Produces efficient estimates through partial pooling, especially for small groups.
- Accommodates group-level predictors (level-2 covariates) that fixed effects cannot estimate.
- Quantifies how much variance lives at each level of the hierarchy.
- Can extend to three or more levels (respondents in counties in states), crossed structures, and binary outcomes (generalized linear mixed models).

**Weaknesses:**

- Requires distributional assumptions about the random effects (usually normality). Violations can affect inference, though the models are somewhat robust.
- Computationally expensive for large datasets with many groups and random slopes.
- Estimation (REML, full ML) is more complex than OLS and requires understanding the distinction between the two.
- The unconfoundedness assumption is still present: the model does not automatically handle selection into groups. If people sort into states based on unobserved characteristics that also affect the outcome, the coefficients are still biased.
- Between-group variation is not separated from between-group selection. Random effects absorb between-state differences, but those differences may reflect selection, not causal context.

**Alternatives:**

- **Fixed effects (FE) regression:** estimates a dummy variable (or within-transformation) for each group. Eliminates all between-group confounding. Cannot estimate group-level predictors. Preferred when causal identification is the priority and between-group variance is a nuisance.
- **OLS with clustered standard errors:** ignores between-group structure in point estimates, but corrects SEs for clustering. Appropriate when the nesting is a design feature to account for rather than a phenomenon to model. Less efficient than MLM when group effects are real.
- **Bayesian hierarchical models:** same structure as MLM but estimated via MCMC. More flexible priors, exact uncertainty quantification, natural regularization. Higher computational cost and steeper learning curve.
- **Aggregate-level analysis:** if you only have group-level outcomes and predictors, this is equivalent. But aggregating individual data throws away within-group variation.

**Rule of thumb for choosing between MLM and FE:** if you care about level-2 predictors, have small groups, or want to model between-group variance as substantively meaningful, use MLM. If your goal is clean identification of a causal effect and you can afford to burn the between-group variation, use FE.
