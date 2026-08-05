/*==============================================================================
   MODULE 12: PANEL DATA & REPEATED MEASURES
   Dataset: CES 2020 Common Content (cleaned from Module 1)
            + Simulated panel structure

   Purpose: Demonstrate fixed effects (FE), random effects (RE), and
   difference-in-differences (DiD) using Stata's xtset suite.

   NOTE: The CES 2020 cross-section is used as a base. We simulate a
   two-wave panel to demonstrate mechanics. The CES Cumulative File
   (2006-2022) is a true panel and can be used with these techniques.

   PANEL DATA = the same units (people, states, firms) observed across
   multiple time periods. This structure lets you control for time-invariant
   unobserved confounders — a major advantage over cross-sections.
==============================================================================*/

clear all
set more off


*==============================================================================
* SECTION 1: CREATE A SIMULATED TWO-WAVE PANEL FROM CES 2020
*==============================================================================

/*
   We simulate a pre/post panel by:
   1. Loading CES respondents (wave 1, t=0 = pre-election)
   2. Duplicating them as wave 2 (t=1 = post-election)
   3. Adding simulated change in ideology over time for a treatment group

   This is for teaching mechanics only — treat the "results" as illustrative.
*/

use "CES2020_clean.dta", clear

* Keep a manageable set of variables
keep caseid age sex education race_eth college white_nh ///
     census_region state_fips ideology5 party_id3 dem rep ///
     imm_restrict econ_retro voted wt_post

* Wave 1 (baseline)
gen wave = 0
save "ces_wave1.dta", replace

* Wave 2 (follow-up) — simulate change in ideology for treated group
* "Treatment" = college-educated respondents were "treated" with post-election info
use "ces_wave1.dta", clear
replace wave = 1

* Add noise to ideology to simulate panel variation
set seed 20240101
gen ideo_noise = rnormal(0, .5)

* Treatment effect: college-educated respondents move slightly more liberal (−.3)
replace ideology5 = ideology5 - 0.3 + ideo_noise if college == 1 & wave == 1
replace ideology5 = ideology5 + ideo_noise       if college == 0 & wave == 1
drop ideo_noise

* Clamp to valid range
replace ideology5 = max(1, min(5, ideology5))

append using "ces_wave1.dta"

* Sort by respondent and wave
sort caseid wave


*==============================================================================
* SECTION 2: DECLARE PANEL STRUCTURE WITH XTSET
*==============================================================================

/*
   xtset unitvar timevar

   unitvar = the panel (individual/group) ID variable
   timevar = the time variable

   After xtset, all xt* commands use this structure.
   Also enables:
     L.varname  = lagged value (t-1)
     F.varname  = lead value (t+1)
     D.varname  = first difference (t - t-1)
*/

xtset caseid wave

xtdescribe   /* summarizes panel structure — how balanced? */
xtsum ideology5 imm_restrict education   /* within vs. between variance */

/*
   xtsum decomposes variance:
   - "between" = variance across units (like a cross-section)
   - "within"  = variance within units over time
   Fixed effects use ONLY within variance — if within variance is very small,
   FE estimates will be imprecise (low power).
*/


*==============================================================================
* SECTION 3: POOLED OLS (NAIVE BASELINE)
*==============================================================================

/*
   Pooled OLS ignores the panel structure — treats all obs as independent.
   This underestimates SEs because observations from the same person are
   correlated. Use as a baseline only; always follow with FE or RE.
*/

regress ideology5 college wave age sex i.census_region, vce(robust)
estimates store pooled_ols

/*
   Clustering by caseid gives correct SEs for pooled OLS:
*/
regress ideology5 college wave age sex i.census_region, vce(cluster caseid)
estimates store pooled_cluster


*==============================================================================
* SECTION 4: FIXED EFFECTS (WITHIN ESTIMATOR)
*==============================================================================

/*
   xtreg depvar indepvars, fe

   Fixed effects removes all between-unit variation by demeaning each
   variable within units. This means:
   - Time-invariant variables (sex, race, state) drop out completely
   - Only the WITHIN-UNIT change in X explains the within-unit change in Y
   - Controls for ALL unobserved time-invariant confounders (education,
     personality, genetics — anything that doesn't change over waves)

   xtreg estimates β by regressing (Y_it - Ȳ_i) on (X_it - X̄_i)

   vce(robust) = cluster-robust SEs (clusters on the panel unit by default)
*/

xtreg ideology5 college wave, fe vce(robust)
estimates store fe_model

/*
   Notice:
   - age and sex have dropped (time-invariant in our simulation)
   - R-sq "within" = variance explained by within-unit changes
   - "sigma_u" = SD of unit fixed effects
   - "sigma_e" = SD of residuals
   - "rho"     = fraction of variance due to unit FE (intraclass correlation)
*/


*==============================================================================
* SECTION 5: RANDOM EFFECTS
*==============================================================================

/*
   xtreg depvar indepvars, re

   Random effects assumes unit-specific intercepts are UNCORRELATED with
   the predictors. This is a strong assumption that is often violated in
   observational data (omitted variable bias at the unit level).

   Advantage over FE: time-invariant predictors can be included.
   Use when: units are a random sample from a population AND the
             RE assumption is defensible.

   Use the Hausman test to choose between FE and RE.
*/

xtreg ideology5 college wave age i.sex, re vce(robust)
estimates store re_model


*==============================================================================
* SECTION 6: HAUSMAN TEST — FE vs. RE
*==============================================================================

/*
   The Hausman test checks whether coefficients from FE and RE differ
   significantly. Under H0 (RE is consistent), FE and RE give similar estimates.
   A significant Hausman test → RE is inconsistent → use FE.

   Note: with vce(robust), use xtoverid instead of hausman
   (install: ssc install xtoverid)
*/

* Run RE without robust SEs for Hausman
quietly xtreg ideology5 college wave, re
estimates store re_hausman

quietly xtreg ideology5 college wave, fe
estimates store fe_hausman

hausman fe_hausman re_hausman, sigmamore

/*
   Significant p-value: RE is inconsistent — use fixed effects.
   Non-significant: RE may be consistent and more efficient than FE.
*/


*==============================================================================
* SECTION 7: FIRST DIFFERENCES
*==============================================================================

/*
   First differencing is equivalent to FE with two waves:
   ΔY_i = Y_i2 - Y_i1
   ΔX_i = X_i2 - X_i1

   Regress ΔY on ΔX — the unit-specific constant cancels.
   Advantage: explicit, intuitive; you can see exactly what you're modeling.
   With T=2 panels, FD and FE give identical estimates.
*/

* Compute first differences manually
sort caseid wave
by caseid: gen d_ideology5 = ideology5 - ideology5[_n-1] if wave == 1
by caseid: gen d_college   = college   - college[_n-1]   if wave == 1

* Keep only wave-1 rows (where differences are defined)
preserve
keep if wave == 1

regress d_ideology5 d_college, vce(robust)
estimates store fd_model

restore


*==============================================================================
* SECTION 8: DIFFERENCE-IN-DIFFERENCES (DiD)
*==============================================================================

/*
   DiD compares the change in Y for a treated group vs. a control group
   across two time periods. It identifies causal effects under the
   "parallel trends" assumption: absent treatment, treated and control
   would have changed by the same amount.

   DiD setup:
   - treated = 1 for units assigned to treatment (college==1 here)
   - post    = 1 for post-treatment period (wave==1 here)
   - DiD coefficient = β on (treated × post)

   Manual interaction approach in regression:
   Y = β0 + β1(post) + β2(treated) + β3(post×treated) + controls + ε
   β3 = the average treatment effect on the treated (ATT)
*/

gen treated = college
gen post    = wave

gen did = treated * post   /* interaction = DiD coefficient */

* DiD regression
regress ideology5 treated post did, vce(cluster caseid)
estimates store did_manual

/*
   β3 (did) = change in ideology in the treated group relative to the
   control group's change. Negative = treatment made treated group more liberal.
*/

* Equivalent using i. notation (recommended — Stata handles base categories)
regress ideology5 i.treated##i.post, vce(cluster caseid)
estimates store did_notation

/*
   1.treated#1.post = the DiD coefficient
   These two regressions give identical results — just different notation.
*/

* Add controls
regress ideology5 i.treated##i.post age i.sex i.census_region, ///
    vce(cluster caseid)
estimates store did_controls


*==============================================================================
* SECTION 9: PARALLEL TRENDS DIAGNOSTIC
*==============================================================================

/*
   You can't test parallel trends directly (it's counterfactual), but you
   can provide suggestive evidence with:
   1. A graph of group trends over time (see Module 6 for graphing)
   2. An event study with leads and lags (requires T ≥ 3)
   3. A "placebo" DiD using a pre-treatment period

   Here we show the graphical check with our two-wave simulation.
*/

collapse (mean) mean_ideo = ideology5, by(treated wave)

twoway ///
    (connected mean_ideo wave if treated == 0, ///
        lcolor(navy) mcolor(navy) msymbol(circle) ///
        lpattern(solid)) ///
    (connected mean_ideo wave if treated == 1, ///
        lcolor(red) mcolor(red) msymbol(square) ///
        lpattern(solid)), ///
    xline(0.5, lcolor(gray) lpattern(dash)) ///
    xlabel(0 "Pre" 1 "Post") ///
    title("Parallel Trends Check") ///
    subtitle("Mean Ideology by Treatment Group and Wave") ///
    ytitle("Mean Ideology (1=Very Liberal, 5=Very Conservative)") ///
    legend(label(1 "No College (Control)") label(2 "College (Treated)"))

graph export "parallel_trends.png", replace width(1200)


*==============================================================================
* SECTION 10: DISPLAY RESULTS TABLE
*==============================================================================

use "CES2020_clean.dta", clear   /* reload non-panel data for fresh context */

esttab pooled_ols fe_model re_model did_controls, ///
    b(%8.3f) se(%8.3f) ///
    star(* 0.05 ** 0.01 *** 0.001) ///
    title("Panel Models: Effect of College on Ideology") ///
    mtitles("Pooled OLS" "Fixed Effects" "Random Effects" "DiD") ///
    note("Note: FE estimates are within-unit; DiD adds treatment×post interaction.")

di "Module 12 complete."
