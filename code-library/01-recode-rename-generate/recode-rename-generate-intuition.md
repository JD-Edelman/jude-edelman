# Module 01 — Recode, Rename, Generate: Intuition

## What Problem Does This Solve?

Raw survey data arrives in a state that is not ready for analysis. Variable names are cryptic instrument codes (`V1103b`, `Q22a_r`). Numeric values carry no inherent meaning without a codebook. Scales point in conflicting directions. Categories are too granular for your research question. Missing data are encoded as numeric sentinels (99, -8, 999) that look, to any statistical function, like real values.

Every one of these problems will silently corrupt your estimates if you ignore them. The recode-rename-generate step is the disciplined process of transforming raw instrument output into an analysis-ready dataset where every variable name is self-documenting, every value has an unambiguous meaning, and derived constructs are built in traceable, deliberate steps.

In the CES 2020 data specifically, you will encounter Likert items that run 1 = "Strongly agree" through 5 = "Strongly disagree" on some questions and 1 = "Strongly disagree" through 5 = "Strongly agree" on others. Computing a composite scale from un-harmonized items does not average opinions; it averages noise.

---

## When to Reach for It, and When Not To

**Reach for it when:**

- Variable names from the raw file will not be legible six months from now (nearly always true for survey data).
- Any item uses sentinel codes for "refused," "don't know," or "not applicable" that need to be declared missing before they enter arithmetic.
- You plan to combine items into a scale, index, or composite, and the items do not currently share a common direction or metric.
- Your research question requires a derived variable (a ratio, an interaction term, a binary indicator from a continuous measure) that does not exist in the raw file.
- You are collapsing a fine-grained category variable into broader substantive groups (e.g., collapsing many racial/ethnic codes into a smaller analytic scheme).

**Do not reach for it when:**

- You are working from a pre-registered analysis plan that specifies exact coding decisions. In that case, every recode must already be documented in the registration; ad hoc recoding after seeing the data introduces researcher degrees of freedom.
- You are exploring the raw data for the first time. Run descriptives on the raw variables first so you know what you are actually recoding.
- A collaborator or PI owns the master dataset. Modify a working copy, not the canonical file.

The fundamental rule: never overwrite raw variables. Always create a new variable with a distinct name. The raw code should be reproducible from the original file at any time.

---

## How the Mechanism Works

**Renaming** is purely administrative. You assign a human-readable label to a cryptic code name so that code written today is still interpretable by your future self and by collaborators. Good names are short, lowercase, underscore-separated, and hint at the variable's content: `pid_strength`, `voted_2020`, `income_cat`.

**Recoding** changes values. There are three common motivations:

1. *Direction harmonization.* If one scale item runs high-to-low and another runs low-to-high, averaging them produces a meaningless composite. You reverse one so that higher values consistently mean "more" of the same construct.

2. *Category collapsing.* A 7-point income bracket variable might need to become a 3-point low/middle/high grouping for a cross-tabulation or because cell sizes are too small for reliable estimation. Each collapse decision should be theoretically motivated, not just convenient.

3. *Missing value declaration.* Sentinel codes like 99 or -1 must be converted to the software's missing indicator before any calculation. This is not optional; it is the difference between valid estimates and garbage estimates.

**Generating derived variables** creates new columns from arithmetic or logical operations on existing ones. Common examples:

- *Indicator (dummy) variables:* converting a multi-category variable into a set of 0/1 flags, one per category.
- *Composite scales:* averaging across multiple harmonized Likert items that tap the same latent construct.
- *Interaction terms:* multiplying two variables together so a regression can ask whether the effect of one predictor varies across levels of another.
- *Ratio variables:* expressing one count as a proportion of another (e.g., share of income from wages).

Each derived variable represents a modeling decision. Documenting that decision in code comments or a data dictionary is not cosmetic; it is the only thing that lets you defend your operationalization to a reviewer.

---

## Strengths and Weaknesses

**Strengths:**

- Makes every analysis step reproducible and auditable. A do-file or script that runs from raw data to analysis output with no manual steps is the standard.
- Protects against silent errors from sentinel codes entering calculations.
- Separates data-shaping decisions from modeling decisions, which makes both easier to scrutinize.
- Self-documenting variable names dramatically reduce the cognitive load of reading others' code and of reading your own code later.

**Weaknesses / Honest Cautions:**

- Recoding choices are researcher choices. Collapsing income into three groups instead of five, or choosing a particular cutpoint for a binary indicator, can substantially change results. This is a garden-of-forking-paths problem: there are many defensible codings, and the one that "works best" for your hypothesis is not automatically the most valid one.
- Direction harmonization errors are extremely common and extremely hard to catch after the fact. Always inspect value-label distributions before and after recoding.
- Over-collapsing categories throws away variance and statistical power. Collapsing should be driven by theory or sample-size constraints, not by a desire for tidy tables.
- Once you generate an interaction term, you are committed to including both constituent main effects in every model that uses it. Omitting a main effect when its interaction is in the model is a specification error, not a shortcut.
