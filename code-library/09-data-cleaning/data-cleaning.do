/*==============================================================================
   MODULE 9: DATA CLEANING & VALIDATION
   Dataset: CES 2020 Common Content (cleaned from Module 1)

   Purpose: Demonstrate systematic data cleaning workflows — detecting and
   handling missing data, outliers, inconsistent responses, duplicates,
   and string-to-numeric conversions. These steps should run BEFORE
   any analysis.

   Rule of thumb: clean once, save a clean file, load that clean file
   in every analysis script. Never clean in the same script as analysis.
==============================================================================*/

clear all
set more off

* Load the cleaned dataset from Module 1
use "CES2020_clean.dta", clear


*==============================================================================
* SECTION 1: INITIAL AUDIT — WHAT DO YOU HAVE?
*==============================================================================

/*
   Before touching data, document its structure.
   describe shows variable types, labels, and storage formats.
   codebook gives a full univariate summary of every variable.
*/

describe
di "Observations: `=_N'   Variables: `=c(k)'"

* codebook for selected key variables
codebook age sex education ideology5 voted biden_voter imm_restrict

/*
   codebook flags:
   - Variables with unique values equal to N (likely ID, not a category)
   - Variables that are string when they should be numeric
   - Variables with many missing values
*/


*==============================================================================
* SECTION 2: MISSING DATA AUDIT
*==============================================================================

/*
   Never assume you know which variables have missing data — check every one.
   misstable summarize lists all variables with any missing.
*/

misstable summarize

/*
   misstable patterns shows combinations of missing across variables —
   useful for understanding whether missingness is correlated.
*/
misstable patterns age education ideology5 imm_restrict voted biden_voter, ///
    frequency

/*
   Manual check for each key variable:
*/
foreach var in age education ideology5 party_id3 imm_restrict ///
               voted biden_voter white_nh college {
    quietly count if missing(`var')
    local pct = round(`r(N)'/_N * 100, .1)
    di "Missing on `var': `r(N)' (`pct'%)"
}


*==============================================================================
* SECTION 3: LOGICAL CONSISTENCY CHECKS
*==============================================================================

/*
   Check for responses that are internally contradictory or impossible.
   These often indicate data entry errors or coding mistakes.
*/

* Age implausibility: anyone under 18 or over 110?
count if age < 18 & !missing(age)
count if age > 110 & !missing(age)

* Did someone report voting Biden but also say they didn't vote?
count if biden_voter != . & voted == 0
/*
   Expected: 0. biden_voter is defined only among voters.
   If any cases here, there's an inconsistency in the recode logic.
*/

* Did someone say they voted (voted==1) but have a missing pres_vote?
count if voted == 1 & missing(biden_voter) & missing(pres_vote)
/*
   Expected: some cases — people who voted but chose a third-party candidate
   or skipped the vote question. Investigate those codes.
*/

* Party ID check: nobody should be "Strong Republican" on pid7 but "Democrat" on pid3
count if party_id7 == 7 & party_id3 == 1   /* Strong Rep but coded as Dem */
count if party_id7 == 1 & party_id3 == 2   /* Strong Dem but coded as Rep */

* Education check: college==1 requires education >= 5
count if college == 1 & education < 5 & !missing(education)
count if college == 0 & education >= 5 & !missing(education)
/*
   Both should be 0 — if not, the college recode in Module 1 has a bug.
*/

* Race check: white_nh==1 requires race_eth==1 and hispanic_id==2
count if white_nh == 1 & (race_eth != 1 | hispanic_id != 2)


*==============================================================================
* SECTION 4: CHECKING FOR DUPLICATE IDs
*==============================================================================

/*
   In cross-sectional survey data, each respondent (caseid) should appear once.
   Duplicates indicate a merge error or a problem with the source data.
*/

duplicates report caseid

duplicates list caseid if _n <= 20   /* show a few if any */

* Tag duplicates for inspection
duplicates tag caseid, gen(is_dup)

count if is_dup > 0
di "Duplicate caseids found: `r(N)'"

* If duplicates exist, investigate before dropping
* list caseid if is_dup > 0

drop is_dup


*==============================================================================
* SECTION 5: OUTLIER DETECTION — CONTINUOUS VARIABLES
*==============================================================================

/*
   Outliers in survey data usually mean miscodes rather than genuine extreme
   values. Check using z-scores and visual inspection.

   The standard rule of thumb: |z| > 3 flags potential outliers.
   But for large samples (N > 60,000), |z| > 4 or |z| > 5 is more appropriate.
*/

* Z-score approach for age
quietly summarize age
gen z_age = (age - r(mean)) / r(sd)
count if abs(z_age) > 4 & !missing(z_age)
list age z_age if abs(z_age) > 4 & !missing(z_age) in 1/20
drop z_age

/*
   In CES, extreme ages are usually valid (very old respondents).
   Always inspect rather than auto-delete.
*/

* IQR approach (less sensitive to extreme values than mean/SD)
quietly summarize age, detail
scalar iqr_age = r(p75) - r(p25)
scalar lo_age  = r(p25) - 3 * iqr_age
scalar hi_age  = r(p75) + 3 * iqr_age

count if (age < lo_age | age > hi_age) & !missing(age)
di "Age outliers by IQR method: `r(N)'"


*==============================================================================
* SECTION 6: HANDLING MISSING DATA — STRATEGIES
*==============================================================================

/*
   Three common approaches:

   1. LISTWISE DELETION (default in Stata's regression)
      - Drop observations with missing on any analysis variable
      - Fast and simple; valid if data are MCAR (missing completely at random)
      - Problem: can produce biased estimates if data are MAR or MNAR
      - Stata does this automatically — just check your model N

   2. MEAN/MEDIAN IMPUTATION (simple, not recommended for inference)
      - Replace missing with mean/median of observed values
      - Underestimates variance; not valid for most inferential uses
      - Only use for single-item scale components, never for outcome Y

   3. MULTIPLE IMPUTATION (gold standard for missing covariates)
      - See Module 10 (multiple imputation)
      - Use for any variable with > 5% missing that will be in a model
*/

* --- Approach 2 example: mean imputation for a control variable ---
* (Demonstrating the mechanics, not recommending this for publication)
quietly summarize ideology5
scalar mean_ideo = r(mean)

gen ideology5_imp = ideology5
replace ideology5_imp = mean_ideo if missing(ideology5)

count if missing(ideology5_imp)   /* should be 0 */
di "ideology5_imp: mean imputed for `=round(scalar(mean_ideo), .01)'"

drop ideology5_imp   /* clean up demonstration variable */


*==============================================================================
* SECTION 7: RECODING STRING VARIABLES TO NUMERIC
*==============================================================================

/*
   Sometimes a variable that should be numeric is stored as a string
   because of non-numeric entries (e.g., "." or "N/A" instead of a blank).

   destring converts a string to numeric, with force option
   dropping non-numeric characters.

   encode converts a string categorical to a Stata labeled numeric.
*/

* Demonstrate with a simulated string variable
gen str_age = string(age)
replace str_age = "missing" in 1/100   /* simulate some bad entries */

* Check: is it a string?
describe str_age   /* type = str# */

* Convert — values that can't convert become missing with force
destring str_age, gen(age_numeric) force

* Check: how many became missing?
count if missing(age_numeric)

drop str_age age_numeric

/*
   encode example: if you had a string variable like state names
   encode state_name, gen(state_code)
   This creates a numeric variable with value labels = the original strings.
*/


*==============================================================================
* SECTION 8: STANDARDIZING VARIABLES
*==============================================================================

/*
   Standardization (z-scoring) puts variables on the same scale.
   Useful for:
   - Comparing effect sizes in OLS (standardized β)
   - Regularization in machine learning
   - Making interaction terms more interpretable

   Syntax: egen newvar = std(oldvar)
*/

foreach var in age education ideology5 imm_restrict econ_retro {
    egen z_`var' = std(`var')
    label variable z_`var' "Standardized `var' (mean=0, SD=1)"
}

summarize z_age z_education z_ideology5 z_imm_restrict z_econ_retro

* Example: regression with standardized predictors
regress z_imm_restrict z_education z_age z_ideology5 i.sex, vce(robust)

/*
   Now all coefficients are in SD units — directly comparable in magnitude.
   This is essentially reporting standardized beta weights.
*/

drop z_age z_education z_ideology5 z_imm_restrict z_econ_retro


*==============================================================================
* SECTION 9: CREATING CATEGORICAL VARIABLES FROM CONTINUOUS
*==============================================================================

/*
   Cut a continuous variable into meaningful categories using:
     xtile  = percentile-based (equal-size groups)
     irecode / recode = custom cut points
     egen cut() = flexible binning
*/

* Age quartiles
xtile age_quartile = age, nq(4)
label variable age_quartile "Age quartile (1=youngest 25%, 4=oldest 25%)"
tab age_quartile

* Age groups with meaningful substantive meaning
recode age ///
    (18/29 = 1 "18-29") ///
    (30/44 = 2 "30-44") ///
    (45/59 = 3 "45-59") ///
    (60/max = 4 "60+"), ///
    gen(age_group)
label variable age_group "Age group"
tab age_group

* Ideology collapsed to 3 groups
recode ideology5 ///
    (1/2 = 1 "Liberal") ///
    (3   = 2 "Moderate") ///
    (4/5 = 3 "Conservative") ///
    if !missing(ideology5), ///
    gen(ideology3)
label variable ideology3 "Ideology 3-category"
tab ideology3


*==============================================================================
* SECTION 10: ADDING VARIABLE LABELS SYSTEMATICALLY
*==============================================================================

/*
   A clean dataset has labels on every variable and clear value labels on
   every categorical variable. Do this before saving.
*/

* Variable labels (in case they were dropped from Module 1)
label variable age             "Age as of 2020 election"
label variable sex             "Sex (1=Male, 2=Female)"
label variable education       "Education level (1=No HS, 6=Postgrad)"
label variable ideology5       "Self-reported ideology (1=Very Liberal, 5=Very Conservative)"
label variable party_id3       "Party identification (3 category)"
label variable party_id7       "Party identification (7 category)"
label variable imm_restrict    "Immigration restrictionism index (0-5)"
label variable voted           "Voted in 2020 (1=Yes)"
label variable biden_voter     "Voted Biden (1=Yes, 0=Trump)"
label variable college         "College degree or higher (1=Yes)"
label variable white_nh        "White non-Hispanic (1=Yes)"
label variable dem             "Democrat (1=Yes)"
label variable rep             "Republican (1=Yes)"
label variable econ_retro      "Retrospective national economy (1=Much better)"
label variable wt_post         "Post-election survey weight"

* Save cleaned, labeled dataset
save "CES2020_analysis_ready.dta", replace

di "Module 9 complete. Analysis-ready dataset saved."
