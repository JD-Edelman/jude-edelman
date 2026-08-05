# Module 11 — Scale Construction: Intuition

## What Problem Does This Technique Solve?

Sociology and political science routinely study concepts that cannot be directly observed: authoritarianism, racial resentment, political sophistication, social trust. These are latent constructs. No single survey question captures them. A single item asking "Are you authoritarian?" is not a reliable measure of authoritarianism; it measures whether the respondent agrees with that self-description on a particular day with that particular wording.

Scale construction formalizes the process of combining multiple observable indicators into a single score that better represents the underlying latent construct. The CES 2020 includes batteries of items on racial attitudes, political knowledge, and policy preferences. Before using these in analysis, you need to know whether they hang together coherently, how much measurement error remains in the composite, and whether the composite measures one thing or several.

---

## When to Reach for It (and When Not To)

**Use scale construction when:** You have multiple survey items that are theoretically supposed to measure the same underlying construct, and you want to aggregate them into a single variable for use in regression or for substantive description.

**Use EFA (exploratory factor analysis) when:** You have a battery of items and no strong prior theory about how many dimensions they represent or which items load on which factors. EFA is exploratory; it discovers structure.

**Use CFA (confirmatory factor analysis) when:** You have an explicit theory: "these 4 items measure factor 1 and these 3 items measure factor 2, and the two factors are correlated." CFA tests whether your specified structure fits the data. CFA is part of structural equation modeling.

**Do not use scale construction when:** You have only one or two items. Reliability metrics require at least three. Also do not blindly sum items without checking that they actually cohere. A composite of incoherent items is noise with a misleading label.

**Do not use Cronbach's alpha as your only criterion.** Alpha measures internal consistency, which reflects whether the items correlate with each other. A scale can have high alpha but still be multidimensional (measuring more than one construct). Alpha tells you about the average inter-item correlation, not about unidimensionality.

---

## Reflective vs. Formative Measurement

This distinction is foundational and frequently ignored, leading to the wrong statistical approach.

**Reflective measurement:** The latent construct causes the indicators. Authoritarianism (the construct) causes endorsement of particular child-rearing values, deference to authority, and in-group favoritism (the items). If the latent trait goes up, all indicators should go up (with measurement error). The items are interchangeable in principle; removing one item slightly degrades reliability but does not change what is being measured. Most sociological scales are reflective. Cronbach's alpha and factor analysis apply here.

**Formative measurement:** The indicators define and constitute the construct; there is no separate latent variable causing them. Socioeconomic status (SES) is a common example: SES is formed by combining income, education, and occupational prestige. These components do not all correlate highly (a professor has high education but moderate income; a plumber may have lower education but high income). Removing one component changes the definition of the construct. Cronbach's alpha does not apply to formative scales because low inter-item correlation is expected and acceptable.

The practical test: ask whether a change in one indicator should, in theory, cause a change in the other indicators. If yes (answering "yes" on one authoritarianism item should mean you tend to endorse others), the measurement is reflective. If no (higher income does not cause higher education), it is formative.

---

## What Factor Loadings Mean

A factor loading is the correlation between an observed item and the underlying latent factor. It ranges from -1 to 1.

A loading of 0.70 means: knowing a person's score on the latent factor allows you to predict their item response with a correlation of 0.70. Roughly, 49% of the variance in that item (0.70²) is explained by the latent factor; the remaining 51% is unique to that item (measurement error plus item-specific variance).

Conventionally:
- Loadings above 0.70 are considered strong.
- Loadings of 0.40 to 0.70 are moderate; the item contributes to the factor but with substantial noise.
- Loadings below 0.40 suggest the item may not belong in the scale or may be cross-loading on a different factor.

An item that loads strongly on two factors simultaneously (cross-loading) is problematic because it is not a clean indicator of either construct.

---

## The Three Criteria for Judging a Scale

**Reliability** refers to consistency: does the scale give similar results across repeated measurements (test-retest reliability) or across parallel items measuring the same thing (internal consistency, assessed by Cronbach's alpha)? A reliable scale is not necessarily valid.

**Convergent validity:** the scale should correlate highly with other established measures of the same construct. If your new racial resentment scale does not correlate strongly with an established racial resentment scale from prior literature, something is wrong with yours or with theirs.

**Discriminant validity:** the scale should not correlate so highly with measures of conceptually distinct constructs that it cannot be distinguished from them. If your racial resentment scale correlates 0.90 with your general political conservatism scale, you cannot tell whether effects attributed to racial resentment are really effects of conservatism. The average variance extracted (AVE) and the maximum shared variance (MSV) are formal tests; in practice, a clear theoretical argument and moderate inter-construct correlation (below roughly 0.85) are the minimum bar.

---

## Strengths, Weaknesses, and Alternatives

| | Scale Construction / Factor Analysis |
|---|---|
| **Strengths** | Reduces measurement error by averaging across items; allows formal testing of scale structure; provides reliability statistics that reviewers and readers can assess |
| **Weaknesses** | Results are sensitive to item selection, rotation choice (for EFA), and sample characteristics; Cronbach's alpha inflates with more items; factor structure found in one sample may not replicate in another |
| **Alternatives** | Item Response Theory (IRT) models the relationship between a latent trait and each item explicitly, allowing items to differ in discrimination and difficulty. IRT is more flexible than classical test theory but requires larger samples and more modeling choices. For ordinal outcomes, polychoric correlations should be used rather than Pearson correlations as input to factor analysis. |
