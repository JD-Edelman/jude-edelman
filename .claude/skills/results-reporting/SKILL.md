---
name: results-reporting
description: "Turn Stata, R, or Python regression output into correct, publication-ready sociology results: choose what to report (coefficients, odds ratios, average marginal effects, predicted probabilities), build the table, and write the results paragraph with the right interpretation and no overclaiming. Catches common errors — comparing logit coefficients across models, reading interactions from main effects, ignoring survey weights, causal language on observational data. Use whenever the user pastes model output, log files, or tables, asks 'how do I interpret this', 'write up my results', 'make a regression table', or is drafting a findings/results section."
---

# Results reporting

Quantitative sociology papers are most often criticized in review for interpretation errors, not wrong code. This skill reads model output, decides what should be reported, and writes the results so a reviewer cannot catch an overclaim.

## Step 1: understand the model before interpreting it

From the output (or the code, if given), establish:
- Outcome type and model: OLS, logit/probit, ordered, count (Poisson/NB), multilevel, fixed effects, survival.
- Unit of analysis and N at each level. Check N matches across nested models; if it drops, listwise deletion is changing the sample and the models are not comparable — flag it.
- Weights, clustering, and survey design (`svy:`, `[pw=]`, `survey` package). If a survey dataset (CES, ACS, NLSY, Add Health, AFCARS/NCANDS-derived samples) is analyzed without design adjustment, say so first; it affects every standard error.
- Reference categories for every categorical predictor.
- Scaling of continuous predictors (a coefficient on income in dollars vs. thousands vs. logged means very different things).

Ask for the missing piece only if it changes the interpretation; otherwise state the assumption.

## Step 2: choose the quantity to report

- **OLS**: unstandardized coefficients with SEs. Standardized only if the user's subfield expects them, never as the only numbers.
- **Logit/probit**: report average marginal effects (Stata `margins, dydx(*)`; R `marginaleffects::avg_slopes`) or predicted probabilities in the text. Odds ratios can go in the table if the venue expects them, but interpret in probabilities. Logit coefficients and odds ratios **cannot be compared across nested models** (scale changes with unobserved heterogeneity — Mood 2010; Karlson, Holm & Breen 2012). If the user is doing mediation or "the coefficient shrinks when we add X" with logit, flag it and suggest AMEs or the KHB method.
- **Interactions**: never interpret the main effect as an average effect when an interaction is present — it is the effect when the moderator equals zero. Report conditional effects or plot predicted values across the moderator. In nonlinear models the interaction term's sign and significance do not equal the interaction effect on the probability scale (Ai & Norton 2003); use `margins`.
- **Count models**: incidence rate ratios or marginal effects; check overdispersion.
- **Multilevel**: report fixed effects, variance components, ICC; say what the random effects mean substantively.
- **Fixed effects**: say what variation identifies the estimate (within-person, within-county…), because that is what the coefficient means.

## Step 3: build the table

Standard sociology layout: models as columns (nested left to right), variables as rows grouped by block, coefficients with SEs in parentheses below, stars at conventional levels with the note stating them, N and fit statistics at the bottom, reference categories stated in a note. Provide code to generate it (`esttab`/`etable` in Stata, `modelsummary` in R) rather than hand-typed numbers, so the table can be regenerated after revisions. The user's code library already covers export tables (module 08); match its conventions when the repo is available.

## Step 4: write the paragraph

Pattern per finding: **direction → magnitude in substantive units → uncertainty → comparison or implication**.

> Net of family background, youth who aged out of privately managed foster care placements were about 6 percentage points less likely to enroll in college by age 21 (AME = –0.061, 95% CI [–0.094, –0.028]), roughly a fifth of the baseline enrollment rate.

Rules that keep reviewers quiet:
- Magnitudes in real units, not just "significant." A significant, tiny effect is a finding about precision, not importance.
- No causal verbs ("increases," "leads to," "the effect of") for observational designs unless the design identifies the effect; use "is associated with," "net of," "compared with." Say once in the text what design would be needed for a causal claim if the argument depends on one.
- Non-significant is not zero. Report the interval; say whether it rules out effects of meaningful size.
- Don't narrate every control variable. Report the ones the argument is about.
- Keep the "Results" section descriptive and save theory for "Discussion", unless the venue blends them.

## Step 5: self-check

Before delivering, reread the paragraph against the output and verify every number, sign, and reference category. Transcription errors between table and text are common and easy to catch.
