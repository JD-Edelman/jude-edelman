/*==============================================================================
   MODULE 2: DESCRIPTIVE STATISTICS & TABULATIONS
   Dataset: CES 2020 Common Content (cleaned from Module 1)

   Purpose: Summarize distributions of continuous and categorical variables,
   produce cross-tabulations, and examine group differences.
   All output is designed to be readable in a log file or pasted into a paper.
==============================================================================*/

clear all
set more off

use "CES2020_clean.dta", clear


*==============================================================================
* SECTION 1: UNIVARIATE SUMMARIES — CONTINUOUS VARIABLES
*==============================================================================

/*
   summarize gives mean, SD, min, max.
   Adding the detail option adds percentiles and skewness — useful for
   checking whether a variable is roughly normal or heavily skewed.
*/

* Basic summary table for continuous/ordinal variables
summarize age education ideology5 party_id7 imm_restrict econ_retro ///
    hh_income_change self_rated_health

* Detailed summary for age and the immigration index (check distribution shape)
summarize age, detail
summarize imm_restrict, detail

/*
   tabstat is more flexible than summarize when you want specific stats
   in a compact table — useful for Table 1 in a paper.

   stats() controls which statistics to display.
*/

tabstat age education ideology5 imm_restrict econ_retro self_rated_health, ///
    statistics(mean sd min p25 median p75 max n) ///
    columns(statistics) ///
    format(%6.2f)


*==============================================================================
* SECTION 2: FREQUENCY TABLES — CATEGORICAL VARIABLES
*==============================================================================

/*
   tabulate (or tab) produces a one-way frequency table.
   missing option includes missing values so you can see how much data you lost.
   nofreq suppresses counts when you only want percentages.
*/

tab sex,           missing
tab census_region, missing
tab college,       missing
tab voted,         missing
tab biden_voter,   missing
tab dem,           missing
tab rep,           missing

* Party ID (7-point scale) with percentages
tab party_id7, missing

* Presidential approval
tab approve_trump, missing


*==============================================================================
* SECTION 3: CROSS-TABULATIONS (TWO-WAY TABLES)
*==============================================================================

/*
   tab var1 var2 produces a cross-tab (rows × columns).

   Useful options:
     row    = row percentages (each row sums to 100)
     col    = column percentages (each column sums to 100)
     chi2   = Pearson chi-square test of independence
     exact  = Fisher's exact test (small N or sparse cells)
     nofreq = suppress raw counts (show only percentages)
*/

* Biden vote by college degree
tab college biden_voter, row chi2 missing

* Biden vote by sex
tab sex biden_voter, row chi2 missing

* Biden vote by census region
tab census_region biden_voter, row chi2 missing

* Biden vote by party ID (3-category)
tab party_id3 biden_voter, row chi2 missing

* Voted by census region
tab census_region voted, row chi2 missing

* College degree by sex
tab sex college, row chi2 missing


*==============================================================================
* SECTION 4: GROUP MEANS — tabstat BY GROUP
*==============================================================================

/*
   tabstat with the by() option computes statistics separately by group.
   This is a fast way to compare means across categories.
*/

* Mean age, ideology, immigration restrictionism by Biden vs. Trump voter
tabstat age ideology5 imm_restrict econ_retro, ///
    by(biden_voter) ///
    statistics(mean sd n) ///
    format(%6.2f)

* Same comparison by party ID
tabstat age ideology5 imm_restrict, ///
    by(party_id3) ///
    statistics(mean sd n) ///
    format(%6.2f)

* Mean immigration restrictionism by college degree
tabstat imm_restrict, ///
    by(college) ///
    statistics(mean sd n) ///
    format(%6.2f)


*==============================================================================
* SECTION 5: MEAN COMPARISONS — ttest
*==============================================================================

/*
   ttest tests whether two group means differ significantly.
   The unequal option runs Welch's t-test (does not assume equal variances).
   This is usually preferred over the default equal-variance version.
*/

* Does immigration restrictionism differ by college degree?
ttest imm_restrict, by(college) unequal

* Does ideology differ between Biden and Trump voters?
ttest ideology5, by(biden_voter) unequal

* Does age differ between voters and non-voters?
ttest age, by(voted) unequal

* Does retrospective economic assessment differ by party ID (Dem vs Rep only)?
ttest econ_retro if party_id3 != 3, by(party_id3) unequal


*==============================================================================
* SECTION 6: CORRELATION MATRIX
*==============================================================================

/*
   pwcorr (pairwise correlation) computes Pearson r between all pairs.
   sig   = display p-values below each correlation
   star  = asterisk significant correlations at p<.05

   Useful for checking multicollinearity before running regressions.
*/

pwcorr age education ideology5 imm_restrict econ_retro ///
    self_rated_health biden_voter, ///
    sig star(.05)


*==============================================================================
* SECTION 7: EXAMINING MISSING DATA PATTERNS
*==============================================================================

/*
   Always document how much missing data you have and whether missingness
   looks systematic (e.g., does it cluster in a particular group?).
*/

* Count missing on key variables
foreach var in age education voted biden_voter imm_restrict ideology5 econ_retro {
    quietly count if missing(`var')
    di "Missing on `var': `r(N)' (`=round(`r(N)'/_N*100, .1)'%)"
}

* Is missingness on pres_vote related to party? (hint: independents skip more)
tab party_id3 if missing(biden_voter), missing


*==============================================================================
* SECTION 8: WEIGHTED DESCRIPTIVES
*==============================================================================

/*
   CES includes survey weights to make the sample nationally representative.
   weight_post adjusts for post-election survey design.

   mean with [aweight] or [pweight] applies weights.
   Use pweight (probability weight) for design-based inference.

   For a full survey-weighted analysis see Module 5 (svyset).
   Here we just show the weighted vs. unweighted difference for key variables.
*/

* Unweighted means
mean age college voted biden_voter

* Weighted means
mean age college voted biden_voter [pweight=wt_post]

di ""
di "Compare weighted vs unweighted means above — differences indicate"
di "that the raw sample over- or under-represents certain groups."


*==============================================================================
* SECTION 9: EXPORT A SUMMARY TABLE (optional)
*==============================================================================

/*
   estout / esttab (from the estout package) can export tables to Word or LaTeX.
   Install with: ssc install estout

   Below is a simple example — see Module 8 (export tables) for the full workflow.
*/

* ssc install estout, replace   /* uncomment to install */

* estpost summarize age education ideology5 imm_restrict econ_retro, detail
* esttab using "table1_descriptives.rtf", cells("mean sd min max") replace

di "Module 2 complete."
