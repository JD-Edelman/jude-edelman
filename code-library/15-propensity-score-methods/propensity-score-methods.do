// =============================================================================
// MODULE 15: PROPENSITY SCORE METHODS
// CES 2020 Social Science Code Library
// =============================================================================
// Topics covered:
//   - Estimating propensity scores via logistic regression
//   - Assessing overlap / common support
//   - Nearest-neighbor matching (teffects psmatch)
//   - Inverse probability of treatment weighting (IPTW) for ATE and ATT
//   - Balance diagnostics via standardized mean differences (SMD)
//   - Weighted outcome analysis
//
// CES 2020 data note:
//   Stata cannot read .parquet files natively. Convert the CES 2020 data in
//   R or Python and export as .dta before running this do file. See
//   propensity-score-methods.R or propensity-score-methods.py.
//
// Unconfoundedness assumption:
//   All methods below assume no unmeasured confounders given the covariates
//   included in the propensity score model. This is an untestable assumption;
//   assess sensitivity with Rosenbaum bounds or an E-value after analysis.
// =============================================================================

// --- SECTION 1: ESTIMATE PROPENSITY SCORES (logit) ---
// logit treatment_var covariate1 covariate2 covariate3 ...
// predict pscore, pr
// label variable pscore "Estimated propensity score"
// summarize pscore if treatment_var==1
// summarize pscore if treatment_var==0

// --- SECTION 2: COMMON SUPPORT AND OVERLAP ---
// twoway (kdensity pscore if treatment_var==1) ///
//        (kdensity pscore if treatment_var==0), ///
//        legend(label(1 "Treated") label(2 "Control")) ///
//        title("Propensity score distributions by treatment status")
// Drop units outside common support region
// drop if pscore < [min treated] | pscore > [max control]

// --- SECTION 3: NEAREST-NEIGHBOR MATCHING ---
// teffects psmatch (outcome_var) (treatment_var covariate1 covariate2 ...), ///
//          atet nn(1) generate(matched_weight)
// Alternatively: psmatch2 (requires installation: ssc install psmatch2)
// tebalance summarize    // covariate balance after matching

// --- SECTION 4: IPTW WEIGHTS ---
// ATE weights:   w_i = D_i/pscore + (1-D_i)/(1-pscore)
// ATT weights:   w_i = D_i + (1-D_i)*pscore/(1-pscore)
// generate ate_weight = treatment_var/pscore + (1-treatment_var)/(1-pscore)
// generate att_weight = treatment_var + (1-treatment_var)*pscore/(1-pscore)
// Trim extreme weights (e.g., cap at 99th percentile) and document decision

// --- SECTION 5: BALANCE DIAGNOSTICS (standardized differences) ---
// ssc install stddiff   // if not installed
// stddiff covariate1 covariate2 ..., by(treatment_var)   // pre-weighting
// svyset [pw=att_weight]
// svy: mean covariate1 covariate2 ..., over(treatment_var)  // post-weighting means
// Compute SMD post-weighting; target |SMD| < 0.10

// --- SECTION 6: OUTCOME ANALYSIS ---
// Unweighted (naive) comparison
// regress outcome_var treatment_var covariate1 covariate2
// IPTW-weighted (ATE)
// svyset [pw=ate_weight]
// svy: regress outcome_var treatment_var
// IPTW-weighted (ATT)
// svyset [pw=att_weight]
// svy: regress outcome_var treatment_var
// Doubly robust: include covariates in weighted regression as additional protection
