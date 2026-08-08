// =============================================================================
// MODULE 14: MULTILEVEL MODELS (MIXED-EFFECTS REGRESSION)
// CES 2020 Social Science Code Library
// =============================================================================
// Topics covered:
//   1. Survey design declaration (svyset)
//   2. Null / empty model and ICC (intraclass correlation coefficient)
//   3. Manual ICC from variance components
//   4. Random intercept model with level-1 predictors
//   5. Random slope model (ideo5 slope varies by state)
//   6. Cross-level interaction (individual ideology x state mean ideology)
//   7. Model comparison with lrtest (both models refit with ML)
//   8. Extract and display random effects (empirical Bayes estimates)
//   9. Variance components and ICC summary across models
//
// Key variables (numeric codes — no string labels assumed):
//   approval_pres : 1=strongly approve, 2=approve, 3=disapprove,
//                   4=strongly disapprove
//   ideo5         : 1=very liberal ... 5=very conservative
//   educ          : 1=no HS, 2=HS grad, 3=some college, 4=2-yr,
//                   5=4-yr degree, 6=postgrad
//   faminc_new    : 1-16 ordered income brackets
//   gender        : 1=Male, 2=Female
//   race          : 1=White, 2=Black, 3=Hispanic, 4=Asian
//   inputstate    : numeric state FIPS (level-2 clustering unit)
//   commonweight  : cross-sectional survey weight
//
// NOTE: `mixed` (not the deprecated `xtmixed`) is used throughout.
//       Do NOT use xtset for cross-sectional multilevel data.
//       lrtest comparisons use ML (not REML) — see Section 7.
//       Mixed-effects models do not accept pweights; svyset is
//       declared for the survey context but mixed models below
//       are unweighted (standard practice for MLM teaching).
// =============================================================================

version 16
clear all
set more off

use "ces2020.dta", clear

// ces2020.dta uses commonpostweight; create commonweight alias for compatibility
capture drop commonweight
gen commonweight = commonpostweight


// =============================================================================
// SECTION 1: DECLARE SURVEY DESIGN
// =============================================================================
// Use commonweight for survey-weighted descriptives and svy: commands.
// Strata = inputstate (state of residence, FIPS numeric code).
// PSU not identified in public CES; inputstate serves as strata.

svyset [pw=commonweight], strata(inputstate)

// Check variable availability
describe approval_pres ideo5 educ faminc_new gender race inputstate commonweight

// Missing data summary for key variables
foreach v of varlist approval_pres ideo5 educ faminc_new gender race inputstate {
    quietly count if missing(`v')
    display "Missing in `v': " r(N)
}

// Drop observations missing the outcome or key level-2 grouping variable
drop if missing(approval_pres) | missing(inputstate)

// Distribution of outcome
tabulate approval_pres

// Group sizes: how many respondents per state?
bysort inputstate: gen _n_state = _N
quietly tabstat _n_state, by(inputstate) stat(mean) nototal
drop _n_state

// Survey-weighted mean of outcome by party (pid3: 1=Dem, 2=Rep, 3=Ind)
// party_id3 in ces2020.dta; create pid3 alias for compatibility
capture drop pid3
gen pid3 = party_id3
svy: mean approval_pres, over(pid3)


// =============================================================================
// SECTION 2: NULL MODEL (INTERCEPT-ONLY) AND ICC
// =============================================================================
// The null model has NO predictors. It decomposes total variance into:
//   Level-2 (between-state):  var(u_0j)   — state random intercept
//   Level-1 (within-state):   var(e_ij)   — individual residual
//
// Model: approval_pres_ij = gamma_00 + u_0j + e_ij
//
//   gamma_00 = grand mean (fixed intercept)
//   u_0j     = state j's deviation from the grand mean (random intercept)
//   e_ij     = individual i's deviation from their state mean (residual)
//
// Default estimation is REML, which is appropriate for variance components.
// We use REML here (null model has same fixed part as nothing to compare to).

mixed approval_pres || inputstate:

// Intraclass correlation coefficient
// ICC = var(u_0j) / [var(u_0j) + var(e_ij)]
estat icc

// Interpretation guide printed to log:
display _newline "--- ICC INTERPRETATION ---"
display "ICC > 0.05: multilevel modeling is warranted."
display "ICC ~ 0.10: 10% of variance in approval_pres lies BETWEEN states."
display "Remaining variance is within-state individual differences."
display "---"


// =============================================================================
// SECTION 3: MANUAL ICC CALCULATION FROM VARIANCE COMPONENTS
// =============================================================================
// estat icc computes ICC automatically. This section shows the arithmetic.
// After `mixed`, variance estimates are accessible via estat recovariance.

// Extract level-2 variance (random intercept variance for inputstate)
estat recovariance, relevel(inputstate)

// The main mixed output shows:
//   var(_cons) under "inputstate" panel = between-state variance (var_u0)
//   var(Residual)                        = within-state variance  (var_e)
//
// Manual formula (run after saving values from output):
//   scalar var_u0 = [var(_cons) from output]
//   scalar var_e  = [var(Residual) from output]
//   scalar icc    = var_u0 / (var_u0 + var_e)
//   display "Manually computed ICC = " icc
//
// You can also retrieve these from e(b) after mixed; the parameters are stored
// as lns1_1_1 (log of sigma_u) and lnsig_e (log of sigma_e):
//
//   scalar sigma_u = exp(_b[/var(_cons[inputstate])])^.5    // approx
//   scalar sigma_e = exp(_b[/var(Residual)])^.5             // approx
//
// Use estat icc for accuracy; this section illustrates the concept only.


// =============================================================================
// SECTION 4: RANDOM INTERCEPT MODEL WITH LEVEL-1 PREDICTORS
// =============================================================================
// Add individual-level covariates. Each state still has its own intercept
// (u_0j), but ALL slopes are constrained to be the same across states (fixed).
//
// Model:
//   approval_pres_ij = gamma_00
//                    + gamma_10*ideo5_ij
//                    + gamma_20*educ_ij
//                    + gamma_30*faminc_new_ij
//                    + gamma_40*(gender==2)_ij
//                    + gamma_50*(race==2)_ij
//                    + gamma_60*(race==3)_ij
//                    + gamma_70*(race==4)_ij
//                    + u_0j + e_ij
//
// i.gender and i.race treat these as categorical; Stata drops the base
// category (gender==1, race==1) automatically.

mixed approval_pres ideo5 educ faminc_new i.gender i.race ///
    || inputstate:

estimates store ri_reml     // store for later reference

estat icc

// Interpretation: the ICC after adding level-1 predictors is the
// "adjusted ICC" — between-state variance that remains after controlling
// for individual composition. A drop from the null-model ICC suggests
// that states differ partly because their residents differ in ideo5, educ,
// etc. (compositional effect). Residual ICC reflects true contextual
// variation across states.
//
// Proportional reduction in level-2 variance (pseudo-R2 at level 2):
//   PRV_L2 = (var_u0_null - var_u0_ri) / var_u0_null
// Proportional reduction in level-1 residual (pseudo-R2 at level 1):
//   PRV_L1 = (var_e_null  - var_e_ri)  / var_e_null


// =============================================================================
// SECTION 5: RANDOM SLOPE MODEL FOR ideo5
// =============================================================================
// Now allow the SLOPE of ideo5 to vary across states.
//
// Model:
//   approval_pres_ij = gamma_00
//                    + (gamma_10 + u_1j)*ideo5_ij   <- slope varies
//                    + gamma_20*educ_ij
//                    + gamma_30*faminc_new_ij
//                    + gamma_40*(gender==2)_ij
//                    + gamma_50*(race==2)_ij
//                    + gamma_60*(race==3)_ij
//                    + gamma_70*(race==4)_ij
//                    + u_0j + e_ij
//
// u_1j = state j's deviation from the grand slope of ideo5.
//
// covariance(unstructured): freely estimates var(u_0j), var(u_1j),
// and cov(u_0j, u_1j). A positive covariance means states with higher
// baseline disapproval also show a steeper ideology-approval gradient.
//
// Default estimation: REML (appropriate for variance components here).

mixed approval_pres ideo5 educ faminc_new i.gender i.race ///
    || inputstate: ideo5, covariance(unstructured)

estimates store rs_reml

estat icc
// Note: with random slopes, estat icc reports the median ICC and a
// range, because ICC varies by the value of ideo5 across observations.

// View the 3-element random-effects covariance matrix:
estat recovariance, relevel(inputstate)


// =============================================================================
// SECTION 6: CROSS-LEVEL INTERACTION
// =============================================================================
// A cross-level interaction tests whether a LEVEL-2 variable moderates
// a LEVEL-1 slope.
//
// Example: does the ideology-approval slope differ in states where
// residents are on average more conservative?
//
// Step 1: Create state-level mean ideology (level-2 covariate).
//         This proxies for the political climate of the state.
//         It is derived from the CES sample itself — no external merge needed.

bysort inputstate: egen state_mean_ideo = mean(ideo5)
label variable state_mean_ideo "State mean ideology (L2 covariate)"

// Step 2: Group-mean center ideo5 around state mean.
//         This separates within-state (L1) from between-state (L2) effects,
//         which is recommended when the same variable appears at both levels.

gen ideo5_cwc = ideo5 - state_mean_ideo
label variable ideo5_cwc "ideo5 group-mean centered (within-state deviation)"

// Step 3: Grand-mean center the level-2 variable for interpretability.
//         The intercept then refers to the average state, not a state
//         with zero mean ideology.

quietly summarize state_mean_ideo
gen state_ideo_gmc = state_mean_ideo - r(mean)
label variable state_ideo_gmc "State mean ideology, grand-mean centered"

// Step 4: Cross-level interaction model.
//         ideo5_cwc (L1) x state_ideo_gmc (L2).
//         state_ideo_gmc must appear as a main effect (required for interaction).
//         The random slope is now on ideo5_cwc (the within-state component).

mixed approval_pres ideo5_cwc state_ideo_gmc c.ideo5_cwc#c.state_ideo_gmc ///
    educ faminc_new i.gender i.race ///
    || inputstate: ideo5_cwc, covariance(unstructured)

estimates store cli_reml

// Interpreting the cross-level interaction coefficient:
//   c.ideo5_cwc#c.state_ideo_gmc answers:
//   "In states that are more conservative than average (positive state_ideo_gmc),
//   is the within-state ideology-approval slope steeper or flatter?"
//
//   Positive coefficient: the ideology gradient is steeper in conservative states.
//   Negative coefficient: the ideology gradient is attenuated in conservative states.
//
// Plot predicted values with margins to visualize:

margins, at(ideo5_cwc=(-2 -1 0 1 2) state_ideo_gmc=(-1 0 1)) ///
    predict(xb) noestimcheck
marginsplot, x(ideo5_cwc) by(state_ideo_gmc) ///
    title("Cross-Level Interaction: Ideology x State Ideology") ///
    xtitle("Individual Ideology (group-mean centered)") ///
    ytitle("Predicted Presidential Disapproval")


// =============================================================================
// SECTION 7: MODEL COMPARISON WITH lrtest (ML NOT REML)
// =============================================================================
// CRITICAL REQUIREMENT: lrtest requires ML estimation.
// REML log-likelihoods are NOT comparable across models with different
// fixed effects (or across nested random-effects structures when fixed
// effects differ). Always refit both models with `ml` before lrtest.
//
// We compare:
//   Model A (ri_ml):  random intercept only
//   Model B (rs_ml):  random intercept + random slope for ideo5
//
// H0: adding var(u_1j) and cov(u_0j, u_1j) does not improve fit.
// A significant LR test (p < .05) favors the random-slope model.

// Refit Model A with ML
mixed approval_pres ideo5 educ faminc_new i.gender i.race ///
    || inputstate:, ml
estimates store ri_ml

// Refit Model B with ML
mixed approval_pres ideo5 educ faminc_new i.gender i.race ///
    || inputstate: ideo5, covariance(unstructured) ml
estimates store rs_ml

// Likelihood ratio test
capture noisily lrtest ri_ml rs_ml

// Output explained:
//   LR chi2(df): Model B adds 2 parameters (var(u_1j), cov(u_0j,u_1j)).
//                df = 2.
//   Prob > chi2: p-value. Significant = random slope improves fit.
//
// Boundary correction note:
//   Because variance components are bounded at zero, the true null distribution
//   is a 50:50 mixture of chi2(1) and chi2(2). Some textbooks recommend
//   halving the p-value Stata reports as a conservative correction.
//   For df=2, the standard chi2(2) p-value is commonly used and is slightly
//   conservative, which is acceptable for teaching purposes.

// Also compare random intercept vs. cross-level interaction model:
mixed approval_pres ideo5_cwc state_ideo_gmc c.ideo5_cwc#c.state_ideo_gmc ///
    educ faminc_new i.gender i.race ///
    || inputstate: ideo5_cwc, covariance(unstructured) ml
estimates store cli_ml

capture noisily lrtest ri_ml cli_ml
// Note: lrtest requires nested models; if models are not nested this is skipped.


// =============================================================================
// SECTION 8: EXTRACT AND DISPLAY RANDOM EFFECTS
// =============================================================================
// After fitting the preferred model, predict empirical Bayes (EB) estimates
// of u_0j (random intercept) and u_1j (random slope) for each state.
//
// These are "shrinkage" estimates — states with fewer respondents are pulled
// more strongly toward zero (the grand mean deviation). States with many
// respondents receive estimates closer to their raw group-specific values.
//
// `predict, reffects` gives the posterior means (EB/BLUP estimates).
// `predict, reses`    gives the posterior standard errors.

// Refit the preferred model (random slope, ML) for prediction
mixed approval_pres ideo5 educ faminc_new i.gender i.race ///
    || inputstate: ideo5, covariance(unstructured) ml

// Predict random effects (one value per observation, constant within state)
predict re_u0 re_u1, reffects

// Predict posterior standard errors
predict re_se_u0 re_se_u1, reses

label variable re_u0    "Random intercept: state deviation from grand mean"
label variable re_u1    "Random slope: state deviation from grand ideo5 slope"
label variable re_se_u0 "Posterior SE of random intercept"
label variable re_se_u1 "Posterior SE of random slope"

// Display state-level random effects (one row per state)
// Use egen tag to keep one observation per state
egen state_tag = tag(inputstate)

list inputstate re_u0 re_u1 re_se_u0 re_se_u1 if state_tag == 1, ///
    separator(5) noobs

// Caterpillar plot of random intercepts with 95% credible intervals:
// (Sort states by random intercept, then plot with CI bands)
// Sort by re_u0 (at state level)
sort re_u0

gen ci_lo = re_u0 - 1.96 * re_se_u0
gen ci_hi = re_u0 + 1.96 * re_se_u0

// Create a state rank variable for plotting
gen state_rank = .
replace state_rank = _n if state_tag == 1

twoway (rcap ci_lo ci_hi state_rank if state_tag == 1, lcolor(gs10)) ///
       (scatter re_u0 state_rank if state_tag == 1, ///
           mcolor(navy) msymbol(circle) msize(small)), ///
    yline(0, lpattern(dash) lcolor(red)) ///
    title("Caterpillar Plot: State Random Intercepts") ///
    subtitle("Random intercept (u_0j) with 95% credible intervals") ///
    ytitle("Deviation from grand mean (u_0j)") ///
    xtitle("States ranked by random intercept") ///
    legend(off)

drop ci_lo ci_hi state_rank state_tag


// =============================================================================
// SECTION 9: VARIANCE COMPONENTS AND ICC SUMMARY ACROSS MODELS
// =============================================================================
// Best practice: report ICC and variance components for all models together.
// Run models sequentially and call estat icc after each.

display _newline(2) as text "============================================================"
display as text "VARIANCE COMPONENTS SUMMARY (REML estimates)"
display as text "============================================================"

// Null model
display _newline as text "-- MODEL 1: NULL (intercept-only) --"
mixed approval_pres || inputstate:
estat icc

// Random intercept model
display _newline as text "-- MODEL 2: RANDOM INTERCEPT (L1 predictors added) --"
mixed approval_pres ideo5 educ faminc_new i.gender i.race ///
    || inputstate:
estat icc

// Random slope model
display _newline as text "-- MODEL 3: RANDOM SLOPE (ideo5 varies by state) --"
mixed approval_pres ideo5 educ faminc_new i.gender i.race ///
    || inputstate: ideo5, covariance(unstructured)
estat icc

// Cross-level interaction model
display _newline as text "-- MODEL 4: CROSS-LEVEL INTERACTION (L1 ideo5_cwc x L2 state_ideo_gmc) --"
mixed approval_pres ideo5_cwc state_ideo_gmc c.ideo5_cwc#c.state_ideo_gmc ///
    educ faminc_new i.gender i.race ///
    || inputstate: ideo5_cwc, covariance(unstructured)
estat icc

display _newline(2) as text "============================================================"
display as text "ICC INTERPRETATION GUIDE:"
display as text "  Null model ICC    = total between-state variance (unconditional)"
display as text "  RI model ICC      = between-state variance net of L1 composition"
display as text "  RS model ICC      = median ICC (varies with ideo5; see range)"
display as text ""
display as text "  Proportional reduction in L2 variance (from null to RI):"
display as text "    PRV_L2 = (var_u0_null - var_u0_ri) / var_u0_null"
display as text "  Proportional reduction in L1 residual (from null to RI):"
display as text "    PRV_L1 = (var_e_null  - var_e_ri)  / var_e_null"
display as text "============================================================"

display _newline as result "MODULE 14 COMPLETE."
