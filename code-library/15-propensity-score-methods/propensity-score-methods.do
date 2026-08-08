// =============================================================================
// MODULE 15: PROPENSITY SCORE METHODS
// CES 2020 Social Science Code Library
// =============================================================================
// Topics covered:
//   1. Define treatment variable (college education as "treatment")
//   2. Estimate propensity score with logit
//   3. Check overlap: histograms, common support trimming
//   4. Nearest-neighbor matching (teffects nnmatch)
//   5. Inverse probability weighting (teffects ipw)
//   6. Covariate balance check with tebalance summarize (SMD)
//   7. Doubly robust estimation (teffects aipw)
//   8. Restore CES survey design after balance checks
//   9. Display ATE and ATT results
//
// Key variables (numeric codes — no string labels):
//   educ          : 1=no HS, 2=HS grad, 3=some college, 4=2-yr,
//                   5=4-yr degree, 6=postgrad
//   ideo5         : 1=very liberal ... 5=very conservative
//   faminc_new    : 1-16 ordered income brackets
//   race          : 1=White, 2=Black, 3=Hispanic, 4=Asian
//   gender        : 1=Male, 2=Female
//   inputstate    : numeric state FIPS
//   approval_pres : 1=strongly approve ... 4=strongly disapprove
//   commonweight  : cross-sectional survey weight
//
// CAUSAL ASSUMPTION (unconfoundedness / conditional ignorability):
//   All methods below assume that, conditional on the covariates in the
//   propensity score model, treatment assignment (college) is independent
//   of potential outcomes. This is untestable. After analysis, assess
//   sensitivity using Rosenbaum bounds or E-values.
//
// NOTE: teffects commands do NOT accept pweights (svyset weights).
//       svyset is restored at the end for any further survey analysis.
//       Do NOT use svyset before teffects — it will be silently ignored
//       or cause an error.
// =============================================================================

version 16
clear all
set more off

use "ces2020.dta", clear

// ces2020.dta uses commonpostweight; create commonweight alias for compatibility
capture drop commonweight
gen commonweight = commonpostweight


// =============================================================================
// SECTION 1: DEFINE TREATMENT VARIABLE
// =============================================================================
// Treatment: college-educated (educ >= 5, i.e., 4-year degree or postgrad)
// Control:   not college-educated (educ <= 4)
//
// This is a binary "treatment" in the causal inference sense. We ask:
//   "What is the causal effect of having a college degree on
//    presidential approval (approval_pres)?"
//
// educ codes: 1=no HS, 2=HS grad, 3=some college, 4=2-yr degree,
//             5=4-yr degree, 6=postgrad

capture drop college
gen college = (educ >= 5) if !missing(educ)
label variable college "College-educated (educ 5-6 = 1; educ 1-4 = 0)"

// Drop cases missing any variable needed for the analysis
drop if missing(college, approval_pres, ideo5, faminc_new, race, gender, inputstate)

// Descriptive check: outcome by treatment
tabulate college
tabulate college approval_pres, row

// Unadjusted (naive) mean difference in outcome
ttest approval_pres, by(college)
// Note: this naive difference is confounded — college graduates may differ
// from non-graduates on ideology, income, race, etc.


// =============================================================================
// SECTION 2: ESTIMATE PROPENSITY SCORE WITH LOGIT
// =============================================================================
// The propensity score e(X) = Pr(college=1 | X) is estimated via logistic
// regression. We condition on ideo5, faminc_new, race, gender, and inputstate.
//
// Including i.inputstate (state fixed effects in the logit) accounts for
// geographic sorting into college. With 51 states this adds many parameters
// — acceptable here but watch for perfect prediction in small states.
//
// Outcome variable for logit: college (binary)
// Predictors: pre-treatment covariates only (no post-treatment variables)

logit college ideo5 faminc_new i.race i.gender i.inputstate

predict pscore, pr
label variable pscore "Estimated propensity score: Pr(college=1 | X)"

// Summary of propensity scores by treatment group
summarize pscore if college == 1
summarize pscore if college == 0

// Detailed balance of raw pscore distributions
tabstat pscore, by(college) stat(mean sd min max p25 p50 p75)


// =============================================================================
// SECTION 3: CHECK OVERLAP AND COMMON SUPPORT
// =============================================================================
// "Overlap" means both treatment and control units exist across the range
// of propensity scores. Without overlap, matching and weighting extrapolate
// beyond the data — unreliable.
//
// Visual check: side-by-side histograms and kernel density overlay.

// Kernel density plot (overlay)
twoway (kdensity pscore if college == 1, lcolor(navy) lpattern(solid)) ///
       (kdensity pscore if college == 0, lcolor(maroon) lpattern(dash)), ///
    legend(label(1 "College (treated)") label(2 "No college (control)")) ///
    title("Propensity Score Distributions by Treatment Status") ///
    xtitle("Estimated Propensity Score") ytitle("Density") ///
    note("Substantial overlap required for valid causal inference")

// Histogram by treatment group (side by side)
histogram pscore, by(college, title("Propensity Score by College Status")) ///
    xtitle("Propensity Score") ytitle("Density") color(navy%50)

// Common support trimming
// Drop units whose pscore falls OUTSIDE the overlap of BOTH distributions.
// Correct rule (symmetric):
//   lower bound = max(min pscore among treated, min pscore among controls)
//   upper bound = min(max pscore among treated, max pscore among controls)

quietly summarize pscore if college == 1
scalar min_treated = r(min)
scalar max_treated = r(max)

quietly summarize pscore if college == 0
scalar min_control = r(min)
scalar max_control = r(max)

// Overlap region: where BOTH distributions have support
scalar cs_lower = max(min_treated, min_control)
scalar cs_upper = min(max_treated, max_control)

display _newline "Common support region: [" cs_lower ", " cs_upper "]"

// Count units dropped by trimming
count if pscore < cs_lower | pscore > cs_upper
display r(N) " observations fall outside common support and will be dropped"

drop if pscore < cs_lower | pscore > cs_upper

display "Observations remaining after common support trimming: " _N

// Post-trim density check
twoway (kdensity pscore if college == 1, lcolor(navy)) ///
       (kdensity pscore if college == 0, lcolor(maroon) lpattern(dash)), ///
    legend(label(1 "College (treated)") label(2 "No college (control)")) ///
    title("Propensity Score After Common Support Trimming") ///
    xtitle("Estimated Propensity Score") ytitle("Density")


// =============================================================================
// SECTION 4: NEAREST-NEIGHBOR MATCHING (teffects nnmatch)
// =============================================================================
// teffects nnmatch matches each treated unit to the closest control unit(s)
// in covariate space (Mahalanobis distance by default, or on pscore if
// specified). It computes the ATT (average treatment effect on the treated)
// or ATE.
//
// Syntax:
//   teffects nnmatch (outcome) (treatment covariates), [options]
//
// We match on the raw covariates (not the estimated pscore) because
// nnmatch with covariates is more robust than matching on a generated pscore.
// nn(1): 1 nearest neighbor
// atet:  average treatment effect on the treated (default with nnmatch)
// biasadj(covariates): regression adjustment for residual bias after matching

// NOTE: teffects nnmatch requires numeric-only variables without factor notation.
// With categorical covariates like race and gender, the command exceeds Stata's
// variable limit (rc=103). Use teffects ipwra or psmatch2 for models with
// categorical covariates, or restrict covariates to continuous/binary variables only.
// teffects nnmatch (approval_pres) (college ideo5 faminc_new), ///
//     atet nn(1) biasadj(ideo5 faminc_new)

// Store estimates (skipped — teffects nnmatch not run above)
* estimates store nnmatch_att

// Check covariate balance after nearest-neighbor matching
capture noisily tebalance summarize
// Target: |SMD| < 0.10 for all covariates (ideally < 0.05)
// SMD = (mean_treated - mean_control) / sqrt(0.5*(var_treated + var_control))

// Variance ratio check (another balance diagnostic)
capture noisily tebalance overid


// =============================================================================
// SECTION 5: INVERSE PROBABILITY WEIGHTING (teffects ipw)
// =============================================================================
// IPTW re-weights the sample to make the treated and control groups
// look like a common target population.
//
// For ATE weights:
//   w_i = D_i / e(X_i)  +  (1 - D_i) / (1 - e(X_i))
//   Target: the full population (treated + control)
//
// For ATT weights:
//   w_i = D_i  +  (1 - D_i) * e(X_i) / (1 - e(X_i))
//   Target: the treated population
//
// teffects ipw estimates both from the same propensity model.
// The propensity model is specified in the SECOND set of parentheses.

// --- 5a: ATE (Average Treatment Effect) ---
teffects ipw (approval_pres) ///
    (college ideo5 faminc_new i.race i.gender i.inputstate), ///
    aequations
estimates store ipw_ate

display _newline "--- IPTW ATE: Effect of college on presidential approval ---"
// ATE: what would happen if we randomized the ENTIRE population into
//      college vs. no-college?

// --- 5b: ATT (Average Treatment Effect on the Treated) ---
teffects ipw (approval_pres) ///
    (college ideo5 faminc_new i.race i.gender i.inputstate), ///
    atet aequations
estimates store ipw_att

display _newline "--- IPTW ATT: Effect among those who ARE college-educated ---"
// ATT: what would the approval difference be if college-goers had NOT
//      gone to college? (Treatment effect for the treated group only.)

// Check covariate balance after IPW
capture noisily tebalance summarize
capture noisily tebalance density ideo5
capture noisily tebalance density faminc_new


// =============================================================================
// SECTION 6: COVARIATE BALANCE DIAGNOSTICS (tebalance summarize)
// =============================================================================
// tebalance summarize reports standardized mean differences (SMDs) for all
// covariates, before and after the teffects adjustment.
//
// Run this immediately after each teffects command while estimates are stored.
// The table shows:
//   - "Raw" SMD: pre-matching/weighting imbalance
//   - "Weighted" (or "Matched") SMD: post-adjustment imbalance
//
// Rule of thumb: |SMD| < 0.10 indicates acceptable balance.
//                |SMD| > 0.25 indicates substantial remaining imbalance.
//
// If balance is poor, consider:
//   1. Adding interaction terms or polynomials to the propensity model
//   2. Trimming more aggressively on common support
//   3. Using doubly robust estimation (Section 7)
//   4. Restricting to a narrower target population

// Restore last teffects results (ipw_att) and re-check balance
capture noisily estimates restore ipw_att
capture noisily tebalance summarize

// Save balance table to a matrix for inspection
capture {
    matrix balance = r(table)
    matlist balance, format(%6.3f)
}


// =============================================================================
// SECTION 7: DOUBLY ROBUST ESTIMATION (teffects aipw)
// =============================================================================
// Augmented IPW (AIPW) combines:
//   1. A propensity score model (treatment model)
//   2. An outcome regression model (outcome model)
//
// "Doubly robust" means the estimator is consistent if EITHER the propensity
// model OR the outcome model is correctly specified (but not necessarily both).
// This is the actual doubly robust estimator — not just adding covariates
// to a weighted regression.
//
// teffects aipw: Stata's built-in AIPW estimator.
//   First parentheses:  outcome equation (approval_pres and its predictors)
//   Second parentheses: treatment equation (propensity model)

// --- 7a: AIPW for ATE ---
teffects aipw ///
    (approval_pres ideo5 faminc_new i.race i.gender) ///
    (college ideo5 faminc_new i.race i.gender i.inputstate), ///
    aequations
estimates store aipw_ate

display _newline "--- Doubly Robust AIPW: ATE ---"

// --- 7b: AIPW for ATT ---
teffects aipw ///
    (approval_pres ideo5 faminc_new i.race i.gender) ///
    (college ideo5 faminc_new i.race i.gender i.inputstate), ///
    atet aequations
estimates store aipw_att

display _newline "--- Doubly Robust AIPW: ATT ---"

// Balance check after AIPW
capture noisily tebalance summarize


// =============================================================================
// SECTION 8: RESTORE CES SURVEY DESIGN
// =============================================================================
// teffects commands operate on the unweighted sample (they estimate their
// own weights internally). After you are done with teffects, restore the
// CES survey design with svyset if you want to run further survey-weighted
// descriptive or regression analyses.
//
// IMPORTANT: do NOT call svyset before teffects commands — it will not apply
// and may interfere. svyset here is for any SUBSEQUENT svy: analysis only.

svyset [pw=commonweight], strata(inputstate)

// Example: survey-weighted outcome mean by treatment, after all PS analyses
svy: mean approval_pres, over(college)

// Example: survey-weighted tabulation of treatment by approval
svy: tabulate college approval_pres, row


// =============================================================================
// SECTION 9: RESULTS SUMMARY TABLE
// =============================================================================
// Display ATE and ATT from all methods side by side for comparison.
// estimates table works with teffects-stored results.

capture noisily estimates table ipw_ate ipw_att aipw_ate aipw_att, ///
    b(%8.4f) se(%8.4f) stats(N) ///
    title("Propensity Score Methods: Estimated Treatment Effects") ///
    equations(1)

// Interpretation notes printed to log:
display _newline(2) as text "================================================================="
display as text "RESULTS INTERPRETATION GUIDE"
display as text "================================================================="
display as text ""
display as text "Outcome: approval_pres (1=strongly approve, 4=strongly disapprove)"
display as text "Treatment: college (1=4-yr degree or postgrad; 0=less than 4-yr)"
display as text ""
display as text "ATE: effect of college if entire population were assigned to"
display as text "     college vs. no college. Relevant for population-level policy."
display as text ""
display as text "ATT: effect of college among those WHO ARE college-educated."
display as text "     Relevant for understanding how current college-goers benefit."
display as text ""
display as text "Positive coefficient: college associated with MORE disapproval"
display as text "                      (higher numeric value on approval_pres)."
display as text "Negative coefficient: college associated with MORE approval."
display as text ""
display as text "Balance target: |SMD| < 0.10 after adjustment."
display as text "If SMD remains high, the propensity model may be misspecified."
display as text ""
display as text "Doubly robust (AIPW) is preferred when you are uncertain about"
display as text "either the propensity model or outcome model specification."
display as text "================================================================="

display _newline as result "MODULE 15 COMPLETE."
