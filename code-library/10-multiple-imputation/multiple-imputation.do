/*==============================================================================
   MODULE 10: MULTIPLE IMPUTATION (MI)
   Dataset: CES 2020 Common Content (cleaned from Module 1)

   Purpose: Handle missing covariate data properly using Stata's mi suite.
   Multiple imputation (MI) is the preferred method when > 5% of a key
   variable is missing, under Missing At Random (MAR) assumption.

   How MI works:
     1. Impute: fill in missing values m times, creating m complete datasets
     2. Analyze: run your model on each of the m datasets
     3. Pool: combine estimates using Rubin's rules (handles uncertainty from imputation)

   Rule of thumb: m >= 5 imputations; m >= 20 for publication; m = 40-100 if
   missingness is > 20% on any variable.
==============================================================================*/

clear all
set more off

use "CES2020_clean.dta", clear


*==============================================================================
* SECTION 1: ASSESS MISSING DATA BEFORE IMPUTING
*==============================================================================

/*
   Good MI practice:
   - Impute only if MAR is defensible (missingness depends on observed vars)
   - Never impute the outcome Y (voted, biden_voter)
   - Include the outcome in the imputation model even if you won't impute it
   - Include auxiliary variables (strong predictors of missingness or Y) in
     the imputation model even if they won't be in the analysis model
*/

* Check missingness on analysis variables
misstable summarize age education ideology5 party_id7 imm_restrict ///
    econ_retro college white_nh sex voted biden_voter

/*
   In CES, missingness is generally low because YouGov uses panel data
   with pre-filled profile variables. Ideology and party ID have the most.
*/

* Is missingness on ideology5 predicted by observed variables? (MAR plausibility)
gen miss_ideo = missing(ideology5)
quietly logit miss_ideo sex age college white_nh census_region
estat classification   /* significant predictors → MAR plausible */
drop miss_ideo


*==============================================================================
* SECTION 2: SET UP MI — DECLARE AND REGISTER
*==============================================================================

/*
   Step 1: mi set — declare the format of the MI dataset
     wide  = all imputed values in same row (good for small datasets)
     long  = separate rows per imputation (more memory-efficient for large data)
     flong = "full long" — includes original + m imputed datasets as rows

   Step 2: mi register — tell Stata which variables are imputed and which are complete
     mi register imputed   = variables with missing that will be imputed
     mi register regular   = variables that are fully observed (never imputed)
     mi register passive   = variables derived from imputed vars (recomputed after imputation)
*/

* Keep only the variables we need for the analysis to save memory
keep caseid age sex education race_eth hispanic_id white_nh college ///
     birth_year census_region state_fips ///
     ideology5 party_id3 party_id7 dem rep ///
     imm_restrict econ_retro hh_income_change ///
     approve_trump self_rated_health ///
     voted voted_2020 pres_vote biden_voter ///
     wt_post

* Set MI format
mi set wide

* Register variables with missing as imputed
mi register imputed ideology5 party_id7 party_id3 econ_retro ///
    self_rated_health hh_income_change approve_trump

* Register complete variables as regular
mi register regular caseid age sex education college white_nh ///
    census_region state_fips birth_year wt_post ///
    voted voted_2020 pres_vote biden_voter
mi register passive dem rep   // derived from imputed party_id3

/*
   Note: imm_restrict is derived from multiple imputed attitude items.
   We treat it as regular here for simplicity. In a thorough analysis
   you would impute the component items and recompute imm_restrict
   as a passive variable.
*/


*==============================================================================
* SECTION 3: IMPUTE — RUN THE IMPUTATION MODEL
*==============================================================================

/*
   mi impute chained (MICE — Multivariate Imputation by Chained Equations)
   is the most flexible method. It imputes each variable one at a time
   using the others as predictors, cycling through multiple times.

   Specify the imputation model for each variable by type:
     (regress)    for continuous variables
     (logit)      for binary variables
     (ologit)     for ordinal categorical variables
     (mlogit)     for nominal categorical variables
     (pmm)        predictive mean matching — good for non-normal continuous

   add(m) = create m imputed datasets
   rseed() = set random seed for reproducibility
   burnin() = number of burn-in iterations before saving (default 10)
   dots    = show progress
*/

mi impute chained ///
    (ologit)  ideology5 party_id7 party_id3 econ_retro ///
              hh_income_change approve_trump ///
    (regress) self_rated_health ///
    = age sex education college white_nh census_region voted ///
    , ///
    add(20) ///
    rseed(20240101) ///
    burnin(10) ///
    dots

/*
   This creates _1_ideology5, _2_ideology5, ... _20_ideology5 etc.
   (in wide format). mi describe shows what was created.
*/
mi describe


*==============================================================================
* SECTION 4: DIAGNOSTICS — DID IMPUTATION WORK?
*==============================================================================

/*
   After imputation, compare the distributions of imputed vs. observed values.
   Large differences suggest the imputation model is misspecified.
*/

* Compare observed vs. imputed means
mi xeq 0: summarize ideology5 party_id7 econ_retro   /* observed only */
mi xeq 1/5: summarize ideology5 party_id7 econ_retro /* imputed datasets */

/*
   mi xeq 0: runs command on the original data (_mi_m == 0)
   mi xeq 1/5: runs command on imputed datasets 1 through 5
   Means should be similar — big differences = imputation problem
*/

* Trace plots (convergence check for MICE)
* After mi impute chained ... , chainonly savetrace(trace_data, replace)
* These require re-running with the savetrace option and then plotting.


*==============================================================================
* SECTION 5: ANALYZE — RUN MODELS ON ALL IMPUTED DATASETS
*==============================================================================

/*
   Any mi estimate: prefix automatically:
   - Runs the specified command on each of the m imputed datasets
   - Pools the results using Rubin's rules
   - Reports combined estimates with proper SEs that account for
     both within-imputation and between-imputation variance
*/

* --- OLS regression on multiply imputed data ---
mi estimate: regress imm_restrict education age ideology5 party_id7 ///
    i.sex i.census_region college white_nh

/*
   Output looks like regular regress output, but SEs are larger because
   they incorporate imputation uncertainty. F-stats use mi-adjusted df.
*/

* Store estimates
mi estimate, saving(mi_ols, replace): ///
    regress imm_restrict education age ideology5 party_id7 ///
    i.sex i.census_region college white_nh

* --- Logit on MI data ---
mi estimate: logit voted education age ideology5 party_id7 ///
    i.sex i.census_region college white_nh, vce(robust)

* Logit with odds ratios
mi estimate, eform("Odds Ratio"): ///
    logit voted education age ideology5 party_id7 ///
    i.sex i.census_region, vce(robust)


*==============================================================================
* SECTION 6: POOL AND DISPLAY RESULTS
*==============================================================================

/*
   mi estimate automatically pools. But if you saved estimates with
   mi estimate, saving() you can replay or post-process them.
*/

* Replay the saved MI estimates
estimates use mi_ols
estimates replay

/*
   Rubin's rules combine m point estimates and m variance estimates:
   - Pooled estimate = average of m estimates
   - Total variance  = within-imputation variance + (1+1/m) × between-imputation variance
   - Fraction of information due to missingness (FMI) shown in output
     FMI ≈ 0 = imputation didn't matter much (variable had little missing)
     FMI > .3 = substantial missing-data uncertainty
*/


*==============================================================================
* SECTION 7: COMPARE MI TO COMPLETE-CASE (SENSITIVITY CHECK)
*==============================================================================

/*
   Always compare MI estimates to complete-case (listwise deletion) estimates.
   If they are similar, the MAR assumption likely holds.
   If they differ substantially, investigate why.
*/

* Complete-case OLS
quietly regress imm_restrict education age ideology5 party_id7 ///
    i.sex i.census_region college white_nh
estimates store cc_ols

* MI OLS (re-run to get current estimates in memory)
mi estimate: regress imm_restrict education age ideology5 party_id7 ///
    i.sex i.census_region college white_nh
estimates store mi_ols_v2

* Compare
esttab cc_ols mi_ols_v2, ///
    b(%8.3f) se(%8.3f) ///
    star(* 0.05 ** 0.01 *** 0.001) ///
    stats(r2 N, fmt(%8.3f %8.0f)) ///
    title("OLS: Complete-Case vs. Multiple Imputation") ///
    mtitles("Complete Case" "MI (m=20)")


*==============================================================================
* SECTION 8: PASSIVE IMPUTATION — DERIVED VARIABLES
*==============================================================================

/*
   Variables derived from imputed vars (e.g., a scale score) must be
   recomputed after each imputation — not imputed directly.

   mi passive: reruns a transformation in each imputed dataset.

   Example: if we had imputed the component immigration items, we would
   recompute imm_restrict as a passive variable.
*/

* Simulate: re-register dem and rep as passive (derived from imputed party_id3).
* NOTE: In a properly structured MI workflow this registration happens BEFORE
* mi impute chained runs. Shown here at the end for teaching purposes only.
* Changing a variable's role after imputation is allowed but means the passive
* recomputation applies only when you call mi passive: going forward.
* passive dem rep already registered at top of section 2

mi passive: replace dem = (party_id3 == 1) if !missing(party_id3)
mi passive: replace rep = (party_id3 == 2) if !missing(party_id3)

* Verify across imputed datasets
mi xeq 1/3: tab dem


*==============================================================================
* SECTION 9: SAVE THE MI DATASET
*==============================================================================

/*
   Save the mi-declared dataset — it contains all m imputed datasets.
   Load this file in any analysis script that needs MI.
*/

save "CES2020_mi.dta", replace
di "MI dataset saved: CES2020_mi.dta (m=20 imputed datasets)"

/*
   To reload and use in another do-file:
     use "CES2020_mi.dta", clear
     mi svyset [pweight=wt_post]   /* if using survey weights with MI */
     mi estimate: svy: regress ...
*/

di "Module 10 complete."
